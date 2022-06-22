#import <UIKit/UIKit.h>

@class MyAvatarManager, ContextMenuManager;

NS_ASSUME_NONNULL_BEGIN

@interface SharedItemsViewController : UIViewController

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *selectAllBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *editBarButtonItem;

@property (weak, nonatomic) IBOutlet UIButton *incomingButton;
@property (weak, nonatomic) IBOutlet UIButton *outgoingButton;
@property (weak, nonatomic) IBOutlet UIButton *linksButton;

@property (nonatomic) MEGASortOrderType sortOrderType;

@property (nonatomic, strong, nullable) MyAvatarManager *myAvatarManager;
@property (nonatomic, strong, nullable) ContextMenuManager * contextMenuManager;
@property (nonatomic, strong) UIBarButtonItem *contextBarButtonItem;

@property (nonatomic) UISearchController *searchController;

- (void)selectSegment:(NSUInteger)index;
- (void)didTapSelect;
- (void)nodesSortTypeHasChanged;

@end

NS_ASSUME_NONNULL_END
