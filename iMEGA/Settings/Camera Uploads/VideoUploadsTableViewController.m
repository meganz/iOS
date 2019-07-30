
#import "VideoUploadsTableViewController.h"
#import "CameraUploadManager+Settings.h"
#import "MEGAConstants.h"

typedef NS_ENUM(NSUInteger, VideoUploadsSection) {
    VideoUploadsSectionFeatureSwitch,
    VideoUploadsSectionFormat,
    VideoUploadsSectionQuality,
    VideoUploadsSectionCount
};

typedef NS_ENUM(NSUInteger, VideoUploadsSectionFormatRow) {
    VideoUploadsSectionFormatRowHEVC,
    VideoUploadsSectionFormatRowH264,
    VideoUploadsSectionFormatRowCount
};

@interface VideoUploadsTableViewController ()

@property (weak, nonatomic) IBOutlet UILabel *uploadVideosLabel;
@property (weak, nonatomic) IBOutlet UISwitch *uploadVideosSwitch;
@property (weak, nonatomic) IBOutlet UILabel *videoQualityLabel;
@property (weak, nonatomic) IBOutlet UILabel *videoQualityRightDetailLabel;
@property (weak, nonatomic) IBOutlet UILabel *HEVCLabel;
@property (weak, nonatomic) IBOutlet UILabel *H264Label;
@property (weak, nonatomic) IBOutlet UIImageView *HEVCRedCheckmarkImageView;
@property (weak, nonatomic) IBOutlet UIImageView *H264RedCheckmarkImageView;

@end

@implementation VideoUploadsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.uploadVideosLabel setText:AMLocalizedString(@"uploadVideosLabel", @"Title to switch on/off video uploads")];
    self.videoQualityLabel.text = AMLocalizedString(@"videoQuality", @"Title that refers to the video compression quality when to transcode from HEVC to H.264 codec");
    [self configVideoFormatTexts];
}

- (void)configVideoFormatTexts {
    NSDictionary<NSAttributedStringKey, id> *formatAttributes = @{NSFontAttributeName : [UIFont systemFontOfSize:17.0], NSForegroundColorAttributeName : [UIColor mnz_black333333]};
    
    NSMutableAttributedString *H264AttributedString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ ", H264Format] attributes:formatAttributes];
    [H264AttributedString appendAttributedString:[[NSAttributedString alloc] initWithString:AMLocalizedString(@"(Recommended)", nil) attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:17.0], NSForegroundColorAttributeName : [UIColor mnz_gray999999]}]];
    self.H264Label.attributedText = H264AttributedString;
    
    self.HEVCLabel.attributedText = [[NSAttributedString alloc] initWithString:HEVCFormat attributes:formatAttributes];
}

- (void)configUI {
    self.uploadVideosSwitch.on = CameraUploadManager.isVideoUploadEnabled;
    [self configVideoFormatUI];
    [self configVideoQualityUI];
    [self.tableView reloadData];
    [self.tableView beginUpdates];
    [self.tableView endUpdates];
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

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self configUI];
}

#pragma mark - UI Actions

- (IBAction)uploadVideosSwitchValueChanged:(UISwitch *)sender {
    if (sender.isOn) {
        [CameraUploadManager.shared enableVideoUpload];
    } else {
        [CameraUploadManager.shared disableVideoUpload];
    }
    
    [self configUI];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    NSInteger numberOfSections = 0;
    if (CameraUploadManager.isVideoUploadEnabled) {
        if (CameraUploadManager.isHEVCFormatSupported) {
            if (CameraUploadManager.shouldConvertHEVCVideo) {
                numberOfSections = VideoUploadsSectionCount;
            } else {
                numberOfSections = VideoUploadsSectionCount - 1;
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
            numberOfRows = VideoUploadsSectionFormatRowCount;
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
        CameraUploadManager.convertHEVCVideo = indexPath.row == VideoUploadsSectionFormatRowH264;
        [self configUI];
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString *title;
    switch (section) {
        case VideoUploadsSectionFormat:
            title = AMLocalizedString(@"SAVE HEVC VIDEOS AS", nil);
            break;
        default:
            break;
    }
    
    return title;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    NSString *title;
    switch (section) {
        case VideoUploadsSectionFeatureSwitch:
            if (CameraUploadManager.isVideoUploadEnabled) {
                title = AMLocalizedString(@"Videos will be uploaded to the Camera Uploads folder.", nil);
            } else {
                title = AMLocalizedString(@"When enabled, videos will be uploaded.", nil);
            }
            break;
        case VideoUploadsSectionFormat:
            title = AMLocalizedString(@"We recommend H.264, as its the most compatible format for videos.", nil);
            break;
        case VideoUploadsSectionQuality:
            title = AMLocalizedString(@"Compression quality when to transcode HEVC videos to H.264 format.", nil);
            break;
        default:
            break;
    }
    
    return title;
}

@end
