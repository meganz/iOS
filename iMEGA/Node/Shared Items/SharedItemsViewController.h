#import <UIKit/UIKit.h>

@class ContextMenuManager, MEGAVerticalButton, SharedItemsViewModel, SharedItemsTableViewCell, SharedItemsNodeSearcher, TaskOCWrapper;

typedef NS_ENUM(NSInteger, SharedItemsViewControllerSection) {
    /// Static sort/header row at the top (height = 50)
    SharedItemsViewControllerSectionSortHeader = 0,

    /// Rows that need attention / “unverified” (incoming & outgoing tabs only)
    SharedItemsViewControllerSectionUnverified,

    /// Main content list:
    /// - incoming/outgoing: verified shares
    /// - links: all public links
    SharedItemsViewControllerSectionContent
};

typedef NS_ENUM(NSInteger, SharedItemsTabSelection) {
    SharedItemsTabSelectionIncoming = 0,
    SharedItemsTabSelectionOutgoing,
    SharedItemsTabSelectionLinks
};

NS_ASSUME_NONNULL_BEGIN

@interface SharedItemsViewController : UIViewController

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *selectAllBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *editBarButtonItem;

@property (weak, nonatomic) IBOutlet MEGAVerticalButton *incomingButton;
@property (weak, nonatomic) IBOutlet MEGAVerticalButton *outgoingButton;
@property (weak, nonatomic) IBOutlet MEGAVerticalButton *linksButton;

@property (strong, nonatomic) UIToolbar *toolbar;
@property (strong, nonatomic) UIBarButtonItem *downloadBarButtonItem;
@property (strong, nonatomic) UIBarButtonItem *carbonCopyBarButtonItem;
@property (strong, nonatomic) UIBarButtonItem *leaveShareBarButtonItem;
@property (strong, nonatomic) UIBarButtonItem *shareLinkBarButtonItem;
@property (strong, nonatomic) UIBarButtonItem *removeLinkBarButtonItem;
@property (strong, nonatomic) UIBarButtonItem *shareFolderBarButtonItem;
@property (strong, nonatomic) UIBarButtonItem *removeShareBarButtonItem;
@property (strong, nonatomic) UIBarButtonItem *saveToPhotosBarButtonItem;

@property (nonatomic) MEGASortOrderType sortOrderType;

@property (nonatomic, strong, nullable) ContextMenuManager * contextMenuManager;
@property (nonatomic, strong) UIBarButtonItem *contextBarButtonItem;
@property (nonatomic, strong) NSMutableArray *selectedNodesMutableArray;

@property (nonatomic) UISearchController *searchController;
@property (nonatomic, strong, nullable) UIView *headerContainerView;
@property (nonatomic) SharedItemsTabSelection selectedTab;

@property (weak, nonatomic) IBOutlet UIView *selectorView;

@property (weak, nonatomic) IBOutlet UIView *incomingLineView;
@property (weak, nonatomic) IBOutlet UIView *outgoingLineView;
@property (weak, nonatomic) IBOutlet UIView *linksLineView;

@property (nonatomic, strong, nullable) MEGAShareList *outgoingShareList;
@property (nonatomic, strong, nullable) MEGAShareList *outgoingUnverifiedShareList;
@property (nonatomic, strong, nullable) NSMutableArray<MEGAShare *> *outgoingUnverifiedSharesMutableArray;
@property (nonatomic, strong, nullable) NSMutableArray<MEGANode *> *outgoingUnverifiedNodesMutableArray;

@property (nonatomic, strong, nullable) MEGAShareList *incomingShareList;
@property (nonatomic, strong, nullable) MEGAShareList *incomingUnverifiedShareList;
@property (nonatomic, strong, nullable) NSMutableArray<MEGAShare *> *incomingUnverifiedSharesMutableArray;
@property (nonatomic, strong, nullable) NSMutableArray<MEGANode *> *incomingUnverifiedNodesMutableArray;

@property (nonatomic) NSMutableArray *searchNodesArray;
@property (nonatomic, strong) NSMutableArray<MEGAShare *> *searchUnverifiedSharesArray;
@property (nonatomic, strong) NSMutableArray<MEGANode *> *searchUnverifiedNodesArray;

@property (nonatomic, strong, nullable) SharedItemsNodeSearcher *nodeSearcher;

@property (nonatomic, strong) NSMutableArray *incomingNodesMutableArray;
@property (nonatomic, strong) NSMutableArray *outgoingNodesMutableArray;
@property (nonatomic, strong) NSArray *publicLinksArray;

@property (strong, nonatomic) SharedItemsViewModel *viewModel;
@property (strong, nonatomic, nullable) TaskOCWrapper *searchTask;

- (void)selectSegment:(NSUInteger)index;
- (void)didTapSelect;
- (void)nodesSortTypeHasChanged;
- (void)setupLabelAndFavouriteForNode:(MEGANode *)node cell:(SharedItemsTableViewCell *)cell;
- (void)configureAccessibilityForCell:(SharedItemsTableViewCell *)cell;
- (void)reloadUI;
- (void)showNodeContextMenu:(UIButton *)sender;
- (void)endEditingMode;
- (void)addSearchBar;
- (void)configToolbarItemsForSharedItems;
- (void)configSearchController;
- (void)showNodeActions:(UIButton *)sender;

@end

NS_ASSUME_NONNULL_END
