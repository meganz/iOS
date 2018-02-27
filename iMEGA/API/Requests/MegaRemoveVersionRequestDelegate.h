
#import "MEGABaseRequestDelegate.h"

@interface MegaRemoveVersionRequestDelegate : MEGABaseRequestDelegate

- (instancetype)initWithCompletion:(void (^)(MEGARequest *request))completion;

@end
