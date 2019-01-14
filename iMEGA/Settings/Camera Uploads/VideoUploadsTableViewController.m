
#import "VideoUploadsTableViewController.h"
#import "CameraUploadManager+Settings.h"

typedef NS_ENUM(NSUInteger, VideoUploadsSection) {
    VideoUploadsSectionFeatureSwitch,
    VideoUploadsSectionFormat,
    VideoUploadsSectionQuality,
    VideoUploadsSectionTotalCount
};

typedef NS_ENUM(NSUInteger, VideoUploadsFormatRow) {
    VideoUploadsFormatRowHEVC,
    VideoUploadsFormatRowH264
};

@interface VideoUploadsTableViewController ()

@property (weak, nonatomic) IBOutlet UILabel *uploadVideosLabel;
@property (weak, nonatomic) IBOutlet UISwitch *uploadVideosSwitch;
@property (weak, nonatomic) IBOutlet UILabel *videoQualityLabel;
@property (weak, nonatomic) IBOutlet UILabel *videoQualityRightDetailLabel;
@property (weak, nonatomic) IBOutlet UIImageView *HEVCRedCheckmarkImageView;
@property (weak, nonatomic) IBOutlet UIImageView *H264RedCheckmarkImageView;

@end

@implementation VideoUploadsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.uploadVideosLabel setText:AMLocalizedString(@"uploadVideosLabel", nil)];
    self.videoQualityLabel.text = AMLocalizedString(@"videoQuality", @"Title that refers to the video compression quality when to transcode from HEVC to H.264 codec");
}

- (void)configUI {
    self.uploadVideosSwitch.on = CameraUploadManager.isVideoUploadEnabled;
    [self configVideoFormatUI];
    [self configVideoQualityUI];
    [self.tableView reloadData];
}

- (void)configVideoFormatUI {
    self.HEVCRedCheckmarkImageView.hidden = CameraUploadManager.shouldConvertHEVCVideo;
    self.H264RedCheckmarkImageView.hidden = !CameraUploadManager.shouldConvertHEVCVideo;
}

- (void)configVideoQualityUI {
    NSString *videoQualityString;
    switch (CameraUploadManager.HEVCToH264CompressionQuality) {
        case CameraUploadVideoQualityLow:
            videoQualityString = AMLocalizedString(@"low", @"Low");
            break;
        case CameraUploadVideoQualityMedium:
            videoQualityString = AMLocalizedString(@"medium", @"Medium");
            break;
        case CameraUploadVideoQualityHigh:
            videoQualityString = AMLocalizedString(@"high", @"High");
            break;
        case CameraUploadVideoQualityOriginal:
            videoQualityString = AMLocalizedString(@"original", @"Original");
            break;
        default:
            break;
    }
    
    self.videoQualityRightDetailLabel.text = videoQualityString;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self configUI];
}

#pragma mark - UI Actions

- (IBAction)uploadVideosSwitchValueChanged:(UISwitch *)sender {
    CameraUploadManager.videoUploadEnabled = sender.isOn;
    [self configUI];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    NSInteger numberOfSections = 0;
    if (CameraUploadManager.isVideoUploadEnabled) {
        if (CameraUploadManager.shouldShowPhotoAndVideoFormat) {
            if (CameraUploadManager.shouldConvertHEVCVideo) {
                numberOfSections = VideoUploadsSectionTotalCount;
            } else {
                numberOfSections = VideoUploadsSectionTotalCount - 1;
            }
        } else {
            numberOfSections = 1;
        }
    } else {
        numberOfSections = 1;
    }
    
    return numberOfSections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger numberOfRows = 0;
    switch (section) {
        case VideoUploadsSectionFeatureSwitch:
            numberOfRows = 1;
            break;
        case VideoUploadsSectionFormat:
            numberOfRows = 2;
            break;
        case VideoUploadsSectionQuality:
            numberOfRows = 1;
            break;
        default:
            break;
    }
    
    return numberOfRows;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.section == VideoUploadsSectionFormat) {
        CameraUploadManager.convertHEVCVideo = indexPath.row == VideoUploadsFormatRowH264;
        [self configUI];
    }
}

@end
