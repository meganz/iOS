
#import "MainTabBarController+CameraUpload.h"
#import "CameraUploadManager+Settings.h"
#import "CustomModalAlertViewController.h"
#import "CameraUploadsTableViewController.h"
#import "UIApplication+MNZCategory.h"
#import "MEGANavigationController.h"

@implementation MainTabBarController (CameraUpload)

#pragma mark - Camera Upload v2 migration

- (void)showCameraUploadV2MigrationScreenIfNeeded {
    if (!CameraUploadManager.shouldShowCameraUploadV2MigrationScreen) {
        return;
    }
    
    CustomModalAlertViewController *migrationVC = [[CustomModalAlertViewController alloc] init];
    migrationVC.modalPresentationStyle = UIModalPresentationOverFullScreen;
    migrationVC.image = [UIImage imageNamed:@"cameraUploadsV2Migration"];
    migrationVC.viewTitle = @"New Camera Upload!";
    migrationVC.detail = @"Now you can choose to convert the HEIF/HEVC format photos and videos to the most compatible JPEG/H.264.\n\nWe now also upload live photos and burst photos to make sure all of your memorable moments are backed up.";
    migrationVC.action = @"Use Most Compatible Formats";
    migrationVC.actionColor = [UIColor mnz_green00BFA5];
    migrationVC.dismiss = @"Custom Settings";
    migrationVC.dismissColor = [UIColor colorFromHexString:@"899B9C"];
    
    __weak __typeof__(CustomModalAlertViewController) *weakCustom = migrationVC;
    migrationVC.completion = ^{
        [weakCustom dismissViewControllerAnimated:YES completion:^{
            [CameraUploadManager migrateCurrentSettingsToCameraUplaodV2];
            CameraUploadManager.migratedToCameraUploadsV2 = YES;
            [CameraUploadManager.shared startCameraUploadIfNeeded];
        }];
    };
    
    migrationVC.onDismiss = ^{
        [weakCustom dismissViewControllerAnimated:YES completion:^{
            [self showCameraUploadSettingsScreen];
        }];
    };
    
    [self presentViewController:migrationVC animated:YES completion:nil];
}

- (void)showCameraUploadSettingsScreen {
    CameraUploadsTableViewController *cameraUploadSettingsVC = [[UIStoryboard storyboardWithName:@"CameraUploadSettings" bundle:nil] instantiateViewControllerWithIdentifier:@"CameraUploadsSettingsID"];
    cameraUploadSettingsVC.isPresentedModally = YES;
    MEGANavigationController *navigationController = [[MEGANavigationController alloc] initWithRootViewController:cameraUploadSettingsVC];
    navigationController.modalPresentationStyle = UIModalPresentationOverFullScreen;
    [self presentViewController:navigationController animated:YES completion:nil];
}

@end
