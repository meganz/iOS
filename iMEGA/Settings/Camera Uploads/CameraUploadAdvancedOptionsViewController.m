
#import "CameraUploadAdvancedOptionsViewController.h"

#import "CameraUploadManager+Settings.h"
#import "CameraScanner.h"
#import "MEGA-Swift.h"

typedef NS_ENUM(NSUInteger, AdvancedOptionSection) {
    AdvancedOptionSectionLivePhoto,
    AdvancedOptionSectionBurstPhoto,
    AdvancedOptionSectionHiddenAlbum,
    AdvancedOptionSectionSharedAlbums,
    AdvancedOptionSectionSyncedAlbums,
};

@interface CameraUploadAdvancedOptionsViewController ()

@property (weak, nonatomic) IBOutlet UILabel *uploadVideosForLivePhotosLabel;
@property (weak, nonatomic) IBOutlet UISwitch *uploadVideosForlivePhotosSwitch;

@property (weak, nonatomic) IBOutlet UILabel *uploadAllBurstPhotosLabel;
@property (weak, nonatomic) IBOutlet UISwitch *uploadAllBurstPhotosSwitch;

@property (weak, nonatomic) IBOutlet UILabel *uploadHiddenAlbumLabel;
@property (weak, nonatomic) IBOutlet UISwitch *uploadHiddenAlbumSwitch;

@property (weak, nonatomic) IBOutlet UILabel *uploadSharedAlbumsLabel;
@property (weak, nonatomic) IBOutlet UISwitch *uploadSharedAlbumsSwitch;

@property (weak, nonatomic) IBOutlet UILabel *uploadSyncedAlbumsLabel;
@property (weak, nonatomic) IBOutlet UISwitch *uploadSyncedAlbumsSwitch;

@end

@implementation CameraUploadAdvancedOptionsViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.navigationItem setTitle:AMLocalizedString(@"advanced", nil)];
    
    self.uploadVideosForLivePhotosLabel.text = AMLocalizedString(@"Upload Videos for Live Photos", @"Title of the switch to config whether to upload videos for Live Photos");
    self.uploadVideosForlivePhotosSwitch.on = CameraUploadManager.shouldUploadVideosForLivePhotos;
    self.uploadAllBurstPhotosLabel.text = AMLocalizedString(@"Upload All Burst Photos", @"Title of the switch to config whether to upload all burst photos");
    self.uploadAllBurstPhotosSwitch.on = CameraUploadManager.shouldUploadAllBurstPhotos;
    self.uploadHiddenAlbumLabel.text = AMLocalizedString(@"Upload Hidden Album", nil);
    self.uploadHiddenAlbumSwitch.on = CameraUploadManager.shouldUploadHiddenAlbum;
    self.uploadSharedAlbumsLabel.text = AMLocalizedString(@"Upload Shared Albums", nil);
    self.uploadSharedAlbumsSwitch.on = CameraUploadManager.shouldUploadSharedAlbums;
    self.uploadSyncedAlbumsLabel.text = AMLocalizedString(@"Upload Albums Synced from iTunes", @"Title of the switch to config whether to upload synced albums");
    self.uploadSyncedAlbumsSwitch.on = CameraUploadManager.shouldUploadSyncedAlbums;
    
    self.tableView.backgroundColor = [UIColor mnz_backgroundGroupedForTraitCollection:self.traitCollection];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    
    if (@available(iOS 13.0, *)) {
        if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
            [self updateAppearance];
        }
    }
}

#pragma mark - Private

- (void)updateAppearance {
    self.tableView.separatorColor = [UIColor mnz_separatorForTraitCollection:self.traitCollection];
    self.tableView.backgroundColor = [UIColor mnz_backgroundGroupedForTraitCollection:self.traitCollection];
    
    [self.tableView reloadData];
}

#pragma mark - UI Actions

- (IBAction)didChangeValueForLivePhotosSwitch:(UISwitch *)sender {
    CameraUploadManager.uploadVideosForLivePhotos = sender.isOn;
    [self configCameraUploadWhenValueChangedForSwitch:sender];
}

- (IBAction)didChangeValueForBurstPhotosSwitch:(UISwitch *)sender {
    CameraUploadManager.uploadAllBurstPhotos = sender.isOn;
    [self configCameraUploadWhenValueChangedForSwitch:sender];
}

- (IBAction)didChangeValueForHiddenAssetsSwitch:(UISwitch *)sender {
    CameraUploadManager.uploadHiddenAlbum = sender.isOn;
    [self configCameraUploadWhenValueChangedForSwitch:sender];
}

- (IBAction)didChangeValueForSharedAlbumsSwitch:(UISwitch *)sender {
    CameraUploadManager.uploadSharedAlbums = sender.isOn;
    [self configCameraUploadWhenValueChangedForSwitch:sender];
}

- (IBAction)didChangeValueForSyncedAlbumsSwitch:(UISwitch *)sender {
    CameraUploadManager.uploadSyncedAlbums = sender.isOn;
    [self configCameraUploadWhenValueChangedForSwitch:sender];
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
                title = AMLocalizedString(@"The video and the photo in each Live Photo will be uploaded.", nil);
            } else {
                title = AMLocalizedString(@"Only the photo in each Live Photo will be uploaded.", nil);
            }
            break;
        case AdvancedOptionSectionBurstPhoto:
            if (self.uploadAllBurstPhotosSwitch.isOn) {
                title = AMLocalizedString(@"All the photos from your burst photo sequences will be uploaded.", nil);
            } else {
                title = AMLocalizedString(@"Only the representative photos from your burst photo sequences will be uploaded.", nil);
            }
            break;
        case AdvancedOptionSectionHiddenAlbum:
            title = AMLocalizedString(@"The Hidden Album is where you hide photos or videos in your device Photos app.", nil);
            break;
        case AdvancedOptionSectionSharedAlbums:
            if (self.uploadSharedAlbumsSwitch.isOn) {
                title = AMLocalizedString(@"Shared Albums from your device's Photos app will be uploaded.", nil);
            } else {
                title = AMLocalizedString(@"Shared Albums from your device's Photos app will not be uploaded.", nil);
            }
            break;
        case AdvancedOptionSectionSyncedAlbums:
            title = AMLocalizedString(@"Synced albums are where you sync photos or videos to your device's Photos app from iTunes.", nil);
            break;
        default:
            break;
    }
    
    return title;
}


#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = [UIColor mnz_secondaryBackgroundGrouped:self.traitCollection];
}

@end
