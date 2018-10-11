
#import "DevicePermissionsHelper.h"

#import <AVFoundation/AVFoundation.h>
#import <Photos/Photos.h>
#import <UserNotifications/UserNotifications.h>

#import "CustomModalAlertViewController.h"
#import "UIApplication+MNZCategory.h"
#import "UIColor+MNZCategory.h"

@implementation DevicePermissionsHelper

#pragma mark - Permissions requests

+ (void)audioPermissionModal:(BOOL)modal forIncomingCall:(BOOL)incomingCall withCompletionHandler:(void (^)(BOOL granted))handler {
    if (modal && [self shouldAskForAudioPermissions]) {
        [self modalAudioPermissionForIncomingCall:incomingCall withCompletionHandler:handler];
    } else {
        [self audioPermissionWithCompletionHandler:handler];
    }
}

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

+ (void)notificationsPermissionWithCompletionHandler:(void (^)(BOOL granted))handler {
    if (@available(iOS 10.0, *)) {
        [UNUserNotificationCenter.currentNotificationCenter requestAuthorizationWithOptions:(UNAuthorizationOptionBadge | UNAuthorizationOptionSound | UNAuthorizationOptionAlert) completionHandler:^(BOOL granted, NSError * _Nullable error) {
            if (handler) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    handler(granted);
                });
            }
        }];
    } else {
        #pragma clang diagnostic push
        #pragma clang diagnostic ignored "-Wdeprecated-declarations"
        [[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert | UIUserNotificationTypeBadge | UIUserNotificationTypeSound categories:nil]];
        #pragma clang diagnostic pop
        if (handler) {
            handler(NO);
        }
    }
}



#pragma mark - Alerts

+ (void)alertAudioPermission {
    [self alertPermissionWithMessage:AMLocalizedString(@"microphonePermissions", @"Alert message to remember that MEGA app needs permission to use the Microphone to make calls and record videos and it doesn't have it") completionHandler:nil];
}

+ (void)alertVideoPermissionWithCompletionHandler:(void (^)(void))handler {
    [self alertPermissionWithMessage:AMLocalizedString(@"cameraPermissions", @"Alert message to remember that MEGA app needs permission to use the Camera to take a photo or video and it doesn't have it") completionHandler:handler];
}

+ (void)alertPhotosPermission {
    [self alertPermissionWithMessage:AMLocalizedString(@"photoLibraryPermissions", @"Alert message to explain that the MEGA app needs permission to access your device photos") completionHandler:nil];
}

+ (void)alertPermissionWithMessage:(NSString *)message completionHandler:(void (^)(void))handler {
    UIAlertController *permissionsAlertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"attention", @"Alert title to attract attention") message:AMLocalizedString(@"photoLibraryPermissions", @"Alert message to explain that the MEGA app needs permission to access your device photos") preferredStyle:UIAlertControllerStyleAlert];
    
    [permissionsAlertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"cancel", @"Button title to cancel something") style:UIAlertActionStyleCancel handler:nil]];
    [permissionsAlertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"ok", @"Button title to accept something") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        if (handler) {
            handler();
        }
        [UIApplication.sharedApplication openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString] options:@{} completionHandler:nil];
    }]];
    
    [UIApplication.mnz_visibleViewController presentViewController:permissionsAlertController animated:YES completion:nil];
}



#pragma mark - Modals

+ (void)modalAudioPermissionForIncomingCall:(BOOL)incomingCall withCompletionHandler:(void (^)(BOOL granted))handler {
    CustomModalAlertViewController *permissionsModal = [self permissionsModal];
    __weak CustomModalAlertViewController *weakPermissionsModal = permissionsModal;
    
    permissionsModal.image = [UIImage imageNamed:@"groupChat"];
    permissionsModal.viewTitle = incomingCall ? AMLocalizedString(@"Incoming call", nil) : AMLocalizedString(@"Enable Microphone and Camera", @"Title label that explains that the user is going to be asked for the microphone and camera permission");
    permissionsModal.detail = AMLocalizedString(@"To make encrypted voice and video calls, allow MEGA access to your Camera and Microphone", @"Detailed explanation of why the user should give permission to access to the camera and the microphone");
    permissionsModal.action = AMLocalizedString(@"Enable Access", @"Button which triggers a request for a specific permission, that have been explained to the user beforehand");
    permissionsModal.dismiss = AMLocalizedString(@"notNow", nil);
    
    permissionsModal.completion = ^{
        [weakPermissionsModal dismissViewControllerAnimated:YES completion:^{
            [self audioPermissionWithCompletionHandler:handler];
        }];
    };
    
    [UIApplication.mnz_visibleViewController presentViewController:permissionsModal animated:YES completion:nil];
}

+ (void)modalNotificationsPermission {
    CustomModalAlertViewController *permissionsModal = [self permissionsModal];
    __weak CustomModalAlertViewController *weakPermissionsModal = permissionsModal;
    
    permissionsModal.image = [UIImage imageNamed:@"privacy_warning_ico"];
    permissionsModal.viewTitle = AMLocalizedString(@"Enable Notifications", @"Title label that explains that the user is going to be asked for the notifications permission");
    permissionsModal.detail = AMLocalizedString(@"We would like to send you notifications so you receive new messages on your device instantly.", @"Detailed explanation of why the user should give permission to deliver notifications");
    permissionsModal.action = AMLocalizedString(@"Enable Access", @"Button which triggers a request for a specific permission, that have been explained to the user beforehand");
    permissionsModal.dismiss = AMLocalizedString(@"notNow", nil);
    
    permissionsModal.completion = ^{
        [self notificationsPermissionWithCompletionHandler:^(BOOL granted) {
            [weakPermissionsModal dismissViewControllerAnimated:YES completion:nil];
        }];
    };
    
    [UIApplication.mnz_visibleViewController presentViewController:permissionsModal animated:YES completion:nil];
}

+ (CustomModalAlertViewController *)permissionsModal {
    CustomModalAlertViewController *permissionsModal = [[CustomModalAlertViewController alloc] init];
    
    permissionsModal.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    permissionsModal.actionColor = UIColor.mnz_green00BFA5;
    permissionsModal.dismissColor = UIColor.mnz_green899B9C;
    
    return permissionsModal;
}



#pragma mark - Permissions status

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
