
#import "CameraUploadOperation.h"

NS_ASSUME_NONNULL_BEGIN

@protocol AssetResourceUploadOperationDelegate <NSObject>

- (void)assetResource:(PHAssetResource *)resource didExportToURL:(NSURL *)URL;

@optional

- (void)assetResource:(PHAssetResource *)resource didFailToExportWithError:(NSError *)error;

@end

@interface AssetResourceUploadOperation : CameraUploadOperation <AssetResourceUploadOperationDelegate>

- (void)exportAssetResource:(PHAssetResource *)resource toURL:(NSURL *)URL;

@end

NS_ASSUME_NONNULL_END
