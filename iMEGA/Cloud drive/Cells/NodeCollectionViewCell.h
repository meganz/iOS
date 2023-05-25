
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class NodeCollectionViewCellViewModel;

@protocol NodeCollectionViewCellDelegate <NSObject>
- (void)showMoreMenuForNode:(MEGANode *)node from:(UIButton *)sender;
@end

@interface NodeCollectionViewCell : UICollectionViewCell

@property (strong, nonatomic) NodeCollectionViewCellViewModel *viewModel;
@property (weak, nonatomic) IBOutlet UILabel *durationLabel;

- (void)configureCellForNode:(MEGANode *)node allowedMultipleSelection:(BOOL)multipleSelection sdk:(MEGASdk *)sdk delegate:(id<NodeCollectionViewCellDelegate> _Nullable)delegate;
- (void)configureCellForFolderLinkNode:(MEGANode *)node allowedMultipleSelection:(BOOL)multipleSelection sdk:(MEGASdk *)sdk delegate:(id<NodeCollectionViewCellDelegate> _Nullable)delegate;
- (void)configureCellForOfflineItem:(NSDictionary *)item itemPath:(NSString *)pathForItem allowedMultipleSelection:(BOOL)multipleSelection sdk:(MEGASdk *)sdk delegate:(id<NodeCollectionViewCellDelegate> _Nullable)delegate;
- (void)setupAppearance;
- (NSString *)itemName;

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
