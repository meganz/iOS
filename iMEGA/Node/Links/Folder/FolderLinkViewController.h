#import <UIKit/UIKit.h>
#import "UnavailableLinkView.h"

@class AudioPlayer;
@class MiniPlayerViewRouter;
@class ContextMenuManager;
@class FolderLinkTableViewController;
@class FolderLinkCollectionViewController;
@class SendLinkToChatsDelegate;
@class FolderLinkViewModel;

NS_ASSUME_NONNULL_BEGIN

@interface FolderLinkViewController : UIViewController

@property (nonatomic) BOOL isFolderRootNode;
@property (nonatomic, strong, nullable) NSString *publicLinkString;
@property (nonatomic, strong, nullable) NSString *linkEncryptedString;
@property (nonatomic, strong, nullable) NSString *titleViewSubtitle;
@property (nonatomic) SendLinkToChatsDelegate *sendLinkDelegate;

@property (strong, nonatomic) UISearchController *searchController;

@property (nonatomic, strong, readonly, nullable) MEGANode *parentNode;
@property (nonatomic, strong) NSArray<MEGANode *> *nodesArray;
@property (nonatomic, strong, nullable) NSArray<MEGANode *> *searchNodesArray;
@property (nonatomic, strong, nullable) NSMutableArray<MEGANode *> *selectedNodesArray;

@property (nonatomic, getter=areAllNodesSelected) BOOL allNodesSelected;

@property (nonatomic, strong, nullable) UIView *bottomView;

@property (nonatomic, strong) IBOutlet UIBarButtonItem *moreBarButtonItem;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *editBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *closeBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *selectAllBarButtonItem;

@property (nonatomic, strong, nullable) MiniPlayerViewRouter *miniPlayerRouter;
@property (nonatomic, strong, nullable) ContextMenuManager * contextMenuManager;
@property (nonatomic, strong, nullable) FolderLinkTableViewController *flTableView;
@property (nonatomic, strong, nullable) FolderLinkCollectionViewController *flCollectionView;

@property (nonatomic, strong, readonly) UIActivityIndicatorView *activityIndicator;

@property (nonatomic, strong) FolderLinkViewModel *viewModel;

@property (nonatomic, assign) CGFloat currentContentInsetHeight;

- (IBAction)shareLinkAction:(UIBarButtonItem *)sender;

- (BOOL)isListViewModeSelected;
- (void)didSelectNode:(MEGANode *)node;
- (void)setNavigationBarTitleLabel;
- (void)setToolbarButtonsEnabled:(BOOL)boolValue;
- (void)setViewEditing:(BOOL)editing;
- (void)setEditMode:(BOOL)editMode;
- (void)changeViewModePreference;
- (void)reloadUI;

- (void)didDownloadTransferFinish:(MEGANode *)node;
- (nullable UIView *)customViewForEmptyDataSet:(UIScrollView *)scrollView;
- (FolderLinkViewController *)folderLinkViewControllerFromNode:(MEGANode *)node;
- (void)showUnavailableLinkViewWithError:(UnavailableLinkError)error;
- (void)handleInvalidDecryptionKey;
- (void)handleLoginDone;
- (void)handleFetchNodesDone:(BOOL)validKey;
- (void)handleLogout;
- (void)handleFileAttributeUpdate:(uint64_t)nodeHandle;
- (void)showDecryptionAlert;
- (void)handleFetchNodesFailed;

@end

NS_ASSUME_NONNULL_END
