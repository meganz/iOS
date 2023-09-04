#import "MEGARequestDelegate.h"

@interface MEGAContactLinkQueryRequestDelegate : NSObject <MEGARequestDelegate>

- (id)init NS_UNAVAILABLE;

- (instancetype)initWithCompletion:(void (^)(MEGARequest *request))completion onError:(void (^)(MEGAError *error))onError;

@end
