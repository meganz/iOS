
#import "MEGABaseRequestDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@interface MEGAGenericRequestDelegate : MEGABaseRequestDelegate

- (id)init NS_UNAVAILABLE;

- (instancetype)initWithCompletion:(void (^)(MEGARequest *request, MEGAError *error))completion;

@end

NS_ASSUME_NONNULL_END
