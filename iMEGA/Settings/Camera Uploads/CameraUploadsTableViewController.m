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

#import "CameraUploadsTableViewController.h"
#import "MEGAReachabilityManager.h"

@interface CameraUploadsTableViewController () 

@property (weak, nonatomic) IBOutlet UITableViewCell *enableCameraUploadsCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *enableUploadVideosCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *enableUseCellularConnectionCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *enableOnlyWhenChargingCell;

@property (weak, nonatomic) IBOutlet UILabel *enableCameraUploadsLabel;
@property (weak, nonatomic) IBOutlet UILabel *uploadVideosLabel;
@property (weak, nonatomic) IBOutlet UILabel *useCellularConnectionLabel;
@property (weak, nonatomic) IBOutlet UILabel *onlyWhenChargingLabel;
@end

@implementation CameraUploadsTableViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.uploadVideosLabel setText:NSLocalizedString(@"uploadVideosLabel", nil)];
    [self.useCellularConnectionLabel setText:NSLocalizedString(@"useCellularConnectionLabel", nil)];
    [self.onlyWhenChargingLabel setText:NSLocalizedString(@"onlyWhenChargingLabel", nil)];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if ([[CameraUploads syncManager] isCameraUploadsEnabled]) {
        [self.enableCameraUploadsLabel setText:NSLocalizedString(@"disableCameraUploadsLabel", nil)];
        [self.enableCameraUploadsCell setAccessoryType:UITableViewCellAccessoryCheckmark];
    } else {
        [self.enableCameraUploadsLabel setText:NSLocalizedString(@"enableCameraUploadsLabel", nil)];
    }
    
    if ([[CameraUploads syncManager] isUploadVideosEnabled]) {
        [self.enableUploadVideosCell setAccessoryType:UITableViewCellAccessoryCheckmark];
    }
    
    if ([[CameraUploads syncManager] isUseCellularConnectionEnabled]) {
        [self.enableUseCellularConnectionCell setAccessoryType:UITableViewCellAccessoryCheckmark];
    }
    
    if ([[CameraUploads syncManager] isOnlyWhenChargingEnabled]) {
        [self.enableOnlyWhenChargingCell setAccessoryType:UITableViewCellAccessoryCheckmark];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if ([[CameraUploads syncManager] isCameraUploadsEnabled]) {
        return 2;
    } else {
        return 1;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger rowPerSection;

    switch (section) {
        case 0:
            rowPerSection = 1;
            break;
            
        case 1:
            rowPerSection = 3;
            break;
            
        default:
            break;
    }
    
    return rowPerSection;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case 0:
            [CameraUploads syncManager].isCameraUploadsEnabled = ![CameraUploads syncManager].isCameraUploadsEnabled;
            
            if ([[CameraUploads syncManager] isCameraUploadsEnabled]) {
                [[CameraUploads syncManager] getAllAssetsForUpload];
                [self.enableCameraUploadsLabel setText:NSLocalizedString(@"disableCameraUploadsLabel", nil)];
                [self.enableCameraUploadsCell setAccessoryType:UITableViewCellAccessoryCheckmark];
            } else {
                [self.enableCameraUploadsLabel setText:NSLocalizedString(@"enableCameraUploadsLabel", nil)];
                [[MEGASdkManager sharedMEGASdk] cancelTransfersForDirection:1 delegate:self];
                [[[CameraUploads syncManager].tabBarController.viewControllers objectAtIndex:1] tabBarItem].badgeValue = nil;
                
                [self.enableCameraUploadsCell setAccessoryType:UITableViewCellAccessoryNone];
                [self.enableUploadVideosCell setAccessoryType:UITableViewCellAccessoryNone];
                [self.enableUseCellularConnectionCell setAccessoryType:UITableViewCellAccessoryNone];
                [self.enableOnlyWhenChargingCell setAccessoryType:UITableViewCellAccessoryNone];
                
                [CameraUploads syncManager].isUploadVideosEnabled = [CameraUploads syncManager].isCameraUploadsEnabled;
                [CameraUploads syncManager].isUseCellularConnectionEnabled = [CameraUploads syncManager].isCameraUploadsEnabled;
                [CameraUploads syncManager].isOnlyWhenChargingEnabled = [CameraUploads syncManager].isCameraUploadsEnabled;
                
                [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:[CameraUploads syncManager].isUploadVideosEnabled] forKey:kIsUploadVideosEnabled];
                [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:[CameraUploads syncManager].isUseCellularConnectionEnabled] forKey:kIsUseCellularConnectionEnabled];
                [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:[CameraUploads syncManager].isOnlyWhenChargingEnabled] forKey:kIsOnlyWhenChargingEnabled];
            }
            
            [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:[CameraUploads syncManager].isCameraUploadsEnabled] forKey:kIsCameraUploadsEnable];
            
            [self.tableView reloadData];
            break;
            
        case 1:
            // Upload videos
            if (indexPath.row == 0) {
                [CameraUploads syncManager].isUploadVideosEnabled = ![CameraUploads syncManager].isUploadVideosEnabled;
                if ([[CameraUploads syncManager] isUploadVideosEnabled]) {
                    [self.enableUploadVideosCell setAccessoryType:UITableViewCellAccessoryCheckmark];
                } else {
                    [self.enableUploadVideosCell setAccessoryType:UITableViewCellAccessoryNone];
                }
                
                [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:[CameraUploads syncManager].isUploadVideosEnabled] forKey:kIsUploadVideosEnabled];
            }
            
            // Use cellular connection
            if (indexPath.row == 1) {
                [CameraUploads syncManager].isUseCellularConnectionEnabled = ![CameraUploads syncManager].isUseCellularConnectionEnabled;
                if ([[CameraUploads syncManager] isUseCellularConnectionEnabled]) {
                    [[CameraUploads syncManager] getAllAssetsForUpload];
                    [self.enableUseCellularConnectionCell setAccessoryType:UITableViewCellAccessoryCheckmark];
                } else {
                    if (![MEGAReachabilityManager isReachableViaWiFi]) {
                        [[MEGASdkManager sharedMEGASdk] cancelTransfersForDirection:1 delegate:self];
                    }
                    [self.enableUseCellularConnectionCell setAccessoryType:UITableViewCellAccessoryNone];
                }
                
                [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:[CameraUploads syncManager].isUseCellularConnectionEnabled] forKey:kIsUseCellularConnectionEnabled];
            }
            
            // Only when charging
            if (indexPath.row == 2) {
                [CameraUploads syncManager].isOnlyWhenChargingEnabled = ![CameraUploads syncManager].isOnlyWhenChargingEnabled;
                if ([[CameraUploads syncManager] isOnlyWhenChargingEnabled]) {
                    if ([[UIDevice currentDevice] batteryState] == 1) {
                        [[MEGASdkManager sharedMEGASdk] cancelTransfersForDirection:1 delegate:self];
                    }
                    [self.enableOnlyWhenChargingCell setAccessoryType:UITableViewCellAccessoryCheckmark];
                } else {
                    [[CameraUploads syncManager] getAllAssetsForUpload];
                    [self.enableOnlyWhenChargingCell setAccessoryType:UITableViewCellAccessoryNone];
                }
                
                [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:[CameraUploads syncManager].isOnlyWhenChargingEnabled] forKey:kIsOnlyWhenChargingEnabled];
            }
            
        default:
            break;
    }
}

#pragma mark - MEGARequestDelegate

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    if ([error type]) {
        return;
    }

    if ([request type] == MEGARequestTypeCancelTransfers) {
        [[[CameraUploads syncManager] assetUploadArray] removeAllObjects];
    }
}

@end
