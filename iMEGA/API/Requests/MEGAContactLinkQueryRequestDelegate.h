
#import "MEGABaseRequestDelegate.h"

@interface MEGAContactLinkQueryRequestDelegate : MEGABaseRequestDelegate

- (id)init NS_UNAVAILABLE;

- (instancetype)initWithCompletion:(void (^)(MEGARequest *request))completion onError:(void (^)(MEGAError *error))onError;

@end
