
#import "MEGABaseRequestDelegate.h"

@interface MEGACreateAccountRequestDelegate : MEGABaseRequestDelegate

- (instancetype)initWithCompletion:(void (^)(void))completion;

@property (nonatomic) BOOL resumeCreateAccount;

@end
