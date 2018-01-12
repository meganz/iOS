#import "DevicePermissionsHelper.h"

#import <AVFoundation/AVFoundation.h>

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

+ (UIAlertController *)audioPermisionAlertController {
    //TODO:change audio permission message
    UIAlertController *permissionsAlertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"attention", @"Alert title to attract attention") message:AMLocalizedString(@"cameraPermissions", @"Alert message to remember that MEGA app needs permission to use the Camera to take a photo or video and it doesn't have it") preferredStyle:UIAlertControllerStyleAlert];
    [permissionsAlertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"cancel", @"Button title to cancel something") style:UIAlertActionStyleCancel handler:nil]];
    
    [permissionsAlertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"ok", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
    }]];
    return permissionsAlertController;
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

+ (UIAlertController *)videoPermisionAlertController {
    UIAlertController *permissionsAlertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"attention", @"Alert title to attract attention") message:AMLocalizedString(@"cameraPermissions", @"Alert message to remember that MEGA app needs permission to use the Camera to take a photo or video and it doesn't have it") preferredStyle:UIAlertControllerStyleAlert];
    [permissionsAlertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"cancel", @"Button title to cancel something") style:UIAlertActionStyleCancel handler:nil]];
    
    [permissionsAlertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"ok", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
    }]];
    return permissionsAlertController;
}

@end
