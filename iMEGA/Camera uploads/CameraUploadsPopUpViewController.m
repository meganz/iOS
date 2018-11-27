#import "CameraUploadsPopUpViewController.h"

#import <Photos/Photos.h>

#import "SVProgressHUD.h"

#import "MEGAReachabilityManager.h"
#import "UIDevice+MNZCategory.h"
#import "PhotosViewController.h"
#import "CameraUploadManager.h"
#import "UIViewController+MNZCategory.h"

@interface CameraUploadsPopUpViewController ()

@property (weak, nonatomic) IBOutlet UILabel *topLabel;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@property (weak, nonatomic) IBOutlet UILabel *uploadVideosLabel;
@property (weak, nonatomic) IBOutlet UISwitch *uploadVideosSwitch;
@property (weak, nonatomic) IBOutlet UILabel *useCellularConnectionLabel;
@property (weak, nonatomic) IBOutlet UISwitch *useCellularConnectionSwitch;

@property (weak, nonatomic) IBOutlet UIButton *skipButton;
@property (weak, nonatomic) IBOutlet UIButton *enableButton;

@end

@implementation CameraUploadsPopUpViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (![MEGAReachabilityManager hasCellularConnection]) {
        [_useCellularConnectionLabel setHidden:YES];
        [_useCellularConnectionSwitch setHidden:YES];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.topLabel.text = AMLocalizedString(@"automaticallyBackupYourPhotos", @"Text shown to explain what means 'Enable Camera Uploads'.");
    
    self.navigationItem.title = AMLocalizedString(@"cameraUploadsLabel", @"Title of one of the Settings sections where you can set up the 'Camera Uploads' options");
    self.imageView.image = [UIImage imageNamed:@"cameraUploadsPopUp"];
    
    [_uploadVideosLabel setText:AMLocalizedString(@"uploadVideosLabel", @"Upload videos")];
    self.useCellularConnectionLabel.text = AMLocalizedString(@"useMobileData", @"Title next to a switch button (On-Off) to allow using mobile data (Roaming) for a feature.");
    
    [_skipButton setTitle:AMLocalizedString(@"skipButton", @"Skip") forState:UIControlStateNormal];
    
    [self.enableButton setTitle:AMLocalizedString(@"enable", @"Text button shown when the chat is disabled and if tapped the chat will be enabled") forState:UIControlStateNormal];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

#pragma mark - IBActions

- (IBAction)uploadVideosValueChanged:(UISwitch *)sender {
    CameraUploadManager.videoUploadEnabled = sender.isOn;
    if (sender.isOn) {
        [CameraUploadManager.shared startVideoUploadIfNeeded];
    } else {
        [CameraUploadManager.shared stopVideoUpload];
    }
}

- (IBAction)useCellularConnectionValueChanged:(UISwitch *)sender {
    CameraUploadManager.cellularUploadAllowed = sender.isOn;
}

- (IBAction)skipTouchUpInside:(UIButton *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)enableTouchUpInside:(UIButton *)sender {
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        switch (status) {
            case PHAuthorizationStatusAuthorized: {
                MEGALogInfo(@"Enable Camera Uploads");
                CameraUploadManager.cameraUploadEnabled = YES;
                [CameraUploadManager.shared startCameraUploadIfNeeded];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self dismissViewControllerAnimated:YES completion:^{
                        [SVProgressHUD showImage:[UIImage imageNamed:@"hudCameraUploads"] status:AMLocalizedString(@"cameraUploadsEnabled", nil)];
                    }];
                });
                break;
            }
            case PHAuthorizationStatusRestricted:
            case PHAuthorizationStatusDenied: {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self dismissViewControllerAnimated:YES completion:^{
                        [self showPhotoLibraryPermissionAlert];
                    }];
                });
                break;
            }
            default:
                break;
        }
    }];
}

@end
