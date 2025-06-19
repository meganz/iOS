#import "NodeTableViewCell.h"

#import "MEGANodeList+MNZCategory.h"

#import "Helper.h"
#import "MEGAGetThumbnailRequestDelegate.h"
#import "MEGANode+MNZCategory.h"
#import "MEGAStore.h"
#import "NSDate+MNZCategory.h"
#import "NSString+MNZCategory.h"
#import "UIImageView+MNZCategory.h"

#ifdef MNZ_SHARE_EXTENSION
#import "MEGAShare-Swift.h"
#else
#import "MEGA-Swift.h"
#endif

@import MEGAAppSDKRepo;
@import MEGAL10nObjc;

@interface NodeTableViewCell()

@property (weak, nonatomic) IBOutlet UILabel *infoStringRightLabel;
@property (weak, nonatomic) IBOutlet UIImageView *disclosureIndicator;

@end

@implementation NodeTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    [self configureImages];
    
    self.cancelButtonTrailingConstraint.constant =  ([[UIDevice currentDevice] iPadDevice] || [[UIDevice currentDevice] iPhonePlus]) ? 10 : 6;
    [self configureDescriptionLabel];
    [self configureMoreButtonUI];
    [self configureIconsImageColor];
}

- (void)configureImages {
    [self.moreButton setImage:[UIImage megaImageWithNamed:@"moreList"] forState:UIControlStateNormal];
    self.downloadedImageView.image = [UIImage megaImageWithNamed:@"downloaded"];
    self.thumbnailPlayImageView.image = [UIImage megaImageWithNamed:@"video_list"];
    self.versionedImageView.image = [UIImage megaImageWithNamed:@"versioned"];
    self.favouriteImageView.image = [UIImage megaImageWithNamed:@"favouriteSmall"];
    self.linkImageView.image = [UIImage megaImageWithNamed:@"linked"];
    [self.incomingPermissionButton setImage:[UIImage megaImageWithNamed:@"readPermissions"] forState:UIControlStateNormal];
    self.uploadOrVersionImageView.image = [UIImage megaImageWithNamed:@"recentUpload"];
    self.disclosureIndicator.image = [UIImage megaImageWithNamed:@"standardDisclosureIndicator"];
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
        
        if (!self.recentActionBucket) {
            self.moreButton.hidden = self.isNodeInRubbishBin || self.isNodeInBrowserView;
        }
    }
}

- (void)configureForRecentAction:(MEGARecentActionBucket *)recentActionBucket {
    self.cellFlavor = NodeTableViewCellFlavorRecentAction;
    NSArray *nodesArray = recentActionBucket.nodesList.mnz_nodesArrayFromNodeList;
    [self bindWithViewModel:[self createViewModelWithNodes:nodesArray shouldApplySensitiveBehaviour:YES]];
    [self setupColors];
    self.leadingConstraint.constant = 24;
    self.recentActionBucket = recentActionBucket;
    
    [self setTitleAndFolderNameFor:recentActionBucket withNodes:nodesArray];
    
    BOOL isMultipleNodes = nodesArray.count > 1;
    self.moreButton.hidden = isMultipleNodes;
    self.disclosureIndicatorView.hidden = !isMultipleNodes;
    MEGANode *node = nodesArray.firstObject;
    self.thumbnailPlayImageView.hidden = node.hasThumbnail ? ![FileExtensionGroupOCWrapper verifyIsVideo:node.name] : YES;
    self.thumbnailImageView.accessibilityIgnoresInvertColors = YES;
    self.thumbnailPlayImageView.accessibilityIgnoresInvertColors = YES;
    
    NSString *imageName = @"standardDisclosureIndicator_designToken";
    self.disclosureIndicator.image = [UIImage megaImageWithNamed:imageName];
    
    MEGAShareType shareType = [MEGASdk.shared accessLevelForNode:node];
    if ([recentActionBucket.userEmail isEqualToString:MEGASdk.currentUserEmail]) {
        if (shareType == MEGAShareTypeAccessOwner) {
            MEGANode *firstbornParentNode = [[MEGASdk.shared nodeForHandle:recentActionBucket.parentHandle] mnz_firstbornInShareOrOutShareParentNode];
            if (firstbornParentNode.isOutShare) {
                self.incomingOrOutgoingView.hidden = NO;
                self.incomingOrOutgoingImageView.image = [UIImage megaImageWithNamed:@"folder_users"];
            } else {
                self.incomingOrOutgoingView.hidden = YES;
            }
        } else {
            self.subtitleLabel.text = [NSString mnz_addedByInRecentActionBucket:recentActionBucket];
            self.incomingOrOutgoingImageView.hidden = NO;
            self.incomingOrOutgoingImageView.image = [UIImage megaImageWithNamed:@"folder_folder-incoming"];
        }
    } else {
        self.subtitleLabel.text = [NSString mnz_addedByInRecentActionBucket:recentActionBucket];
        self.incomingOrOutgoingImageView.hidden = NO;
        self.incomingOrOutgoingImageView.image = (shareType == MEGAShareTypeAccessOwner) ? [UIImage megaImageWithNamed:@"folder_users"] : [UIImage megaImageWithNamed:@"folder_folder-incoming"];
    }
    
    self.uploadOrVersionImageView.image = recentActionBucket.isUpdate ? [UIImage megaImageWithNamed:@"versioned"] : [UIImage megaImageWithNamed:@"recentUpload"];
    
    self.timeLabel.text = recentActionBucket.timestamp.mnz_formattedHourAndMinutes;
    
    self.subtitleLabel.textColor = self.infoLabel.textColor = self.timeLabel.textColor = [UIColor mnz_secondaryTextColor];
}

#pragma mark - IBActions

- (IBAction)moreButtonPressed:(UIButton *)moreButton {
    self.moreButtonAction(moreButton);
}

- (void)setupColors {
    [self configureMoreButtonUI];
    
    self.infoLabel.textColor = [UIColor mnz_secondaryTextColor];
    self.infoStringRightLabel.textColor = [UIColor mnz_secondaryTextColor];
    
    [self setCellBackgroundColor];
   
    if (self.cellFlavor != NodeTableViewCellFlavorRecentAction) {
        return;
    }
    
    self.timeLabel.textColor = [UIColor mnz_secondaryTextColor];
    self.subtitleLabel.textColor = [UIColor mnz_secondaryTextColor];

    [self configureIconsImageColor];
}

- (void)updateInfo {
    if (self.cellFlavor == NodeTableViewCellExplorerView && self.node != nil) {
        self.infoStringRightLabel.lineBreakMode = NSLineBreakByTruncatingHead;
        BOOL shouldIncludeRootFolder = self.node.isInShare
        || (self.node.parentHandle == MEGASdk.shared.rootNode.handle);
        self.infoLabel.text = shouldIncludeRootFolder ? LocalizedString(@"", @"") : LocalizedString(@"> ", @"");
        self.infoStringRightLabel.text = [self.node filePathWithDelimeter:@" > "
                                                                      sdk:MEGASdk.shared
                                                    includeRootFolderName:shouldIncludeRootFolder
                                                          excludeFileName:YES];
        self.versionedImageView.image = [UIImage megaImageWithNamed:self.node.isInShare ? @"pathInShares" : @"pathCloudDrive"];
        self.versionedImageView.hidden = NO;
    }
}

@end
