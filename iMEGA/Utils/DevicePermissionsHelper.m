
#import "DevicePermissionsHelper.h"

#import <Contacts/Contacts.h>
#import <Photos/Photos.h>
#import <UserNotifications/UserNotifications.h>

#import "CustomModalAlertViewController.h"
#import "UIApplication+MNZCategory.h"

@implementation DevicePermissionsHelper

#pragma mark - Permissions requests

+ (void)audioPermissionModal:(BOOL)modal forIncomingCall:(BOOL)incomingCall withCompletionHandler:(void (^)(BOOL granted))handler {
    if (modal && self.shouldAskForAudioPermissions) {
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
    [PHPhotoLibrary requestAuthorizationForAccessLevel:PHAccessLevelReadWrite
                                               handler:^(PHAuthorizationStatus status) {
        if (handler) {
            dispatch_async(dispatch_get_main_queue(), ^{
                handler(status == PHAuthorizationStatusAuthorized || status == PHAuthorizationStatusLimited);
            });
        }
    }];
}

+ (void)notificationsPermissionWithCompletionHandler:(void (^)(BOOL granted))handler {
    [UNUserNotificationCenter.currentNotificationCenter requestAuthorizationWithOptions:(UNAuthorizationOptionBadge | UNAuthorizationOptionSound | UNAuthorizationOptionAlert) completionHandler:^(BOOL granted, NSError * _Nullable error) {
        if (handler) {
            dispatch_async(dispatch_get_main_queue(), ^{
                handler(granted);
            });
        }
    }];
}

+ (void)contactsPermissionWithCompletionHandler:(void (^)(BOOL granted))handler {
    CNContactStore *contactStore = CNContactStore.new;
    [contactStore requestAccessForEntityType:CNEntityTypeContacts completionHandler:^(BOOL granted, NSError * _Nullable error) {
        if (handler) {
            dispatch_async(dispatch_get_main_queue(), ^{
                handler(granted);
            });
        }
    }];
}

#pragma mark - Alerts

+ (void)alertAudioPermissionForIncomingCall:(BOOL)incomingCall {
    if (incomingCall) {
        [self alertPermissionWithTitle:NSLocalizedString(@"Incoming call", nil) message:NSLocalizedString(@"microphonePermissions", @"Alert message to remember that MEGA app needs permission to use the Microphone to make calls and record videos and it doesn't have it") completionHandler:nil];
    } else {
        [self alertPermissionWithMessage:NSLocalizedString(@"microphonePermissions", @"Alert message to remember that MEGA app needs permission to use the Microphone to make calls and record videos and it doesn't have it") completionHandler:nil];
    }
}

+ (void)alertVideoPermissionWithCompletionHandler:(void (^)(void))handler {
    [self alertPermissionWithMessage:NSLocalizedString(@"cameraPermissions", @"Alert message to remember that MEGA app needs permission to use the Camera to take a photo or video and it doesn't have it") completionHandler:handler];
}

+ (void)alertPhotosPermission {
    [self alertPermissionWithMessage:NSLocalizedString(@"photoLibraryPermissions", @"Alert message to explain that the MEGA app needs permission to access your device photos") completionHandler:nil];
}

+ (void)alertPermissionWithMessage:(NSString *)message completionHandler:(void (^)(void))handler {
    [self alertPermissionWithTitle:NSLocalizedString(@"attention", @"Alert title to attract attention") message:message completionHandler:handler];
}

+ (void)alertPermissionWithTitle:(NSString *)title message:(NSString *)message completionHandler:(void (^)(void))handler {
#ifdef MAIN_APP_TARGET
    UIAlertController *permissionsAlertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    
    [permissionsAlertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"notNow", @"Used in the \"rich previews\", when the user first tries to send an url - we ask them before we generate previews for that URL, since we need to send them unencrypted to our servers.") style:UIAlertActionStyleCancel handler:nil]];
    [permissionsAlertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"settingsTitle", @"Title of the Settings section") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        if (handler) {
            handler();
        }
        
        [UIApplication.sharedApplication openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString] options:@{} completionHandler:nil];
    }]];
    
    [UIApplication.mnz_presentingViewController presentViewController:permissionsAlertController animated:YES completion:nil];
#endif
}



#pragma mark - Modals

+ (void)modalAudioPermissionForIncomingCall:(BOOL)incomingCall withCompletionHandler:(void (^)(BOOL granted))handler {
    CustomModalAlertViewController *permissionsModal = CustomModalAlertViewController.alloc.init;
    __weak CustomModalAlertViewController *weakPermissionsModal = permissionsModal;
    
    permissionsModal.image = [UIImage imageNamed:@"groupChat"];
    permissionsModal.viewTitle = incomingCall ? NSLocalizedString(@"Incoming call", nil) : NSLocalizedString(@"Enable Microphone and Camera", @"Title label that explains that the user is going to be asked for the microphone and camera permission");
    permissionsModal.detail = NSLocalizedString(@"To make encrypted voice and video calls, allow MEGA access to your Camera and Microphone", @"Detailed explanation of why the user should give permission to access to the camera and the microphone");
    permissionsModal.firstButtonTitle = NSLocalizedString(@"Allow Access", @"Button which triggers a request for a specific permission, that have been explained to the user beforehand");
    permissionsModal.dismissButtonTitle = NSLocalizedString(@"notNow", nil);
    
    permissionsModal.firstCompletion = ^{
        [weakPermissionsModal dismissViewControllerAnimated:YES completion:^{
            [self audioPermissionWithCompletionHandler:handler];
        }];
    };
    
    [UIApplication.mnz_presentingViewController presentViewController:permissionsModal animated:YES completion:nil];
}

+ (void)modalNotificationsPermission {
#ifdef MAIN_APP_TARGET
    CustomModalAlertViewController *permissionsModal = CustomModalAlertViewController.alloc.init;
    __weak CustomModalAlertViewController *weakPermissionsModal = permissionsModal;
    
    permissionsModal.image = [UIImage imageNamed:@"micAndCamPermission"];
    permissionsModal.viewTitle = NSLocalizedString(@"Enable Notifications", @"Title label that explains that the user is going to be asked for the notifications permission");
    permissionsModal.detail = NSLocalizedString(@"We would like to send you notifications so you receive new messages on your device instantly.", @"Detailed explanation of why the user should give permission to deliver notifications");
    permissionsModal.firstButtonTitle = NSLocalizedString(@"continue", @"'Next' button in a dialog");
    
    permissionsModal.firstCompletion = ^{
        [self notificationsPermissionWithCompletionHandler:^(BOOL granted) {
            if (granted) {
                
                [UIApplication.sharedApplication registerForRemoteNotifications];
            }
            [weakPermissionsModal dismissViewControllerAnimated:YES completion:nil];
        }];
    };
    
    [UIApplication.mnz_presentingViewController presentViewController:permissionsModal animated:YES completion:nil];
#endif
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
    return PHPhotoLibrary.authorizationStatus == PHAuthorizationStatusNotDetermined;
}

+ (BOOL)shouldAskForNotificationsPermissions {
    __block BOOL shouldAskForNotificationsPermissions = NO;
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
    
    return shouldAskForNotificationsPermissions;
}

+ (BOOL)shouldAskForContactsPermissions {
    return [CNContactStore authorizationStatusForEntityType:CNEntityTypeContacts] == CNAuthorizationStatusNotDetermined;
}

+ (BOOL)shouldSetupPermissions {
    BOOL shouldAskForAudioPermissions = self.shouldAskForAudioPermissions;
    BOOL shouldAskForVideoPermissions = self.shouldAskForVideoPermissions;
    BOOL shouldAskForPhotosPermissions = self.shouldAskForPhotosPermissions;
    BOOL shouldAskForNotificationsPermissions = self.shouldAskForNotificationsPermissions;
    BOOL shouldAskForContactsPermissions = self.shouldAskForContactsPermissions;

    return shouldAskForAudioPermissions || shouldAskForVideoPermissions || shouldAskForPhotosPermissions || shouldAskForNotificationsPermissions || shouldAskForContactsPermissions;
}

+ (BOOL)isAudioPermissionAuthorizedOrNotDetermined {
    return [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio] == AVAuthorizationStatusAuthorized || [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio] == AVAuthorizationStatusNotDetermined;
}

+ (AVAuthorizationStatus )audioPermissionAuthorizationStatus {
    return [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
}

+ (BOOL)isVideoPermissionAuthorizedOrNotDetermined {
    return [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo] == AVAuthorizationStatusAuthorized || [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo] == AVAuthorizationStatusNotDetermined;
}

+ (BOOL)isVideoPermissionAuthorized {
    return [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo] == AVAuthorizationStatusAuthorized;
}

@end
