#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class NodeCollectionViewCellViewModel;

@protocol NodeCollectionViewCellDelegate <NSObject>
- (void)showMoreMenuForNode:(MEGANode *)node from:(UIButton *)sender;
@end

@interface NodeCollectionViewCell : UICollectionViewCell

@property (strong, nonatomic) NodeCollectionViewCellViewModel *viewModel;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *infoLabel;
@property (weak, nonatomic) IBOutlet UILabel *durationLabel;
@property (weak, nonatomic) IBOutlet UIImageView *thumbnailImageView;
@property (weak, nonatomic) IBOutlet UIImageView *thumbnailIconView;
@property (weak, nonatomic) IBOutlet UIImageView *favouriteImageView;
@property (weak, nonatomic) IBOutlet UIImageView *linkImageView;
@property (weak, nonatomic) IBOutlet UIImageView *versionedImageView;
@property (weak, nonatomic) IBOutlet UIImageView *videoIconView;
@property (weak, nonatomic) IBOutlet UIImageView *downloadedImageView;
@property (weak, nonatomic) IBOutlet UIView *topNodeIconsView;
@property (weak, nonatomic) IBOutlet UIButton *moreButton;
@property (weak, nonatomic) IBOutlet UIImageView *selectImageView;
@property (weak, nonatomic) IBOutlet UIStackView *labelsContainerStackView;
@property (strong, nonatomic) NSSet<id> *cancellables;

- (void)configureCellForNode:(MEGANode *)node
    allowedMultipleSelection:(BOOL)multipleSelection
            isFromSharedItem:(BOOL)isFromSharedItem
                         sdk:(MEGASdk *)sdk
                    delegate:(id<NodeCollectionViewCellDelegate> _Nullable)delegate
                 isSampleRow:(BOOL)isSampleRow;
- (void)configureCellForNode:(MEGANode *)node allowedMultipleSelection:(BOOL)multipleSelection isFromSharedItem:(BOOL)isFromSharedItem sdk:(MEGASdk *)sdk delegate:(id<NodeCollectionViewCellDelegate> _Nullable)delegate;
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
    ThumbnailSizeHeight = 230,
    ThumbnailSizeWidth = 180
};

typedef NS_ENUM(NSUInteger, FileType) {
    FileTypeFile,
    FileTypeFolder
};

NS_ASSUME_NONNULL_END
