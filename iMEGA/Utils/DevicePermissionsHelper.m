#import "DevicePermissionsHelper.h"

#import <AVFoundation/AVFoundation.h>
#import <Photos/Photos.h>
#import <UserNotifications/UserNotifications.h>

@implementation DevicePermissionsHelper

+ (void)audioPermissionWithCompletionHandler:(void (^)(BOOL granted))handler {
    if ([AVCaptureDevice respondsToSelector:@selector(requestAccessForMediaType:completionHandler:)]) {
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeAudio completionHandler:^(BOOL permissionGranted) {
            if (permissionGranted) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (handler) {
                        handler(YES);
                    }
                });
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (handler) {
                        handler(NO);
                    }
                });
            }
        }];
    }
}

+ (void)videoPermissionWithCompletionHandler:(void (^)(BOOL granted))handler {
    if ([AVCaptureDevice respondsToSelector:@selector(requestAccessForMediaType:completionHandler:)]) {
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL permissionGranted) {
            if (permissionGranted) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (handler) {
                        handler(YES);
                    }
                });
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (handler) {
                        handler(NO);
                    }
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

+ (UIAlertController *)audioPermisionAlertController {
    UIAlertController *permissionsAlertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"attention", @"Alert title to attract attention") message:AMLocalizedString(@"microphonePermissions", @"Alert message to remember that MEGA app needs permission to use the Microphone to make calls and record videos and it doesn't have it") preferredStyle:UIAlertControllerStyleAlert];
    [permissionsAlertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"cancel", @"Button title to cancel something") style:UIAlertActionStyleCancel handler:nil]];
    
    [permissionsAlertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"ok", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
    }]];
    return permissionsAlertController;
}

+ (UIAlertController *)videoPermisionAlertController {
    UIAlertController *permissionsAlertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"attention", @"Alert title to attract attention") message:AMLocalizedString(@"cameraPermissions", @"Alert message to remember that MEGA app needs permission to use the Camera to take a photo or video and it doesn't have it") preferredStyle:UIAlertControllerStyleAlert];
    [permissionsAlertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"cancel", @"Button title to cancel something") style:UIAlertActionStyleCancel handler:nil]];
    
    [permissionsAlertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"ok", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
    }]];
    return permissionsAlertController;
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
