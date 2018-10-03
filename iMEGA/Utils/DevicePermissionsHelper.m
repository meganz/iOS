
#import "DevicePermissionsHelper.h"

#import <AVFoundation/AVFoundation.h>
#import <Photos/Photos.h>
#import <UserNotifications/UserNotifications.h>

#import "CustomModalAlertViewController.h"
#import "UIApplication+MNZCategory.h"
#import "UIColor+MNZCategory.h"

@implementation DevicePermissionsHelper

+ (void)audioPermissionWithCompletionHandler:(void (^)(BOOL granted))handler {
    if ([AVCaptureDevice respondsToSelector:@selector(requestAccessForMediaType:completionHandler:)]) {
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeAudio completionHandler:^(BOOL permissionGranted) {
            if (handler) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    handler(permissionGranted);
                });
            }
        }];
    }
}

+ (void)videoPermissionWithCompletionHandler:(void (^)(BOOL granted))handler {
    if ([AVCaptureDevice respondsToSelector:@selector(requestAccessForMediaType:completionHandler:)]) {
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL permissionGranted) {
            if (handler) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    handler(permissionGranted);
                });
            }
        }];
    }
}

+ (void)photosPermissionWithCompletionHandler:(void (^)(BOOL granted))handler {
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        if (handler) {
            dispatch_async(dispatch_get_main_queue(), ^{
                handler(status == PHAuthorizationStatusAuthorized);
            });
        }
    }];
}

+ (void)notificationsPermissionWithCompletionHandler:(void (^)(BOOL))handler {
    if (@available(iOS 10.0, *)) {
        [UNUserNotificationCenter.currentNotificationCenter requestAuthorizationWithOptions:(UNAuthorizationOptionBadge | UNAuthorizationOptionSound | UNAuthorizationOptionAlert) completionHandler:^(BOOL granted, NSError * _Nullable error) {
            if (handler) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    handler(granted);
                });
            }
        }];
    } else {
        [[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert | UIUserNotificationTypeBadge | UIUserNotificationTypeSound categories:nil]];
        if (handler) {
            handler(NO);
        }
    }
}

+ (void)warnAboutPhotosPermission {
    CustomModalAlertViewController *permissionsModal = [self permissionsModal];
    
    permissionsModal.image = [UIImage imageNamed:@"photosPermission"];
    permissionsModal.viewTitle = AMLocalizedString(@"Allow Access to Photos", @"Title label that explains that the user is going to be asked for the photos permission");
    permissionsModal.detail = AMLocalizedString(@"To share photos and videos, allow MEGA to access your photos", @"Detailed explanation of why the user should give permission to access to the photos");
    permissionsModal.action = AMLocalizedString(@"Enable Access", @"Button which triggers a request for a specific permission, that have been explained to the user beforehand");
    permissionsModal.dismiss = AMLocalizedString(@"notNow", nil);
    
    [UIApplication.mnz_visibleViewController presentViewController:permissionsModal animated:YES completion:nil];
}

+ (void)warnAboutAudioAndVideoPermissions {
    CustomModalAlertViewController *permissionsModal = [self permissionsModal];
    
    permissionsModal.image = [UIImage imageNamed:@"groupChat"];
    permissionsModal.viewTitle = AMLocalizedString(@"Enable Microphone and Camera", @"Title label that explains that the user is going to be asked for the microphone and camera permission");
    permissionsModal.detail = AMLocalizedString(@"To make encrypted voice and video calls, allow MEGA access to your Camera and Microphone", @"Detailed explanation of why the user should give permission to access to the camera and the microphone");
    permissionsModal.action = AMLocalizedString(@"Enable Access", @"Button which triggers a request for a specific permission, that have been explained to the user beforehand");
    permissionsModal.dismiss = AMLocalizedString(@"notNow", nil);
    
    [UIApplication.mnz_visibleViewController presentViewController:permissionsModal animated:YES completion:nil];
}

+ (void)warnAboutNotificationsPermission {
    CustomModalAlertViewController *permissionsModal = [self permissionsModal];
    
    permissionsModal.image = [UIImage imageNamed:@"privacy_warning_ico"];
    permissionsModal.viewTitle = AMLocalizedString(@"Enable Notifications", @"Title label that explains that the user is going to be asked for the notifications permission");
    permissionsModal.detail = AMLocalizedString(@"We would like to send you notifications so you receive new messages on your device instantly.", @"Detailed explanation of why the user should give permission to deliver notifications");
    permissionsModal.action = AMLocalizedString(@"Enable Access", @"Button which triggers a request for a specific permission, that have been explained to the user beforehand");
    permissionsModal.dismiss = AMLocalizedString(@"notNow", nil);
    
    [UIApplication.mnz_visibleViewController presentViewController:permissionsModal animated:YES completion:nil];
}

+ (CustomModalAlertViewController *)permissionsModal {
    CustomModalAlertViewController *permissionsModal = [[CustomModalAlertViewController alloc] init];
    __weak CustomModalAlertViewController *weakPermissionsModal = permissionsModal;
    permissionsModal.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    permissionsModal.actionColor = UIColor.mnz_green00BFA5;
    permissionsModal.dismissColor = UIColor.mnz_green899B9C;
    permissionsModal.completion = ^{
        [UIApplication.sharedApplication openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
        [weakPermissionsModal dismissViewControllerAnimated:YES completion:nil];
    };
    return permissionsModal;
}

+ (BOOL)shouldAskForAudioPermissions {
    if ([AVCaptureDevice respondsToSelector:@selector(requestAccessForMediaType:completionHandler:)]) {
        return [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio] == AVAuthorizationStatusNotDetermined;
    }
    return NO;
}

+ (BOOL)shouldAskForVideoPermissions {
    if ([AVCaptureDevice respondsToSelector:@selector(requestAccessForMediaType:completionHandler:)]) {
        return [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo] == AVAuthorizationStatusNotDetermined;
    }
    return NO;
}

+ (BOOL)shouldAskForPhotosPermissions {
    return [PHPhotoLibrary authorizationStatus] == PHAuthorizationStatusNotDetermined;
}

+ (BOOL)shouldAskForNotificationsPermissions {
    __block BOOL shouldAskForNotificationsPermissions = NO;
    if (@available(iOS 10.0, *)) {
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        [UNUserNotificationCenter.currentNotificationCenter getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings * _Nonnull settings) {
            if (settings.authorizationStatus == UNAuthorizationStatusNotDetermined) {
                shouldAskForNotificationsPermissions = YES;
            }
            dispatch_semaphore_signal(semaphore);
        }];
        double delayInSeconds = 10.0;
        dispatch_time_t waitTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_semaphore_wait(semaphore, waitTime);
    } else {
        shouldAskForNotificationsPermissions = !UIApplication.sharedApplication.isRegisteredForRemoteNotifications;
    }
    return shouldAskForNotificationsPermissions;
}

+ (BOOL)shouldSetupPermissions {
    BOOL shouldAskForAudioPermissions = [self shouldAskForAudioPermissions];
    BOOL shouldAskForVideoPermissions = [self shouldAskForVideoPermissions];
    BOOL shouldAskForPhotosPermissions = [self shouldAskForPhotosPermissions];
    BOOL shouldAskForNotificationsPermissions = [self shouldAskForNotificationsPermissions];
    
    return shouldAskForAudioPermissions || shouldAskForVideoPermissions || shouldAskForPhotosPermissions || shouldAskForNotificationsPermissions;
}

@end
