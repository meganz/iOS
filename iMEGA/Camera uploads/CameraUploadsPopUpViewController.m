#import "CameraUploadsPopUpViewController.h"

#import <AssetsLibrary/AssetsLibrary.h>
#import <Photos/Photos.h>

#import "SVProgressHUD.h"

#import "MEGAReachabilityManager.h"
#import "UIDevice+MNZCategory.h"

#import "CameraUploads.h"
#import "CameraUploadsTableViewController.h"
#import "PhotosViewController.h"

@interface CameraUploadsPopUpViewController () <UIAlertViewDelegate>

@property (weak, nonatomic) IBOutlet UILabel *topLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *imageWidthLayoutConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *imageHeightLayoutConstraint;
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
    
    if ([[UIDevice currentDevice] iPhone5X]) {
        self.imageWidthLayoutConstraint.constant = 190.0f;
        self.imageHeightLayoutConstraint.constant = 208.0f;
    }
    
    //TODO: iPhone 4X
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.topLabel.text = AMLocalizedString(@"automaticallyBackupYouPhotos", @"Text shown to explain what means 'Enable Camera Uploads'.");
    
    [self.navigationItem setTitle:AMLocalizedString(@"enableCameraUploadsButton", @"Enable Camera Uploads")];
    [_imageView setImage:[UIImage imageNamed:@"emptyCameraUploads"]];
    
    [_uploadVideosLabel setText:AMLocalizedString(@"uploadVideosLabel", @"Upload videos")];
    self.useCellularConnectionLabel.text = AMLocalizedString(@"useMobileData", @"Title next to a switch button (On-Off) to allow using mobile data (Roaming) for a feature.");
    
    [_skipButton.layer setCornerRadius:4.0f];
    [_skipButton.layer setMasksToBounds:YES];
    [_skipButton setTitle:AMLocalizedString(@"skipButton", @"Skip") forState:UIControlStateNormal];
    
    [_enableButton.layer setCornerRadius:4.0f];
    [_enableButton.layer setMasksToBounds:YES];
    [self.enableButton setTitle:AMLocalizedString(@"enableCameraUploadsButton", @"Button title that enables the functionality 'Camera Uploads', which uploads all the photos in your device to MEGA") forState:UIControlStateNormal];
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
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0) {
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
        
    } else if ([ALAssetsLibrary authorizationStatus] != ALAuthorizationStatusAuthorized && [ALAssetsLibrary authorizationStatus] != ALAuthorizationStatusNotDetermined) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:AMLocalizedString(@"attention", @"Attention") message:AMLocalizedString(@"photoLibraryPermissions", @"Please give MEGA app permission to access your photo library in your settings app!") delegate:self cancelButtonTitle:AMLocalizedString(@"cancel", nil) otherButtonTitles:AMLocalizedString(@"ok", nil), nil];
        [alert show];
    } else {
        MEGALogInfo(@"Enable Camera Uploads");
        [[CameraUploads syncManager] setIsCameraUploadsEnabled:YES];
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:[CameraUploads syncManager].isCameraUploadsEnabled] forKey:kIsCameraUploadsEnabled];
        
        [self dismissViewControllerAnimated:YES completion:^{
            [SVProgressHUD showImage:[UIImage imageNamed:@"hudCameraUploads"] status:AMLocalizedString(@"cameraUploadsEnabled", nil)];
        }];
    }
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
    }
}

@end
