#import <UIKit/UIKit.h>

@interface ChatSettingsTableViewController : UITableViewController

@property (nonatomic, assign, getter=isComingfromEmptyState) BOOL comingFromEmptyState;

- (void)enableChatWithSession;

@end
