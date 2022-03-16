#import "NodeTableViewCell.h"

#import "MEGANodeList+MNZCategory.h"

#import "Helper.h"
#import "MEGAGetThumbnailRequestDelegate.h"
#import "MEGANode+MNZCategory.h"
#import "MEGASdkManager.h"
#import "MEGAStore.h"
#import "NSDate+MNZCategory.h"
#import "NSString+MNZCategory.h"
#import "UIImageView+MNZCategory.h"

#ifdef MNZ_SHARE_EXTENSION
#import "MEGAShare-Swift.h"
#elif MNZ_PICKER_EXTENSION
#import "MEGAPicker-Swift.h"
#else
#import "MEGA-Swift.h"
#endif

@interface NodeTableViewCell()

@property (weak, nonatomic) IBOutlet UILabel *infoStringRightLabel;

@end

@implementation NodeTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.cancelButtonTrailingConstraint.constant =  ([[UIDevice currentDevice] iPadDevice] || [[UIDevice currentDevice] iPhonePlus]) ? 10 : 6;
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    
    BOOL editSingleRow = self.subviews.count == 3; // leading or trailing UITableViewCellEditControl doesn't appear
    
    if (editing) {
        self.moreButton.hidden = YES;
        if (!editSingleRow) {
            [UIView animateWithDuration:0.3 animations:^{
                self.separatorInset = UIEdgeInsetsMake(0, 102, 0, 0);
                [self layoutIfNeeded];
            }];
        }
    } else {
        [UIView animateWithDuration:0.3 animations:^{
            self.separatorInset = UIEdgeInsetsMake(0, 62, 0, 0);
            [self layoutIfNeeded];
        }];
        self.moreButton.hidden = self.recentActionBucket ? self.moreButton.hidden : self.isNodeInRubbishBin;
    }
}

- (void)configureCellForNode:(MEGANode *)node api:(MEGASdk *)api {
    self.node = node;
    
    self.downloadingArrowImageView.hidden = self.downloadProgressView.hidden = YES;
    
    self.moreButton.hidden = self.isNodeInRubbishBin;
    
    if (self.downloadingArrowView != nil) {
        self.downloadingArrowView.hidden = self.downloadingArrowImageView.isHidden;
    }
    
    self.favouriteView.hidden = !node.isFavourite;
    self.labelView.hidden = (node.label == MEGANodeLabelUnknown);
    if (node.label != MEGANodeLabelUnknown) {
        NSString *labelString = [[MEGANode stringForNodeLabel:node.label] stringByAppendingString:@"Small"];
        self.labelImageView.image = [UIImage imageNamed:labelString];
    }
    BOOL isDownloaded = (node.isFile && [[MEGAStore shareInstance] offlineNodeWithNode:node]);
    self.downloadedImageView.hidden = !isDownloaded;
    if (self.downloadedView != nil) {
        self.downloadedView.hidden = self.downloadedImageView.isHidden;
    }
    self.linkView.hidden = !node.isExported || node.mnz_isInRubbishBin;
    
    if (node.hasThumbnail) {
        NSString *thumbnailFilePath = [Helper pathForNode:node inSharedSandboxCacheDirectory:@"thumbnailsV3"];
        if ([[NSFileManager defaultManager] fileExistsAtPath:thumbnailFilePath]) {
            self.thumbnailPlayImageView.hidden = !node.name.mnz_isVideoPathExtension;
            self.thumbnailImageView.image = [UIImage imageWithContentsOfFile:thumbnailFilePath];
        } else {
            MEGAGetThumbnailRequestDelegate *getThumbnailRequestDelegate = [[MEGAGetThumbnailRequestDelegate alloc] initWithCompletion:^(MEGARequest *request) {
                if (request.nodeHandle == self.node.handle) {
                    self.thumbnailPlayImageView.hidden = !node.name.mnz_isVideoPathExtension;
                    self.thumbnailImageView.image = [UIImage imageWithContentsOfFile:request.file];
                }
            }];
            [[MEGASdkManager sharedMEGASdk] getThumbnailNode:node destinationFilePath:thumbnailFilePath delegate:getThumbnailRequestDelegate];
            [self.thumbnailImageView mnz_imageForNode:node];
        }
    } else {
        [self.thumbnailImageView mnz_imageForNode:node];
    }
    
    if (!node.name.mnz_isVideoPathExtension) {
        self.thumbnailPlayImageView.hidden = YES;
    }
        
    if (node.isTakenDown) {
        self.nameLabel.attributedText = [node mnz_attributedTakenDownNameWithHeight:self.nameLabel.font.capHeight];
        self.nameLabel.textColor = [UIColor mnz_redForTraitCollection:(self.traitCollection)];
    } else {
        self.nameLabel.text = node.name;
        self.nameLabel.textColor = UIColor.mnz_label;
        self.subtitleLabel.textColor = [UIColor mnz_subtitlesForTraitCollection:self.traitCollection];
    }
    
    self.infoLabel.textColor = [UIColor mnz_subtitlesForTraitCollection:self.traitCollection];
    if (node.isFile) {
        MEGASdk *megaSDK = self.recentActionBucket ? MEGASdkManager.sharedMEGASdk : api;
        switch (self.cellFlavor) {
            case NodeTableViewCellFlavorVersions:
            case NodeTableViewCellFlavorRecentAction:
            case NodeTableViewCellFlavorCloudDrive:
                self.infoLabel.text =
                    self.recentActionBucket ? [Helper sizeAndCreationHourAndMininuteForNode:node api:megaSDK] :
                    [Helper sizeAndModicationDateForNode:node api:megaSDK];
                self.versionedImageView.hidden = ![[MEGASdkManager sharedMEGASdk] hasVersionsForNode:node];
                break;
            case NodeTableViewCellFlavorSharedLink:
                self.infoLabel.text = [Helper sizeAndShareLinkCreateDateForSharedLinkNode:node api:megaSDK];
                self.versionedImageView.hidden = ![[MEGASdkManager sharedMEGASdk] hasVersionsForNode:node];
                break;
            case NodeTableViewCellExplorerView:
                [self updateInfo];
                break;
        }
    } else if (node.isFolder) {
        self.infoLabel.text = [Helper filesAndFoldersInFolderNode:node api:api];
        self.versionedImageView.hidden = YES;
    }
    
    self.thumbnailImageView.accessibilityIgnoresInvertColors = YES;
    self.thumbnailPlayImageView.accessibilityIgnoresInvertColors = YES;
    
    self.separatorView.backgroundColor = [UIColor mnz_separatorForTraitCollection:self.traitCollection];
}

- (void)configureForRecentAction:(MEGARecentActionBucket *)recentActionBucket {
    self.cellFlavor = NodeTableViewCellFlavorRecentAction;
    [self updateWithTrait:[self traitCollection]];
    self.leadingConstraint.constant = 24;
    self.recentActionBucket = recentActionBucket;
    NSArray *nodesArray = recentActionBucket.nodesList.mnz_nodesArrayFromNodeList;
    
    MEGANode *node = nodesArray.firstObject;
    [self.thumbnailImageView mnz_imageForNode:node];
    self.thumbnailPlayImageView.hidden = node.hasThumbnail ? !node.name.mnz_isVideoPathExtension : YES;
    self.thumbnailImageView.accessibilityIgnoresInvertColors = YES;
    self.thumbnailPlayImageView.accessibilityIgnoresInvertColors = YES;
    
    NSString *title;
    if (nodesArray.count == 1) {
        title = node.name;
        
        self.moreButton.hidden = NO;
        self.disclosureIndicatorView.hidden = YES;
    } else if (nodesArray.count > 1) {
        NSString *tempString = NSLocalizedString(@"%1 and [A]%2 more[/A]", @"Title for a recent action shown in the webclient, see the attached image for context. Please ensure that the `%2 more` is inside the [A] tag as this will become a toggle to show the hidden content.");
        tempString = tempString.mnz_removeWebclientFormatters;
        tempString = [tempString stringByReplacingOccurrencesOfString:@"%1" withString:node.name];
        title = [tempString stringByReplacingOccurrencesOfString:@"%2" withString:[NSString stringWithFormat:@"%tu", nodesArray.count - 1]];
        
        self.moreButton.hidden = YES;
        self.disclosureIndicatorView.hidden = NO;
    }
    self.nameLabel.text = title;
    
    MEGAShareType shareType = [MEGASdkManager.sharedMEGASdk accessLevelForNode:node];
    if ([recentActionBucket.userEmail isEqualToString:MEGASdkManager.sharedMEGASdk.myEmail]) {
        if (shareType == MEGAShareTypeAccessOwner) {
            MEGANode *firstbornParentNode = [[MEGASdkManager.sharedMEGASdk nodeForHandle:recentActionBucket.parentHandle] mnz_firstbornInShareOrOutShareParentNode];
            if (firstbornParentNode.isOutShare) {
                self.incomingOrOutgoingView.hidden = NO;
                self.incomingOrOutgoingImageView.image = [UIImage imageNamed:@"mini_folder_outgoing"];
            } else {
                self.incomingOrOutgoingView.hidden = YES;
            }
        } else {
            self.subtitleLabel.text = [NSString mnz_addedByInRecentActionBucket:recentActionBucket];
            self.incomingOrOutgoingImageView.hidden = NO;
            self.incomingOrOutgoingImageView.image = [UIImage imageNamed:@"mini_folder_incoming"];
        }
    } else {
        self.subtitleLabel.text = [NSString mnz_addedByInRecentActionBucket:recentActionBucket];
        self.incomingOrOutgoingImageView.hidden = NO;
        self.incomingOrOutgoingImageView.image = (shareType == MEGAShareTypeAccessOwner) ? [UIImage imageNamed:@"mini_folder_outgoing"] : [UIImage imageNamed:@"mini_folder_incoming"];
    }
    
    MEGANode *parentNode = [MEGASdkManager.sharedMEGASdk nodeForHandle:recentActionBucket.parentHandle];
    self.infoLabel.text = [NSString stringWithFormat:@"%@ ・", parentNode.name];
    
    self.uploadOrVersionImageView.image = recentActionBucket.isUpdate ? [UIImage imageNamed:@"versioned"] : [UIImage imageNamed:@"recentUpload"];
    
    self.timeLabel.text = recentActionBucket.timestamp.mnz_formattedHourAndMinutes;
    
    self.subtitleLabel.textColor = self.infoLabel.textColor = self.timeLabel.textColor = [UIColor mnz_subtitlesForTraitCollection:self.traitCollection];
}

#pragma mark - IBActions

- (IBAction)moreButtonPressed:(UIButton *)moreButton {
    self.moreButtonAction(moreButton);
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    
    if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
        [self updateWithTrait:self.traitCollection];
    }
}

- (void)updateWithTrait:(UITraitCollection *)currentTraitCollection {
    self.infoLabel.textColor = [UIColor mnz_subtitlesForTraitCollection:self.traitCollection];
    if (self.cellFlavor != NodeTableViewCellFlavorRecentAction) {
        return;
    }
    self.backgroundColor = [UIColor mnz_homeRecentsCellBackgroundForTraitCollection:currentTraitCollection];
}

- (void)updateInfo {
    if (self.cellFlavor == NodeTableViewCellExplorerView && self.node != nil) {
        self.infoStringRightLabel.lineBreakMode = NSLineBreakByTruncatingHead;
        BOOL shouldIncludeRootFolder = self.node.isInShare
        || (self.node.parentHandle == MEGASdkManager.sharedMEGASdk.rootNode.handle);
        self.infoLabel.text = shouldIncludeRootFolder ? @"" : @"> ";
        self.infoStringRightLabel.text = [self.node filePathWithDelimeter:@" > "
                                                            sdk:MEGASdkManager.sharedMEGASdk
                                          includeRootFolderName:shouldIncludeRootFolder
                                                excludeFileName:YES];
        self.versionedImageView.image = [UIImage imageNamed:self.node.isInShare ? @"pathInShares" : @"pathCloudDrive"];
        self.versionedImageView.hidden = NO;
    }
}

@end
