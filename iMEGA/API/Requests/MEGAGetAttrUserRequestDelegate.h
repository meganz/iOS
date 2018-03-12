
#import "MEGABaseRequestDelegate.h"

@interface MEGAGetAttrUserRequestDelegate : MEGABaseRequestDelegate

- (id)init NS_UNAVAILABLE;

- (instancetype)initWithCompletion:(void (^)(MEGARequest *request))completion;

@end
