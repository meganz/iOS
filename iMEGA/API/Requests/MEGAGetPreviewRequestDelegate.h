#import "MEGARequestDelegate.h"

@interface MEGAGetPreviewRequestDelegate : NSObject <MEGARequestDelegate>

- (instancetype)initWithCompletion:(void (^)(MEGARequest *request))completion;

@end
