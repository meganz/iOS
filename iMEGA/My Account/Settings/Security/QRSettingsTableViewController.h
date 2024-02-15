#import <UIKit/UIKit.h>

@interface QRSettingsTableViewController : UITableViewController
@property (weak, nonatomic) IBOutlet UIBarButtonItem *closeBarButtonItem;
@property (weak, nonatomic) IBOutlet UILabel *autoAcceptLabel;
@property (weak, nonatomic) IBOutlet UILabel *resetQRCodeLabel;
@property (weak, nonatomic) IBOutlet UISwitch *autoAcceptSwitch;
@end
