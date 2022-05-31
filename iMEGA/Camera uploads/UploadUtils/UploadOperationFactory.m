
#import "UploadOperationFactory.h"
#import "AssetUploadInfo.h"
#import "LivePhotoUploadOperation.h"
#import "CameraUploadRecordManager.h"
#import "SavedIdentifierParser.h"
#import "PHFetchOptions+CameraUpload.h"
#import "NSError+CameraUpload.h"
#import "CameraUploadManager+Settings.h"
#import "MEGA-Swift.h"
@import Photos;

@implementation UploadOperationFactory

+ (CameraUploadOperation *)operationForUploadRecord:(MOAssetUploadRecord *)uploadRecord parentNode:(MEGANode *)node error:(NSError * _Nullable __autoreleasing * _Nullable)error {
    NSString *savedIdentifier = [CameraUploadRecordManager.shared savedIdentifierInRecord:uploadRecord];
    MEGALogDebug(@"[Camera Upload] prepare to queue up %@", savedIdentifier);
    AssetIdentifierInfo *identifierInfo = [[[SavedIdentifierParser alloc] init] parseSavedIdentifier:savedIdentifier];
    
    if (identifierInfo.localIdentifier.length == 0) {
        if (error != NULL) {
            *error = [NSError mnz_cameraUploadEmptyLocalIdentifierError];
        }
        
        return nil;
    }
    
    PHAsset *asset = [[PHAsset fetchAssetsWithLocalIdentifiers:@[identifierInfo.localIdentifier] options:[PHFetchOptions mnz_fetchOptionsForCameraUpload]] firstObject];
    if (asset == nil) {
        if (error != NULL) {
            *error = [NSError mnz_cameraUploadNoMediaAssetFetchedWithIdentifier:identifierInfo.localIdentifier];
        }
        
        return nil;
    }
    
    CameraUploadOperation *operation;
    AssetUploadInfo *uploadInfo = [[AssetUploadInfo alloc] initWithAsset:asset savedIdentifier:savedIdentifier parentNode:node];
    switch (uploadInfo.asset.mediaType) {
        case PHAssetMediaTypeImage:
            if (identifierInfo.mediaSubtype & PHAssetMediaSubtypePhotoLive) {
                if (CameraUploadManager.shouldScanLivePhotosForVideos) {
                    operation = [[LivePhotoUploadOperation alloc] initWithUploadInfo:uploadInfo uploadRecord:uploadRecord];
                } else {
                    if (error != NULL) {
                        *error = [NSError mnz_cameraUploadDisabledMediaSubtype:identifierInfo.mediaSubtype];
                    }
                }
            } else if (uploadInfo.asset.mnz_isRawImage) {
                operation = [[RawPhotoUploadOperation alloc] initWithUploadInfo:uploadInfo uploadRecord:uploadRecord];
            } else {
                operation = [[PhotoUploadOperation alloc] initWithUploadInfo:uploadInfo uploadRecord:uploadRecord];
            }
            break;
        case PHAssetMediaTypeVideo:
            operation = [[VideoUploadOperation alloc] initWithUploadInfo:uploadInfo uploadRecord:uploadRecord];
            break;
        default:
            if (error != NULL) {
                *error = [NSError mnz_cameraUploadUnknownMediaType:uploadInfo.asset.mediaType];
            }
            break;
    }
    
    return operation;
}

@end
