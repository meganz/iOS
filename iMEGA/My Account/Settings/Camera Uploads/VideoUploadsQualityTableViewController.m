#import "VideoUploadsQualityTableViewController.h"

#import "MEGA-Swift.h"

#import "SelectableTableViewCell.h"
#import "CameraUploadManager+Settings.h"

@import MEGAL10nObjc;

@interface VideoUploadsQualityTableViewController ()

@property (weak, nonatomic) IBOutlet UILabel *lowLabel;
@property (weak, nonatomic) IBOutlet UILabel *mediumLabel;
@property (weak, nonatomic) IBOutlet UILabel *highLabel;
@property (weak, nonatomic) IBOutlet UILabel *originalLabel;

@property (weak, nonatomic) NSIndexPath *currentIndexPath;

@end

@implementation VideoUploadsQualityTableViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = LocalizedString(@"videoQuality", @"Title that refers to the quality of the chat (Either Online or Offline)");
    
    self.lowLabel.text = LocalizedString(@"media.quality.low", @"Low");
    self.mediumLabel.text = LocalizedString(@"media.quality.medium", @"Medium");
    self.highLabel.text = LocalizedString(@"media.quality.high", @"High");
    self.originalLabel.text = LocalizedString(@"media.quality.original", @"Original");
    
    [self setupColors];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    self.currentIndexPath = [NSIndexPath indexPathForRow:CameraUploadManager.HEVCToH264CompressionQuality inSection:0];
    SelectableTableViewCell *cell = [self.tableView cellForRowAtIndexPath:self.currentIndexPath];
    cell.redCheckmarkImageView.hidden = NO;
}

- (VideoUploadsViewModel *)viewModel {
    if (!_viewModel) {
        _viewModel = [self makeViewModel];
    }
    return _viewModel;
}

#pragma mark - Private

- (void)setupColors {
    self.tableView.separatorColor = [UIColor borderStrong];
    self.tableView.backgroundColor = [UIColor pageBackgroundColor];
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = [UIColor pageBackgroundColor];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (CameraUploadManager.HEVCToH264CompressionQuality == indexPath.row) {
        return;
    }
    
    [CameraUploadManager setHEVCToH264CompressionQuality:indexPath.row];
    SelectableTableViewCell *previousSelectedCell = [self.tableView cellForRowAtIndexPath:self.currentIndexPath];
    previousSelectedCell.redCheckmarkImageView.hidden = YES;
    SelectableTableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    cell.redCheckmarkImageView.hidden = NO;
    self.currentIndexPath = indexPath;
    
    [self trackVideoQualityEvent:indexPath.row];
}

@end
