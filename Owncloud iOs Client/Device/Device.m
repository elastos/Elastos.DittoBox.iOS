#import "Device.h"
#import "AsyncSocket.h"

static NSString * const KEY_LocalPort = @"localPort";

@interface Device () <ELACarrierStreamDelegate>
{
    ELACarrierSession *_session;
    ELACarrierStream *_stream;
    ELACarrierStreamState _state;
    NSInteger _portForwardingID;
}

@property (nonatomic, strong) ELACarrierFriendInfo *deviceInfo;
@end

@implementation Device

- (instancetype)initWithDeviceInfo:(ELACarrierFriendInfo *)deviceInfo;
{
    if (self = [super init]) {
        _deviceInfo = deviceInfo;
        _state = 0;
        _portForwardingID = 0;
        
        NSDictionary *deviceConfig = [[NSUserDefaults standardUserDefaults] objectForKey:self.deviceId];
        if (deviceConfig) {
            _localPort = [deviceConfig[KEY_LocalPort] intValue];
        }
    }
    return self;
}

- (void)dealloc
{
    [self disconnect];
}

- (NSString *)deviceId
{
    return self.deviceInfo.userId;
}

- (NSString *)deviceName
{
    NSString *deviceName = self.deviceInfo.label;
    if (deviceName.length == 0) {
        deviceName = self.deviceInfo.name;
        if (deviceName.length == 0) {
            deviceName = self.deviceInfo.userId;
        }
    }
    return deviceName;
}

- (BOOL)isOnline
{
    return self.deviceInfo.status == ELACarrierConnectionStatusConnected && self.deviceInfo.presence == ELACarrierPresenceStatusNone;
}

- (BOOL)connect
{
    if (!self.isOnline) {
        return NO;
    }

    if (_portForwardingID > 0) {
        return YES;
    }

    if (_session == nil) {
        ELACarrierSessionManager *sessionManager = [ELACarrierSessionManager getInstance];
        if (sessionManager == nil) {
            return NO;
        }

        NSError *error = nil;
        _session = [sessionManager newSessionTo:self.deviceId error:&error];
        if (_session == nil) {
            DLog(@"Create session error: %@", error);
            [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationDeviceConnectFailed object:self userInfo:@{@"error": error}];
            return NO;
        }
    }

    if (_stream == nil) {
        ELACarrierStreamOptions options = ELACarrierStreamOptionMultiplexing | ELACarrierStreamOptionPortForwarding | ELACarrierStreamOptionReliable;

        NSError *error = nil;
        _stream = [_session addStreamWithType:ELACarrierStreamTypeApplication options:options delegate:self error:&error];
        if (_stream == nil) {
            DLog(@"Add stream error: %@", error);
            [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationDeviceConnectFailed object:self userInfo:@{@"error": error}];
            return NO;
        }
    }
    else if (_state == ELACarrierStreamStateInitialized || _state == ELACarrierStreamStateTransportReady) {
        [self sendInviteRequest];
    }
    else if (_state == ELACarrierStreamStateConnected) {
        [self openPortForwarding];
    }

    return NO;
}

- (void)disconnect
{
    if (_session) {
        _state = -1;

        if (_stream) {
            NSError *error = nil;

            if (_portForwardingID > 0) {
                if (![_stream closePortForwarding:_portForwardingID error:&error]) {
                    DLog(@"Close port forwarding error: %@", error);
                }
                _portForwardingID = 0;
            }

            if (![_session removeStream:_stream error:&error]) {
                DLog(@"Remove stream error: %@", error);
            }
            _stream = nil;
        }

        [_session close];
        _session = nil;
        _state = 0;
    }
}

- (void)setLocalPort:(int)localPort
{
    if (_localPort == 0) {
        return;
    }

    if (_localPort == localPort) {
        return;
    }

    _localPort = localPort;
    [self savePort];
    
    if (_portForwardingID > 0) {
        NSError *error = nil;
        if (![_stream closePortForwarding:_portForwardingID error:&error]) {
            DLog(@"Close port forwarding error: %@", error);
        }
        _portForwardingID = 0;
    }

    if (_state == ELACarrierStreamStateConnected) {
        [self openPortForwarding];
    }
}

- (void)savePort
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *deviceConfig = [[userDefaults objectForKey:self.deviceId] mutableCopy];
    if (deviceConfig == nil) {
        deviceConfig = [NSMutableDictionary dictionaryWithCapacity:1];
    }
    deviceConfig[KEY_LocalPort] = @(_localPort);
    [userDefaults setObject:deviceConfig forKey:self.deviceId];
    [userDefaults synchronize];
}

- (void)sendInviteRequest
{
    NSError *error = nil;
    if (![_session sendInviteRequestWithResponseHandler:
          ^(ELACarrierSession *session, NSInteger status, NSString *reason, NSString *sdp) {
              DLog(@"Invite request response, stream state: %zd", _state);
              if (session != _session || _state != ELACarrierStreamStateTransportReady) {
                  return;
              }

              if (status == 0) {
                  NSError *error = nil;
                  if (![session startWithRemoteSdp:sdp error:&error]) {
                      DLog(@"Start session error: %@", error);
                      [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationDeviceConnectFailed object:self userInfo:@{@"error": error}];
                  }
              }
              else {
                  DLog(@"Remote refused session invite: %d, sdp: %@", (int)status, reason);
                  [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationDeviceConnectFailed object:self userInfo:nil];
              }
          } error:&error]) {
              DLog(@"Session send invite request error: %@", error);
              [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationDeviceConnectFailed object:self userInfo:@{@"error": error}];
          }
}

- (void)openPortForwarding
{
    NSError *error = nil;
    uint16_t localPort = self.localPort;
    if (localPort == 0) {
        localPort = [Device getAvailableLocalPort:&error];
        if (localPort == 0) {
            [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationDeviceConnectFailed object:self userInfo:@{@"error": error}];
            return;
        }
    }
    else if (![Device isPortAvailable:localPort]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationDeviceConnectFailed object:self userInfo:@{@"error": error}];
        return;
    }

    NSNumber *portForwarding = [_stream openPortForwardingForService:@"owncloud"
                                                        withProtocol:ELAPortForwardingProtocolTCP
                                                                host:@"localhost"
                                                                port:[@(localPort) stringValue]
                                                               error:&error];
    if (portForwarding) {
        _portForwardingID = portForwarding.integerValue;
        _localPort = localPort;
        [self savePort];
        DLog(@"Success to open port forwarding : %zd, loacl port : %d", _portForwardingID, localPort);
        [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationDeviceConnected object:self userInfo:nil];
    }
    else {
        DLog(@"Open port forwarding error: %@", error);
        [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationDeviceConnectFailed object:self userInfo:@{@"error": error}];
    }
}

#pragma mark - ELACarrierStreamDelegate
- (void)carrierStream:(ELACarrierStream *)stream stateDidChange:(enum ELACarrierStreamState)newState
{
    DLog(@"Stream state: %d", (int)newState);

    if (stream != _stream || _state < 0) {
        return;
    }

    _state = newState;

    switch (newState) {
        case ELACarrierStreamStateInitialized:
            [self sendInviteRequest];
            break;

        case ELACarrierStreamStateConnected:
            [self openPortForwarding];
            break;

        case ELACarrierStreamStateDeactivated:
        case ELACarrierStreamStateClosed:
        case ELACarrierStreamStateError:
            [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationDeviceConnectFailed object:self userInfo:nil];
            [self disconnect];
            break;

        default:
            break;
    }
}

#pragma mark - static methods

static AsyncSocket *asyncSocket = nil;

+ (BOOL)isPortAvailable:(int)port
{
    if (asyncSocket == nil) {
        asyncSocket = [[AsyncSocket alloc] init];
    }
    asyncSocket.delegate = self;
    
    NSError *error = nil;
    BOOL result = [asyncSocket acceptOnInterface:@"127.0.0.1" port:port error:&error];
    if (result) {
        [asyncSocket disconnect];
    }
    else {
        DLog(@"Port %d is not available: %@", port, error);
    }
    
    return result;
}

+ (uint16_t)getAvailableLocalPort:(NSError * __autoreleasing *)error
{
    if (asyncSocket == nil) {
        asyncSocket = [[AsyncSocket alloc] init];
    }
    asyncSocket.delegate = self;
    
    uint16_t localPort = 0;
    if ([asyncSocket acceptOnInterface:@"127.0.0.1" port:0 error:error]) {
        localPort = [asyncSocket localPort];
        DLog(@"localPort: %d", localPort);
        [asyncSocket disconnect];
    } else {
        DLog(@"Get free localPort failed: %@", *error);
    }
    
    return localPort;
}

@end
