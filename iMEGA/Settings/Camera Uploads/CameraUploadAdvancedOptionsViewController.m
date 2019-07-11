
#import "CameraUploadAdvancedOptionsViewController.h"
#import "CameraUploadManager+Settings.h"

typedef NS_ENUM(NSUInteger, AdvancedOptionSection) {
    AdvancedOptionSectionLivePhoto,
    AdvancedOptionSectionBurstPhoto,
    AdvancedOptionSectionHiddenAlbum,
};

@interface CameraUploadAdvancedOptionsViewController ()

@property (weak, nonatomic) IBOutlet UILabel *uploadVideosForLivePhotosLabel;
@property (weak, nonatomic) IBOutlet UISwitch *uploadVideosForlivePhotosSwitch;
@property (weak, nonatomic) IBOutlet UILabel *uploadBurstPhotosLabel;
@property (weak, nonatomic) IBOutlet UISwitch *uploadBurstPhotosSwitch;
@property (weak, nonatomic) IBOutlet UILabel *uploadHiddenAlbumLabel;
@property (weak, nonatomic) IBOutlet UISwitch *uploadHiddenAlbumSwitch;

@end

@implementation CameraUploadAdvancedOptionsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.uploadVideosForLivePhotosLabel.text = @"Upload videos for Live Photos";
    self.uploadVideosForlivePhotosSwitch.on = CameraUploadManager.shouldUploadVideosForLivePhotos;
    self.uploadBurstPhotosLabel.text = @"Upload all burst photos";
    self.uploadBurstPhotosSwitch.on = CameraUploadManager.shouldUploadAllBurstPhotos;
    self.uploadHiddenAlbumLabel.text = @"Upload Hidden album";
    self.uploadHiddenAlbumSwitch.on = CameraUploadManager.shouldUploadHiddenAssets;
}

#pragma mark - UI Actions

- (IBAction)didChangeValueForLivePhotosSwitch:(UISwitch *)sender {
    CameraUploadManager.uploadVideosForLivePhotos = sender.isOn;
    [self.tableView reloadData];
}

- (IBAction)didChangeValueForBurstPhotosSwitch:(UISwitch *)sender {
    CameraUploadManager.uploadAllBurstPhotos = sender.isOn;
    [self.tableView reloadData];
}

- (IBAction)didChangeValueForHiddenAssetsSwitch:(UISwitch *)sender {
    CameraUploadManager.uploadHiddenAssets = sender.isOn;
    [self.tableView reloadData];
}


#pragma mark - UITableViewDataSource

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    NSString *title;
    switch (section) {
        case AdvancedOptionSectionLivePhoto:
            if (self.uploadVideosForlivePhotosSwitch.isOn) {
                title = @"Underlying videos and key photos in Live Photos will be uploaded.";
            } else {
                title = @"Only key photos in Live Photos will be uploaded.";
            }
            break;
        case AdvancedOptionSectionBurstPhoto:
            if (self.uploadBurstPhotosSwitch.isOn) {
                title = @"All photos from burst photo sequences will be uploaded.";
            } else {
                title = @"Only the user-picked and representative photos from burst photo sequences will be uploaded.";
            }
            break;
        case AdvancedOptionSectionHiddenAlbum:
            if (self.uploadHiddenAlbumSwitch.isOn) {
                title = @"The photos or videos in your Hidden album will be uploaded.";
            } else {
                title = @"The photos or videos in your Hidden album will not be uploaded.";
            }
            break;
        default:
            break;
    }
    
    
    return title;
}

@end
