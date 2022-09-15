#import <UIKit/UIKit.h>

@class MEGAChatPresenceConfig;

@interface ChatStatusTableViewController : UITableViewController

@property (nonatomic) MEGAChatPresenceConfig *presenceConfig;
@property (nonatomic) NSInteger autoAwayTimeoutInMinutes;
@property (nonatomic) BOOL isSelectingTimeout;
@property (weak, nonatomic) NSIndexPath *currentStatusIndexPath;

@property (weak, nonatomic) IBOutlet UITableViewCell *timeoutAutoAwayCell;
@property (weak, nonatomic) IBOutlet UIPickerView *autoAwayTimePicker;
@property (weak, nonatomic) IBOutlet UIButton *autoAwayTimeSaveButton;
@property (weak, nonatomic) IBOutlet UILabel *timeoutAutoAwayLabel;

- (void)setPresenceAutoAway:(BOOL)boolValue;

@end
