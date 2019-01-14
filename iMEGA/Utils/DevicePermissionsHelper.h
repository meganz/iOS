
#import <Foundation/Foundation.h>

@interface DevicePermissionsHelper : NSObject

+ (void)audioPermissionModal:(BOOL)modal forIncomingCall:(BOOL)incomingCall withCompletionHandler:(void (^)(BOOL granted))handler;
+ (void)videoPermissionWithCompletionHandler:(void (^)(BOOL granted))handler;
+ (void)photosPermissionWithCompletionHandler:(void (^)(BOOL granted))handler;
+ (void)notificationsPermissionWithCompletionHandler:(void (^)(BOOL granted))handler;

+ (void)alertAudioPermission;
+ (void)alertVideoPermissionWithCompletionHandler:(void (^)(void))handler;
+ (void)alertPhotosPermission;

+ (void)modalNotificationsPermission;

+ (BOOL)shouldAskForAudioPermissions;
+ (BOOL)shouldAskForVideoPermissions;
+ (BOOL)shouldAskForPhotosPermissions;
+ (BOOL)shouldAskForNotificationsPermissions;
+ (BOOL)shouldSetupPermissions;

@end
