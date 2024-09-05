#import <UIKit/UIKit.h>

@class UpgradeAccountViewModel;

@interface UpgradeTableViewController : UIViewController

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *currentPlanStorageLabel;
@property (weak, nonatomic) IBOutlet UILabel *currentPlanBandwidthLabel;
@property (nonatomic, getter=isChoosingTheAccountType) BOOL chooseAccountType;
@property (strong, nonatomic) NSNumber *accountBaseStorage;
@property (strong, nonatomic) UpgradeAccountViewModel *viewModel;
@property (strong, nonatomic) NSMutableArray *proLevelsMutableArray;

@end
