
#import "NodeCollectionViewCell.h"

#import "NSString+MNZCategory.h"

#import "Helper.h"
#import "MEGAGetThumbnailRequestDelegate.h"
#import "MEGANode+MNZCategory.h"
#import "MEGASdkManager.h"
#import "UIImageView+MNZCategory.h"

@interface NodeCollectionViewCell ()

@property (strong, nonatomic) MEGANode *node;

@end

@implementation NodeCollectionViewCell

- (void)configureCellForNode:(MEGANode *)node {
    self.node = node;
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
        self.thumbnailImageView.hidden = NO;
        self.thumbnailIconView.hidden = YES;
    } else {
        self.thumbnailIconView.hidden = NO;
        [self.thumbnailIconView mnz_imageForNode:node];
        self.thumbnailImageView.hidden = YES;
    }
    
    if (node.isTakenDown) {
        self.nameLabel.attributedText = [node mnz_attributedTakenDownNameWithHeight:self.nameLabel.font.capHeight];
        self.nameLabel.textColor = [UIColor mnz_redMainForTraitCollection:(self.traitCollection)];
    } else {
        self.nameLabel.text = node.name;
    }
    
    if (!node.name.mnz_isVideoPathExtension) {
        self.thumbnailPlayImageView.hidden = YES;
    }

    if (@available(iOS 11.0, *)) {
        self.thumbnailImageView.accessibilityIgnoresInvertColors = YES;
        self.thumbnailPlayImageView.accessibilityIgnoresInvertColors = YES;
    }
}

- (void)selectCell:(BOOL)selected {
    self.selected = selected;
    self.selectImageView.image = selected ? [UIImage imageNamed:@"thumbnail_selected"] :[UIImage imageNamed:@"checkBoxUnselected"];
}

@end
