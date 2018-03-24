#import <Foundation/Foundation.h>
#import <ElastosCarrier/ElastosCarrier.h>
#import "Device.h"

#define kNotificationDeviceListUpdated      @"kNotificationDeviceListUpdated"
#define kNotificationSelfDisconncted        @"kNotificationSelfDisconncted"
#define kNotificationSelfInfoUpdated        @"kNotificationSelfInfoUpdated"

@interface DeviceManager : NSObject

@property (nonatomic, strong, readonly) ELACarrierUserInfo *selfInfo;
@property (nonatomic, strong, readonly) NSArray *devices;
@property (nonatomic, strong) Device *currentDevice;

+ (DeviceManager *)sharedManager;

- (void)cleanup;

- (void)start:(void (^)(NSError *error))completion;

- (void)logout;

- (BOOL)setDeviceLabel:(Device *)device
              newLabel:(NSString *)newLabel
                 error:(NSError **)error;

- (BOOL)pairWithDevice:(NSString *)deviceID
              passWord:(NSString *)password
                 error:(NSError **)error;

- (BOOL)unPairDevice:(Device *)device
               error:(NSError **)error;

@end
