
#import "MEGAExpirableOperation.h"
#import "MEGASdkManager.h"

NS_ASSUME_NONNULL_BEGIN

@class CLLocation;

@interface CoordinatesUploadOperation : MEGAExpirableOperation

- (instancetype)initWithLocation:(CLLocation *)location node:(MEGANode *)node expiresAfterTimeInterval:(NSTimeInterval)timeInterval;

@end

NS_ASSUME_NONNULL_END
