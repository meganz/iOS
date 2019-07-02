
#import "MEGAError.h"

NS_ASSUME_NONNULL_BEGIN

@interface MEGAError (MNZCategory)

/**
 This is to generalize the MEGAError object to a native error type.
 */
@property (readonly) NSError *nativeError;

@end

NS_ASSUME_NONNULL_END
