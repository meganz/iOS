#import "MEGARequestDelegate.h"

@interface MEGALoginRequestDelegate : NSObject <MEGARequestDelegate>

@property (nonatomic, copy) void (^errorCompletion)(MEGAError *error);

@property (nonatomic) BOOL confirmAccountInOtherClient;

@end
