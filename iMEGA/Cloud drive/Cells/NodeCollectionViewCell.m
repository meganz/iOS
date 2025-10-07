#import "NodeCollectionViewCell.h"

#import "NSString+MNZCategory.h"
#import "UIImage+MNZCategory.h"

#import "Helper.h"
#import "MEGAGetThumbnailRequestDelegate.h"
#import "MEGANode+MNZCategory.h"
#import "UIImageView+MNZCategory.h"
#import "MEGAStore.h"
#import "MEGA-Swift.h"
@import MEGAUIKit;

static NSString *kFileName = @"kFileName";
static NSString *kFileSize = @"kFileSize";

@interface NodeCollectionViewCell ()

@property (weak, nonatomic) IBOutlet UIView *labelView;
@property (weak, nonatomic) IBOutlet UIImageView *labelImageView;
@property (weak, nonatomic) IBOutlet UIView *favouriteView;
@property (weak, nonatomic) IBOutlet UIView *versionedView;
@property (weak, nonatomic) IBOutlet UIView *linkView;
@property (weak, nonatomic) IBOutlet UIView *downloadedView;

@property (strong, nonatomic) MEGANode *node;
@property (nonatomic, weak) id<NodeCollectionViewCellDelegate> delegate;

@end

@implementation NodeCollectionViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    [self configureImages];
    [self setupTokenColors];
    [self configureDurationLabel];
}

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    [self updateSelection];
}

- (void)configureCellForNode:(MEGANode *)node
    allowedMultipleSelection:(BOOL)multipleSelection
            isFromSharedItem:(BOOL)isFromSharedItem
                         sdk:(MEGASdk *)sdk
                    delegate:(id<NodeCollectionViewCellDelegate> _Nullable)delegate {
    [self configureCellForNode:node
      allowedMultipleSelection:multipleSelection
              isFromSharedItem:isFromSharedItem
                           sdk:sdk
                      delegate:delegate
                   isSampleRow:NO];
}

- (void)configureCellForNode:(MEGANode *)node
    allowedMultipleSelection:(BOOL)multipleSelection
            isFromSharedItem:(BOOL)isFromSharedItem
                         sdk:(MEGASdk *)sdk
                    delegate:(id<NodeCollectionViewCellDelegate> _Nullable)delegate
                 isSampleRow:(BOOL)isSampleRow {
    self.node = node;
    self.delegate = delegate;
    
    [self bindWithViewModel:[self createViewModelWithNode:node isFromSharedItem:isFromSharedItem sdk:sdk]];
        
    if (node.isTakenDown) {
        self.nameLabel.attributedText = [node attributedTakenDownName];
        self.nameLabel.textColor = [UIColor mnz_takenDownNodeTextColor];
    } else {
        self.nameLabel.textColor = [UIColor primaryTextColor];
        self.nameLabel.text = [node nameAfterDecryptionCheck];
        if (node.isFile) {
            self.infoLabel.text = [Helper sizeForNode:node api:sdk];
        } else if (node.isFolder) {
            if (isSampleRow) {
                self.infoLabel.text = @"Sample Row";
            } else {
                self.infoLabel.text = nil;
            }
        }
    }
    
    self.labelView.hidden = (node.label == MEGANodeLabelUnknown);
    if (node.label != MEGANodeLabelUnknown) {
        NSString *labelString = [[MEGANode stringForNodeLabel:node.label] stringByAppendingString:@"Small"];
        self.labelImageView.image = [UIImage megaImageWithNamed:labelString];
    }
    
    BOOL favouriteIsHidden = !node.isFavourite;
    self.favouriteView.hidden = favouriteIsHidden;
    BOOL linkIsHidden = !node.isExported || node.mnz_isInRubbishBin;
    self.linkView.hidden = linkIsHidden;
    [MEGASdk.shared hasVersionsForNode:node completion:^(BOOL hasVersions) {
        BOOL versionedIsHidden = !hasVersions;
        dispatch_async(dispatch_get_main_queue(), ^{
            self.versionedView.hidden = versionedIsHidden;
            self.topNodeIconsView.hidden = favouriteIsHidden && versionedIsHidden && linkIsHidden;
        });
    }];
    
    self.durationLabel.hidden = ![self.viewModel isNodeVideoWithValidDuration];
    self.videoIconView.hidden = ![self.viewModel isNodeVideo];
    if (!self.durationLabel.hidden) {
        self.durationLabel.layer.cornerRadius = 4;
        self.durationLabel.layer.masksToBounds = true;
        self.durationLabel.text = [NSString mnz_stringFromTimeInterval:node.duration];
    }

    self.downloadedImageView.hidden = self.downloadedView.hidden = !([self hasDownloadedNode:node]) && !isSampleRow;
    self.selectImageView.hidden = !multipleSelection;
    self.moreButton.hidden = multipleSelection;
    
    [self setupAppearance];
}

- (void)configureCellForOfflineItem:(NSDictionary *)item itemPath:(NSString *)pathForItem allowedMultipleSelection:(BOOL)multipleSelection sdk:(nonnull MEGASdk *)sdk delegate:(id<NodeCollectionViewCellDelegate> _Nullable)delegate {
    
    [self bindWithViewModel:[self createViewModelWithNode:nil isFromSharedItem:NO sdk: sdk]];

    self.favouriteView.hidden = self.linkView.hidden = self.versionedView.hidden = self.topNodeIconsView.hidden = YES;
    self.labelView.hidden = self.downloadedImageView.hidden = self.downloadedView.hidden = YES;
    self.delegate = delegate;
    
    NSString *nameString = item[kFileName];
    
    MOOfflineNode *offNode = [[MEGAStore shareInstance] fetchOfflineNodeWithPath:[Helper pathRelativeToOfflineDirectory:pathForItem]];
    
    self.nameLabel.text = nameString;
    
    NSString *handleString = [offNode base64Handle];
    
    BOOL isDirectory;
    [[NSFileManager defaultManager] fileExistsAtPath:pathForItem isDirectory:&isDirectory];
    if (isDirectory) {
        self.thumbnailIconView.image = UIImage.mnz_folderImage;
        self.thumbnailIconView.hidden = NO;
        self.infoLabel.text = nil;
    } else {
        self.infoLabel.text = [NSString memoryStyleStringFromByteCount:[item[kFileSize] longLongValue]];
        NSString *extension = nameString.pathExtension.lowercaseString;
        
        NSString *thumbnailFilePath = [Helper pathForSharedSandboxCacheDirectory:@"thumbnailsV3"];
        thumbnailFilePath = [thumbnailFilePath stringByAppendingPathComponent:handleString];
        
        if (handleString) {
            if ([[NSFileManager defaultManager] fileExistsAtPath:thumbnailFilePath]) {
                [self configureWithThumbnailFilePath:thumbnailFilePath];
            } else {
                dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^{
                    if ([sdk createThumbnail:pathForItem destinatioPath:thumbnailFilePath]) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self configureWithThumbnailFilePath:thumbnailFilePath];
                        });
                    } else {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            self.thumbnailIconView.hidden = NO;
                            [self.thumbnailIconView setImage:[NodeAssetsManager.shared imageFor:extension]];
                            self.thumbnailImageView.image = nil;
                        });
                    }
                });
            }
        } else {
            self.thumbnailIconView.hidden = NO;
            [self.thumbnailIconView setImage:[NodeAssetsManager.shared imageFor:extension]];
            self.thumbnailImageView.image = nil;
            
            NSURL *url = [NSURL fileURLWithPath:pathForItem];
            [self setThumbnailWithUrl:url];
        }
        
    }
    self.nameLabel.text = [sdk unescapeFsIncompatible:nameString destinationPath:[NSHomeDirectory() stringByAppendingString:@"/"]];
    
    self.selectImageView.hidden = !multipleSelection;
    self.moreButton.hidden = multipleSelection;
    BOOL isNodeVideo = [self.viewModel isNodeVideoWithName:nameString];
    if (isNodeVideo) {
        self.videoIconView.hidden = NO;
        [self setDurationForVideoWithPath:pathForItem];
    } else {
        self.videoIconView.hidden = YES;
    }
    
    self.thumbnailImageView.accessibilityIgnoresInvertColors = YES;
    [self setupAppearance];
}

- (void)configureCellForFolderLinkNode:(MEGANode *)node allowedMultipleSelection:(BOOL)multipleSelection sdk:(nonnull MEGASdk *)sdk delegate:(id<NodeCollectionViewCellDelegate> _Nullable)delegate {
    [self configureCellForNode:node allowedMultipleSelection:multipleSelection isFromSharedItem:YES sdk:sdk delegate:delegate];

    self.downloadedImageView.hidden = !([self hasDownloadedNode:node]);
}

- (NSString *)itemName {
    return self.nameLabel.text;
}

- (void)setupAppearance {
    [self setSelected:NO];
    [self setupThumbnailBackground];
}

- (IBAction)optionButtonAction:(id)sender {
    [self.delegate showMoreMenuForNode:self.node from:sender];
}

#pragma mark: - Private

- (void)configureImages {
    self.favouriteImageView.image = [UIImage megaImageWithNamed:@"favouriteThumbnail"];
    self.versionedImageView.image = [UIImage megaImageWithNamed:@"versionedThumbnail"];
    self.linkImageView.image = [UIImage megaImageWithNamed:@"linkedThumbnail"];
    self.downloadedImageView.image = [UIImage megaImageWithNamed:@"downloaded"];

    [self.moreButton setImage:[UIImage megaImageWithNamed:@"moreGrid"] forState:UIControlStateNormal];
    [self.moreButton setImage:[UIImage megaImageWithNamed:@"moreGrid"] forState:UIControlStateSelected];
    [self.moreButton setImage:[UIImage megaImageWithNamed:@"moreGrid"] forState:UIControlStateHighlighted];

    self.selectImageView.image = [UIImage megaImageWithNamed:@"checkBoxUnselected"];
    self.videoIconView.image = [UIImage megaImageWithNamed:@"video_list"];
}

- (void)configureWithThumbnailFilePath:(NSString *)thumbnailFilePath {
    UIImage *thumbnailImage = [UIImage imageWithContentsOfFile:thumbnailFilePath];
    if (thumbnailImage) {
        self.thumbnailImageView.image = thumbnailImage;
    }
    self.thumbnailIconView.hidden = YES;
}

@end
