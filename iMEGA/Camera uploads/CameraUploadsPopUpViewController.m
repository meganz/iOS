#import "CameraUploadsPopUpViewController.h"

#import <Photos/Photos.h>

#import "SVProgressHUD.h"

#import "DevicePermissionsHelper.h"
#import "MEGAReachabilityManager.h"
#import "UIDevice+MNZCategory.h"

#import "CameraUploads.h"
#import "CameraUploadsTableViewController.h"
#import "PhotosViewController.h"

@interface CameraUploadsPopUpViewController ()

@property (weak, nonatomic) IBOutlet UILabel *topLabel;

@property (weak, nonatomic) IBOutlet UIButton *skipButton;
@property (weak, nonatomic) IBOutlet UIButton *enableButton;

@end

@implementation CameraUploadsPopUpViewController

#pragma mark - Lifecycle

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.navigationItem.title = AMLocalizedString(@"enableCameraUploadsButton", @"Button title that enables the functionality 'Camera Uploads', which uploads all the photos in your device to MEGA");
    self.topLabel.text = AMLocalizedString(@"automaticallyBackupYourPhotos", @"Text shown to explain what means 'Enable Camera Uploads'.");
    [self.enableButton setTitle:AMLocalizedString(@"enable", @"Text button shown when the chat is disabled and if tapped the chat will be enabled") forState:UIControlStateNormal];
    [self.skipButton setTitle:AMLocalizedString(@"notNow", nil) forState:UIControlStateNormal];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

#pragma mark - IBActions

- (IBAction)skipTouchUpInside:(UIButton *)sender {
    [NSUserDefaults.standardUserDefaults setObject:@0 forKey:kIsCameraUploadsEnabled];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)enableTouchUpInside:(UIButton *)sender {
    [DevicePermissionsHelper photosPermissionWithCompletionHandler:^(BOOL granted) {
        [NSUserDefaults.standardUserDefaults setObject:@(granted) forKey:kIsCameraUploadsEnabled];
        if (granted) {
            MEGALogInfo(@"Enable Camera Uploads");
            [CameraUploads syncManager].isCameraUploadsEnabled = YES;
            [CameraUploads syncManager].isUploadVideosEnabled = YES;
            [NSUserDefaults.standardUserDefaults setObject:@1 forKey:kIsUploadVideosEnabled];
            
            [self dismissViewControllerAnimated:YES completion:^{
                [SVProgressHUD showImage:[UIImage imageNamed:@"hudCameraUploads"] status:AMLocalizedString(@"cameraUploadsEnabled", nil)];
            }];
        } else {
            [self dismissViewControllerAnimated:YES completion:^{
                [DevicePermissionsHelper alertPhotosPermission];
            }];
        }
    }];
}

@end
