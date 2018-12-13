
#import "MEGAOperation.h"

NS_ASSUME_NONNULL_BEGIN

@interface MEGABackgroundTaskOperation : MEGAOperation

- (instancetype)initWithBackgroundTaskExpirationHandler:(nullable void (^)(void))expirationHandler;

@end

NS_ASSUME_NONNULL_END
