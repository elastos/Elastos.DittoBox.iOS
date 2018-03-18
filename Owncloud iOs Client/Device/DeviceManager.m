#import "DeviceManager.h"
#import "MBProgressHUD.h"

static NSString * const KEY_CurrentDeviceId = @"currentDeviceIdentifier";

@interface DeviceManager () <ELACarrierDelegate>
{
    BOOL initializerd;
    ELACarrier *elaCarrier;
    ELACarrierConnectionStatus connectStatus;
    NSMutableArray *devices;
    Device *currentDevice;
    dispatch_queue_t managerDeviceQueue;
}
@end

@implementation DeviceManager

+ (DeviceManager *)sharedManager
{
    static DeviceManager *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    
    return instance;
}

- (instancetype)init {
    if (self = [super init]) {
        initializerd = NO;
        connectStatus = ELACarrierConnectionStatusDisconnected;
        managerDeviceQueue = dispatch_queue_create("managerDeviceQueue", NULL);
        [ELACarrier setLogLevel:ELACarrierLogLevelDebug];

        //[self checkNetworkConnection];
    }
    return self;
}

//- (void)checkNetworkConnection
//{
//    NSURL *url = [NSURL URLWithString:[API_SERVER stringByAppendingString:@"/version"]];
//    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:3];
//    NSURLSession *urlSession = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:nil delegateQueue:nil];
//    [[urlSession dataTaskWithRequest:urlRequest] resume];
//}

- (void)start:(void (^)(NSError *error))completion
{
    if (initializerd) {
        return;
    }
    
    initializerd = YES;
    
    dispatch_async(managerDeviceQueue, ^{
        NSError *error = nil;
        if (elaCarrier == nil) {
            NSString *libraryDirectory = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES)[0];
            NSString *elaDirectory = [libraryDirectory stringByAppendingPathComponent:@"elastos"];
            if (![[NSFileManager defaultManager] fileExistsAtPath:elaDirectory]) {
                NSURL *url = [NSURL fileURLWithPath:elaDirectory];
                if (![[NSFileManager defaultManager] createDirectoryAtURL:url withIntermediateDirectories:YES attributes:nil error:&error]) {
                    DLog(@"Create ELACarrier persistent directory failed: %@", error);
                    connectStatus = ELACarrierConnectionStatusDisconnected;
                    initializerd = NO;
                    if (completion) {
                        completion(error);
                    }
                    return;
                }

                [url setResourceValue:@YES forKey:NSURLIsExcludedFromBackupKey error:nil];
            }

            NSString *plistPath = [[NSBundle mainBundle]pathForResource:@"ElastosCarrier" ofType:@"plist"];
            NSDictionary *config = [[NSDictionary alloc]initWithContentsOfFile:plistPath];
            NSArray *bootstraps = config[@"Bootstraps"];
            NSMutableArray *bootstrapNodes = [[NSMutableArray alloc] initWithCapacity:bootstraps.count];
            for (NSDictionary *bootstrap in bootstraps) {
                ELABootstrapNode *node = [[ELABootstrapNode alloc] init];
                node.ipv4 = bootstrap[@"ipv4"];
                node.ipv6 = bootstrap[@"ipv6"];
                node.port = bootstrap[@"port"];
                node.publicKey = bootstrap[@"public_key"];
                [bootstrapNodes addObject:node];
            }
            
            ELACarrierOptions *options = [[ELACarrierOptions alloc] init];
            options.persistentLocation = elaDirectory;
            options.udpEnabled = [config[@"udp_enabled"] boolValue];
            options.bootstrapNodes = bootstrapNodes;

            elaCarrier = [ELACarrier getInstanceWithOptions:options delegate:self error:&error];
            initializerd = NO;
            if (elaCarrier == nil) {
                DLog(@"Create ELACarrier instance failed: %@", error);
                connectStatus = ELACarrierConnectionStatusDisconnected;
                if (completion) {
                    completion(error);
                }
                return;
            }
        }

        initializerd = [elaCarrier startWithIterateInterval:1000 error:&error];
        if (initializerd) {
            devices = [[NSMutableArray alloc] init];
        }
        else {
            DLog(@"Start ELACarrier instance failed: %@", error);
            [elaCarrier kill];
            elaCarrier = nil;
            connectStatus = ELACarrierConnectionStatusDisconnected;
        }

        if (completion) {
            completion(error);
        }
    });
}

- (void)logout
{
    [self cleanup];

    NSString *libraryDirectory = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES)[0];
    NSString *elaDirectory = [libraryDirectory stringByAppendingPathComponent:@"elastos"];
    [[NSFileManager defaultManager] removeItemAtPath:elaDirectory error:nil];
}

- (void)cleanup
{
    for (Device *device in devices) {
        [device disconnect];
    }

    devices = nil;
    currentDevice = nil;

    [[ELACarrierSessionManager getInstance] cleanup];
    [elaCarrier kill];
    elaCarrier = nil;

    initializerd = NO;
    connectStatus = ELACarrierConnectionStatusDisconnected;
}

- (NSArray *)devices
{
    return devices;
}

- (Device *)currentDevice
{
    return currentDevice;
}

- (void)setCurrentDevice:(Device *)device
{
    if (device == nil) {
        currentDevice = nil;
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:KEY_CurrentDeviceId];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    else if (device != currentDevice && [devices containsObject:device]) {
        currentDevice = device;
        [[NSUserDefaults standardUserDefaults] setObject:device.deviceId forKey:KEY_CurrentDeviceId];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        [currentDevice connect];
    }
}

- (BOOL)setDeviceLabel:(Device *)device
              newLabel:(NSString *)newLabel
                 error:(NSError *__autoreleasing *)error
{
    return [elaCarrier setLabelForFriend:device.deviceId withLabel:newLabel error:error];
}

- (BOOL)pairWithDevice:(NSString *)deviceID
              passWord:(NSString *)password
                 error:(NSError *__autoreleasing *)error
{
    NSError *err = nil;
    if ([elaCarrier addFriendWith:deviceID withGreeting:password error:&err]) {
        return NO;
    }

    if (err.code == 0x100000C) {
        return YES;
    }

    *error = err;
    return NO;
}

- (BOOL)unPairDevice:(Device *)device
               error:(NSError *__autoreleasing *)error
{
    return [elaCarrier removeFriend:device.deviceId error:error];
}

- (ELACarrierUserInfo *)selfInfo
{
    return [elaCarrier getSelfUserInfo:nil];
}

#pragma mark - ELACarrierDelegate

//- (void)carrierWillBecomeIdle:(ELACarrier * _Nonnull)carrier
//{
//    BLYLogDebug(@"elaWillBecomeIdle");
//}

- (void)carrier:(ELACarrier *)carrier connectionStatusDidChange:(enum ELACarrierConnectionStatus)newStatus
{
    DLog(@"connectionStatusDidChange : %d", (int)newStatus);
    connectStatus = newStatus;

    if (connectStatus == ELACarrierConnectionStatusDisconnected) {
        for (Device *device in devices) {
            [device disconnect];
        }

        [devices removeAllObjects];
        currentDevice = nil;

        [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationDeviceListUpdated object:nil userInfo:nil];

        if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [MBProgressHUD showToast:NSLocalizedString(@"连接服务器失败", nil) inView:[UIApplication sharedApplication].delegate.window duration:3 animated:YES];
            });
        }
    }
}

- (void)carrierDidBecomeReady:(ELACarrier *)carrier
{
    DLog(@"didBecomeReady");
    ELACarrierUserInfo *selfInfo = [carrier getSelfUserInfo:nil];
    if (selfInfo.name.length == 0) {
        selfInfo.name = [UIDevice currentDevice].name;
        [carrier setSelfUserInfo:selfInfo error:nil];
    }

    [ELACarrierSessionManager getInstance:carrier error:nil];
    [self.currentDevice connect];
}

- (void)carrier:(ELACarrier *)carrier selfUserInfoDidChange:(ELACarrierUserInfo *)newInfo
{
    DLog(@"selfUserInfoDidChange : %@", newInfo);
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationSelfInfoUpdated object:newInfo userInfo:nil];
}

- (void)carrier:(ELACarrier *)carrier didReceiveFriendsList:(NSArray<ELACarrierFriendInfo *> *)friends
{
    DLog(@"didReceiveFriendsList : %@", friends);

    NSString *savedDeviceId = [[NSUserDefaults standardUserDefaults] objectForKey:KEY_CurrentDeviceId];

    for (ELACarrierFriendInfo *friend in friends) {
        Device *device = [[Device alloc] initWithDeviceInfo:friend];
        [devices addObject:device];

        if ([device.deviceId isEqualToString:savedDeviceId]) {
            self.currentDevice = device;
        }
    }

    if (self.currentDevice == nil && devices.count > 0) {
        for (Device *device in devices) {
            if (device.isOnline) {
                self.currentDevice = device;
                break;
            }
        }

        if (self.currentDevice == nil) {
            self.currentDevice = devices[0];
        }
    }

    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationDeviceListUpdated object:nil userInfo:nil];
}

- (void)carrier:(ELACarrier *)carrier friendInfoDidChange:(NSString *)friendId newInfo:(ELACarrierFriendInfo *)newInfo
{
    DLog(@"friendInfoDidChange : %@", newInfo);
    for (Device *device in devices) {
        if ([device.deviceId isEqual:friendId]) {
            [device performSelector:@selector(setDeviceInfo:) withObject:newInfo];
            [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationDeviceListUpdated object:nil userInfo:nil];
            break;
        }
    }
}

- (void)carrier:(ELACarrier *)carrier friendConnectionDidChange:(NSString *)friendId newStatus:(ELACarrierConnectionStatus)newStatus
{
    DLog(@"friendConnectionDidChange, userId : %@, newStatus : %zd", friendId, newStatus);
    for (Device *device in devices) {
        if ([device.deviceId isEqual:friendId]) {
            device.deviceInfo.status = newStatus;
            if (device.isOnline) {
                if (self.currentDevice == nil) {
                    self.currentDevice = device;
                }
                else if (self.currentDevice == device) {
                    [device connect];
                }
            }
            else {
                [device disconnect];
            }
            [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationDeviceListUpdated object:nil userInfo:nil];
            break;
        }
    }
}

- (void)carrier:(ELACarrier *)carrier friendPresenceDidChange:(NSString *)friendId newPresence:(ELACarrierPresenceStatus)newPresence
{
    DLog(@"friendPresenceDidChange, userId : %@, newPresence : %zd", friendId, newPresence);
    for (Device *device in devices) {
        if ([device.deviceId isEqual:friendId]) {
            device.deviceInfo.presence = newPresence;
            if (device.isOnline) {
                if (self.currentDevice == nil) {
                    self.currentDevice = device;
                }
                else if (self.currentDevice == device) {
                    [device connect];
                }
            }
            else {
                [device disconnect];
            }
            [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationDeviceListUpdated object:nil userInfo:nil];
            break;
        }
    }
}

- (void)carrier:(ELACarrier *)carrier didReceiveFriendRequestFromUser:(NSString *)userId withUserInfo:(ELACarrierUserInfo *)userInfo hello:(NSString *)hello
{
    DLog(@"didReceiveFriendRequestFromUser, userId : %@", userId);
}

- (void)carrier:(ELACarrier *)carrier newFriendAdded:(ELACarrierFriendInfo *)newFriend
{
    DLog(@"newFriendAdded : %@", newFriend);
    Device *device = [[Device alloc] initWithDeviceInfo:newFriend];
    [devices addObject:device];
    if (self.currentDevice == nil) {
        self.currentDevice = device;
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationDeviceListUpdated object:nil userInfo:nil];
}

- (void)carrier:(ELACarrier *)carrier friendRemoved:(NSString *)friendId
{
    for (Device *device in devices) {
        if ([device.deviceId isEqual:friendId]) {
            [device disconnect];
            [devices removeObject:device];

            if (self.currentDevice == device) {
                self.currentDevice = nil;

                if (devices.count > 0) {
                    for (Device *device in devices) {
                        if (device.isOnline) {
                            self.currentDevice = device;
                            break;
                        }
                    }

                    if (self.currentDevice == nil) {
                        self.currentDevice = devices[0];
                    }
                }
            }

            [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationDeviceListUpdated object:nil userInfo:nil];
            break;
        }
    }
}

@end
