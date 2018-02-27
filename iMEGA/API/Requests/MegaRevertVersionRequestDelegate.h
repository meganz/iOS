
#import "MEGABaseRequestDelegate.h"

@interface MegaRevertVersionRequestDelegate : MEGABaseRequestDelegate

- (instancetype)initWithCompletion:(void (^)(MEGARequest *request))completion;

@end
