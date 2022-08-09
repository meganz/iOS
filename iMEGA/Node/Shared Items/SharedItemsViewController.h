#import <UIKit/UIKit.h>

@class MyAvatarManager, ContextMenuManager, MEGAVerticalButton;

NS_ASSUME_NONNULL_BEGIN

@interface SharedItemsViewController : UIViewController

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *selectAllBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *editBarButtonItem;

@property (weak, nonatomic) IBOutlet MEGAVerticalButton *incomingButton;
@property (weak, nonatomic) IBOutlet MEGAVerticalButton *outgoingButton;
@property (weak, nonatomic) IBOutlet MEGAVerticalButton *linksButton;

@property (nonatomic) MEGASortOrderType sortOrderType;

@property (nonatomic, strong, nullable) MyAvatarManager *myAvatarManager;
@property (nonatomic, strong, nullable) ContextMenuManager * contextMenuManager;
@property (nonatomic, strong) UIBarButtonItem *contextBarButtonItem;

@property (nonatomic) UISearchController *searchController;

@property (weak, nonatomic) IBOutlet UIView *selectorView;

@property (weak, nonatomic) IBOutlet UIView *incomingLineView;
@property (weak, nonatomic) IBOutlet UIView *outgoingLineView;
@property (weak, nonatomic) IBOutlet UIView *linksLineView;

- (void)selectSegment:(NSUInteger)index;
- (void)didTapSelect;
- (void)nodesSortTypeHasChanged;

@end

NS_ASSUME_NONNULL_END
