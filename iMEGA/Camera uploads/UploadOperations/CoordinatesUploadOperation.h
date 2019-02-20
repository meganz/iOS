
#import "MEGABackgroundTaskOperation.h"
#import "MEGASdkManager.h"

NS_ASSUME_NONNULL_BEGIN

@class CLLocation;

@interface CoordinatesUploadOperation : MEGABackgroundTaskOperation

- (instancetype)initWithLocation:(CLLocation *)location node:(MEGANode *)node;

@end

NS_ASSUME_NONNULL_END
