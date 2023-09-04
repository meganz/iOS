#import "MEGARequestDelegate.h"

@interface MEGACreateAccountRequestDelegate : NSObject <MEGARequestDelegate>

- (instancetype)initWithCompletion:(void (^)(MEGAError *error))completion;

@property (nonatomic) BOOL resumeCreateAccount;

@end
