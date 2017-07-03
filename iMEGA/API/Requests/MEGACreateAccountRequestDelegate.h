
#import "MEGABaseRequestDelegate.h"

@interface MEGACreateAccountRequestDelegate : MEGABaseRequestDelegate

- (instancetype)initWithCompletion:(void (^)(MEGAError *error))completion;

@property (nonatomic) BOOL resumeCreateAccount;

@end
