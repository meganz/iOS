#import "CameraUploadAdvancedOptionsViewController.h"

#import "CameraUploadManager+Settings.h"
#import "CameraScanner.h"
#import "MEGA-Swift.h"

#import "LocalizationHelper.h"

typedef NS_ENUM(NSUInteger, AdvancedOptionSection) {
    AdvancedOptionSectionLivePhoto,
    AdvancedOptionSectionBurstPhoto,
    AdvancedOptionSectionHiddenAlbum,
    AdvancedOptionSectionSharedAlbums,
    AdvancedOptionSectionSyncedAlbums,
};

@interface CameraUploadAdvancedOptionsViewController ()

@property (weak, nonatomic) IBOutlet UILabel *uploadVideosForLivePhotosLabel;
@property (weak, nonatomic) IBOutlet UILabel *uploadAllBurstPhotosLabel;
@property (weak, nonatomic) IBOutlet UILabel *uploadHiddenAlbumLabel;
@property (weak, nonatomic) IBOutlet UILabel *uploadSharedAlbumsLabel;
@property (weak, nonatomic) IBOutlet UILabel *uploadSyncedAlbumsLabel;

@end

@implementation CameraUploadAdvancedOptionsViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.navigationItem setTitle:LocalizedString(@"advanced", @"")];
    
    self.uploadVideosForLivePhotosLabel.text = LocalizedString(@"Upload Videos for Live Photos", @"Title of the switch to config whether to upload videos for Live Photos");
    self.uploadVideosForlivePhotosSwitch.on = CameraUploadManager.shouldUploadVideosForLivePhotos;
    self.uploadAllBurstPhotosLabel.text = LocalizedString(@"Upload All Burst Photos", @"Title of the switch to config whether to upload all burst photos");
    self.uploadAllBurstPhotosSwitch.on = CameraUploadManager.shouldUploadAllBurstPhotos;
    self.uploadHiddenAlbumLabel.text = LocalizedString(@"Upload Hidden Album", @"");
    self.uploadHiddenAlbumSwitch.on = CameraUploadManager.shouldUploadHiddenAlbum;

    self.uploadSharedAlbumsLabel.text = LocalizedString(@"Upload Shared Albums", @"");
    self.uploadSharedAlbumsSwitch.on = CameraUploadManager.shouldUploadSharedAlbums;

    self.uploadSyncedAlbumsLabel.text = LocalizedString(@"Upload Albums Synced from iTunes", @"Title of the switch to config whether to upload synced albums");
    self.uploadSyncedAlbumsSwitch.on = CameraUploadManager.shouldUploadSyncedAlbums;
    
    [self setupColors];
}

- (CameraUploadsAdvancedOptionsViewModel *)viewModel {
    if (!_viewModel) {
        _viewModel = [self makeViewModel];
    }
    return _viewModel;
}

#pragma mark - Private

- (void)setupColors {
    [self configSwitchTintColors];
    
    self.tableView.separatorColor = [UIColor borderStrong];
    self.tableView.backgroundColor = [UIColor pageBackgroundColor];
}

#pragma mark - UI Actions

- (IBAction)didChangeValueForLivePhotosSwitch:(UISwitch *)sender {
    CameraUploadManager.uploadVideosForLivePhotos = sender.isOn;
    [self configCameraUploadWhenValueChangedForSwitch:sender];
    [self trackLivePhotoVideoUploadsEvent: sender.isOn];
}

- (IBAction)didChangeValueForBurstPhotosSwitch:(UISwitch *)sender {
    CameraUploadManager.uploadAllBurstPhotos = sender.isOn;
    [self configCameraUploadWhenValueChangedForSwitch:sender];
    [self trackBurstPhotosUploadEvent: sender.isOn];
}

- (IBAction)didChangeValueForHiddenAssetsSwitch:(UISwitch *)sender {
    CameraUploadManager.uploadHiddenAlbum = sender.isOn;
    [self configCameraUploadWhenValueChangedForSwitch:sender];
    [self trackHiddenAlbumUploadEvent: sender.isOn];
}

- (IBAction)didChangeValueForSharedAlbumsSwitch:(UISwitch *)sender {
    CameraUploadManager.uploadSharedAlbums = sender.isOn;
    [self configCameraUploadWhenValueChangedForSwitch:sender];
    [self trackLivePhotoVideoUploadsEvent: sender.isOn];
}

- (IBAction)didChangeValueForSyncedAlbumsSwitch:(UISwitch *)sender {
    CameraUploadManager.uploadSyncedAlbums = sender.isOn;
    [self configCameraUploadWhenValueChangedForSwitch:sender];
    [self trackITunesSyncedAlbumsUploadEvent: sender.isOn];
}

- (void)configCameraUploadWhenValueChangedForSwitch:(UISwitch *)sender {
    [self.tableView reloadData];
    if (sender.isOn) {
        [CameraUploadManager.shared startCameraUploadIfNeeded];
    }
}

#pragma mark - UITableViewDataSource

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    NSString *title;
    switch (section) {
        case AdvancedOptionSectionLivePhoto:
            if (self.uploadVideosForlivePhotosSwitch.isOn) {
                title = LocalizedString(@"The video and the photo in each Live Photo will be uploaded.", @"");
            } else {
                title = LocalizedString(@"Only the photo in each Live Photo will be uploaded.", @"");
            }
            break;
        case AdvancedOptionSectionBurstPhoto:
            if (self.uploadAllBurstPhotosSwitch.isOn) {
                title = LocalizedString(@"All the photos from your burst photo sequences will be uploaded.", @"");
            } else {
                title = LocalizedString(@"Only the representative photos from your burst photo sequences will be uploaded.", @"");
            }
            break;
        case AdvancedOptionSectionHiddenAlbum:
            title = LocalizedString(@"The Hidden Album is where you hide photos or videos in your device Photos app.", @"");
            break;
        case AdvancedOptionSectionSharedAlbums:
            if (self.uploadSharedAlbumsSwitch.isOn) {
                title = LocalizedString(@"Shared Albums from your device's Photos app will be uploaded.", @"");
            } else {
                title = LocalizedString(@"Shared Albums from your device's Photos app will not be uploaded.", @"");
            }
            break;
        case AdvancedOptionSectionSyncedAlbums:
            title = LocalizedString(@"Synced albums are where you sync photos or videos to your device's Photos app from iTunes.", @"");
            break;
        default:
            break;
    }
    
    return title;
}


#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = [UIColor pageBackgroundColor];
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    if([view isKindOfClass:[UITableViewHeaderFooterView class]]){
        UITableViewHeaderFooterView * headerFooterView = (UITableViewHeaderFooterView *) view;
        headerFooterView.textLabel.textColor = [UIColor mnz_secondaryTextColor];
    }
}

- (void)tableView:(UITableView *)tableView willDisplayFooterView:(UIView *)view forSection:(NSInteger)section {
    if([view isKindOfClass:[UITableViewHeaderFooterView class]]){
        UITableViewHeaderFooterView * headerFooterView = (UITableViewHeaderFooterView *) view;
        headerFooterView.textLabel.textColor = [UIColor mnz_secondaryTextColor];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewAutomaticDimension;
}

@end
