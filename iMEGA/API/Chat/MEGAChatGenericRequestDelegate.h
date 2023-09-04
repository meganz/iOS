#import "MEGAChatBaseRequestDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@interface MEGAChatGenericRequestDelegate : MEGAChatBaseRequestDelegate

- (id)init NS_UNAVAILABLE;

- (instancetype)initWithCompletion:(void (^)(MEGAChatRequest *request, MEGAChatError *error))completion;

@end

NS_ASSUME_NONNULL_END
