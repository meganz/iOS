
#import "VideoUploadsQualityTableViewController.h"

#import "MEGA-Swift.h"

#import "SelectableTableViewCell.h"
#import "CameraUploadManager+Settings.h"

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
    
    self.navigationItem.title = NSLocalizedString(@"videoQuality", @"Title that refers to the quality of the chat (Either Online or Offline)");
    
    self.lowLabel.text = NSLocalizedString(@"media.quality.low", @"Low");
    self.mediumLabel.text = NSLocalizedString(@"media.quality.medium", @"Medium");
    self.highLabel.text = NSLocalizedString(@"media.quality.high", @"High");
    self.originalLabel.text = NSLocalizedString(@"media.quality.original", @"Original");
    
    [self updateAppearance];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    self.currentIndexPath = [NSIndexPath indexPathForRow:CameraUploadManager.HEVCToH264CompressionQuality inSection:0];
    SelectableTableViewCell *cell = [self.tableView cellForRowAtIndexPath:self.currentIndexPath];
    cell.redCheckmarkImageView.hidden = NO;
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    
    if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
        [self updateAppearance];
    }
}

#pragma mark - Private

- (void)updateAppearance {
    self.tableView.separatorColor = [UIColor mnz_separatorForTraitCollection:self.traitCollection];
    self.tableView.backgroundColor = [UIColor mnz_backgroundGroupedForTraitCollection:self.traitCollection];
    
    [self.tableView reloadData];
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = [UIColor mnz_secondaryBackgroundGrouped:self.traitCollection];
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
}

@end
