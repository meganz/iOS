#import <UIKit/UIKit.h>

@class QRSettingsViewModel;

@interface QRSettingsTableViewController : UITableViewController
@property (weak, nonatomic) IBOutlet UIBarButtonItem *closeBarButtonItem;
@property (weak, nonatomic) IBOutlet UILabel *autoAcceptLabel;
@property (weak, nonatomic) IBOutlet UILabel *resetQRCodeLabel;
@property (weak, nonatomic) IBOutlet UISwitch *autoAcceptSwitch;

@property (strong, nonatomic) QRSettingsViewModel *viewModel;
@end
