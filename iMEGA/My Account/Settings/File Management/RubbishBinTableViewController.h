#import <UIKit/UIKit.h>

@interface RubbishBinTableViewController : UITableViewController

@property (weak, nonatomic) IBOutlet UILabel *clearRubbishBinLabel;
@property (weak, nonatomic) IBOutlet UILabel *clearRubbishBinDetailLabel;

@property (weak, nonatomic) IBOutlet UILabel *rubbishBinCleaningSchedulerLabel;

@property (weak, nonatomic) IBOutlet UILabel *removeFilesOlderThanLabel;
@property (weak, nonatomic) IBOutlet UILabel *removeFilesOlderThanDetailLabel;

- (void)setupTableViewHeaderAndFooter;

@end
