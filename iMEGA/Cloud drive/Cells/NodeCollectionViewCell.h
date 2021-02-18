
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface NodeCollectionViewCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UIImageView *thumbnailImageView;
@property (weak, nonatomic) IBOutlet UIImageView *thumbnailIconView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UIButton *moreButton;
@property (weak, nonatomic) IBOutlet UIImageView *selectImageView;
@property (weak, nonatomic) IBOutlet UILabel *infoLabel;
@property (weak, nonatomic) IBOutlet UILabel *durationLabel;

- (void)configureCellForNode:(MEGANode *)node api:(MEGASdk *)api;
- (void)setupAppearance;

@end

typedef NS_ENUM(NSUInteger, ThumbnailSection) {
    ThumbnailSectionFolder = 0,
    ThumbnailSectionFile = 1,
    ThumbnailSectionCount = 2
};

typedef NS_ENUM(NSUInteger, ThumbnailSize) {
    ThumbnailSizeHeightFile = 230,
    ThumbnailSizeHeightFolder = 45,
    ThumbnailSizeWidth = 180
};

typedef NS_ENUM(NSUInteger, FileType) {
    FileTypeFile,
    FileTypeFolder
};

NS_ASSUME_NONNULL_END
