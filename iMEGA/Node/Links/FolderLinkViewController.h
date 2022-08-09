#import <UIKit/UIKit.h>

@class AudioPlayer;
@class MiniPlayerViewRouter;

NS_ASSUME_NONNULL_BEGIN

@interface FolderLinkViewController : UIViewController

@property (nonatomic) BOOL isFolderRootNode;
@property (nonatomic, strong, nullable) NSString *publicLinkString;
@property (nonatomic, strong, nullable) NSString *linkEncryptedString;

@property (strong, nonatomic) UISearchController *searchController;

@property (nonatomic, strong) NSArray<MEGANode *> *nodesArray;
@property (nonatomic, strong, nullable) NSArray<MEGANode *> *searchNodesArray;
@property (nonatomic, strong, nullable) NSMutableArray<MEGANode *> *selectedNodesArray;

@property (nonatomic, getter=isFolderLinkNotValid) BOOL folderLinkNotValid;
@property (nonatomic, getter=areAllNodesSelected) BOOL allNodesSelected;

@property (nonatomic, strong, nullable) UIView *bottomView;
@property (nonatomic, strong, nullable) AudioPlayer *player;
@property (nonatomic, strong, nullable) MiniPlayerViewRouter *miniPlayerRouter;

- (void)didSelectNode:(MEGANode *)node;
- (void)showActionsForNode:(MEGANode *)node from:(UIButton *)sender;
- (void)setNavigationBarTitleLabel;
- (void)setToolbarButtonsEnabled:(BOOL)boolValue;
- (void)setViewEditing:(BOOL)editing;

- (void)didDownloadTransferFinish:(MEGANode *)node;
- (nullable UIView *)customViewForEmptyDataSet:(UIScrollView *)scrollView;
- (FolderLinkViewController *)folderLinkViewControllerFromNode:(MEGANode *)node;

@end

NS_ASSUME_NONNULL_END
