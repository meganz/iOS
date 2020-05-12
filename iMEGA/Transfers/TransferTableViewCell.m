#import "TransferTableViewCell.h"

#import <Photos/Photos.h>

#import "Helper.h"
#import "MEGAPauseTransferRequestDelegate.h"
#import "MEGASdkManager.h"
#import "NSDate+MNZCategory.h"
#import "NSString+MNZCategory.h"
#import "UIImage+MNZCategory.h"
#import "UIImageView+MNZCategory.h"

@interface TransferTableViewCell ()

@property (weak, nonatomic) IBOutlet UIImageView *iconImageView;
@property (nonatomic, getter=isThumbnailSet) BOOL thumbnailSet;

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UIImageView *arrowImageView;
@property (weak, nonatomic) IBOutlet UILabel *infoLabel;

@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UIButton *pauseButton;

@property (weak, nonatomic) IBOutlet UIView *separatorView;

@property (strong, nonatomic) MEGATransfer *transfer;
@property (strong, nonatomic) NSString *uploadTransferLocalIdentifier;

@end

@implementation TransferTableViewCell

#pragma mark - Public

- (void)configureCellForTransfer:(MEGATransfer *)transfer delegate:(id<TransferTableViewCellDelegate>)delegate {
    self.delegate = delegate;
    self.transfer = transfer;
    self.uploadTransferLocalIdentifier = nil;
    
    self.nameLabel.text = [[MEGASdkManager sharedMEGASdk] unescapeFsIncompatible:transfer.fileName];
    self.pauseButton.hidden = self.cancelButton.hidden = NO;

    switch (transfer.type) {
        case MEGATransferTypeDownload: {
            MEGANode *node = [[MEGASdkManager sharedMEGASdk] nodeForHandle:transfer.nodeHandle];
            if (node) {
                [self.iconImageView mnz_setThumbnailByNode:node];
            } else {
                [self.iconImageView mnz_setImageForExtension:transfer.fileName.pathExtension];
            }
            self.thumbnailSet = YES;
            break;
        }
            
        case MEGATransferTypeUpload: {
            if (transfer.fileName.mnz_isImagePathExtension || transfer.fileName.mnz_isVideoPathExtension) {
                NSString *transferThumbnailAbsolutePath = [[[NSHomeDirectory() stringByAppendingPathComponent:transfer.path] stringByDeletingPathExtension] stringByAppendingString:@"_thumbnail"];
                if ([[NSFileManager defaultManager] fileExistsAtPath:transferThumbnailAbsolutePath]) {
                    self.iconImageView.image = [UIImage imageWithContentsOfFile:transferThumbnailAbsolutePath];
                    self.thumbnailSet = YES;
                } else {
                    [self.iconImageView mnz_setImageForExtension:transfer.fileName.pathExtension];
                    self.thumbnailSet = NO;
                }
            } else {
                [self.iconImageView mnz_setImageForExtension:transfer.fileName.pathExtension];
                self.thumbnailSet = YES;
            }
            break;
        }
            
        default:
            break;
    }
    
    
    [self configureCellWithTransferState:transfer.state];
    
    self.separatorView.layer.borderColor = [UIColor mnz_separatorColorForTraitCollection:self.traitCollection].CGColor;
    self.separatorView.layer.borderWidth = 0.5;
}

- (void)reconfigureCellWithTransfer:(MEGATransfer *)transfer {
    self.uploadTransferLocalIdentifier = nil;
    self.transfer = transfer;
    
    [self configureCellWithTransferState:MEGATransferStateActive];
}

- (void)configureCellForQueuedTransfer:(NSString *)uploadTransferLocalIdentifier delegate:(id<TransferTableViewCellDelegate>)delegate {
    self.delegate = delegate;
    self.transfer = nil;
    self.uploadTransferLocalIdentifier = uploadTransferLocalIdentifier;
    
    if (!uploadTransferLocalIdentifier) {
        return;
    }
    
    PHFetchResult *fetchResult = [PHAsset fetchAssetsWithLocalIdentifiers:@[uploadTransferLocalIdentifier] options:nil];
    if (fetchResult == nil) {
        return;
    }
    
    PHAsset *asset = fetchResult.firstObject;
    if (asset == nil) {
        return;
    }
    
    NSString *extension;
    
    if ([PHAssetResource assetResourcesForAsset:asset].count > 0) {
        PHAssetResource *assetResource = [PHAssetResource assetResourcesForAsset:asset].firstObject;
        if (assetResource.originalFilename) {
            extension = assetResource.originalFilename.mnz_lastExtensionInLowercase;
        }
    }
    
    NSString *name = asset.creationDate.mnz_formattedDefaultNameForMedia;
    if (extension) {
        name = [name stringByAppendingPathExtension:extension];
    }
    
    self.nameLabel.text = name;

    PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
    options.version = PHImageRequestOptionsVersionCurrent;
    options.networkAccessAllowed = YES;
    
    [[PHImageManager defaultManager] requestImageForAsset:asset targetSize:self.iconImageView.frame.size contentMode:PHImageContentModeAspectFit options:options resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
        if (result) {
            self.iconImageView.image = result;
        } else {
            [self.iconImageView mnz_setImageForExtension:extension];
        }
    }];
    
    [self queuedStateLayout];
}

- (void)reloadThumbnailImage {
    if (!self.isThumbnailSet) {
        NSString *transferThumbnailAbsolutePath = [[[NSHomeDirectory() stringByAppendingPathComponent:self.transfer.path] stringByDeletingPathExtension] stringByAppendingString:@"_thumbnail"];
        self.iconImageView.image = [UIImage imageWithContentsOfFile:transferThumbnailAbsolutePath];
    }
}

- (void)updatePercentAndSpeedLabelsForTransfer:(MEGATransfer *)transfer {
    UIColor *percentageColor = (transfer.type == MEGATransferTypeDownload) ? UIColor.mnz_green31B500 : UIColor.mnz_blue2BA6DE;
    float percentage = (transfer.transferredBytes.floatValue / transfer.totalBytes.floatValue * 100);
    NSString *percentageCompleted = [NSString stringWithFormat:@"%.f %%", percentage];
    NSMutableAttributedString *percentageAttributedString = [NSMutableAttributedString.alloc initWithString:percentageCompleted attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:12.0f], NSForegroundColorAttributeName:percentageColor}];
    
    NSString *speed = [NSString stringWithFormat:@" %@/s", [Helper memoryStyleStringFromByteCount:transfer.speed.longLongValue]];
    NSAttributedString *speedAttributedString = [NSAttributedString.alloc initWithString:speed attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:12.0f], NSForegroundColorAttributeName:[UIColor mnz_primaryGrayForTraitCollection:self.traitCollection]}];
    [percentageAttributedString appendAttributedString:speedAttributedString];
    self.infoLabel.attributedText = percentageAttributedString;
}

- (void)updateTransferIfNewState:(MEGATransfer *)transfer {
    if (self.transfer.state != transfer.state) {
        self.transfer = transfer;
        [self configureCellWithTransferState:self.transfer.state];
    }
}

#pragma mark - Private

- (void)configureCellWithTransferState:(MEGATransferState)transferState {
    switch (transferState) {
        case MEGATransferStateQueued: {
            self.arrowImageView.image = (self.transfer.type == MEGATransferTypeDownload) ? UIImage.mnz_downloadQueuedTransferImage : UIImage.mnz_uploadQueuedTransferImage;
            self.infoLabel.textColor = [UIColor mnz_primaryGrayForTraitCollection:self.traitCollection];
            self.infoLabel.text = AMLocalizedString(@"queued", @"Queued");
            [self.pauseButton setImage:[UIImage imageNamed:@"pauseTransfers"] forState:UIControlStateNormal];
            self.pauseButton.hidden = self.cancelButton.hidden = NO;
            break;
        }
            
        case MEGATransferStateActive: {
            self.arrowImageView.image = (self.transfer.type == MEGATransferTypeDownload) ? UIImage.mnz_downloadingTransferImage : UIImage.mnz_uploadingTransferImage;
            [self.arrowImageView setNeedsDisplay];
            [self.pauseButton setImage:[UIImage imageNamed:@"pauseTransfers"] forState:UIControlStateNormal];
            self.pauseButton.hidden = self.cancelButton.hidden = NO;
            break;
        }
            
        case MEGATransferStatePaused: {
            self.arrowImageView.image = (self.transfer.type == MEGATransferTypeDownload) ? UIImage.mnz_downloadQueuedTransferImage : UIImage.mnz_uploadQueuedTransferImage;
            self.infoLabel.textColor = [UIColor mnz_primaryGrayForTraitCollection:self.traitCollection];
            self.infoLabel.text = AMLocalizedString(@"paused", @"Paused");
            [self.pauseButton setImage:[UIImage imageNamed:@"resumeTransfers"] forState:UIControlStateNormal];
            self.pauseButton.hidden = self.cancelButton.hidden = NO;
            break;
        }
            
        case MEGATransferStateRetrying: {
            self.arrowImageView.image = (self.transfer.type == MEGATransferTypeDownload) ? UIImage.mnz_downloadingTransferImage : UIImage.mnz_uploadingTransferImage;
            self.infoLabel.text = AMLocalizedString(@"Retrying...", @"Label for the state of a transfer when is being retrying - (String as short as possible).");
            self.pauseButton.hidden = self.cancelButton.hidden = NO;
            break;
        }
            
        case MEGATransferStateCompleting:
            self.infoLabel.textColor = (self.transfer.type == MEGATransferTypeDownload) ? UIColor.mnz_green31B500 : UIColor.mnz_blue2BA6DE;
            self.infoLabel.text = AMLocalizedString(@"Completing...", @"Label for the state of a transfer when is being completing - (String as short as possible).");
            self.pauseButton.hidden = self.cancelButton.hidden = YES;
            break;
            
        default: {
            self.arrowImageView.image = (self.transfer.type == MEGATransferTypeDownload) ? UIImage.mnz_downloadQueuedTransferImage : UIImage.mnz_uploadQueuedTransferImage;
            self.infoLabel.textColor = [UIColor mnz_primaryGrayForTraitCollection:self.traitCollection];
            self.infoLabel.text = AMLocalizedString(@"queued", @"Queued");
            [self.pauseButton setImage:[UIImage imageNamed:@"pauseTransfers"] forState:UIControlStateNormal];
            self.pauseButton.hidden = self.cancelButton.hidden = NO;
            break;
        }
    }
}

- (void)queuedStateLayout {
    self.arrowImageView.image = UIImage.mnz_uploadQueuedTransferImage;
    self.infoLabel.textColor = [UIColor mnz_primaryGrayForTraitCollection:self.traitCollection];
    self.infoLabel.text = AMLocalizedString(@"pending", @"Label shown when a contact request is pending");
    self.pauseButton.hidden = YES;
    self.cancelButton.hidden = NO;
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
    } else if (self.uploadTransferLocalIdentifier) {
        [self.delegate cancelQueuedUploadTransfer:self.uploadTransferLocalIdentifier];
    }
}

- (IBAction)pauseTransfer:(id)sender {
    if (self.transfer) {
        MEGAPauseTransferRequestDelegate *pauseTransferDelegate = [[MEGAPauseTransferRequestDelegate alloc] initWithCompletion:^(MEGARequest *request) {
            MEGATransfer *transfer = [[MEGASdkManager sharedMEGASdk] transferByTag:self.transfer.tag];
            if (transfer) {
                self.transfer = transfer;
            } else {
                transfer = [[MEGASdkManager sharedMEGASdkFolder] transferByTag:self.transfer.tag];
                if (transfer) {
                    self.transfer = transfer;
                }
            }
            
            [self.delegate pauseTransfer:self.transfer];
            [self configureCellWithTransferState:(request.flag) ? MEGATransferStatePaused : MEGATransferStateActive];
        }];
        
        MEGATransfer *transfer = [[MEGASdkManager sharedMEGASdk] transferByTag:self.transfer.tag];
        if (transfer) {
            [[MEGASdkManager sharedMEGASdk] pauseTransferByTag:self.transfer.tag pause:!(transfer.state == MEGATransferStatePaused) delegate:pauseTransferDelegate];
        } else {
            transfer = [[MEGASdkManager sharedMEGASdkFolder] transferByTag:self.transfer.tag];
            if (transfer) {
                [[MEGASdkManager sharedMEGASdkFolder] pauseTransferByTag:self.transfer.tag pause:!(transfer.state == MEGATransferStatePaused) delegate:pauseTransferDelegate];
            }
        }
    }
}

@end
