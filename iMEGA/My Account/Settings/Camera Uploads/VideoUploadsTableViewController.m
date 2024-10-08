#import "VideoUploadsTableViewController.h"
#import "MEGA-Swift.h"
#import "CameraUploadManager+Settings.h"

@import MEGAL10nObjc;

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

@property (weak, nonatomic) IBOutlet UISwitch *uploadVideosSwitch;
@property (weak, nonatomic) IBOutlet UIImageView *HEVCRedCheckmarkImageView;
@property (weak, nonatomic) IBOutlet UIImageView *H264RedCheckmarkImageView;

@property (weak, nonatomic) IBOutlet UILabel *videoQualityRightDetailLabel;

@end

@implementation VideoUploadsTableViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.uploadVideosLabel setText:LocalizedString(@"uploadVideosLabel", @"Title to switch on/off video uploads")];
    self.videoQualityLabel.text = LocalizedString(@"videoQuality", @"Title that refers to the video compression quality when to transcode from HEVC to H.264 codec");
    [self configVideoFormatTexts];
    
    [self updateNavigationTitle];
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
    NSDictionary<NSAttributedStringKey, id> *formatAttributes = @{NSFontAttributeName : [UIFont preferredFontForTextStyle:UIFontTextStyleBody], NSForegroundColorAttributeName : UIColor.labelColor};
    
    NSMutableAttributedString *H264AttributedString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ ", H264Format] attributes:formatAttributes];
    [H264AttributedString appendAttributedString:[NSAttributedString.alloc initWithString:LocalizedString(@"(Recommended)", @"") attributes:@{NSFontAttributeName : [UIFont preferredFontForTextStyle:UIFontTextStyleBody], NSForegroundColorAttributeName : [UIColor iconSecondaryColor]}]];
    self.H264Label.attributedText = H264AttributedString;
    self.HEVCLabel.attributedText = [[NSAttributedString alloc] initWithString:HEVCFormat attributes:formatAttributes];
}

- (void)configUI {
    self.uploadVideosSwitch.on = CameraUploadManager.isVideoUploadEnabled;
    self.uploadVideosSwitch.onTintColor = [UIColor switchOnTintColor];
    
    [self configVideoFormatUI];
    [self configVideoQualityUI];
    [self configLabelsTextColor];
    
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
            videoQualityString = LocalizedString(@"media.quality.low", @"Low");
            break;
        case CameraUploadVideoQualityMedium:
            videoQualityString = LocalizedString(@"media.quality.medium", @"Medium");
            break;
        case CameraUploadVideoQualityHigh:
            videoQualityString = LocalizedString(@"media.quality.high", @"High");
            break;
        case CameraUploadVideoQualityOriginal:
            videoQualityString = LocalizedString(@"media.quality.original", @"Original");
            break;
        default:
            break;
    }
    
    self.videoQualityRightDetailLabel.text = videoQualityString;
}

- (void)updateAppearance {
    self.videoQualityRightDetailLabel.textColor = UIColor.secondaryLabelColor;
    
    [self configLabelsTextColor];
    
    self.tableView.separatorColor = [UIColor mnz_separator];
    self.tableView.backgroundColor = [UIColor pageBackgroundForTraitCollection:self.traitCollection];
    
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
            title = LocalizedString(@"SAVE HEVC VIDEOS AS", @"");
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
                title = LocalizedString(@"Videos will be uploaded to the Camera Uploads folder.", @"");
            } else {
                title = LocalizedString(@"When enabled, videos will be uploaded.", @"");
            }
            break;
        case VideoUploadsSectionFormat:
            title = LocalizedString(@"We recommend H.264, as its the most compatible format for videos.", @"");
            break;
        case VideoUploadsSectionQuality:
            title = LocalizedString(@"Compression quality when to transcode HEVC videos to H.264 format.", @"");
            break;
        default:
            break;
    }
    
    return title;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = [UIColor mnz_backgroundElevated];
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    if([view isKindOfClass:[UITableViewHeaderFooterView class]]){
        UITableViewHeaderFooterView * headerFooterView = (UITableViewHeaderFooterView *) view;
        headerFooterView.textLabel.textColor = [UIColor mnz_subtitles];
    }
}

- (void)tableView:(UITableView *)tableView willDisplayFooterView:(UIView *)view forSection:(NSInteger)section {
    if([view isKindOfClass:[UITableViewHeaderFooterView class]]){
        UITableViewHeaderFooterView * headerFooterView = (UITableViewHeaderFooterView *) view;
        headerFooterView.textLabel.textColor = [UIColor mnz_subtitles];
    }
}

@end
