
#import "MEGABaseRequestDelegate.h"

@interface MEGAGetPreviewRequestDelegate : MEGABaseRequestDelegate

- (instancetype)initWithCompletion:(void (^)(MEGARequest *request))completion;

@end
