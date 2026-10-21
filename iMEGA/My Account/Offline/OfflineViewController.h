#import <UIKit/UIKit.h>
#import "OfflineTableViewViewController.h"
#import "OfflineCollectionViewController.h"

@class MEGAQLPreviewController, MOOfflineNode, ContextMenuManager, OfflineViewModel;

typedef NS_ENUM(NSUInteger, OfflineViewControllerFlavor) {
    AccountScreen = 0,
    HomeScreen,
};

NS_ASSUME_NONNULL_BEGIN

static NSString *documentProviderLog = @"MEGAiOS.docExt.log";
static NSString *fileProviderLog = @"MEGAiOS.fileExt.log";
static NSString *shareExtensionLog = @"MEGAiOS.shareExt.log";
static NSString *notificationServiceExtensionLog = @"MEGAiOS.NSE.log";

@interface OfflineViewController : UIViewController

@property (nonatomic, strong, nullable) UIToolbar *editingToolbar;
/// Bottom constraint of the editing toolbar. Its constant is set when Select mode starts, so the toolbar sits where the tab bar was.
@property (nonatomic, strong, nullable) NSLayoutConstraint *editingToolbarBottomConstraint;
/// Whether the tab bar was already hidden when Select mode started, so leaving Select mode restores that state.
/// Discussion: The Offline screen's hides the tabbar when opened from Menu, but it shows the tabbar when opened from Home screen
/// Therefore we need `tabBarHiddenBeforeEditing` to properly handle the tabbar after exiting Edit mode.
/// Using NSNumber as an alternative for `Bool?`: nil while Select mode is off, so a repeated show or a hide without show cannot change the saved state.
@property (nonatomic, strong, nullable) NSNumber *tabBarHiddenBeforeEditing;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *activityBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *deleteBarButtonItem;

@property (nonatomic, strong, nullable) NSIndexPath *peekIndexPath;

@property (nonatomic, assign) BOOL allItemsSelected;
@property (nonatomic, strong, nullable) NSString *previewDocumentPath;

@property (nonatomic, strong, nullable) NSMutableArray *selectedItems;
@property (nonatomic, strong, nullable) NSMutableArray *offlineSortedItems;
@property (nonatomic, strong, nullable) NSMutableArray *offlineSortedFileItems;
@property (nonatomic, strong, nullable) NSMutableArray *searchItemsArray;
@property (nonatomic, strong, nullable) UISearchController *searchController;
@property (nonatomic, assign) OfflineViewControllerFlavor flavor;
@property (nonatomic, readonly) NSString *currentOfflinePath;
@property (nonatomic, strong, nullable) NSString *folderPathFromOffline;

@property (nonatomic, strong, nullable) ContextMenuManager * contextMenuManager;
@property (nonatomic, strong) UIBarButtonItem *contextBarButtonItem;
@property (nonatomic, strong) NSString *logsPath;
@property (nonatomic, strong) OfflineViewModel *viewModel;

@property (nonatomic, assign) CGFloat currentContentInsetHeight;

@property (nonatomic, strong, nullable) OfflineTableViewViewController *offlineTableView;
@property (nonatomic, strong, nullable) OfflineCollectionViewController *offlineCollectionView;

- (nullable NSDictionary *)itemAtIndexPath:(NSIndexPath *)indexPath;
- (void)updateNavigationBarTitle;
- (void)setViewEditing:(BOOL)editing;
- (void)itemTapped:(NSString *)name atIndexPath:(NSIndexPath *)indexPath;
- (void)enableButtonsBySelectedItems;
- (void)showInfoFilePath:(NSString *)itemPath at:(nullable NSIndexPath *)indexPath from:(UIButton *)sender;
- (void)showRemoveAlertWithConfirmAction:(void (^)(void))confirmAction andCancelAction:(nullable void (^)(void))cancelAction;
- (void)setEditMode:(BOOL)editMode;
- (void)openFileFromWidgetWith:(NSString *)path;
- (NSString *)folderPathFromOffline:(NSString *)absolutePath folder:(NSString *)folderName;

- (BOOL)isListViewModeSelected;
- (void)changeViewModePreference;
- (void)changeEditingModeStatus;
- (void)nodesSortTypeHasChanged;
- (void)reloadUI;
- (void)reloadData;
- (void)determineViewMode;
@end

NS_ASSUME_NONNULL_END
