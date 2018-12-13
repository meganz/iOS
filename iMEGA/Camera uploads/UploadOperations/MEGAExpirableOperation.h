
#import "MEGABackgroundTaskOperation.h"

NS_ASSUME_NONNULL_BEGIN

@interface MEGAExpirableOperation : MEGABackgroundTaskOperation

- (instancetype)initWithExpirationTimeInterval:(NSTimeInterval)timeInterval;

@end

NS_ASSUME_NONNULL_END
