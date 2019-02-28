
#import "UploadOperationFactory.h"
#import "AssetUploadInfo.h"
#import "MOAssetUploadRecord+CoreDataClass.h"
#import "LivePhotoUploadOperation.h"
#import "CameraUploadRecordManager.h"
#import "SavedIdentifierParser.h"
#import "MEGAConstants.h"
@import Photos;

@implementation UploadOperationFactory

+ (CameraUploadOperation *)operationForUploadRecord:(MOAssetUploadRecord *)uploadRecord parentNode:(MEGANode *)node {
    NSString *savedIdentifier = [CameraUploadRecordManager.shared savedIdentifierInRecord:uploadRecord];
    AssetIdentifierInfo *identifierInfo = [[[SavedIdentifierParser alloc] init] parseSavedIdentifier:savedIdentifier];
    
    if (identifierInfo.localIdentifier.length == 0) {
        return nil;
    }
    
    PHAsset *asset = [[PHAsset fetchAssetsWithLocalIdentifiers:@[identifierInfo.localIdentifier] options:nil] firstObject];
    AssetUploadInfo *uploadInfo = [[AssetUploadInfo alloc] initWithAsset:asset savedIdentifier:savedIdentifier parentNode:node];
    return [self operationWithUploadInfo:uploadInfo uploadRecord:uploadRecord additionalMediaSubtype:identifierInfo.mediaSubtype];
}

+ (nullable CameraUploadOperation *)operationWithUploadInfo:(AssetUploadInfo *)uploadInfo uploadRecord:(MOAssetUploadRecord *)uploadRecord additionalMediaSubtype:(PHAssetMediaSubtype)mediaSubtype {
    CameraUploadOperation *operation;
    switch (uploadInfo.asset.mediaType) {
        case PHAssetMediaTypeImage:
            if (mediaSubtype & PHAssetMediaSubtypePhotoLive) {
                operation = [[LivePhotoUploadOperation alloc] initWithUploadInfo:uploadInfo uploadRecord:uploadRecord];
            } else {
                operation = [[PhotoUploadOperation alloc] initWithUploadInfo:uploadInfo uploadRecord:uploadRecord];
            }
            break;
        case PHAssetMediaTypeVideo:
            operation = [[VideoUploadOperation alloc] initWithUploadInfo:uploadInfo uploadRecord:uploadRecord];
            break;
        default:
            break;
    }
    
    return operation;
}

@end
