#import "MEGARequestDelegate.h"

NS_SWIFT_SENDABLE
@interface MEGALoginRequestDelegate : NSObject <MEGARequestDelegate>

@property (atomic, copy) void (^errorCompletion)(MEGAError *error);

@property (atomic) BOOL confirmAccountInOtherClient;
@property (atomic) BOOL isNewUserRegistration;

@end
