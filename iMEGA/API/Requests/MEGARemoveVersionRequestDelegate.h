
#import "MEGABaseRequestDelegate.h"

@interface MEGARemoveVersionRequestDelegate : MEGABaseRequestDelegate

- (instancetype)initWithCompletion:(void (^)(MEGARequest *request))completion;

@end
