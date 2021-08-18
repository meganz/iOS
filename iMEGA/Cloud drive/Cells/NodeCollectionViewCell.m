
#import "NodeCollectionViewCell.h"

#import "NSString+MNZCategory.h"

#import "Helper.h"
#import "MEGAGetThumbnailRequestDelegate.h"
#import "MEGANode+MNZCategory.h"
#import "MEGASdkManager.h"
#import "UIImageView+MNZCategory.h"
#import "MEGAStore.h"

@interface NodeCollectionViewCell ()

@property (strong, nonatomic) MEGANode *node;

@end

@implementation NodeCollectionViewCell

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

- (void)configureCellForNode:(MEGANode *)node api:(MEGASdk *)api {
    self.node = node;
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
            [api getThumbnailNode:node destinationFilePath:thumbnailFilePath delegate:getThumbnailRequestDelegate];
            [self.thumbnailImageView mnz_imageForNode:node];
        }
        self.thumbnailIconView.hidden = YES;
    } else {
        self.thumbnailIconView.hidden = NO;
        [self.thumbnailIconView mnz_imageForNode:node];
        self.thumbnailImageView.image = nil;
    }
    
    if (node.isTakenDown) {
        self.nameLabel.attributedText = [node mnz_attributedTakenDownNameWithHeight:self.nameLabel.font.capHeight];
        self.nameLabel.textColor = [UIColor mnz_redForTraitCollection:(self.traitCollection)];
    } else {
        self.nameLabel.text = node.name;
        if (node.isFile) {
            self.infoLabel.text = [Helper sizeForNode:node api:api];
        } else if (node.isFolder) {
            self.infoLabel.text = [Helper filesAndFoldersInFolderNode:node api:api];
        }
    }
    
    self.durationLabel.hidden = !node.name.mnz_isVideoPathExtension;
    if (!self.durationLabel.hidden) {
        self.durationLabel.layer.cornerRadius = 4;
        self.durationLabel.layer.masksToBounds = true;
        self.durationLabel.text = node.name.mnz_isVideoPathExtension ? [NSString mnz_stringFromTimeInterval:node.duration] : @"";
    }
    
    if (self.downloadedView != nil) {
        self.downloadedImageView.hidden = self.downloadedView.hidden = !(node.isFile && [[MEGAStore shareInstance] offlineNodeWithNode:node]);
    } else {
        self.downloadedImageView.hidden = !(node.isFile && [[MEGAStore shareInstance] offlineNodeWithNode:node]);
    }
    
    
    [self setupAppearance];
}

- (void)setupAppearance {
    [self setSelected:NO];
    
    switch (self.traitCollection.userInterfaceStyle) {
        case UIUserInterfaceStyleUnspecified:
        case UIUserInterfaceStyleLight: {
            self.thumbnailImageView.backgroundColor = [UIColor mnz_fromHexString:@"F7F7F7"];
        }
            break;
        case UIUserInterfaceStyleDark: {
            self.thumbnailImageView.backgroundColor = [UIColor mnz_fromHexString:@"1C1C1E"];
        }
    }
}

@end
