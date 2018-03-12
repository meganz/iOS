
#import "MEGABaseRequestDelegate.h"

@interface MEGAContactLinkCreateRequestDelegate : MEGABaseRequestDelegate

- (id)init NS_UNAVAILABLE;

- (instancetype)initWithCompletion:(void (^)(MEGARequest *request))completion;

@end
