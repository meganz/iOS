#import "CameraUploadsTableViewController.h"
#import <Photos/Photos.h>
#import "MEGAReachabilityManager.h"
#import "MEGATransfer+MNZCategory.h"
#import "NSString+MNZCategory.h"
#import "CameraUploadManager+Settings.h"
#import "DevicePermissionsHelper.h"
#import "Helper.h"
#import "CustomModalAlertViewController.h"
#import "MEGAConstants.h"
@import CoreLocation;

typedef NS_ENUM(NSUInteger, CameraUploadSection) {
    CameraUploadSectionFeatureSwitch,
    CameraUploadSectionVideoInfo,
    CameraUploadSectionPhotoFormat,
    CameraUploadSectionOptions,
    CameraUploadSectionTotalCount
};

typedef NS_ENUM(NSUInteger, CameraUploadOptionRow) {
    CameraUploadOptionRowUseMobileData,
    CameraUploadOptionRowUseMobileDataForVideos,
    CameraUploadOptionRowBackgroundUpload
};

typedef NS_ENUM(NSUInteger, CameraUploadVideoRow) {
    CameraUploadVideoRowDetailInfo,
    CameraUploadVideoRowSinglePageSetting
};

typedef NS_ENUM(NSUInteger, CameraUploadPhotoFormatRow) {
    CameraUploadPhotoFormatRowHEIC,
    CameraUploadPhotoFormatRowJPG
};

static const CGFloat TableViewSectionHeaderFooterHiddenHeight = 0.1;

@interface CameraUploadsTableViewController () <CLLocationManagerDelegate>

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

@property (weak, nonatomic) IBOutlet UILabel *useCellularConnectionLabel;
@property (weak, nonatomic) IBOutlet UISwitch *useCellularConnectionSwitch;
@property (weak, nonatomic) IBOutlet UILabel *useCellularConnectionForVideosLabel;
@property (weak, nonatomic) IBOutlet UISwitch *useCellularConnectionForVideosSwitch;

@property (weak, nonatomic) IBOutlet UILabel *backgroundUploadLabel;
@property (weak, nonatomic) IBOutlet UISwitch *backgroundUploadSwitch;

@property (strong, nonatomic) CLLocationManager *locationManager;

@end

@implementation CameraUploadsTableViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.navigationItem setTitle:AMLocalizedString(@"cameraUploadsLabel", nil)];
    [self.enableCameraUploadsLabel setText:AMLocalizedString(@"cameraUploadsLabel", nil)];
    
    [self.uploadVideosInfoLabel setText:AMLocalizedString(@"uploadVideosLabel", nil)];
    [self.uploadVideosLabel setText:AMLocalizedString(@"uploadVideosLabel", nil)];
    
    self.useCellularConnectionLabel.text = AMLocalizedString(@"useMobileData", nil);
    self.useCellularConnectionForVideosLabel.text = AMLocalizedString(@"Use Mobile Data for Videos", nil);

    self.backgroundUploadLabel.text = AMLocalizedString(@"Upload in Background", nil);
    
    [self configImageFormatTexts];
    
    if (self.isPresentedModally) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(modalDialogDoneButtonTouched)];
        if (!CameraUploadManager.hasMigratedToCameraUploadsV2) {
            [CameraUploadManager migrateCurrentSettingsToCameraUplaodV2];
        }
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(configBackgroudUploadUI) name:UIApplicationDidBecomeActiveNotification object:nil];
    
    [self configUI];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [NSNotificationCenter.defaultCenter removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

#pragma mark - Properties

- (CLLocationManager *)locationManager {
    if (_locationManager == nil) {
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.delegate = self;
    }
    
    return _locationManager;
}

#pragma mark - UI configuration

- (void)configImageFormatTexts {
    NSDictionary<NSAttributedStringKey, id> *formatAttributes = @{NSFontAttributeName : [UIFont systemFontOfSize:17.0], NSForegroundColorAttributeName : [UIColor mnz_black333333]};
    
    NSMutableAttributedString *JPGAttributedString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ ", JPGFormat] attributes:formatAttributes];
    
    [JPGAttributedString appendAttributedString:[[NSAttributedString alloc] initWithString:AMLocalizedString(@"(Recommended)", nil) attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:17.0], NSForegroundColorAttributeName : [UIColor mnz_gray999999]}]];
    self.JPGLabel.attributedText = JPGAttributedString;
    
    self.HEICLabel.attributedText = [[NSAttributedString alloc] initWithString:HEICFormat attributes:formatAttributes];
}

- (void)configUI {
    self.enableCameraUploadsSwitch.on = CameraUploadManager.isCameraUploadEnabled;
    self.uploadVideosSwitch.on = CameraUploadManager.isVideoUploadEnabled;
    self.uploadVideosInfoRightDetailLabel.text = CameraUploadManager.isVideoUploadEnabled ? AMLocalizedString(@"on", nil) : AMLocalizedString(@"off", nil);

    [self configPhotoFormatUI];
    [self configOptionsUI];
    
    [self.tableView reloadData];
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

#pragma mark - IBActions

- (IBAction)modalDialogDoneButtonTouched {
    CameraUploadManager.migratedToCameraUploadsV2 = YES;
    [self dismissViewControllerAnimated:YES completion:nil];
    [CameraUploadManager.shared startCameraUploadIfNeeded];
}

- (IBAction)enableCameraUploadsSwitchValueChanged:(UISwitch *)sender {
    if (sender.isOn) {
        [DevicePermissionsHelper photosPermissionWithCompletionHandler:^(BOOL granted) {
            if (granted) {
                [CameraUploadManager.shared enableCameraUpload];
            } else {
                [DevicePermissionsHelper alertPhotosPermission];
            }
            
            [self configUI];
        }];
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
}

- (IBAction)useCellularConnectionForVideosSwitchValueChanged:(UISwitch *)sender {
    MEGALogInfo(@"%@ mobile data for videos", sender.isOn ? @"Enable" : @"Disable");
    CameraUploadManager.cellularUploadForVideosAllowed = sender.isOn;
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
    customModalAlertVC.modalPresentationStyle = UIModalPresentationOverFullScreen;
    customModalAlertVC.image = [UIImage imageNamed:@"backgroundUploadLocation"];
    customModalAlertVC.viewTitle = AMLocalizedString(@"Enable location services for background upload", nil);
    NSString *actionTitle;
    NSString *detail;
    if (CLLocationManager.authorizationStatus == kCLAuthorizationStatusAuthorizedAlways || CLLocationManager.authorizationStatus == kCLAuthorizationStatusNotDetermined) {
        actionTitle = AMLocalizedString(@"Turn On", nil);
        detail = AMLocalizedString(@"MEGA can periodically start camera uploads in background when your location changes.", nil);
    } else {
        actionTitle = AMLocalizedString(@"Turn On in Settings", nil);
        detail = AMLocalizedString(@"Please select “Always” at your Location page in Settings, then MEGA can periodically start camera uploads in background when your location changes.", nil);
    }
    customModalAlertVC.detail = detail;
    customModalAlertVC.firstButtonTitle = actionTitle;
    customModalAlertVC.dismissButtonTitle = AMLocalizedString(@"notNow", nil);
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
                [UIApplication.sharedApplication openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
                break;
        }
    };
    
    [self presentViewController:customModalAlertVC animated:YES completion:nil];
}

#pragma mark - UITableview data source and delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (CameraUploadManager.isCameraUploadEnabled) {
        return CameraUploadSectionTotalCount;
    } else {
        return 1;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger numberOfRows = 0;
    switch (section) {
        case CameraUploadSectionFeatureSwitch:
            numberOfRows = 1;
            break;
        case CameraUploadSectionVideoInfo:
            numberOfRows = 2;
            break;
        case CameraUploadSectionPhotoFormat:
            if (CameraUploadManager.isHEVCFormatSupported) {
                numberOfRows = 2;
            } else {
                numberOfRows = 0;
            }
            break;
        case CameraUploadSectionOptions:
            numberOfRows = 3;
        default:
            break;
    }
    
    return numberOfRows;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.hidden = [self shouldHideRowAtIndexPath:indexPath];
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    view.hidden = [self shouldHideSection:section];
}

- (void)tableView:(UITableView *)tableView willDisplayFooterView:(UIView *)view forSection:(NSInteger)section {
    view.hidden = [self shouldHideSection:section];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self shouldHideRowAtIndexPath:indexPath]) {
        return 0;
    }
    
    return [super tableView:tableView heightForRowAtIndexPath:indexPath];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if ([self shouldHideSection:section]) {
        return TableViewSectionHeaderFooterHiddenHeight;
    }
    
    return [super tableView:tableView heightForHeaderInSection:section];
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if ([self shouldHideSection:section]) {
        return TableViewSectionHeaderFooterHiddenHeight;
    }
    
    return [super tableView:tableView heightForFooterInSection:section];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.section == CameraUploadSectionPhotoFormat) {
        CameraUploadManager.convertHEICPhoto = indexPath.row == CameraUploadPhotoFormatRowJPG;
        [self configUI];
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString *title;
    switch (section) {
        case CameraUploadSectionPhotoFormat:
            title = AMLocalizedString(@"SAVE HEIC PHOTOS AS", @"What format to upload HEIC photos");
            break;
        case CameraUploadSectionOptions:
            title = AMLocalizedString(@"options", @"Camera Upload options");
            break;
        default:
            break;
    }
    
    return title;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    NSString *title;
    switch (section) {
        case CameraUploadSectionFeatureSwitch:
            if (CameraUploadManager.isCameraUploadEnabled) {
                if (CameraUploadManager.isVideoUploadEnabled) {
                    title = AMLocalizedString(@"Photos and videos will be uploaded to Camera Uploads folder.", nil);
                } else {
                    title = AMLocalizedString(@"Photos will be uploaded to Camera Uploads folder.", nil);
                }
                
                title = [NSString stringWithFormat:@"%@ %@", title, AMLocalizedString(@"(Live Photos and Bursts are included)", nil)];
            } else {
                title = AMLocalizedString(@"When enabled, photos will be uploaded.", nil);
            }
            break;
        case CameraUploadSectionPhotoFormat:
            title = AMLocalizedString(@"We recommend JPG, as its the most compatible format for photos.", nil);
            break;
        default:
            break;
    }
    
    return title;
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

- (BOOL)shouldHideSection:(NSInteger)section {
    BOOL hide = NO;
    switch (section) {
        case CameraUploadSectionPhotoFormat:
            hide = !CameraUploadManager.isHEVCFormatSupported;
            break;
        default:
            break;
    }
    
    return hide;
}

- (BOOL)shouldHideRowAtIndexPath:(NSIndexPath *)indexPath {
    BOOL hide = NO;
    if (indexPath.section == CameraUploadSectionVideoInfo) {
        switch (indexPath.row) {
            case CameraUploadVideoRowDetailInfo:
                hide = !CameraUploadManager.isHEVCFormatSupported;
                break;
            case CameraUploadVideoRowSinglePageSetting:
                hide = CameraUploadManager.isHEVCFormatSupported;
                break;
            default: break;
        }
    } else if (indexPath.section == CameraUploadSectionOptions) {
        switch (indexPath.row) {
            case CameraUploadOptionRowUseMobileData:
                hide = ![self shouldShowMobileData];
                break;
            case CameraUploadOptionRowUseMobileDataForVideos:
                hide = ![self shouldShowMobileDataForVideos];
                break;
            default: break;
        }
    }
    
    return hide;
}

@end
