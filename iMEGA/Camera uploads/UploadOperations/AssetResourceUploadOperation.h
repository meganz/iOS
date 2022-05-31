
#import "CameraUploadOperation.h"

NS_ASSUME_NONNULL_BEGIN

@protocol AssetResourcExportDelegate <NSObject>

- (void)assetResource:(PHAssetResource *)resource didExportToURL:(NSURL *)URL;

@end

@interface AssetResourceUploadOperation : CameraUploadOperation

- (void)exportAssetResource:(PHAssetResource *)resource toURL:(NSURL *)URL delegate:(id<AssetResourcExportDelegate>)delegate;

@end

NS_ASSUME_NONNULL_END
