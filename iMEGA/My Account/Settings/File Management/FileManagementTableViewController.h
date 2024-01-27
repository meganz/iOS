#import <UIKit/UIKit.h>

@interface FileManagementTableViewController : UITableViewController

@property (weak, nonatomic) IBOutlet UILabel *clearOfflineFilesLabel;
@property (weak, nonatomic) IBOutlet UILabel *clearCacheLabel;

@property (weak, nonatomic) IBOutlet UILabel *rubbishBinLabel;

@property (weak, nonatomic) IBOutlet UILabel *fileVersioningLabel;
@property (weak, nonatomic) IBOutlet UILabel *fileVersioningDetail;

@property (weak, nonatomic) IBOutlet UILabel *useMobileDataLabel;
@property (weak, nonatomic) IBOutlet UISwitch *useMobileDataSwitch;

@end
