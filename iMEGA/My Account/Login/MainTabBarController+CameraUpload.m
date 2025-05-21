#import "MainTabBarController+CameraUpload.h"
#import "CameraUploadManager+Settings.h"
#import "CustomModalAlertViewController.h"
#import "CameraUploadsTableViewController.h"
#import "UIApplication+MNZCategory.h"
#import "MEGANavigationController.h"
#import "MEGA-Swift.h"

@import MEGAL10nObjc;

@implementation MainTabBarController (CameraUpload)

#pragma mark - Camera Upload v2 migration

- (void)showCameraUploadV2MigrationScreenIfNeeded {
    if (!CameraUploadManager.shouldShowCameraUploadV2MigrationScreen) {
        return;
    }
    
    CustomModalAlertViewController *migrationVC = [[CustomModalAlertViewController alloc] init];
    migrationVC.image = [UIImage megaImageWithNamed:@"cameraUploadsV2Migration"];
    migrationVC.viewTitle = LocalizedString(@"New Camera Upload!", @"");
    migrationVC.detail = LocalizedString(@"Now you can choose to convert the HEIF/HEVC photos and videos to the most compatible JPEG/H.264 formats.", @"");
    migrationVC.firstButtonTitle = LocalizedString(@"Use Most Compatible Formats", @"");
    migrationVC.dismissButtonTitle = LocalizedString(@"Custom Settings", @"");
    
    __weak __typeof__(CustomModalAlertViewController) *weakCustom = migrationVC;
    migrationVC.firstCompletion = ^{
        [weakCustom dismissViewControllerAnimated:YES completion:^{
            [CameraUploadManager configDefaultSettingsForCameraUploadV2];
            CameraUploadManager.migratedToCameraUploadsV2 = YES;
            [CameraUploadManager.shared startCameraUploadIfNeeded];
        }];
    };
    
    migrationVC.dismissCompletion = ^{
        [weakCustom dismissViewControllerAnimated:YES completion:^{
            [self showCameraUploadSettingsScreen];
        }];
    };
    
    [UIApplication.mnz_presentingViewController presentViewController:migrationVC animated:YES completion:nil];
}

- (void)showCameraUploadSettingsScreen {
    CameraUploadsTableViewController *cameraUploadSettingsVC = [[UIStoryboard storyboardWithName:@"CameraUploadSettings" bundle:nil] instantiateViewControllerWithIdentifier:@"CameraUploadsSettingsID"];
    cameraUploadSettingsVC.isPresentedModally = YES;
    MEGANavigationController *navigationController = [[MEGANavigationController alloc] initWithRootViewController:cameraUploadSettingsVC];
    navigationController.modalPresentationStyle = UIModalPresentationOverFullScreen;
    [UIApplication.mnz_presentingViewController presentViewController:navigationController animated:YES completion:nil];
}

@end
