#import <Foundation/Foundation.h>

@interface DevicePermissionsHelper : NSObject

+ (void)audioPermissionWithCompletionHandler:(void (^)(BOOL granted))handler;
+ (void)videoPermissionWithCompletionHandler:(void (^)(BOOL granted))handler;

+ (UIAlertController*)audioPermisionAlertController;
+ (UIAlertController*)videoPermisionAlertController;

@end
