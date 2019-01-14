#import "CameraUploadsTableViewController.h"
#import <Photos/Photos.h>
#import "MEGAReachabilityManager.h"
#import "MEGATransfer+MNZCategory.h"
#import "NSString+MNZCategory.h"
#import "CameraUploadManager.h"
#import "CameraUploadManager+Settings.h"
#import "DevicePermissionsHelper.h"
#import "Helper.h"
#import "BackgroundUploadManager.h"

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

@interface CameraUploadsTableViewController ()

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

@end

@implementation CameraUploadsTableViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.navigationItem setTitle:AMLocalizedString(@"cameraUploadsLabel", nil)];
    [self.enableCameraUploadsLabel setText:AMLocalizedString(@"cameraUploadsLabel", nil)];
    
    [self.uploadVideosInfoLabel setText:AMLocalizedString(@"uploadVideosLabel", nil)];
    self.uploadVideosInfoRightDetailLabel.text = CameraUploadManager.isVideoUploadEnabled ? AMLocalizedString(@"on", nil) : AMLocalizedString(@"off", nil);
    
    [self.uploadVideosLabel setText:AMLocalizedString(@"uploadVideosLabel", nil)];
    
    self.useCellularConnectionLabel.text = AMLocalizedString(@"useMobileData", @"Title next to a switch button (On-Off) to allow using mobile data (Roaming) for a feature.");
    
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self configUI];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

#pragma mark - UI configuration

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
    self.backgroundUploadSwitch.on = BackgroundUploadManager.isBackgroundUploadEnabled;
}

#pragma mark - IBActions

- (IBAction)enableCameraUploadsSwitchValueChanged:(UISwitch *)sender {
    if (sender.isOn) {
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
            switch (status) {
                case PHAuthorizationStatusAuthorized: {
                    CameraUploadManager.cameraUploadEnabled = YES;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self configUI];
                    });
                    break;
                }
                case PHAuthorizationStatusRestricted:
                case PHAuthorizationStatusDenied: {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        MEGALogInfo(@"Disable Camera Uploads");
                        [self presentViewController:DevicePermissionsHelper.photosPermissionDeniedAlertController animated:YES completion:nil];
                        [self configUI];
                    });
                    break;
                }
                default:
                    break;
            }
        }];
    } else {
        CameraUploadManager.cameraUploadEnabled = NO;
        [self configUI];
    }
}

- (IBAction)uploadVideosSwitchValueChanged:(UISwitch *)sender {
    MEGALogInfo(@"%@ uploads videos", sender.isOn ? @"Enable" : @"Disable");
    CameraUploadManager.videoUploadEnabled = sender.isOn;
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

- (IBAction)backgroundUploadSwitchValueChanged:(UISwitch *)sender {
    
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
            if (CameraUploadManager.shouldShowPhotoAndVideoFormat) {
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

//- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
//    NSString *titleForHeader;
//    if (section == 1) {
//        titleForHeader = AMLocalizedString(@"options", nil);
//    }
//    return titleForHeader;
//}
//
//- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
//    NSString *titleForFooter;
//    if (section == 0) {
//        titleForFooter = AMLocalizedString(@"cameraUploads_footer", @"Footer explicative text to explain the Camera Uploads funtionality");
//    }
//    return titleForFooter;
//}

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
            hide = !CameraUploadManager.shouldShowPhotoAndVideoFormat;
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
                hide = !CameraUploadManager.shouldShowPhotoAndVideoFormat;
                break;
            case CameraUploadVideoRowSinglePageSetting:
                hide = CameraUploadManager.shouldShowPhotoAndVideoFormat;
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
