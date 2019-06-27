
#import <UIKit/UIKit.h>

@class CloudDriveViewController;

@interface RecentsViewController : UIViewController

@property (nonatomic, strong) CloudDriveViewController *cloudDrive;

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end
