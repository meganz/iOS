
#import "MEGABaseRequestDelegate.h"

@interface MEGAGetThumbnailRequestDelegate : MEGABaseRequestDelegate

- (instancetype)initWithCompletion:(void (^)(MEGARequest *request))completion;

@end
