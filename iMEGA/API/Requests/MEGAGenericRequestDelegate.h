
#import "MEGABaseRequestDelegate.h"

@interface MEGAGenericRequestDelegate : MEGABaseRequestDelegate

- (id)init NS_UNAVAILABLE;

- (instancetype)initWithCompletion:(void (^)(MEGARequest *request, MEGAError *error))completion;

@end
