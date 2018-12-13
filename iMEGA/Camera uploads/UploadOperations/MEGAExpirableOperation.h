
#import "MEGABackgroundTaskOperation.h"

NS_ASSUME_NONNULL_BEGIN

@interface MEGAExpirableOperation : MEGABackgroundTaskOperation

- (instancetype)initWithExpireTimeInterval:(NSTimeInterval)timeInterval;

@end

NS_ASSUME_NONNULL_END
