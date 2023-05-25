
#import "NodeCollectionViewCell.h"

#import "NSString+MNZCategory.h"
#import "UIImage+MNZCategory.h"

#import "Helper.h"
#import "MEGAGetThumbnailRequestDelegate.h"
#import "MEGANode+MNZCategory.h"
#import "MEGASdkManager.h"
#import "UIImageView+MNZCategory.h"
#import "MEGAStore.h"
#import "MEGA-Swift.h"

static NSString *kFileName = @"kFileName";
static NSString *kFileSize = @"kFileSize";

@interface NodeCollectionViewCell ()

@property (weak, nonatomic) IBOutlet UIView *topNodeIconsView;

@property (weak, nonatomic) IBOutlet UIImageView *thumbnailImageView;
@property (weak, nonatomic) IBOutlet UIImageView *thumbnailIconView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UIView *labelView;
@property (weak, nonatomic) IBOutlet UIImageView *labelImageView;

@property (weak, nonatomic) IBOutlet UIButton *moreButton;
@property (weak, nonatomic) IBOutlet UIImageView *selectImageView;
@property (weak, nonatomic) IBOutlet UILabel *infoLabel;
@property (weak, nonatomic) IBOutlet UIView *favouriteView;
@property (weak, nonatomic) IBOutlet UIImageView *favouriteImageView;
@property (weak, nonatomic) IBOutlet UIView *versionedView;
@property (weak, nonatomic) IBOutlet UIImageView *versionedImageView;
@property (weak, nonatomic) IBOutlet UIView *linkView;
@property (weak, nonatomic) IBOutlet UIImageView *linkImageView;
@property (weak, nonatomic) IBOutlet UIImageView *videoIconView;
@property (weak, nonatomic) IBOutlet UIImageView *downloadedImageView;
@property (weak, nonatomic) IBOutlet UIView *downloadedView;

@property (strong, nonatomic) MEGANode *node;
@property (nonatomic, weak) id<NodeCollectionViewCellDelegate> delegate;

@end

@implementation NodeCollectionViewCell

- (NodeCollectionViewCellViewModel *)viewModel {
    if (_viewModel == nil) {
        _viewModel = [self createNodeCollectionCellViewModel];
    }
    return _viewModel;
}

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    if (self.moreButton.hidden && selected) {
        self.selectImageView.image = [UIImage imageNamed:@"thumbnail_selected"];
        self.contentView.layer.borderColor = [UIColor mnz_fromHexString:@"00A886"].CGColor;
    } else {
        self.selectImageView.image = [UIImage imageNamed:@"checkBoxUnselected"];
        switch (self.traitCollection.userInterfaceStyle) {
            case UIUserInterfaceStyleUnspecified:
            case UIUserInterfaceStyleLight: {
                self.contentView.layer.borderColor = [UIColor mnz_fromHexString:@"F7F7F7"].CGColor;
            }
                break;
            case UIUserInterfaceStyleDark: {
                self.contentView.layer.borderColor = [UIColor mnz_fromHexString:@"545458"].CGColor;
            }
        }
    }
}

- (void)configureCellForNode:(MEGANode *)node allowedMultipleSelection:(BOOL)multipleSelection sdk:(MEGASdk *)sdk delegate:(id<NodeCollectionViewCellDelegate> _Nullable)delegate {
    self.node = node;
    self.delegate = delegate;
    if (node.hasThumbnail) {
        NSString *thumbnailFilePath = [Helper pathForNode:node inSharedSandboxCacheDirectory:@"thumbnailsV3"];
        if ([[NSFileManager defaultManager] fileExistsAtPath:thumbnailFilePath]) {
            self.thumbnailImageView.image = [UIImage imageWithContentsOfFile:thumbnailFilePath];
        } else {
            MEGAGetThumbnailRequestDelegate *getThumbnailRequestDelegate = [[MEGAGetThumbnailRequestDelegate alloc] initWithCompletion:^(MEGARequest *request) {
                if (request.nodeHandle == self.node.handle) {
                    self.thumbnailImageView.image = [UIImage imageWithContentsOfFile:request.file];
                }
            }];
            [sdk getThumbnailNode:node destinationFilePath:thumbnailFilePath delegate:getThumbnailRequestDelegate];
            [self.thumbnailImageView setImage:[NodeAssetsManager.shared iconFor:node]];
        }
        self.thumbnailIconView.hidden = YES;
    } else {
        self.thumbnailIconView.hidden = NO;
        [self.thumbnailIconView setImage:[NodeAssetsManager.shared iconFor:node]];
        self.thumbnailImageView.image = nil;
    }
    
    if (node.isTakenDown) {
        self.nameLabel.attributedText = [node attributedTakenDownName];
        self.nameLabel.textColor = [UIColor mnz_redForTraitCollection:(self.traitCollection)];
    } else {
        self.nameLabel.text = node.name;
        if (node.isFile) {
            self.infoLabel.text = [Helper sizeForNode:node api:sdk];
        } else if (node.isFolder) {
            self.infoLabel.text = [Helper filesAndFoldersInFolderNode:node api:sdk];
        }
    }
    
    self.labelView.hidden = (node.label == MEGANodeLabelUnknown);
    if (node.label != MEGANodeLabelUnknown) {
        NSString *labelString = [[MEGANode stringForNodeLabel:node.label] stringByAppendingString:@"Small"];
        self.labelImageView.image = [UIImage imageNamed:labelString];
    }
    
    BOOL favouriteIsHidden = !node.isFavourite;
    self.favouriteView.hidden = favouriteIsHidden;
    BOOL linkIsHidden = !node.isExported || node.mnz_isInRubbishBin;
    self.linkView.hidden = linkIsHidden;
    [MEGASdkManager.sharedMEGASdk hasVersionsForNode:node completion:^(BOOL hasVersions) {
        BOOL versionedIsHidden = !hasVersions;
        dispatch_async(dispatch_get_main_queue(), ^{
            self.versionedView.hidden = versionedIsHidden;
            self.topNodeIconsView.hidden = favouriteIsHidden && versionedIsHidden && linkIsHidden;
        });
    }];
    
    self.durationLabel.hidden = ![self.viewModel isNodeVideoWithValidDurationWithNode:node];
    self.videoIconView.hidden = ![self.viewModel isNodeVideoWithName:node.name];
    if (!self.durationLabel.hidden) {
        self.durationLabel.layer.cornerRadius = 4;
        self.durationLabel.layer.masksToBounds = true;
        self.durationLabel.text = [NSString mnz_stringFromTimeInterval:node.duration];
    }
    
    if (self.downloadedView != nil) {
        self.downloadedImageView.hidden = self.downloadedView.hidden = !(node.isFile && [[MEGAStore shareInstance] offlineNodeWithNode:node]);
    } else {
        self.downloadedImageView.hidden = !(node.isFile && [[MEGAStore shareInstance] offlineNodeWithNode:node]);
    }

    self.selectImageView.hidden = !multipleSelection;
    self.moreButton.hidden = multipleSelection;
    
    [self setupAppearance];
}

- (void)configureCellForOfflineItem:(NSDictionary *)item itemPath:(NSString *)pathForItem allowedMultipleSelection:(BOOL)multipleSelection sdk:(nonnull MEGASdk *)sdk delegate:(id<NodeCollectionViewCellDelegate> _Nullable)delegate {
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
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^(void){
            // heavy non-UI work
            FolderContentStat *folderContentStat = [[NSFileManager defaultManager] mnz_folderContentStatWithPathForItem:pathForItem];
            NSInteger files = folderContentStat.fileCount;
            NSInteger folders = folderContentStat.folderCount;
            dispatch_async(dispatch_get_main_queue(), ^(void){
                // update UI
                self.infoLabel.text = [NSString mnz_stringByFiles:files andFolders:folders];
            });
        });
    } else {
        self.infoLabel.text = [NSString memoryStyleStringFromByteCount:[item[kFileSize] longLongValue]];
        NSString *extension = nameString.pathExtension.lowercaseString;
        
        if (!handleString) {
            NSString *fpLocal = [sdk fingerprintForFilePath:pathForItem];
            if (fpLocal) {
                MEGANode *node = [sdk nodeForFingerprint:fpLocal];
                if (node) {
                    handleString = node.base64Handle;
                    [[MEGAStore shareInstance] insertOfflineNode:node api:sdk path:[[Helper pathRelativeToOfflineDirectory:pathForItem] decomposedStringWithCanonicalMapping]];
                }
            }
        }
        
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
    [self configureCellForNode:node allowedMultipleSelection:multipleSelection sdk:sdk delegate:delegate];
    
    if (self.downloadedImageView != nil) {
        if ([node isFile] && [MEGAStore.shareInstance offlineNodeWithNode:node] != nil) {
            self.downloadedImageView.hidden = NO;
        } else {
            self.downloadedImageView.hidden = YES;
        }
    }
}

- (NSString *)itemName {
    return self.nameLabel.text;
}

- (void)setupAppearance {
    [self setSelected:NO];
    
    switch (self.traitCollection.userInterfaceStyle) {
        case UIUserInterfaceStyleUnspecified:
        case UIUserInterfaceStyleLight: {
            self.topNodeIconsView.backgroundColor = [UIColor colorWithWhite:1 alpha:0.3];
            self.thumbnailImageView.backgroundColor = [UIColor mnz_fromHexString:@"F7F7F7"];
        }
            break;
        case UIUserInterfaceStyleDark: {
            self.topNodeIconsView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.4];
            self.thumbnailImageView.backgroundColor = [UIColor mnz_fromHexString:@"1C1C1E"];
        }
    }
}

- (IBAction)optionButtonAction:(id)sender {
    [self.delegate showMoreMenuForNode:self.node from:sender];
}

#pragma mark: - Private

- (void)configureWithThumbnailFilePath:(NSString *)thumbnailFilePath {
    UIImage *thumbnailImage = [UIImage imageWithContentsOfFile:thumbnailFilePath];
    if (thumbnailImage) {
        self.thumbnailImageView.image = thumbnailImage;
    }
    self.thumbnailIconView.hidden = YES;
}

@end
