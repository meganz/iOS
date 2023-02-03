
#import <UIKit/UIKit.h>

@class ScheduleMeetingOccurrenceNotification;

NS_ASSUME_NONNULL_BEGIN

@interface NotificationsTableViewController : UITableViewController

@property (nonatomic) NSArray<ScheduleMeetingOccurrenceNotification *> *scheduleMeetingOccurrenceNotificationList;

@end

NS_ASSUME_NONNULL_END
