
#import "CameraUploadOperation.h"

NS_ASSUME_NONNULL_BEGIN

@protocol AssetResourcExportDelegate <NSObject>

- (void)assetResource:(PHAssetResource *)resource didExportToURL:(NSURL *)URL;

@optional

- (void)assetResource:(PHAssetResource *)resource didFailToExportWithError:(NSError *)error;

@end

@interface AssetResourceUploadOperation : CameraUploadOperation <AssetResourcExportDelegate>

- (void)exportAssetResource:(PHAssetResource *)resource toURL:(NSURL *)URL;

@end

NS_ASSUME_NONNULL_END
