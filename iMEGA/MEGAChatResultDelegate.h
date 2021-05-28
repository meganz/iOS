#import "MEGAChatDelegate.h"
#import "MEGAChatSdk.h"

NS_ASSUME_NONNULL_BEGIN

@interface MEGAChatResultDelegate : NSObject <MEGAChatDelegate>

- (id)init NS_UNAVAILABLE;

- (instancetype)initWithCompletion:(void (^)(MEGAChatSdk *api, uint64_t chatId , MEGAChatConnection newState))completion;

@end

NS_ASSUME_NONNULL_END
