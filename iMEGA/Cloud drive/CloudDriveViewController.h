#import <UIKit/UIKit.h>

#import "DisplayMode.h"
#import "BrowserViewController.h"
#import "ContactsViewController.h"
#import "CloudDriveTableViewController.h"
#import "CloudDriveCollectionViewController.h"

@class MEGANode, MEGAUser, MyAvatarManager, ContextMenuManager, CloudDriveViewModel;

static const NSUInteger kMinimumLettersToStartTheSearch = 1;

NS_ASSUME_NONNULL_BEGIN

@interface CloudDriveViewController : UIViewController <BrowserViewControllerDelegate, ContatctsViewControllerDelegate, UIDocumentPickerDelegate>

@property (nonatomic, strong, nullable) MEGANode *parentNode;
@property (nonatomic, strong, nullable) MEGAUser *user;
@property (nonatomic) DisplayMode displayMode;
@property (nonatomic, getter=isIncomingShareChildView) BOOL incomingShareChildView;

@property (nonatomic, strong, nullable) MEGANodeList *nodes;
@property (nonatomic, strong, nullable) NSMutableArray<MEGANode *> *searchNodesArray;
@property (nonatomic, strong, nullable) NSMutableArray<MEGANode *> *selectedNodesArray;
@property (nonatomic, strong, nullable) NSMutableDictionary *nodesIndexPathMutableDictionary;

@property (nonatomic, strong, nullable) MEGARecentActionBucket *recentActionBucket;
@property (nonatomic) NSInteger recentIndex;

@property (strong, nonatomic, nullable) UISearchController *searchController;

@property (nonatomic, strong, nullable) CloudDriveTableViewController *cdTableView;
@property (nonatomic, strong, nullable) CloudDriveCollectionViewController *cdCollectionView;

@property (assign, nonatomic) BOOL allNodesSelected;
@property (assign, nonatomic) BOOL shouldRemovePlayerDelegate;
@property (assign, nonatomic) BOOL isFromViewInFolder;
@property (assign, nonatomic) BOOL isFromSharedItem;
@property (assign, nonatomic) MEGAShareType shareType; //Control the actions allowed for node/nodes selected
@property (assign, nonatomic) BOOL hasMediaFiles;

@property (nonatomic, strong, nullable) MyAvatarManager * myAvatarManager;

@property (strong, nonatomic) UIBarButtonItem *contextBarButtonItem;
@property (strong, nonatomic) UIBarButtonItem *uploadAddBarButtonItem;
@property (nonatomic, strong, nullable) ContextMenuManager * contextMenuManager;

@property (strong, nonatomic) CloudDriveViewModel *viewModel;

- (void)presentScanDocument;
- (void)setViewEditing:(BOOL)editing;
- (void)setToolbarActionsEnabled:(BOOL)boolValue;
- (void)didSelectNode:(MEGANode *)node;
- (void)moveNode:(MEGANode * _Nonnull)node;
- (void)confirmDeleteActionFiles:(NSUInteger)numFilesAction andFolders:(NSUInteger)numFoldersAction;
- (void)setEditMode:(BOOL)editMode;
- (void)showNodeInfo:(MEGANode *)node;
- (nullable MEGANode *)nodeAtIndexPath:(NSIndexPath *)indexPath;
- (void)presentGetLinkVCForNodes:(NSArray<MEGANode *> *)nodes;
- (void)toolbarActionsForShareType:(MEGAShareType)shareType isBackupNode:(BOOL)isBackupNode;

- (BOOL)isListViewModeSelected;
- (void)changeViewModePreference;
- (void)nodesSortTypeHasChanged;
- (void)createNewFolderAction;
- (void)showImagePickerForSourceType:(UIImagePickerControllerSourceType)sourceType;
@end

NS_ASSUME_NONNULL_END
