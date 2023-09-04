#import "MEGARequestDelegate.h"

@interface MEGAMultiFactorAuthCheckRequestDelegate : NSObject <MEGARequestDelegate>

- (id)init NS_UNAVAILABLE;

- (instancetype)initWithCompletion:(void (^)(MEGARequest *request, MEGAError *error))completion;

@end
