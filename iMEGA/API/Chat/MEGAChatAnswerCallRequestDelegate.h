#import "MEGAChatBaseRequestDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@interface MEGAChatAnswerCallRequestDelegate : MEGAChatBaseRequestDelegate

@property (nonatomic, readonly) void (^completion)(MEGAChatError *error);

- (id)init NS_UNAVAILABLE;

- (instancetype)initWithCompletion:(void (^)(MEGAChatError *error))completion;

@end

NS_ASSUME_NONNULL_END
