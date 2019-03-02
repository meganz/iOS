
#import "MEGAOperation.h"
#import "MEGASdkManager.h"

NS_ASSUME_NONNULL_BEGIN

@class CLLocation;

@interface CoordinatesUploadOperation : MEGAOperation

- (instancetype)initWithLocation:(CLLocation *)location node:(MEGANode *)node;

@end

NS_ASSUME_NONNULL_END
