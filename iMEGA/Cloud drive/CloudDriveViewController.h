#import <UIKit/UIKit.h>
#import "DisplayMode.h"
#import "BrowserViewController.h"
#import "ContactsViewController.h"
#import "CloudDriveTableViewController.h"
#import "CloudDriveCollectionViewController.h"

@class MEGANode, MEGAUser, MyAvatarManager, ContextMenuManager, CloudDriveViewModel, WarningBannerViewModel, DefaultNodeAccessoryActionDelegate;

static const NSUInteger kMinimumLettersToStartTheSearch = 1;

NS_ASSUME_NONNULL_BEGIN
@protocol ViewModeStoringObjC;
@interface CloudDriveViewController : UIViewController <BrowserViewControllerDelegate, ContactsViewControllerDelegate, UIDocumentPickerDelegate>

@property (nonatomic, strong, nullable) MEGANode *parentNode;
@property (nonatomic, strong, nullable) MEGAUser *user;
@property (nonatomic) DisplayMode displayMode;
@property (nonatomic, getter=isIncomingShareChildView) BOOL incomingShareChildView;

@property (nonatomic, strong, nullable) MEGANodeList *nodes;
@property (nonatomic, strong, nullable) NSMutableArray<MEGANode *> *searchNodesArray;
@property (nonatomic, strong, nullable) NSMutableArray<MEGANode *> *selectedNodesArray;
@property (nonatomic, strong, nullable) NSMutableDictionary *nodesIndexPathMutableDictionary;

@property (nonatomic, strong, nullable) MEGARecentActionBucket *recentActionBucket;

@property (strong, nonatomic, nullable) UISearchController *searchController;

@property (nonatomic, strong, nullable) CloudDriveTableViewController *cdTableView;
@property (nonatomic, strong, nullable) CloudDriveCollectionViewController *cdCollectionView;
@property (nonatomic, strong, nullable) UIViewController *mdHostedController;

@property (assign, nonatomic) BOOL allNodesSelected;
@property (assign, nonatomic) BOOL shouldRemovePlayerDelegate;
@property (assign, nonatomic) BOOL isFromViewInFolder;
@property (assign, nonatomic) BOOL isFromSharedItem;
@property (assign, nonatomic) BOOL isFromUnverifiedContactSharedFolder;
@property (assign, nonatomic) MEGAShareType shareType; //Control the actions allowed for node/nodes selected
@property (assign, nonatomic) BOOL hasMediaFiles;
@property (assign, nonatomic) BOOL isEditingModeBeingDisabled;
@property (assign, nonatomic) BOOL wasSelectingFavoriteUnfavoriteNodeActionOption;

@property (strong, nonatomic, nullable) WarningBannerViewModel *warningViewModel;

@property (nonatomic, strong, nullable) MyAvatarManager * myAvatarManager;

@property (strong, nonatomic) IBOutlet UIView *warningBannerView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *warningBannerViewHeight;
@property (strong, nonatomic) UIBarButtonItem *contextBarButtonItem;
@property (strong, nonatomic) UIBarButtonItem *uploadAddBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *downloadBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *shareLinkBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *moveBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *carbonCopyBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *deleteBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *restoreBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *actionsBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *selectAllBarButtonItem;
@property (nonatomic, assign) BOOL shouldDetermineViewMode;
@property (nonatomic, strong, nullable) ContextMenuManager * contextMenuManager;
@property (nonatomic, strong, nullable) id<ViewModeStoringObjC> viewModeStore;
@property (strong, nonatomic) CloudDriveViewModel *viewModel;
@property (weak, nonatomic) IBOutlet UIStackView *containerStackView;
@property (nonatomic, assign) NSInteger viewModePreference_ObjC;
@property (strong, nonatomic) DefaultNodeAccessoryActionDelegate *defaultNodeAccessoryActionDelegate;
// This creator closure is used to replace the
// viewModeStore instance for the mock one, between init and viewDidLoad calls.
// We can't inject in the init, as view is defined in Storyboard
@property (nonatomic, copy) dispatch_block_t viewModeStoreCreator;
- (void)presentScanDocument;
- (void)setViewEditing:(BOOL)editing;
- (void)setToolbarActionsEnabled:(BOOL)boolValue;
- (void)moveNode:(MEGANode * _Nonnull)node;
- (void)confirmDeleteActionFiles:(NSUInteger)numFilesAction andFolders:(NSUInteger)numFoldersAction;
- (void)setEditMode:(BOOL)editMode;
- (nullable MEGANode *)nodeAtIndexPath:(NSIndexPath *)indexPath;
- (void)toolbarActionsForShareType:(MEGAShareType)shareType isBackupNode:(BOOL)isBackupNode;

- (BOOL)isListViewModeSelected;
- (BOOL)isThumbnailViewModeSelected;
- (BOOL)isMediaDiscoveryViewModeSelected;

-(void)changeModeToListView;
-(void)changeModeToThumbnail;
-(void)changeModeToMediaDiscovery;

- (void)nodesSortTypeHasChanged;
- (void)createNewFolderAction;
- (void)reloadUI:(MEGANodeList * _Nullable)updatedNodes;
- (void)loadPhotoAlbumBrowser;
- (void)initTable;
- (void)initCollection;
@end

NS_ASSUME_NONNULL_END
