#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ArchivedChatRoomsViewController : UIViewController

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (strong, nonatomic) UISearchController *searchController;

- (void)reloadData;

@end

NS_ASSUME_NONNULL_END
