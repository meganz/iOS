
#import "UploadOperationFactory.h"
#import "AssetUploadInfo.h"
@import Photos;

@implementation UploadOperationFactory

+ (CameraUploadOperation *)operationWithLocalIdentifier:(NSString *)identifier parentNode:(MEGANode *)node {
    PHAsset *asset = [[PHAsset fetchAssetsWithLocalIdentifiers:@[identifier] options:nil] firstObject];
    AssetUploadInfo *uploadInfo = [[AssetUploadInfo alloc] initWithAsset:asset parentNode:node];
    switch (asset.mediaType) {
        case PHAssetMediaTypeImage:
            return [[PhotoUploadOperation alloc] initWithUploadInfo:uploadInfo];
            break;
        case PHAssetMediaTypeVideo:
            return [[VideoUploadOperation alloc] initWithUploadInfo:uploadInfo];
            break;
        default:
            return nil;
            break;
    }
}

@end
