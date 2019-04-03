
#import "PhotosViewController+MNZCategory.h"
#import "CustomModalAlertViewController.h"
#import "CameraUploadManager.h"
#import "CameraUploadManager+Settings.h"
#import "CameraUploadsTableViewController.h"

@implementation PhotosViewController (MNZCategory)

#pragma mark - View transitions

- (void)showCameraUploadBoardingScreen {
    CustomModalAlertViewController *boardingAlertVC = [[CustomModalAlertViewController alloc] init];
    boardingAlertVC.modalPresentationStyle = UIModalPresentationOverFullScreen;
    boardingAlertVC.image = [UIImage imageNamed:@"cameraUploadsBoarding"];
    boardingAlertVC.viewTitle = AMLocalizedString(@"enableCameraUploadsButton", @"Button title that enables the functionality 'Camera Uploads', which uploads all the photos in your device to MEGA");
    boardingAlertVC.detail = AMLocalizedString(@"automaticallyBackupYourPhotos", @"Text shown to explain what means 'Enable Camera Uploads'.");
    boardingAlertVC.action = AMLocalizedString(@"enable", @"Text button shown when camera upload will be enabled");
    boardingAlertVC.actionColor = [UIColor mnz_green00BFA5];
    boardingAlertVC.dismiss = AMLocalizedString(@"notNow", nil);
    boardingAlertVC.dismissColor = [UIColor colorFromHexString:@"899B9C"];
    
    boardingAlertVC.completion = ^{
        [self dismissViewControllerAnimated:YES completion:^{
            [self pushCameraUploadSettings];
        }];
    };
    
    boardingAlertVC.onDismiss = ^{
        [self dismissViewControllerAnimated:YES completion:nil];
        CameraUploadManager.cameraUploadEnabled = NO;
    };
    
    [self presentViewController:boardingAlertVC animated:YES completion:nil];
    CameraUploadManager.boardingScreenLastShowedDate = NSDate.date;
}

- (void)pushCameraUploadSettings {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"CameraUploadSettings" bundle:nil];
    CameraUploadsTableViewController *cameraUploadsTableViewController = [storyboard instantiateViewControllerWithIdentifier:@"CameraUploadsSettingsID"];
    [self.navigationController pushViewController:cameraUploadsTableViewController animated:YES];
}

- (void)pushVideoUploadSettings {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"CameraUploadSettings" bundle:nil];
    UIViewController *videoUploadsController = [storyboard instantiateViewControllerWithIdentifier:@"VideoUploadsTableViewControllerID"];
    [self.navigationController pushViewController:videoUploadsController animated:YES];
}

- (void)showLocalDiskIsFullWarningScreen {
    CustomModalAlertViewController *warningVC = [[CustomModalAlertViewController alloc] init];
    warningVC.modalPresentationStyle = UIModalPresentationOverFullScreen;
    warningVC.image = [UIImage imageNamed:@"disk_storage_full"];
    warningVC.viewTitle = [NSString stringWithFormat:@"%@ Storage Full", UIDevice.currentDevice.localizedModel];
    warningVC.detail = @"You do not have enough storage to upload camera. Free up space by deleting unneeded apps, videos or music.";
    warningVC.action = @"Manage";
    warningVC.actionColor = [UIColor mnz_green00BFA5];
    warningVC.dismiss = AMLocalizedString(@"notNow", nil);
    warningVC.dismissColor = [UIColor colorFromHexString:@"899B9C"];
    
    warningVC.completion = ^{
        [self dismissViewControllerAnimated:YES completion:^{
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
        }];
    };
    
    [self presentViewController:warningVC animated:YES completion:nil];
}

@end
