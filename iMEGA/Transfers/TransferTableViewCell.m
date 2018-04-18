#import "TransferTableViewCell.h"
#import "MEGASdkManager.h"

#import "MEGAPauseTransferRequestDelegate.h"
#import "MEGAGetThumbnailRequestDelegate.h"

#import "Helper.h"

@interface TransferTableViewCell ()

@property (assign, nonatomic) BOOL isPaused;

@end

@implementation TransferTableViewCell

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    
    if (selected) {
        UIView *view = [[UIView alloc] init];
        view.backgroundColor = [UIColor whiteColor];
        self.selectedBackgroundView = view;
        
        self.lineView.backgroundColor = [UIColor mnz_grayCCCCCC];
    }
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    [super setHighlighted:highlighted animated:animated];
    
    if (highlighted) {
        UIView *view = [[UIView alloc] init];
        view.backgroundColor = [UIColor mnz_grayF7F7F7];
        self.selectedBackgroundView = view;
        
        self.lineView.backgroundColor = [UIColor mnz_grayCCCCCC];
    }
}

- (void)configureCellForActiveTransfer:(MEGATransfer *)transfer delegate:(id<TransferTableViewCellDelegate>)delegate {
    self.delegate = delegate;
    self.transfer = transfer;
    if (transfer.type == MEGATransferTypeDownload) {
        self.arrowImageView.image = [Helper downloadingTransferImage];
        [self.percentageLabel setTextColor:UIColor.mnz_green31B500];
    } else {
        self.arrowImageView.image = [Helper uploadingTransferImage];
        [self.percentageLabel setTextColor:UIColor.mnz_blue2BA6DE];
    }
    
    [self.pauseButton setImage:[UIImage imageNamed:@"pauseTransfers"] forState:UIControlStateNormal];

    [self updatePercentAndSpeedLabelsForTransfer:transfer];
    
    [self configureCell];
}

- (void)configureCellForPausedTransfer:(MEGATransfer *)transfer delegate:(id<TransferTableViewCellDelegate>)delegate {
    self.delegate = delegate;
    self.transfer = transfer;
    [self.pauseButton setImage:[UIImage imageNamed:@"resumeTransfers"] forState:UIControlStateNormal];
    [self.percentageLabel setText:AMLocalizedString(@"paused", @"Paused")];
    [self.percentageLabel setTextColor:UIColor.mnz_gray666666];

    [self configureCell];
}

- (void)configureCellForQueuedTransfer:(MEGATransfer *)transfer delegate:(id<TransferTableViewCellDelegate>)delegate {
    self.delegate = delegate;
    self.transfer = transfer;
    [self.pauseButton setImage:[UIImage imageNamed:@"pauseTransfers"] forState:UIControlStateNormal];
    [self.percentageLabel setText:AMLocalizedString(@"queued", @"Queued")];
    [self.percentageLabel setTextColor:UIColor.mnz_gray666666];

    [self configureCell];
}

- (void)configureCell {
    if (self.transfer.type == MEGATransferTypeDownload) {
        [self.arrowImageView setImage:[Helper downloadQueuedTransferImage]];
    } else {
        [self.arrowImageView setImage:[Helper uploadQueuedTransferImage]];
    }
    [self.nameLabel setText:[[MEGASdkManager sharedMEGASdk] unescapeFsIncompatible:self.transfer.fileName]];
    
    MEGANode *node = [[MEGASdkManager sharedMEGASdk] nodeForHandle:self.transfer.nodeHandle];
    if (node.hasThumbnail) {
        NSString *thumbnailFilePath = [Helper pathForNode:node inSharedSandboxCacheDirectory:@"thumbnailsV3"];
        if ([[NSFileManager defaultManager] fileExistsAtPath:thumbnailFilePath]) {
            self.iconImageView.image = [UIImage imageWithContentsOfFile:thumbnailFilePath];
        } else {
            MEGAGetThumbnailRequestDelegate *getThumbnailRequestDelegate = [[MEGAGetThumbnailRequestDelegate alloc] initWithCompletion:^(MEGARequest *request) {
                self.iconImageView.image = [UIImage imageWithContentsOfFile:request.file];
            }];
            [[MEGASdkManager sharedMEGASdk] getThumbnailNode:node destinationFilePath:thumbnailFilePath delegate:getThumbnailRequestDelegate];
            self.iconImageView.image = [Helper imageForNode:node];
        }
    } else {
        self.iconImageView.image = [Helper imageForNode:node];
    }
}

- (void)updatePercentAndSpeedLabelsForTransfer:(MEGATransfer *)transfer {
    self.transfer = transfer;
    
    if (transfer.type == MEGATransferTypeDownload) {
        [self.arrowImageView setImage:[Helper downloadingTransferImage]];
        [self.percentageLabel setTextColor:UIColor.mnz_green31B500];
    } else {
        [self.arrowImageView setImage:[Helper uploadingTransferImage]];
        [self.percentageLabel setTextColor:UIColor.mnz_blue2BA6DE];
    }
    
    float percentage = (transfer.transferredBytes.floatValue / transfer.totalBytes.floatValue * 100);
    NSString *percentageCompleted = [NSString stringWithFormat:@"%.f %%", percentage];
    self.percentageLabel.text = percentageCompleted;
    NSString *speed = [NSString stringWithFormat:@"%@/s", [NSByteCountFormatter stringFromByteCount:transfer.speed.longLongValue  countStyle:NSByteCountFormatterCountStyleMemory]];
    self.speedLabel.text = speed;
}

#pragma mark - IBActions

- (IBAction)cancelTransfer:(id)sender {
    if ([[MEGASdkManager sharedMEGASdk] transferByTag:self.transfer.tag] != nil) {
        [[MEGASdkManager sharedMEGASdk] cancelTransferByTag:self.transfer.tag];
    } else {
        if ([[MEGASdkManager sharedMEGASdkFolder] transferByTag:self.transfer.tag] != nil) {
            [[MEGASdkManager sharedMEGASdkFolder] cancelTransferByTag:self.transfer.tag];
        }
    }
}

- (IBAction)pauseTransfer:(id)sender {
    self.isPaused = self.transfer.state == MEGATransferStatePaused;
    
    MEGAPauseTransferRequestDelegate *pauseTransferDelegate = [[MEGAPauseTransferRequestDelegate alloc] initWithCompletion:^(MEGARequest *request) {
        self.isPaused = self.transfer.state == MEGATransferStatePaused;
        [self.delegate pauseTransferCell:self];
    }];
    
    if ([[MEGASdkManager sharedMEGASdk] transferByTag:self.transfer.tag] != nil) {
        [[MEGASdkManager sharedMEGASdk] pauseTransferByTag:self.transfer.tag pause:!self.isPaused delegate:pauseTransferDelegate];
    } else {
        if ([[MEGASdkManager sharedMEGASdkFolder] transferByTag:self.transfer.tag] != nil) {
            [[MEGASdkManager sharedMEGASdkFolder] pauseTransferByTag:self.transfer.tag pause:!self.isPaused delegate:pauseTransferDelegate];
        }
    }
}

@end
