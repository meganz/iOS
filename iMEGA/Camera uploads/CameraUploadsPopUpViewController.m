/**
 * @file CameraUploadsPopUpViewController.m
 * @brief Pop up that is shown when the user hasn't enable Camera Uploads.
 *
 * (c) 2013-2015 by Mega Limited, Auckland, New Zealand
 *
 * This file is part of the MEGA SDK - Client Access Engine.
 *
 * Applications using the MEGA API must present a valid application key
 * and comply with the the rules set forth in the Terms of Service.
 *
 * The MEGA SDK is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 *
 * @copyright Simplified (2-clause) BSD License.
 *
 * You should have received a copy of the license along with this
 * program.
 */

#import <AssetsLibrary/AssetsLibrary.h>
#import <Photos/Photos.h>

#import "SVProgressHUD.h"

#import "MEGAReachabilityManager.h"
#import "Helper.h"

#import "CameraUploadsPopUpViewController.h"
#import "CameraUploads.h"
#import "CameraUploadsTableViewController.h"
#import "PhotosViewController.h"

@interface CameraUploadsPopUpViewController () <UIAlertViewDelegate>

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
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.navigationItem setTitle:AMLocalizedString(@"enableCameraUploadsButton", @"Enable Camera Uploads")];
    [_imageView setImage:[UIImage imageNamed:@"emptyCameraUploads"]];
    
    [_uploadVideosLabel setText:AMLocalizedString(@"uploadVideosLabel", @"Upload videos")];
    [_useCellularConnectionLabel setText:AMLocalizedString(@"useCellularConnectionLabel", @"Use cellular connection")];
    
    [_skipButton.layer setCornerRadius:6];
    [_skipButton.layer setMasksToBounds:YES];
    [_skipButton setTitle:AMLocalizedString(@"skipButton", @"Skip") forState:UIControlStateNormal];
    
    [_enableButton.layer setCornerRadius:6];
    [_enableButton.layer setMasksToBounds:YES];
    [_enableButton setTitle:AMLocalizedString(@"ok", nil) forState:UIControlStateNormal];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationPortrait;
}

#pragma mark - IBActions

- (IBAction)uploadVideosValueChanged:(UISwitch *)sender {
    NSError *error = nil;
    BOOL success = [[NSFileManager defaultManager] removeItemAtPath:NSTemporaryDirectory() error:&error];
    if (!success || error) {
        [MEGASdk logWithLevel:MEGALogLevelError message:[NSString stringWithFormat:@"Remove file error %@", error]];
    }
    
    [CameraUploads syncManager].isUploadVideosEnabled = ![CameraUploads syncManager].isUploadVideosEnabled;
    
    [[CameraUploads syncManager] resetOperationQueue];
    
    if ([[CameraUploads syncManager] isUploadVideosEnabled]) {
        [_uploadVideosSwitch setOn:YES animated:YES];
    } else {
        [_uploadVideosSwitch setOn:NO animated:YES];
    }
    
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:[CameraUploads syncManager].isUploadVideosEnabled] forKey:kIsUploadVideosEnabled];
}

- (IBAction)useCellularConnectionValueChanged:(UISwitch *)sender {
    [CameraUploads syncManager].isUseCellularConnectionEnabled = ![CameraUploads syncManager].isUseCellularConnectionEnabled;
    if ([[CameraUploads syncManager] isUseCellularConnectionEnabled]) {
        [[CameraUploads syncManager] setIsCameraUploadsEnabled:YES];
        [_useCellularConnectionSwitch setOn:YES animated:YES];
    } else {
        if (![MEGAReachabilityManager isReachableViaWiFi]) {
            [[CameraUploads syncManager] resetOperationQueue];
        }
        [_useCellularConnectionSwitch setOn:NO animated:YES];
    }
    
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:[CameraUploads syncManager].isUseCellularConnectionEnabled] forKey:kIsUseCellularConnectionEnabled];
}

- (IBAction)skipTouchUpInside:(UIButton *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)enableTouchUpInside:(UIButton *)sender {
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 9.0) {
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
            switch (status) {
                case PHAuthorizationStatusNotDetermined:
                    break;
                case PHAuthorizationStatusAuthorized: {                    
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
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:AMLocalizedString(@"attention", @"Attention") message:AMLocalizedString(@"photoLibraryPermissions", @"Please give MEGA app permission to access your photo library in your settings app!") delegate:self cancelButtonTitle:(&UIApplicationOpenSettingsURLString ? AMLocalizedString(@"cancel", nil) : AMLocalizedString(@"ok", nil)) otherButtonTitles:(&UIApplicationOpenSettingsURLString ? AMLocalizedString(@"ok", nil) : nil), nil];
                        [alert show];
                    });
                    break;
                }
                default:
                    break;
            }
        }];
        
    } else if ([ALAssetsLibrary authorizationStatus] != ALAuthorizationStatusAuthorized && [ALAssetsLibrary authorizationStatus] != ALAuthorizationStatusNotDetermined) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:AMLocalizedString(@"attention", @"Attention") message:AMLocalizedString(@"photoLibraryPermissions", @"Please give MEGA app permission to access your photo library in your settings app!") delegate:self cancelButtonTitle:(&UIApplicationOpenSettingsURLString ? AMLocalizedString(@"cancel", nil) : AMLocalizedString(@"ok", nil)) otherButtonTitles:(&UIApplicationOpenSettingsURLString ? AMLocalizedString(@"ok", nil) : nil), nil];
        [alert show];
    } else {
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
