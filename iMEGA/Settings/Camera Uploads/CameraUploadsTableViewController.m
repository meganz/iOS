#import "CameraUploadsTableViewController.h"

#import <Photos/Photos.h>

#import "MEGAReachabilityManager.h"
#import "NSString+MNZCategory.h"

#import "CameraUploads.h"
#import "Helper.h"

@interface CameraUploadsTableViewController ()  <UIAlertViewDelegate>

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
    
    self.useCellularConnectionLabel.text = AMLocalizedString(@"useMobileData", @"Title next to a switch button (On-Off) to allow using mobile data (Roaming) for a feature.");
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
    if (!sender.isOn) {
        MEGATransferList *transferList = [[MEGASdkManager sharedMEGASdk] uploadTransfers];
        if (transferList.size.integerValue > 0) {
            for (NSInteger i = 0; i < transferList.size.integerValue; i++) {
                MEGATransfer *transfer = [transferList transferAtIndex:i];
                NSArray *appDataComponentsArray = [transfer.appData componentsSeparatedByString:@"="];
                NSString *appDataFirstComponentString = [appDataComponentsArray objectAtIndex:0];
                if ([appDataFirstComponentString isEqualToString:@"CU"]) {
                    [[MEGASdkManager sharedMEGASdk] cancelTransfer:transfer];
                }
            }
        }
    }
    
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        switch (status) {
            case PHAuthorizationStatusNotDetermined:
                break;
            case PHAuthorizationStatusAuthorized: {
                dispatch_async(dispatch_get_main_queue(), ^{
                    BOOL isCameraUploadsEnabled = ![CameraUploads syncManager].isCameraUploadsEnabled;
                    if (isCameraUploadsEnabled) {
                        MEGALogInfo(@"Enable Camera Uploads");
                        [[CameraUploads syncManager] setIsCameraUploadsEnabled:YES];
                        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:isCameraUploadsEnabled] forKey:kIsCameraUploadsEnabled];
                    } else {
                        MEGALogInfo(@"Disable Camera Uploads");
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
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:AMLocalizedString(@"attention", @"Attention") message:AMLocalizedString(@"photoLibraryPermissions", @"Please give MEGA app permission to access your photo library in your settings app!") delegate:self cancelButtonTitle:AMLocalizedString(@"cancel", nil) otherButtonTitles:AMLocalizedString(@"ok", nil), nil];
                    [alert show];
                    MEGALogInfo(@"Disable Camera Uploads");
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
}

- (IBAction)uploadVideosSwitchValueChanged:(UISwitch *)sender {
    MEGALogInfo(@"%@ uploads videos", sender.isOn ? @"Enable" : @"Disable");
    if (!sender.isOn) {
        MEGATransferList *transferList = [[MEGASdkManager sharedMEGASdk] uploadTransfers];
        if (transferList.size.integerValue > 0) {
            for (NSInteger i = 0; i < transferList.size.integerValue; i++) {
                MEGATransfer *transfer = [transferList transferAtIndex:i];
                NSArray *appDataComponentsArray = [transfer.appData componentsSeparatedByString:@"="];
                NSString *appDataFirstComponentString = [appDataComponentsArray objectAtIndex:0];
                if ([appDataFirstComponentString isEqualToString:@"CU"] && transfer.fileName.mnz_isVideoPathExtension) {
                    [[MEGASdkManager sharedMEGASdk] cancelTransfer:transfer];
                }
            }
        }
    }
    
    [CameraUploads syncManager].isUploadVideosEnabled = ![CameraUploads syncManager].isUploadVideosEnabled;
    
    [[CameraUploads syncManager] resetOperationQueue];
    
    [self.uploadVideosSwitch setOn:[[CameraUploads syncManager] isUploadVideosEnabled] animated:YES];
    
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:[CameraUploads syncManager].isUploadVideosEnabled] forKey:kIsUploadVideosEnabled];
}

- (IBAction)useCellularConnectionSwitchValueChanged:(UISwitch *)sender {
    MEGALogInfo(@"%@ mobile data", sender.isOn ? @"Enable" : @"Disable");
    [CameraUploads syncManager].isUseCellularConnectionEnabled = ![CameraUploads syncManager].isUseCellularConnectionEnabled;
    if ([[CameraUploads syncManager] isUseCellularConnectionEnabled]) {
        MEGALogInfo(@"Enable Camera Uploads");
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
        MEGALogInfo(@"Enable Camera Uploads");
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
