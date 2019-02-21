
#import "UploadOperationFactory.h"
#import "AssetUploadInfo.h"
#import "MOAssetUploadRecord+CoreDataClass.h"
#import "LivePhotoUploadOperation.h"
#import "CameraUploadRecordManager.h"
#import "SavedIdentifierParser.h"
#import "MEGAConstants.h"
@import Photos;

@implementation UploadOperationFactory

+ (NSArray<CameraUploadOperation *> *)operationsForUploadRecord:(MOAssetUploadRecord *)uploadRecord parentNode:(MEGANode *)node {
    NSMutableArray<CameraUploadOperation *> *operations = [NSMutableArray array];
    
    NSString *savedIdentifier = [CameraUploadRecordManager.shared savedIdentifierInRecord:uploadRecord];
    AssetIdentifierInfo *identifierInfo = [[[SavedIdentifierParser alloc] init] parseSavedIdentifier:savedIdentifier separator:MEGACameraUploadIdentifierSeparator];
    
    if (identifierInfo.localIdentifier.length == 0) {
        return [operations copy];
    }
    
    PHAsset *asset = [[PHAsset fetchAssetsWithLocalIdentifiers:@[identifierInfo.localIdentifier] options:nil] firstObject];
    if (asset == nil) {
        return [operations copy];
    }
    
    AssetUploadInfo *uploadInfo = [[AssetUploadInfo alloc] initWithAsset:asset savedIdentifier:savedIdentifier parentNode:node];
    CameraUploadOperation *operation = [self operationWithUploadInfo:uploadInfo uploadRecord:uploadRecord savedMediaSubtype:identifierInfo.mediaSubtype];
    if (operation) {
        [operations addObject:operation];
    }
    
    NSArray<CameraUploadOperation *> *subTypeOperations = [self operationsForSavedMediaSubtype:identifierInfo.mediaSubtype asset:asset parentNode:node];
    [operations addObjectsFromArray:subTypeOperations];
    
    return [operations copy];
}

+ (NSArray<CameraUploadOperation *> *)operationsForSavedMediaSubtype:(PHAssetMediaSubtype)savedMediaSubtype asset:(PHAsset *)asset parentNode:(MEGANode *)node {
    NSMutableArray<CameraUploadOperation *> *operations = [NSMutableArray array];
    if (@available(iOS 9.1, *)) {
        if (asset.mediaType == PHAssetMediaTypeImage && savedMediaSubtype == PHAssetMediaSubtypeNone && (asset.mediaSubtypes & PHAssetMediaSubtypePhotoLive)) {
            NSString *mediaSubtypedLocalIdentifier = [@[asset.localIdentifier, [@(PHAssetMediaSubtypePhotoLive) stringValue]] componentsJoinedByString:MEGACameraUploadIdentifierSeparator];
            
            __block CameraUploadOperation *operation;
            [CameraUploadRecordManager.shared.backgroundContext performBlockAndWait:^{
                NSArray *existingRecords = [CameraUploadRecordManager.shared fetchUploadRecordsByLocalIdentifier:mediaSubtypedLocalIdentifier shouldPrefetchErrorRecords:NO error:nil];
                if (existingRecords.count == 0) {
                    NSError *error;
                    MOAssetUploadRecord *record = [CameraUploadRecordManager.shared saveAndQueueUpUploadRecordForAsset:asset withMediaSubtypedLocalIdentifier:mediaSubtypedLocalIdentifier error:&error];
                    if (record && error == nil) {
                        AssetUploadInfo *uploadInfo = [[AssetUploadInfo alloc] initWithAsset:asset savedIdentifier:mediaSubtypedLocalIdentifier parentNode:node];
                        operation = [self operationWithUploadInfo:uploadInfo uploadRecord:record savedMediaSubtype:PHAssetMediaSubtypePhotoLive];
                    }
                }
            }];
            
            if (operation) {
                [operations addObject:operation];
            }
        }
    }
    
    return [operations copy];
}

+ (nullable CameraUploadOperation *)operationWithUploadInfo:(AssetUploadInfo *)uploadInfo uploadRecord:(MOAssetUploadRecord *)uploadRecord savedMediaSubtype:(PHAssetMediaSubtype)mediaSubtype {
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
