#import <UIKit/UIKit.h>

@class UpgradeAccountViewModel;

@interface UpgradeTableViewController : UIViewController

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, getter=isChoosingTheAccountType) BOOL chooseAccountType;
@property (strong, nonatomic) UpgradeAccountViewModel *viewModel;
@property (strong, nonatomic) NSMutableArray *proLevelsMutableArray;

@end
