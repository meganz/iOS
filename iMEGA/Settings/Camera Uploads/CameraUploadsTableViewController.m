/**
 * @file CameraUploadsTableViewController.m
 * @brief View controller that show camera uploads options
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

#import "CameraUploadsTableViewController.h"
#import "MEGAReachabilityManager.h"

#import "CameraUploads.h"

@interface CameraUploadsTableViewController ()  <UIAlertViewDelegate>

@property (weak, nonatomic) IBOutlet UITableViewCell *enableCameraUploadsCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *enableUploadVideosCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *enableUseCellularConnectionCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *enableOnlyWhenChargingCell;

@property (weak, nonatomic) IBOutlet UILabel *enableCameraUploadsLabel;
@property (weak, nonatomic) IBOutlet UISwitch *enableCameraUploadsSwitch;
@property (weak, nonatomic) IBOutlet UILabel *uploadVideosLabel;
@property (weak, nonatomic) IBOutlet UISwitch *uploadVideosSwitch;
@property (weak, nonatomic) IBOutlet UILabel *useCellularConnectionLabel;
@property (weak, nonatomic) IBOutlet UISwitch *useCellularConnectionSwitch;
@property (weak, nonatomic) IBOutlet UILabel *onlyWhenChargingLabel;
@property (weak, nonatomic) IBOutlet UISwitch *onlyWhenChargingSwitch;

@end

@implementation CameraUploadsTableViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveNotification:) name:@"kUserDeniedPhotoAccess" object:nil];
    
    [self.navigationItem setTitle:AMLocalizedString(@"cameraUploadsLabel", nil)];
    [self.enableCameraUploadsLabel setText:AMLocalizedString(@"cameraUploadsLabel", nil)];
    
    [self.useCellularConnectionLabel setText:AMLocalizedString(@"useCellularConnectionLabel", nil)];
    [self.uploadVideosLabel setText:AMLocalizedString(@"uploadVideosLabel", nil)];
    [self.onlyWhenChargingLabel setText:AMLocalizedString(@"onlyWhenChargingLabel", nil)];
    
    if ([[CameraUploads syncManager] isCameraUploadsEnabled]) {
        [self.enableCameraUploadsSwitch setOn:YES animated:YES];
        
        [self.uploadVideosSwitch setOn:[[CameraUploads syncManager] isUploadVideosEnabled] animated:YES];
        
        [self.useCellularConnectionSwitch setOn:[[CameraUploads syncManager] isUseCellularConnectionEnabled] animated:YES];
        
        [self.onlyWhenChargingSwitch setOn:[[CameraUploads syncManager] isOnlyWhenChargingEnabled] animated:YES];
    } else {
        [self.enableCameraUploadsSwitch setOn:NO animated:YES];
    }
    
    [self.tableView reloadData];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationPortrait;
}

#pragma mark - IBActions

- (void)receiveNotification:(NSNotification *)notification {
    [self.enableCameraUploadsSwitch setOn:NO animated:YES];
    [self.uploadVideosSwitch setOn:NO animated:YES];
    [self.useCellularConnectionSwitch setOn:NO animated:YES];
    [self.tableView reloadData];
}

- (IBAction)enableCameraUploadsSwitchValueChanged:(UISwitch *)sender {
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 9.0) {
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
            switch (status) {
                case PHAuthorizationStatusNotDetermined:
                    break;
                case PHAuthorizationStatusAuthorized: {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        BOOL isCameraUploadsEnabled = ![CameraUploads syncManager].isCameraUploadsEnabled;
                        if (isCameraUploadsEnabled) {
                            [[CameraUploads syncManager] setIsCameraUploadsEnabled:YES];
                            [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:isCameraUploadsEnabled] forKey:kIsCameraUploadsEnabled];
                        } else {
                            [[CameraUploads syncManager] setIsCameraUploadsEnabled:NO];
                            [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:isCameraUploadsEnabled] forKey:kIsCameraUploadsEnabled];
                            
                            [self.uploadVideosSwitch setOn:isCameraUploadsEnabled animated:YES];
                            [self.useCellularConnectionSwitch setOn:isCameraUploadsEnabled animated:YES];
                            [self.onlyWhenChargingSwitch setOn:isCameraUploadsEnabled animated:YES];
                        }
                        
                        [self.tableView reloadData];
                    });
                    break;
                }
                case PHAuthorizationStatusRestricted: {
                    break;
                }
                case PHAuthorizationStatusDenied:{
                    dispatch_async(dispatch_get_main_queue(), ^{
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:AMLocalizedString(@"attention", @"Attention") message:AMLocalizedString(@"photoLibraryPermissions", @"Please give MEGA app permission to access your photo library in your settings app!") delegate:self cancelButtonTitle:(&UIApplicationOpenSettingsURLString ? AMLocalizedString(@"cancel", nil) : AMLocalizedString(@"ok", nil)) otherButtonTitles:(&UIApplicationOpenSettingsURLString ? AMLocalizedString(@"ok", nil) : nil), nil];
                        [alert show];
                        [[CameraUploads syncManager] setIsCameraUploadsEnabled:NO];
                            
                        [self.uploadVideosSwitch setOn:NO animated:YES];
                        [self.useCellularConnectionSwitch setOn:NO animated:YES];
                        [self.onlyWhenChargingSwitch setOn:NO animated:YES];
                        [self.tableView reloadData];
                    });
                    break;
                }
                default:
                    break;
            }
        }];
        
    } else if ([ALAssetsLibrary authorizationStatus] != ALAuthorizationStatusAuthorized && [ALAssetsLibrary authorizationStatus] != ALAuthorizationStatusNotDetermined && [self.enableCameraUploadsSwitch isOn]) {
        [self.enableCameraUploadsSwitch setOn:!self.enableCameraUploadsSwitch.isOn animated:YES];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:AMLocalizedString(@"attention", @"Attention") message:AMLocalizedString(@"photoLibraryPermissions", @"Please give MEGA app permission to access your photo library in your settings app!") delegate:self cancelButtonTitle:(&UIApplicationOpenSettingsURLString ? AMLocalizedString(@"cancel", nil) : AMLocalizedString(@"ok", nil)) otherButtonTitles:(&UIApplicationOpenSettingsURLString ? AMLocalizedString(@"ok", nil) : nil), nil];
        [alert show];
    } else {
        BOOL isCameraUploadsEnabled = ![CameraUploads syncManager].isCameraUploadsEnabled;
        if (isCameraUploadsEnabled) {
            [[CameraUploads syncManager] setIsCameraUploadsEnabled:YES];
            [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:isCameraUploadsEnabled] forKey:kIsCameraUploadsEnabled];
        } else {
            [[CameraUploads syncManager] setIsCameraUploadsEnabled:NO];
            [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:isCameraUploadsEnabled] forKey:kIsCameraUploadsEnabled];
            
            [self.uploadVideosSwitch setOn:isCameraUploadsEnabled animated:YES];
            [self.useCellularConnectionSwitch setOn:isCameraUploadsEnabled animated:YES];
            [self.onlyWhenChargingSwitch setOn:isCameraUploadsEnabled animated:YES];
        }
        
        [self.tableView reloadData];
    }
}

- (IBAction)uploadVideosSwitchValueChanged:(UISwitch *)sender {
    NSError *error = nil;
    BOOL success = [[NSFileManager defaultManager] removeItemAtPath:NSTemporaryDirectory() error:&error];
    if (!success || error) {
        [MEGASdk logWithLevel:MEGALogLevelError message:[NSString stringWithFormat:@"Remove file error %@", error]];
    }
    
    [CameraUploads syncManager].isUploadVideosEnabled = ![CameraUploads syncManager].isUploadVideosEnabled;
    
    [[CameraUploads syncManager] resetOperationQueue];
    
    [self.uploadVideosSwitch setOn:[[CameraUploads syncManager] isUploadVideosEnabled] animated:YES];
    
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:[CameraUploads syncManager].isUploadVideosEnabled] forKey:kIsUploadVideosEnabled];
}

- (IBAction)useCellularConnectionSwitchValueChanged:(UISwitch *)sender {
    [CameraUploads syncManager].isUseCellularConnectionEnabled = ![CameraUploads syncManager].isUseCellularConnectionEnabled;
    if ([[CameraUploads syncManager] isUseCellularConnectionEnabled]) {
        [[CameraUploads syncManager] setIsCameraUploadsEnabled:YES];
    } else {
        if (![MEGAReachabilityManager isReachableViaWiFi]) {
            [[CameraUploads syncManager] resetOperationQueue];
        }
    }
    [self.useCellularConnectionSwitch setOn:[[CameraUploads syncManager] isUseCellularConnectionEnabled] animated:YES];
    
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:[CameraUploads syncManager].isUseCellularConnectionEnabled] forKey:kIsUseCellularConnectionEnabled];
}

- (IBAction)onlyWhenChargindSwitchValueChanged:(UISwitch *)sender {
    [CameraUploads syncManager].isOnlyWhenChargingEnabled = ![CameraUploads syncManager].isOnlyWhenChargingEnabled;
    if ([[CameraUploads syncManager] isOnlyWhenChargingEnabled]) {
        if ([[UIDevice currentDevice] batteryState] == 1) {            
            [[CameraUploads syncManager] resetOperationQueue];
        }
    } else {
        [[CameraUploads syncManager] setIsCameraUploadsEnabled:YES];
    }
    [self.onlyWhenChargingSwitch setOn:[[CameraUploads syncManager] isOnlyWhenChargingEnabled] animated:YES];
    
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:[CameraUploads syncManager].isOnlyWhenChargingEnabled] forKey:kIsOnlyWhenChargingEnabled];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    BOOL isCameraUploadsEnabled = [[CameraUploads syncManager] isCameraUploadsEnabled];
    [self.uploadVideosLabel setEnabled:isCameraUploadsEnabled];
    [self.uploadVideosSwitch setEnabled:isCameraUploadsEnabled];
    [self.useCellularConnectionLabel setEnabled:isCameraUploadsEnabled];
    [self.useCellularConnectionSwitch setEnabled:isCameraUploadsEnabled];
    [self.onlyWhenChargingLabel setEnabled:isCameraUploadsEnabled];
    [self.onlyWhenChargingSwitch setEnabled:isCameraUploadsEnabled];
    
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger numberOfRows = 0;

    switch (section) {
        case 0:
            numberOfRows = 1;
            break;
            
        case 1:
            //TODO: numberOfRows = 3 => Shows upload only when charging option. Valid for uploads in background.
            if ([MEGAReachabilityManager hasCellularConnection]) {
                numberOfRows = 2;
            } else {
                numberOfRows = 1;
            }
            break;
            
        default:
            break;
    }
    
    return numberOfRows;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString *titleForHeader;
    if (section == 1) {
        titleForHeader = [NSString stringWithFormat:@"%@:", AMLocalizedString(@"options", nil)];
    }
    return titleForHeader;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    NSString *titleForFooter;
    if (section == 0) {
        titleForFooter = AMLocalizedString(@"cameraUploads_footer", @"Footer explicative text to explain the Camera Uploads funtionality");
    }
    return titleForFooter;
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
    }
}

@end
