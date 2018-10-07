#import "TransferTableViewCell.h"

#import <Photos/Photos.h>

#import "SVProgressHUD.h"

#import "Helper.h"
#import "MEGAPauseTransferRequestDelegate.h"
#import "MEGAGetThumbnailRequestDelegate.h"
#import "MEGASdkManager.h"
#import "MEGAStore.h"
#import "NSString+MNZCategory.h"
#import "QueuedTransferItem.h"
#import "UIImageView+MNZCategory.h"

@interface TransferTableViewCell ()

@property (weak, nonatomic) IBOutlet UIImageView *iconImageView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UIImageView *arrowImageView;
@property (weak, nonatomic) IBOutlet UILabel *infoLabel;
@property (weak, nonatomic) IBOutlet UILabel *percentageLabel;
@property (weak, nonatomic) IBOutlet UILabel *speedLabel;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UIButton *pauseButton;

@property (assign, nonatomic) BOOL isPaused;
@property (strong, nonatomic) MEGATransfer *transfer;
@property (strong, nonatomic) QueuedTransferItem *queuedTransfer;

@end

@implementation TransferTableViewCell

#pragma mark - Public

- (void)configureCellForTransfer:(MEGATransfer *)transfer delegate:(id<TransferTableViewCellDelegate>)delegate {
    self.delegate = delegate;
    self.transfer = transfer;
    self.queuedTransfer = nil;
    
    self.nameLabel.text = [[MEGASdkManager sharedMEGASdk] unescapeFsIncompatible:self.transfer.fileName];
    self.pauseButton.hidden = NO;

    MEGANode *node = [[MEGASdkManager sharedMEGASdk] nodeForHandle:self.transfer.nodeHandle];
    switch (self.transfer.type) {
        case MEGATransferTypeDownload: {
            if (node.hasThumbnail) {
                NSString *thumbnailFilePath = [Helper pathForNode:node inSharedSandboxCacheDirectory:@"thumbnailsV3"];
                if ([[NSFileManager defaultManager] fileExistsAtPath:thumbnailFilePath]) {
                    self.iconImageView.image = [UIImage imageWithContentsOfFile:thumbnailFilePath];
                } else {
                    MEGAGetThumbnailRequestDelegate *getThumbnailRequestDelegate = [[MEGAGetThumbnailRequestDelegate alloc] initWithCompletion:^(MEGARequest *request) {
                        self.iconImageView.image = [UIImage imageWithContentsOfFile:request.file];
                    }];
                    [[MEGASdkManager sharedMEGASdk] getThumbnailNode:node destinationFilePath:thumbnailFilePath delegate:getThumbnailRequestDelegate];
                    [self.iconImageView mnz_imageForNode:node];
                }
            } else {
                [self.iconImageView mnz_imageForNode:node];
            }
            break;
        }
            
        case MEGATransferTypeUpload: {
            if (transfer.fileName.mnz_isImagePathExtension || transfer.fileName.mnz_isVideoPathExtension) {
                NSString *transferThumbnailAbsolutePath = [[[NSHomeDirectory() stringByAppendingPathComponent:transfer.path] stringByDeletingPathExtension] stringByAppendingString:@"_thumbnail"];
                self.iconImageView.image = [UIImage imageWithContentsOfFile:transferThumbnailAbsolutePath];
            } else {
                [self.iconImageView mnz_setImageForExtension:transfer.fileName.pathExtension];
            }
            break;
        }
            
        default:
            break;
    }
    
    
    [self configureCellState];
}

- (void)configureCellForQueuedTransfer:(QueuedTransferItem *)queuedTransferItem delegate:(id<TransferTableViewCellDelegate>)delegate {
    self.delegate = delegate;
    self.queuedTransfer = queuedTransferItem;
    self.transfer = nil;
    
    PHAssetResource *assetResource = [PHAssetResource assetResourcesForAsset:self.queuedTransfer.asset].firstObject;
    NSString *name = [[NSString mnz_fileNameWithDate:self.queuedTransfer.asset.creationDate] stringByAppendingPathExtension:assetResource.originalFilename.mnz_lastExtensionInLowercase];
    self.nameLabel.text = name;
    self.pauseButton.hidden = YES;

    PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
    options.version = PHImageRequestOptionsVersionCurrent;
    options.networkAccessAllowed = YES;
    
    [[PHImageManager defaultManager] requestImageForAsset:self.queuedTransfer.asset targetSize:self.iconImageView.frame.size contentMode:PHImageContentModeAspectFit options:options resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
        if (result) {
            self.iconImageView.image = result;
        } else {
            [self.iconImageView mnz_setImageForExtension:assetResource.originalFilename.pathExtension];
        }
    }];
    
    [self queuedStateLayout];
}

- (void)updatePercentAndSpeedLabelsForTransfer:(MEGATransfer *)transfer {
    self.transfer = transfer;
    
    if (transfer.type == MEGATransferTypeDownload) {
        self.arrowImageView.image = [Helper downloadingTransferImage];
        self.percentageLabel.textColor = UIColor.mnz_green31B500;
    } else {
        self.arrowImageView.image = [Helper uploadingTransferImage];
        self.percentageLabel.textColor = UIColor.mnz_blue2BA6DE;
    }
    
    float percentage = (transfer.transferredBytes.floatValue / transfer.totalBytes.floatValue * 100);
    NSString *percentageCompleted = [NSString stringWithFormat:@"%.f %%", percentage];
    self.percentageLabel.text = percentageCompleted;
    NSString *speed = [NSString stringWithFormat:@"%@/s", [NSByteCountFormatter stringFromByteCount:transfer.speed.longLongValue countStyle:NSByteCountFormatterCountStyleMemory]];
    self.speedLabel.text = speed;
}

#pragma mark - Private

- (void)configureCellState {

    switch (self.transfer.state) {
            
        case MEGATransferStateActive:
            [self.pauseButton setImage:[UIImage imageNamed:@"pauseTransfers"] forState:UIControlStateNormal];
            [self updatePercentAndSpeedLabelsForTransfer:self.transfer];
            break;
            
        case MEGATransferStatePaused:
            [self inactiveStateLayout];
            self.percentageLabel.text = AMLocalizedString(@"paused", @"Paused");
            [self.pauseButton setImage:[UIImage imageNamed:@"resumeTransfers"] forState:UIControlStateNormal];
            break;
            
        case MEGATransferStateRetrying:
            [self inactiveStateLayout];
            self.percentageLabel.text = AMLocalizedString(@"Retrying...", @"Label for the state of a transfer when is being retrying - (String as short as possible).");
            break;
            
        case MEGATransferStateCompleting:
            [self inactiveStateLayout];
            self.percentageLabel.text = AMLocalizedString(@"Completing...", @"Label for the state of a transfer when is being completing - (String as short as possible).");
            break;
            
        default:
            [self inactiveStateLayout];
            self.percentageLabel.text = AMLocalizedString(@"queued", @"Queued");
            break;
    }
}

- (void)inactiveStateLayout {
    [self.pauseButton setImage:[UIImage imageNamed:@"pauseTransfers"] forState:UIControlStateNormal];
    self.percentageLabel.textColor = UIColor.mnz_gray666666;
    
    if (self.transfer.type == MEGATransferTypeDownload) {
        self.arrowImageView.image = [Helper downloadQueuedTransferImage];
    } else {
        self.arrowImageView.image = [Helper uploadQueuedTransferImage];
    }
}

- (void)queuedStateLayout {
    self.percentageLabel.textColor = UIColor.mnz_gray666666;
    self.arrowImageView.image = [Helper uploadQueuedTransferImage];
    self.percentageLabel.text = AMLocalizedString(@"pending", nil);
}

#pragma mark - IBActions

- (IBAction)cancelTransfer:(id)sender {
    if (self.transfer) {
        if ([[MEGASdkManager sharedMEGASdk] transferByTag:self.transfer.tag] != nil) {
            [[MEGASdkManager sharedMEGASdk] cancelTransferByTag:self.transfer.tag];
        } else {
            if ([[MEGASdkManager sharedMEGASdkFolder] transferByTag:self.transfer.tag] != nil) {
                [[MEGASdkManager sharedMEGASdkFolder] cancelTransferByTag:self.transfer.tag];
            }
        }
    } else if (self.queuedTransfer) {
        [[MEGAStore shareInstance] deleteUploadTransfer:self.queuedTransfer.uploadTransfer];
        [SVProgressHUD showImage:[UIImage imageNamed:@"hudMinus"] status:AMLocalizedString(@"transferCancelled", nil)];
    }
}

- (IBAction)pauseTransfer:(id)sender {
    if (self.transfer) {
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
}

@end
