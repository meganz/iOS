#import <UIKit/UIKit.h>

@class ScheduleMeetingOccurrenceNotification, NotificationsViewModel;

NS_ASSUME_NONNULL_BEGIN

@interface NotificationsTableViewController : UITableViewController

@property (nonatomic) NSArray<ScheduleMeetingOccurrenceNotification *> *scheduleMeetingOccurrenceNotificationList;
@property (nonatomic, strong) NotificationsViewModel *viewModel;

@end

NS_ASSUME_NONNULL_END
