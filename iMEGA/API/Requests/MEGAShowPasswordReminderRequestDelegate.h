#import "MEGARequestDelegate.h"

@interface MEGAShowPasswordReminderRequestDelegate : NSObject <MEGARequestDelegate>

- (id)init NS_UNAVAILABLE;

- (instancetype)initToLogout:(BOOL)logout;

@end
