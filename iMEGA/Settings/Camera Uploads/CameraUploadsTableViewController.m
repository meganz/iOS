#import "CameraUploadsTableViewController.h"
#import <Photos/Photos.h>
#import "MEGAReachabilityManager.h"
#import "MEGATransfer+MNZCategory.h"
#import "NSString+MNZCategory.h"
#import "CameraUploadManager.h"
#import "Helper.h"
#import "UIViewController+MNZCategory.h"

@interface CameraUploadsTableViewController ()

@property (weak, nonatomic) IBOutlet UILabel *enableCameraUploadsLabel;
@property (weak, nonatomic) IBOutlet UISwitch *enableCameraUploadsSwitch;
@property (weak, nonatomic) IBOutlet UILabel *uploadVideosLabel;
@property (weak, nonatomic) IBOutlet UISwitch *uploadVideosSwitch;
@property (weak, nonatomic) IBOutlet UILabel *useCellularConnectionLabel;
@property (weak, nonatomic) IBOutlet UISwitch *useCellularConnectionSwitch;

@end

@implementation CameraUploadsTableViewController

#pragma mark - Lifecycle

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveNotification:) name:@"kUserDeniedPhotoAccess" object:nil];
    
    [self.navigationItem setTitle:AMLocalizedString(@"cameraUploadsLabel", nil)];
    [self.enableCameraUploadsLabel setText:AMLocalizedString(@"cameraUploadsLabel", nil)];
    
    self.useCellularConnectionLabel.text = AMLocalizedString(@"useMobileData", @"Title next to a switch button (On-Off) to allow using mobile data (Roaming) for a feature.");
    [self.uploadVideosLabel setText:AMLocalizedString(@"uploadVideosLabel", nil)];
    
    if (CameraUploadManager.isCameraUploadEnabled) {
        [self.enableCameraUploadsSwitch setOn:YES animated:YES];
        [self.uploadVideosSwitch setOn:CameraUploadManager.isVideoUploadEnabled animated:YES];
        [self.useCellularConnectionSwitch setOn:CameraUploadManager.isCellularUploadAllowed animated:YES];
    } else {
        [self.enableCameraUploadsSwitch setOn:NO animated:YES];
    }
    
    [self.tableView reloadData];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

#pragma mark - IBActions

- (void)receiveNotification:(NSNotification *)notification {
    [self.enableCameraUploadsSwitch setOn:NO animated:YES];
    [self.uploadVideosSwitch setOn:NO animated:YES];
    [self.useCellularConnectionSwitch setOn:NO animated:YES];
    [self.tableView reloadData];
}

- (IBAction)enableCameraUploadsSwitchValueChanged:(UISwitch *)sender {
    if (sender.isOn) {
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
            switch (status) {
                case PHAuthorizationStatusAuthorized: {
                    CameraUploadManager.cameraUploadEnabled = YES;
                    [CameraUploadManager.shared startCameraUploadIfNeeded];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.tableView reloadData];
                    });
                    break;
                }
                case PHAuthorizationStatusRestricted:
                case PHAuthorizationStatusDenied: {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        MEGALogInfo(@"Disable Camera Uploads");
                        [self showPhotoLibraryPermissionAlert];
                        [self.tableView reloadData];
                    });
                    break;
                }
                default:
                    break;
            }
        }];
    } else {
        [CameraUploadManager.shared stopCameraUpload];
    }
}

- (IBAction)uploadVideosSwitchValueChanged:(UISwitch *)sender {
    MEGALogInfo(@"%@ uploads videos", sender.isOn ? @"Enable" : @"Disable");
    
    CameraUploadManager.videoUploadEnabled = sender.isOn;
    if (sender.isOn) {
        [CameraUploadManager.shared startVideoUploadIfNeeded];
    } else {
        [CameraUploadManager.shared stopVideoUpload];
    }
}

- (IBAction)useCellularConnectionSwitchValueChanged:(UISwitch *)sender {
    MEGALogInfo(@"%@ mobile data", sender.isOn ? @"Enable" : @"Disable");
    CameraUploadManager.cellularUploadAllowed = sender.isOn;
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger numberOfRows = 0;

    switch (section) {
        case 0:
            numberOfRows = 1;
            break;
            
        case 1:
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

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    
    BOOL isCameraUploadsEnabled = CameraUploadManager.isCameraUploadEnabled;
    [self.uploadVideosLabel setEnabled:isCameraUploadsEnabled];
    [self.uploadVideosSwitch setEnabled:isCameraUploadsEnabled];
    [self.useCellularConnectionLabel setEnabled:isCameraUploadsEnabled];
    [self.useCellularConnectionSwitch setEnabled:isCameraUploadsEnabled];
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString *titleForHeader;
    if (section == 1) {
        titleForHeader = AMLocalizedString(@"options", nil);
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

@end
