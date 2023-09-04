#import "MEGAOperation.h"

NS_ASSUME_NONNULL_BEGIN

@interface MEGAExpirableOperation : MEGAOperation

- (instancetype)initWithExpireTimeInterval:(NSTimeInterval)timeInterval;

@end

NS_ASSUME_NONNULL_END
