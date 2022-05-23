
#import "VideoUploadsTableViewController.h"

#import "MEGA-Swift.h"

#import "CameraUploadManager+Settings.h"

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

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.uploadVideosLabel setText:NSLocalizedString(@"uploadVideosLabel", @"Title to switch on/off video uploads")];
    self.videoQualityLabel.text = NSLocalizedString(@"videoQuality", @"Title that refers to the video compression quality when to transcode from HEVC to H.264 codec");
    [self configVideoFormatTexts];
    
    [self updateAppearance];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self configUI];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    
    if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
        [self updateAppearance];
    }
}

#pragma mark - Private

- (void)configVideoFormatTexts {
    NSDictionary<NSAttributedStringKey, id> *formatAttributes = @{NSFontAttributeName : [UIFont preferredFontForTextStyle:UIFontTextStyleBody], NSForegroundColorAttributeName : UIColor.mnz_label};
    
    NSMutableAttributedString *H264AttributedString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ ", H264Format] attributes:formatAttributes];
    [H264AttributedString appendAttributedString:[NSAttributedString.alloc initWithString:NSLocalizedString(@"(Recommended)", nil) attributes:@{NSFontAttributeName : [UIFont preferredFontForTextStyle:UIFontTextStyleBody], NSForegroundColorAttributeName : [UIColor mnz_secondaryGrayForTraitCollection:self.traitCollection]}]];
    self.H264Label.attributedText = H264AttributedString;
    
    self.HEVCLabel.attributedText = [[NSAttributedString alloc] initWithString:HEVCFormat attributes:formatAttributes];
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
            videoQualityString = NSLocalizedString(@"media.video.quality.low", @"Low");
            break;
        case CameraUploadVideoQualityMedium:
            videoQualityString = NSLocalizedString(@"media.video.quality.medium", @"Medium");
            break;
        case CameraUploadVideoQualityHigh:
            videoQualityString = NSLocalizedString(@"media.video.quality.high", @"High");
            break;
        case CameraUploadVideoQualityOriginal:
            videoQualityString = NSLocalizedString(@"media.video.quality.original", @"Original");
            break;
        default:
            break;
    }
    
    self.videoQualityRightDetailLabel.text = videoQualityString;
}

- (void)updateAppearance {
    self.videoQualityRightDetailLabel.textColor = UIColor.mnz_secondaryLabel;
    
    self.tableView.separatorColor = [UIColor mnz_separatorForTraitCollection:self.traitCollection];
    self.tableView.backgroundColor = [UIColor mnz_backgroundGroupedForTraitCollection:self.traitCollection];
    
    [self.tableView reloadData];
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

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    NSInteger numberOfSections = 0;
    if (CameraUploadManager.isVideoUploadEnabled) {
        if (CameraUploadManager.shouldConvertHEVCVideo) {
            numberOfSections = VideoUploadsSectionCount;
        } else {
            numberOfSections = VideoUploadsSectionCount - 1;
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
            title = NSLocalizedString(@"SAVE HEVC VIDEOS AS", nil);
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
                title = NSLocalizedString(@"Videos will be uploaded to the Camera Uploads folder.", nil);
            } else {
                title = NSLocalizedString(@"When enabled, videos will be uploaded.", nil);
            }
            break;
        case VideoUploadsSectionFormat:
            title = NSLocalizedString(@"We recommend H.264, as its the most compatible format for videos.", nil);
            break;
        case VideoUploadsSectionQuality:
            title = NSLocalizedString(@"Compression quality when to transcode HEVC videos to H.264 format.", nil);
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
