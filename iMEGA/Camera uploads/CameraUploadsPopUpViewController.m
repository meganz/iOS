#import "CameraUploadsPopUpViewController.h"

#import <Photos/Photos.h>

#import "SVProgressHUD.h"

#import "MEGAReachabilityManager.h"
#import "UIDevice+MNZCategory.h"

#import "CameraUploads.h"
#import "CameraUploadsTableViewController.h"
#import "PhotosViewController.h"

@interface CameraUploadsPopUpViewController () <UIAlertViewDelegate>

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
    [_imageView setImage:[UIImage imageNamed:@"emptyCameraUploads"]];
    
    [_uploadVideosLabel setText:AMLocalizedString(@"uploadVideosLabel", @"Upload videos")];
    self.useCellularConnectionLabel.text = AMLocalizedString(@"useMobileData", @"Title next to a switch button (On-Off) to allow using mobile data (Roaming) for a feature.");
    
    [_skipButton setTitle:AMLocalizedString(@"skipButton", @"Skip") forState:UIControlStateNormal];
    
    [self.enableButton setTitle:AMLocalizedString(@"enable", @"Text button shown when the chat is disabled and if tapped the chat will be enabled") forState:UIControlStateNormal];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

#pragma mark - IBActions

- (IBAction)uploadVideosValueChanged:(UISwitch *)sender {
    [CameraUploads syncManager].isUploadVideosEnabled = ![CameraUploads syncManager].isUploadVideosEnabled;
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:[CameraUploads syncManager].isUploadVideosEnabled] forKey:kIsUploadVideosEnabled];
}

- (IBAction)useCellularConnectionValueChanged:(UISwitch *)sender {
    [CameraUploads syncManager].isUseCellularConnectionEnabled = ![CameraUploads syncManager].isUseCellularConnectionEnabled;
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:[CameraUploads syncManager].isUseCellularConnectionEnabled] forKey:kIsUseCellularConnectionEnabled];
}

- (IBAction)skipTouchUpInside:(UIButton *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)enableTouchUpInside:(UIButton *)sender {
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        switch (status) {
            case PHAuthorizationStatusNotDetermined:
                break;
            case PHAuthorizationStatusAuthorized: {
                MEGALogInfo(@"Enable Camera Uploads");
                [[CameraUploads syncManager] setIsCameraUploadsEnabled:YES];
                [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:[CameraUploads syncManager].isCameraUploadsEnabled] forKey:kIsCameraUploadsEnabled];
                
                [self dismissViewControllerAnimated:YES completion:^{
                    [SVProgressHUD showImage:[UIImage imageNamed:@"hudCameraUploads"] status:AMLocalizedString(@"cameraUploadsEnabled", nil)];
                }];
                break;
            }
            case PHAuthorizationStatusRestricted:
                break;
            case PHAuthorizationStatusDenied:{
                [self dismissViewControllerAnimated:YES completion:nil];
                dispatch_async(dispatch_get_main_queue(), ^{
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:AMLocalizedString(@"attention", @"Attention") message:AMLocalizedString(@"photoLibraryPermissions", @"Please give MEGA app permission to access your photo library in your settings app!") delegate:self cancelButtonTitle:AMLocalizedString(@"cancel", nil) otherButtonTitles:AMLocalizedString(@"ok", nil), nil];
                    [alert show];
                });
                break;
            }
            default:
                break;
        }
    }];
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
    }
}

@end
