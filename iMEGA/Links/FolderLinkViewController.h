#import <UIKit/UIKit.h>

@class AudioPlayer;
@class MiniPlayerViewRouter;

@interface FolderLinkViewController : UIViewController

@property (nonatomic) BOOL isFolderRootNode;
@property (nonatomic, strong) NSString *publicLinkString;
@property (nonatomic, strong) NSString *linkEncryptedString;

@property (strong, nonatomic) UISearchController *searchController;

@property (nonatomic, strong) NSArray<MEGANode *> *nodesArray;
@property (nonatomic, strong) NSArray<MEGANode *> *searchNodesArray;
@property (nonatomic, strong) NSMutableArray<MEGANode *> *selectedNodesArray;

@property (nonatomic, getter=isFolderLinkNotValid) BOOL folderLinkNotValid;
@property (nonatomic, getter=areAllNodesSelected) BOOL allNodesSelected;

@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;

@property (nonatomic, strong) UIView * _Nullable bottomView;
@property (nonatomic, strong) AudioPlayer * _Nullable player;
@property (nonatomic, strong) MiniPlayerViewRouter * _Nullable miniPlayerRouter;

- (void)didSelectNode:(MEGANode *)node;
- (void)showActionsForNode:(MEGANode *)node from:(UIButton *)sender;
- (void)setNavigationBarTitleLabel;
- (void)setToolbarButtonsEnabled:(BOOL)boolValue;
- (void)setViewEditing:(BOOL)editing;

- (void)didDownloadTransferStart:(MEGANode * _Nonnull)node;
- (void)didDownloadTransferFinish:(MEGANode * _Nonnull)node;
- (void)didDownloadTransferUpdated:(MEGANode * _Nonnull)node transferredBytes:(NSNumber * _Nonnull)bytes totalBytes:(NSNumber * _Nonnull)totalBytes speed:(NSNumber * _Nonnull)speed;
- (BOOL)isADownloadingNode:(MEGANode * _Nonnull)node;
- (nullable UIView *)customViewForEmptyDataSet:(UIScrollView *)scrollView;

@end
