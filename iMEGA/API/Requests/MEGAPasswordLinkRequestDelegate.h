
#import "MEGABaseRequestDelegate.h"

@interface MEGAPasswordLinkRequestDelegate : MEGABaseRequestDelegate

- (instancetype)initWithCompletion:(void (^)(MEGARequest *request))completion multipleLinks:(BOOL)multipleLinks;

@end
