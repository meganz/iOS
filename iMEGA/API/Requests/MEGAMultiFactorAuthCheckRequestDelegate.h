
#import "MEGABaseRequestDelegate.h"

@interface MEGAMultiFactorAuthCheckRequestDelegate : MEGABaseRequestDelegate

- (id)init NS_UNAVAILABLE;

- (instancetype)initWithCompletion:(void (^)(MEGARequest *request, MEGAError *error))completion;

@end
