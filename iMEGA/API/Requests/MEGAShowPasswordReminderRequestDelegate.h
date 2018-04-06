
#import "MEGABaseRequestDelegate.h"

@interface MEGAShowPasswordReminderRequestDelegate : MEGABaseRequestDelegate

- (id)init NS_UNAVAILABLE;

- (instancetype)initToLogout:(BOOL)logout;

@end
