#import "CameraUploadsTableViewController.h"
#import <Photos/Photos.h>
#import "MEGAReachabilityManager.h"
#import "MEGATransfer+MNZCategory.h"
#import "NSString+MNZCategory.h"
#import "CameraUploadManager+Settings.h"
#import "DevicePermissionsHelper.h"
#import "Helper.h"
#import "CustomModalAlertViewController.h"
#import "MEGASdkManager.h"
#import "MEGA-Swift.h"
#import "TransferSessionManager.h"
@import CoreLocation;

@interface CameraUploadsTableViewController () <CLLocationManagerDelegate, BrowserViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UILabel *enableCameraUploadsLabel;
@property (weak, nonatomic) IBOutlet UISwitch *enableCameraUploadsSwitch;

@property (weak, nonatomic) IBOutlet UILabel *uploadVideosInfoLabel;
@property (weak, nonatomic) IBOutlet UILabel *uploadVideosInfoRightDetailLabel;

@property (weak, nonatomic) IBOutlet UILabel *uploadVideosLabel;
@property (weak, nonatomic) IBOutlet UISwitch *uploadVideosSwitch;

@property (weak, nonatomic) IBOutlet UILabel *HEICLabel;
@property (weak, nonatomic) IBOutlet UIImageView *HEICRedCheckmarkImageView;
@property (weak, nonatomic) IBOutlet UILabel *JPGLabel;
@property (weak, nonatomic) IBOutlet UIImageView *JPGRedCheckmarkImageView;

@property (weak, nonatomic) IBOutlet UILabel *includeGPSTagsLabel;
@property (weak, nonatomic) IBOutlet UISwitch *includeGPSTagsSwitch;

@property (weak, nonatomic) IBOutlet UILabel *useCellularConnectionLabel;
@property (weak, nonatomic) IBOutlet UISwitch *useCellularConnectionSwitch;
@property (weak, nonatomic) IBOutlet UILabel *useCellularConnectionForVideosLabel;
@property (weak, nonatomic) IBOutlet UISwitch *useCellularConnectionForVideosSwitch;

@property (weak, nonatomic) IBOutlet UILabel *backgroundUploadLabel;
@property (weak, nonatomic) IBOutlet UISwitch *backgroundUploadSwitch;

@property (weak, nonatomic) IBOutlet UILabel *advancedLabel;

@property (weak, nonatomic) IBOutlet UILabel *targetFolderLabel;

@property (weak, nonatomic) IBOutlet UITableViewCell *cameraUploadCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *videoUploadInfoCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *videoUploadSwitchCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *HEICCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *JPGCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *includeGPSTagsCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *mobileDataCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *mobileDataForVideosCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *uploadInBackgroundCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *advancedCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *targetFolderCell;

@property (strong, nonatomic) NSArray<NSArray<UITableViewCell *> *> *tableSections;
@property (strong, nonatomic) NSArray<NSString *> *sectionHeaderTitles;
@property (strong, nonatomic) NSArray<NSString *> *sectionFooterTitles;

@property (strong, nonatomic) CLLocationManager *locationManager;

@end

@implementation CameraUploadsTableViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.navigationItem setTitle:NSLocalizedString(@"cameraUploadsLabel", nil)];
    [self.enableCameraUploadsLabel setText:NSLocalizedString(@"cameraUploadsLabel", nil)];
    
    [self.uploadVideosInfoLabel setText:NSLocalizedString(@"uploadVideosLabel", nil)];
    [self.uploadVideosLabel setText:NSLocalizedString(@"uploadVideosLabel", nil)];
    
    self.useCellularConnectionLabel.text = NSLocalizedString(@"useMobileData", nil);
    self.useCellularConnectionForVideosLabel.text = NSLocalizedString(@"Use Mobile Data for Videos", nil);

    self.backgroundUploadLabel.text = NSLocalizedString(@"Upload in Background", nil);
    self.advancedLabel.text = NSLocalizedString(@"advanced", nil);
    
    self.includeGPSTagsLabel.text = NSLocalizedString(@"Include Location Tags", @"Used in camera upload settings: This text will appear with a switch to turn on/off location tags while uploading a file");

    [self configImageFormatTexts];
    
    if (self.isPresentedModally) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(modalDialogDoneButtonTouched)];
        if (!CameraUploadManager.hasMigratedToCameraUploadsV2) {
            [CameraUploadManager configDefaultSettingsForCameraUploadV2];
        }
    }
    
    [self updateAppearance];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(configBackgroudUploadUI) name:UIApplicationDidBecomeActiveNotification object:nil];
    
    [self configUI];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    
    if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
        [self updateAppearance];
    }
}

#pragma mark - Private

- (CLLocationManager *)locationManager {
    if (_locationManager == nil) {
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.delegate = self;
    }
    
    return _locationManager;
}

- (void)configImageFormatTexts {
    NSDictionary<NSAttributedStringKey, id> *formatAttributes = @{NSFontAttributeName : [UIFont preferredFontForTextStyle:UIFontTextStyleBody], NSForegroundColorAttributeName : UIColor.mnz_label};
    
    NSMutableAttributedString *JPGAttributedString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ ", JPGFormat] attributes:formatAttributes];
    
    [JPGAttributedString appendAttributedString:[NSAttributedString.alloc initWithString:NSLocalizedString(@"(Recommended)", nil) attributes:@{NSFontAttributeName : [UIFont preferredFontForTextStyle:UIFontTextStyleBody], NSForegroundColorAttributeName : [UIColor mnz_secondaryGrayForTraitCollection:self.traitCollection]}]];
    self.JPGLabel.attributedText = JPGAttributedString;
    
    self.HEICLabel.attributedText = [[NSAttributedString alloc] initWithString:HEICFormat attributes:formatAttributes];
}

- (void)configUI {
    self.enableCameraUploadsSwitch.on = CameraUploadManager.isCameraUploadEnabled;
    self.uploadVideosSwitch.on = CameraUploadManager.isVideoUploadEnabled;
    self.uploadVideosInfoRightDetailLabel.text = CameraUploadManager.isVideoUploadEnabled ? NSLocalizedString(@"on", nil) : NSLocalizedString(@"off", nil);
    self.includeGPSTagsSwitch.on = CameraUploadManager.includeGPSTags;
    
    [self configTargetFolder];
    [self configPhotoFormatUI];
    [self configOptionsUI];
    
    [self configTableSections];
    [self.tableView reloadData];
}

- (void)updateAppearance {
    self.uploadVideosInfoRightDetailLabel.textColor = UIColor.mnz_secondaryLabel;
    
    self.tableView.separatorColor = [UIColor mnz_separatorForTraitCollection:self.traitCollection];
    self.tableView.backgroundColor = [UIColor mnz_backgroundGroupedForTraitCollection:self.traitCollection];
    
    [self.tableView reloadData];
}

- (void)configTargetFolder {
    [CameraUploadNodeAccess.shared loadNodeWithCompletion:^(MEGANode * _Nullable node, NSError * _Nullable error) {
        if (node) {
            [NSOperationQueue.mainQueue addOperationWithBlock:^{
                self.targetFolderLabel.text = node.name;
                [self.tableView reloadData];
            }];
        } else {
            MEGALogWarning(@"Could not load CU target folder due to error %@", error)
        }
    }];
}

- (void)configPhotoFormatUI {
    self.HEICRedCheckmarkImageView.hidden = CameraUploadManager.shouldConvertHEICPhoto;
    self.JPGRedCheckmarkImageView.hidden = !CameraUploadManager.shouldConvertHEICPhoto;
}

- (void)configOptionsUI {
    self.useCellularConnectionSwitch.on = CameraUploadManager.isCellularUploadAllowed;
    self.useCellularConnectionForVideosSwitch.on = CameraUploadManager.isCellularUploadForVideosAllowed;
    [self configBackgroudUploadUI];
}

- (void)configBackgroudUploadUI {
    self.backgroundUploadSwitch.on = CameraUploadManager.canBackgroundUploadBeStarted;
}

- (void)configTableSections {
    if (!CameraUploadManager.isCameraUploadEnabled) {
        self.tableSections = @[@[self.cameraUploadCell]];
        self.sectionHeaderTitles = @[@""];
        self.sectionFooterTitles = @[[self titleForCameraUploadFooter]];
        return;
    }
    
    NSMutableArray<NSArray<UITableViewCell *> *> *sections = [NSMutableArray array];
    NSMutableArray<NSString *> *headerTitles = [NSMutableArray array];
    NSMutableArray<NSString *> *footerTitles = [NSMutableArray array];
    
    // camera upload feature switch section
    [sections addObject:@[self.cameraUploadCell]];
    [headerTitles addObject:@""];
    [footerTitles addObject:[self titleForCameraUploadFooter]];
    
    // video upload section
    [sections addObject:@[self.videoUploadInfoCell]];
    [headerTitles addObject:@""];
    [footerTitles addObject:@""];
    
    // photo format section
    [sections addObject:@[self.HEICCell, self.JPGCell]];
    [headerTitles addObject:NSLocalizedString(@"SAVE HEIC PHOTOS AS", @"What format to upload HEIC photos")];
    [footerTitles addObject:NSLocalizedString(@"We recommend JPG, as its the most compatible format for photos.", nil)];
    
    // Target folder
    [sections addObject:@[self.targetFolderCell]];
    [headerTitles addObject:NSLocalizedString(@"MEGA CAMERA UPLOADS FOLDER", nil)];
    [footerTitles addObject:@""];
    
    // Include GPS info cell.
    [sections addObject:@[self.includeGPSTagsCell]];
    [headerTitles addObject:@""];
    [footerTitles addObject:NSLocalizedString(@"If enabled, you will upload information about where your pictures and videos were taken, so be careful when sharing them.", nil)];
    
    // options section
    NSMutableArray *optionSection = [NSMutableArray array];
    if ([self shouldShowMobileData]) {
        [optionSection addObject:self.mobileDataCell];
    }
    if ([self shouldShowMobileDataForVideos]) {
        [optionSection addObject:self.mobileDataForVideosCell];
    }
    [optionSection addObjectsFromArray:@[self.uploadInBackgroundCell, self.advancedCell]];
    [sections addObject:[optionSection copy]];
    [headerTitles addObject:NSLocalizedString(@"options", @"Camera Upload options")];
    [footerTitles addObject:@""];
    
    self.tableSections = [sections copy];
    self.sectionHeaderTitles = [headerTitles copy];
    self.sectionFooterTitles = [footerTitles copy];
}

- (NSString *)titleForCameraUploadFooter {
    NSString *title;
    if (CameraUploadManager.isCameraUploadEnabled) {
        if (CameraUploadManager.isVideoUploadEnabled) {
            title = NSLocalizedString(@"Photos and videos will be uploaded to Camera Uploads folder.", nil);
        } else {
            title = NSLocalizedString(@"Photos will be uploaded to Camera Uploads folder.", nil);
        }
    } else {
        title = NSLocalizedString(@"When enabled, photos will be uploaded.", nil);
    }
    
    return title;
}

#pragma mark - IBActions

- (IBAction)modalDialogDoneButtonTouched {
    CameraUploadManager.migratedToCameraUploadsV2 = YES;
    [self dismissViewControllerAnimated:YES completion:nil];
    [CameraUploadManager.shared startCameraUploadIfNeeded];
}

- (IBAction)enableCameraUploadsSwitchValueChanged:(UISwitch *)sender {
    MEGALogInfo(@"%@ camera uploads", sender.isOn ? @"Enable" : @"Disable");
    if (sender.isOn) {
        if (MEGASdkManager.sharedMEGASdk.businessStatus == BusinessStatusExpired) {
            NSString *alertTitle = NSLocalizedString(@"Your business account is expired", @"A dialog title shown to users when their business account is expired.");
            NSString *alertMessage;
            if (MEGASdkManager.sharedMEGASdk.isMasterBusinessAccount) {
                alertMessage = NSLocalizedString(@"There has been a problem processing your payment. MEGA is limited to view only until this issue has been fixed in a desktop web browser.", @"Details shown when a Business account is expired. Details for the administrator of the Business account");
            } else {
                alertMessage = [[[[NSLocalizedString(@"Your account is currently [B]suspended[/B]. You can only browse your data.", @"A dialog message which is shown to sub-users of expired business accounts.") stringByReplacingOccurrencesOfString:@"[B]" withString:@""] stringByReplacingOccurrencesOfString:@"[/B]" withString:@""] stringByAppendingString:@"\n\n"] stringByAppendingString:NSLocalizedString(@"Contact your business account administrator to resolve the issue and activate your account.", @"A dialog message which is shown to sub-users of expired business accounts.")];
            }
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:alertTitle message:alertMessage preferredStyle:UIAlertControllerStyleAlert];
            [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"dismiss", nil) style:UIAlertActionStyleCancel handler:nil]];
            [self presentViewController:alertController animated:YES completion:nil];
            [sender setOn:NO];
        } else {
            [DevicePermissionsHelper photosPermissionWithCompletionHandler:^(BOOL granted) {
                if (granted) {
                    if (MEGASdkManager.sharedMEGASdk.isBusinessAccount && !MEGASdkManager.sharedMEGASdk.isMasterBusinessAccount) {
                        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"cameraUploadsLabel", @"Title of one of the Settings sections where you can set up the 'Camera Uploads' options") message:NSLocalizedString(@"While MEGA does not have access to your data, your organization administrators do have the ability to control and view the Camera Uploads in your user account", @"Message shown when users with a business account (no administrators of a business account) try to enable the Camera Uploads, to advise them that the administrator do have the ability to view their data.") preferredStyle:UIAlertControllerStyleAlert];
                        [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"cancel", nil) style:UIAlertActionStyleCancel handler:nil]];
                        [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"enable", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                            [CameraUploadManager.shared enableCameraUpload];
                            [self configUI];
                        }]];
                        [self presentViewController:alertController animated:YES completion:nil];
                    } else {
                        [CameraUploadManager.shared enableCameraUpload];
                    }
                } else {
                    [DevicePermissionsHelper alertPhotosPermission];
                }
                
                [self configUI];
            }];
        }
    } else {
        [CameraUploadManager.shared disableCameraUpload];
        [self configUI];
    }
}

- (IBAction)uploadVideosSwitchValueChanged:(UISwitch *)sender {
    MEGALogInfo(@"%@ uploads videos", sender.isOn ? @"Enable" : @"Disable");
    if (sender.isOn) {
        [CameraUploadManager.shared enableVideoUpload];
    } else {
        [CameraUploadManager.shared disableVideoUpload];
    }
    
    [self configUI];
}

- (IBAction)useCellularConnectionSwitchValueChanged:(UISwitch *)sender {
    MEGALogInfo(@"%@ mobile data", sender.isOn ? @"Enable" : @"Disable");
    CameraUploadManager.cellularUploadAllowed = sender.isOn;
    [self configUI];
    
    if (CameraUploadManager.isCellularUploadAllowed) {
        [TransferSessionManager.shared invalidateAndCancelPhotoCellularDisallowedSession];
        if (CameraUploadManager.isCellularUploadForVideosAllowed) {
            [TransferSessionManager.shared invalidateAndCancelVideoCellularDisallowedSession];
        }
    } else {
        [TransferSessionManager.shared invalidateAndCancelPhotoCellularAllowedSession];
        [TransferSessionManager.shared invalidateAndCancelVideoCellularAllowedSession];
    }
}

- (IBAction)useCellularConnectionForVideosSwitchValueChanged:(UISwitch *)sender {
    MEGALogInfo(@"%@ mobile data for videos", sender.isOn ? @"Enable" : @"Disable");
    CameraUploadManager.cellularUploadForVideosAllowed = sender.isOn;
    
    if (CameraUploadManager.isCellularUploadForVideosAllowed) {
        [TransferSessionManager.shared invalidateAndCancelVideoCellularDisallowedSession];
    } else {
        [TransferSessionManager.shared invalidateAndCancelVideoCellularAllowedSession];
    }
}

- (IBAction)backgroundUploadButtonTouched:(UIButton *)sender {
    if (self.backgroundUploadSwitch.isOn) {
        CameraUploadManager.backgroundUploadAllowed = NO;
        [self configBackgroudUploadUI];
    } else {
        [self showBackgroundUploadBoardingScreen];
    }
}

- (void)showBackgroundUploadBoardingScreen {
    CustomModalAlertViewController *customModalAlertVC = [[CustomModalAlertViewController alloc] init];
    customModalAlertVC.image = [UIImage imageNamed:@"backgroundUploadLocation"];
    customModalAlertVC.viewTitle = NSLocalizedString(@"Enable location services for background upload", nil);
    NSString *actionTitle;
    NSString *detail;
    if (CLLocationManager.authorizationStatus == kCLAuthorizationStatusAuthorizedAlways || CLLocationManager.authorizationStatus == kCLAuthorizationStatusNotDetermined) {
        actionTitle = NSLocalizedString(@"Turn On", nil);
        detail = NSLocalizedString(@"MEGA can periodically start camera uploads in background when your location changes.", nil);
    } else {
        actionTitle = NSLocalizedString(@"Turn On in Settings", nil);
        detail = NSLocalizedString(@"Please select “Always” at your Location page in Settings, then MEGA can periodically start camera uploads in background when your location changes.", nil);
    }
    customModalAlertVC.detail = detail;
    customModalAlertVC.firstButtonTitle = actionTitle;
    customModalAlertVC.dismissButtonTitle = NSLocalizedString(@"notNow", nil);
    customModalAlertVC.firstCompletion = ^{
        [self dismissViewControllerAnimated:YES completion:nil];
        switch (CLLocationManager.authorizationStatus) {
            case kCLAuthorizationStatusNotDetermined:
                [self.locationManager requestAlwaysAuthorization];
                break;
            case kCLAuthorizationStatusAuthorizedAlways:
                CameraUploadManager.backgroundUploadAllowed = YES;
                [self configBackgroudUploadUI];
                break;
            default:
                [UIApplication.sharedApplication openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString] options:@{} completionHandler:nil];
                break;
        }
    };
    
    [self presentViewController:customModalAlertVC animated:YES completion:nil];
}

- (IBAction)includeGPSTagsSwitchValueChanged:(UISwitch *)sender {
    CameraUploadManager.includeGPSTags = sender.on;
}

- (void)selectNode {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Cloud" bundle:nil];
    MEGANavigationController *navigationController = [storyboard instantiateViewControllerWithIdentifier:@"BrowserNavigationControllerID"];
    BrowserViewController *browserVC = navigationController.viewControllers.firstObject;
    browserVC.browserAction = BrowserActionSelectFolder;
    browserVC.childBrowser = YES;
    browserVC.parentNode = MEGASdkManager.sharedMEGASdk.rootNode;
    browserVC.browserViewControllerDelegate = self;
    [self presentViewController:navigationController animated:YES completion:nil];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.tableSections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.tableSections[section].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    return self.tableSections[indexPath.section][indexPath.row];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString *title = self.sectionHeaderTitles[section];
    return [title isEqualToString:@""] ? nil : title;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    NSString *title = self.sectionFooterTitles[section];
    return [title isEqualToString:@""] ? nil : title;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = [UIColor mnz_secondaryBackgroundGrouped:self.traitCollection];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    UITableViewCell *selectedCell = self.tableSections[indexPath.section][indexPath.row];
    if (selectedCell == self.HEICCell) {
        CameraUploadManager.convertHEICPhoto = NO;
        [self configPhotoFormatUI];
    } else if (selectedCell == self.JPGCell) {
        CameraUploadManager.convertHEICPhoto = YES;
        [self configPhotoFormatUI];
    } else if (selectedCell == self.targetFolderCell) {
        [self selectNode];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewAutomaticDimension;
}

- (NSInteger)tableView:(UITableView *)tableView indentationLevelForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 0;
}

#pragma mark - Location manager delegate

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    CameraUploadManager.backgroundUploadAllowed = status == kCLAuthorizationStatusAuthorizedAlways;
    [self configBackgroudUploadUI];
}

#pragma mark - util methods

- (BOOL)shouldShowMobileData {
    return [MEGAReachabilityManager hasCellularConnection];
}

- (BOOL)shouldShowMobileDataForVideos {
    return [self shouldShowMobileData] && CameraUploadManager.isCellularUploadAllowed && CameraUploadManager.isVideoUploadEnabled;
}

#pragma mark - BrowserViewControllerDelegate

- (void)didSelectNode:(MEGANode *)node {
    [CameraUploadNodeAccess.shared setNode:node completion:^(MEGANode * _Nullable node, NSError * _Nullable error) {
        if (node) {
            [NSOperationQueue.mainQueue addOperationWithBlock:^{
                self.targetFolderLabel.text = node.name;
                [self.tableView reloadData];
            }];
        } else {
            MEGALogWarning(@"Could not load CU target folder due to error %@", error)
        }
    }];
}

@end
