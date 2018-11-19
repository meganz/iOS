
#import "MEGAError.h"

NS_ASSUME_NONNULL_BEGIN

@interface MEGAError (MNZCategory)

/**
 Create a NSError object from MEGAError. This is to generalize the MEGAError object to a native error type.

 @return a NSError object
 */
- (NSError *)nativeError;

@end

NS_ASSUME_NONNULL_END
