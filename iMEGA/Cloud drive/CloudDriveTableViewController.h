#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class CloudDriveViewController;
@interface CloudDriveTableViewController : UIViewController

@property (weak, nonatomic) CloudDriveViewController *cloudDrive;

@property (weak, nonatomic) IBOutlet UITableView *tableView;

- (void)setTableViewEditing:(BOOL)editing animated:(BOOL)animated;
- (void)tableViewSelectIndexPath:(NSIndexPath *)indexPath;

@end

NS_ASSUME_NONNULL_END
