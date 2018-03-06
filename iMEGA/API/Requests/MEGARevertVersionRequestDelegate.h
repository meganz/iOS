
#import "MEGABaseRequestDelegate.h"

@interface MEGARevertVersionRequestDelegate : MEGABaseRequestDelegate

- (instancetype)initWithCompletion:(void (^)(MEGARequest *request))completion;

@end
