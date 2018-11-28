
#import "MEGATaskOperation.h"

NS_ASSUME_NONNULL_BEGIN

@interface MEGAExpirableOperation : MEGATaskOperation

- (instancetype)initWithExpireTimeInterval:(NSTimeInterval)timeInterval;

@end

NS_ASSUME_NONNULL_END
