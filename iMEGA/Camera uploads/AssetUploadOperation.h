
#import <UIKit/UIKit.h>
#import "MEGAOperation.h"

NS_ASSUME_NONNULL_BEGIN

@class PHAsset;

@interface AssetUploadOperation : MEGAOperation

- (instancetype)initWithAsset:(PHAsset *)asset cameraUploadNode:(MEGANode *)node;
- (instancetype)initWithLocalIdentifier:(NSString *)localIdentifier cameraUploadNode:(MEGANode *)node;

@end

NS_ASSUME_NONNULL_END
