
#import <UIKit/UIKit.h>
#import "MEGAOperation.h"

NS_ASSUME_NONNULL_BEGIN

@class PHAsset;

@interface AssetUploadOperation : MEGAOperation

- (instancetype)initWithAsset:(PHAsset *)asset;
- (instancetype)initWithLocalIdentifier:(NSString *)localIdentifier;

@end

NS_ASSUME_NONNULL_END
