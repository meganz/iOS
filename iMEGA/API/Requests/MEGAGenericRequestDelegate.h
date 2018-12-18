
#import "MEGABaseRequestDelegate.h"

@interface MEGAGenericRequestDelegate : MEGABaseRequestDelegate

- (id)init NS_UNAVAILABLE;

- (instancetype)initWithRequestCompletion:(void (^)(MEGARequest *request))requestCompletion errorCompletion:(void (^)(MEGARequest *request, MEGAError *error))errorCompletion;

@end
