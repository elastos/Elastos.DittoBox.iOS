#import <Foundation/Foundation.h>
#import <ElastosCarrierSDK/ElastosCarrierSDK.h>

#define kNotificationDeviceConnected        @"kNotificationDeviceConnected"
#define kNotificationDeviceConnectFailed    @"kNotificationDeviceConnectFailed"

@interface Device : NSObject

@property (nonatomic, strong, readonly) ELACarrierFriendInfo *deviceInfo;
@property (nonatomic, strong, readonly) NSString *deviceId;
@property (nonatomic, strong, readonly) NSString *deviceName;
@property (nonatomic, assign, readonly) BOOL isOnline;

@property (nonatomic, assign) int localPort;

+ (BOOL)isPortAvailable:(int)port;

- (instancetype)initWithDeviceInfo:(ELACarrierFriendInfo *)deviceInfo;

- (BOOL)connect;
- (void)disconnect;

@end
