
#import <Foundation/Foundation.h>

@interface DevicePermissionsHelper : NSObject

+ (void)audioPermissionWithCompletionHandler:(void (^)(BOOL granted))handler;
+ (void)videoPermissionWithCompletionHandler:(void (^)(BOOL granted))handler;
+ (void)photosPermissionWithCompletionHandler:(void (^)(BOOL granted))handler;
+ (void)notificationsPermissionWithCompletionHandler:(void (^)(BOOL granted))handler;

+ (void)warnAboutPhotosPermission;
+ (void)warnAboutAudioAndVideoPermissions;
+ (void)warnAboutNotificationsPermission;

+ (BOOL)shouldAskForAudioPermissions;
+ (BOOL)shouldAskForVideoPermissions;
+ (BOOL)shouldAskForPhotosPermissions;
+ (BOOL)shouldAskForNotificationsPermissions;
+ (BOOL)shouldSetupPermissions;

@end
