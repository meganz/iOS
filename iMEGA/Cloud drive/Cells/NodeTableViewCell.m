#import "NodeTableViewCell.h"
#import "MEGASdkManager.h"
#import "Helper.h"
#import "MEGAGetThumbnailRequestDelegate.h"
#import "MEGAStore.h"

@implementation NodeTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.cancelButtonTrailingConstraint.constant =  ([[UIDevice currentDevice] iPadDevice] || [[UIDevice currentDevice] iPhonePlus]) ? 10 : 6;
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    
    if (editing) {
        self.moreButton.hidden = YES;
    } else {
        if ([[Helper downloadingNodes] objectForKey:self.node.base64Handle] == nil) {
            self.moreButton.hidden = NO;
        }
    }
}

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

- (void)hideCancelButton:(BOOL)hide {
    self.moreButton.hidden = hide;
}

- (void)configureCellForNode:(MEGANode *)node delegate:(id<MGSwipeTableCellDelegate>)delegate {
    BOOL isDownloaded = NO;
    
    self.node = node;
    
    if ([[Helper downloadingNodes] objectForKey:node.base64Handle] != nil) {
        
        self.infoLabel.text = AMLocalizedString(@"queued", @"Queued");
        self.downloadingArrowImageView.hidden = NO;
        self.downloadProgressView.hidden = NO;
        self.cancelButton.hidden = NO;
        self.moreButton.hidden = YES;
    } else {
        
        if (node.type == MEGANodeTypeFile && [[MEGAStore shareInstance] offlineNodeWithNode:node api:[MEGASdkManager sharedMEGASdk]]) {
                isDownloaded = YES;
        }
        self.infoLabel.text = [Helper sizeAndDateForNode:node api:[MEGASdkManager sharedMEGASdk]];
        self.downloadProgressView.hidden = YES;
        self.downloadingArrowImageView.hidden = YES;
        self.cancelButton.hidden = YES;
        self.moreButton.hidden = NO;
    }
    
    if ([node isExported]) {
        if (isDownloaded) {
            self.upImageView.image = [UIImage imageNamed:@"linked"];
            self.middleImageView.image = nil;
            self.downImageView.image = [Helper downloadedArrowImage];
        } else {
            self.upImageView.image = nil;
            self.middleImageView.image = [UIImage imageNamed:@"linked"];
            self.downImageView.image = nil;
        }
    } else {
        self.upImageView.image = nil;
        self.downImageView.image = nil;
        
        if (isDownloaded) {
            self.middleImageView.image = [Helper downloadedArrowImage];
        } else {
            self.middleImageView.image = nil;
        }
    }
    
    UIView *view = [[UIView alloc] init];
    [view setBackgroundColor:UIColor.mnz_grayF7F7F7];
    [self setSelectedBackgroundView:view];
    [self setSeparatorInset:UIEdgeInsetsMake(0.0, 60.0, 0.0, 0.0)];
    
    self.nameLabel.text = [node name];
    
    [self.thumbnailPlayImageView setHidden:YES];
    
    if (node.isFile) {
        if (node.hasThumbnail) {
            NSString *thumbnailFilePath = [Helper pathForNode:node inSharedSandboxCacheDirectory:@"thumbnailsV3"];
            
            if ([[NSFileManager defaultManager] fileExistsAtPath:thumbnailFilePath]) {
                self.thumbnailImageView.image = [UIImage imageWithContentsOfFile:thumbnailFilePath];
            } else {
                MEGAGetThumbnailRequestDelegate *getThumbnailRequestDelegate = [[MEGAGetThumbnailRequestDelegate alloc] initWithCompletion:^(MEGARequest *request){
                    self.thumbnailImageView.image = [UIImage imageWithContentsOfFile:request.file];
                }];
                [[MEGASdkManager sharedMEGASdk] getThumbnailNode:node destinationFilePath:thumbnailFilePath delegate:getThumbnailRequestDelegate];
                self.thumbnailImageView.image = [Helper imageForNode:node];
            }
        } else {
            [self.thumbnailImageView setImage:[Helper imageForNode:node]];
        }
    } else if (node.isFolder) {
        [self.thumbnailImageView setImage:[Helper imageForNode:node]];
        
        self.infoLabel.text = [Helper filesAndFoldersInFolderNode:node api:[MEGASdkManager sharedMEGASdk]];
    }
    
    self.nodeHandle = [node handle];
    
    if (@available(iOS 11.0, *)) {
        self.thumbnailImageView.accessibilityIgnoresInvertColors = YES;
        self.thumbnailPlayImageView.accessibilityIgnoresInvertColors = YES;
    } else {
        self.delegate = delegate;
    }
}

#pragma mark - IBActions

- (IBAction)cancelTransfer:(id)sender {
    NSNumber *transferTag = [[Helper downloadingNodes] objectForKey:[MEGASdk base64HandleForHandle:self.nodeHandle]];
    if ([[MEGASdkManager sharedMEGASdk] transferByTag:transferTag.integerValue] != nil) {
        [[MEGASdkManager sharedMEGASdk] cancelTransferByTag:transferTag.integerValue];
    } else {
        if ([[MEGASdkManager sharedMEGASdkFolder] transferByTag:transferTag.integerValue] != nil) {
            [[MEGASdkManager sharedMEGASdkFolder] cancelTransferByTag:transferTag.integerValue];
        }
    }
}

@end
