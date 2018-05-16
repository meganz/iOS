
#import "MEGABaseRequestDelegate.h"

@interface MEGAGetPublicNodeRequestDelegate : MEGABaseRequestDelegate

- (id)init NS_UNAVAILABLE;

- (instancetype)initWithCompletion:(void (^)(MEGARequest *request))completion;

@end
