
#import "UploadOperationFactory.h"
#import "AssetUploadInfo.h"
#import "MOAssetUploadRecord+CoreDataClass.h"
@import Photos;

@implementation UploadOperationFactory

+ (CameraUploadOperation *)operationWithUploadRecord:(MOAssetUploadRecord *)uploadRecord parentNode:(MEGANode *)node {
    PHAsset *asset = [[PHAsset fetchAssetsWithLocalIdentifiers:@[[uploadRecord localIdentifier]] options:nil] firstObject];
    if (asset == nil) {
        return nil;
    }

    AssetUploadInfo *uploadInfo = [[AssetUploadInfo alloc] initWithAsset:asset parentNode:node];
    switch (asset.mediaType) {
        case PHAssetMediaTypeImage:
            return [[PhotoUploadOperation alloc] initWithUploadInfo:uploadInfo uploadRecord:uploadRecord];
            break;
        case PHAssetMediaTypeVideo:
            return [[VideoUploadOperation alloc] initWithUploadInfo:uploadInfo uploadRecord:uploadRecord];
            break;
        default:
            return nil;
            break;
    }
}

@end
