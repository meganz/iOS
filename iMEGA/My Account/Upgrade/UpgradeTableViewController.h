#import <UIKit/UIKit.h>

@interface UpgradeTableViewController : UIViewController

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, getter=isChoosingTheAccountType) BOOL chooseAccountType;

@end
