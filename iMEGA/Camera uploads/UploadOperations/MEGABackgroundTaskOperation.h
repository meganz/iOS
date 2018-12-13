
#import "MEGAOperation.h"

NS_ASSUME_NONNULL_BEGIN

@interface MEGABackgroundTaskOperation : MEGAOperation

- (void)beginBackgroundTaskWithExpirationHandler:(nullable void (^)(void))handler;

@end

NS_ASSUME_NONNULL_END
