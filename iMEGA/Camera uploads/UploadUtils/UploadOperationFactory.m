
#import "UploadOperationFactory.h"
#import "AssetUploadInfo.h"
#import "MOAssetUploadRecord+CoreDataClass.h"
#import "LivePhotoUploadOperation.h"
#import "CameraUploadRecordManager.h"
@import Photos;

@implementation UploadOperationFactory

+ (CameraUploadOperation *)operationWithUploadRecord:(MOAssetUploadRecord *)uploadRecord parentNode:(MEGANode *)node identifierSeparator:(NSString *)identifierSeparator savedMediaSubtype:(PHAssetMediaSubtype *)savedMediaSubtype {
    NSString *savedIdentifier = [CameraUploadRecordManager.shared savedIdentifierInRecord:uploadRecord];
    
    NSString *localIdentifier;
    PHAssetMediaSubtype mediaSubtype = PHAssetMediaSubtypeNone;
    NSArray<NSString *> *separatedStrings = [savedIdentifier componentsSeparatedByString:identifierSeparator];
    if (separatedStrings.count == 0) {
        return nil;
    } else if (separatedStrings.count == 1) {
        localIdentifier = [separatedStrings firstObject];
    } else if (separatedStrings.count == 2) {
        localIdentifier = [separatedStrings firstObject];
        mediaSubtype = (PHAssetMediaSubtype)[separatedStrings[1] integerValue];
    } else {
        NSString *subTypeString = [separatedStrings lastObject];
        mediaSubtype = (PHAssetMediaSubtype)[subTypeString integerValue];
        NSRange identifierRange = NSMakeRange(0, savedIdentifier.length - subTypeString.length - identifierSeparator.length);
        localIdentifier = [savedIdentifier substringWithRange:identifierRange];
    }
    
    if (localIdentifier.length == 0) {
        return nil;
    }
    
    PHAsset *asset = [[PHAsset fetchAssetsWithLocalIdentifiers:@[localIdentifier] options:nil] firstObject];
    if (asset == nil) {
        return nil;
    }

    *savedMediaSubtype = mediaSubtype;
    AssetUploadInfo *uploadInfo = [[AssetUploadInfo alloc] initWithAsset:asset parentNode:node];
    uploadInfo.savedRecordLocalIdentifier = savedIdentifier;
    switch (asset.mediaType) {
        case PHAssetMediaTypeImage:
            if (mediaSubtype == PHAssetMediaSubtypePhotoLive) {
                return [[LivePhotoUploadOperation alloc] initWithUploadInfo:uploadInfo uploadRecord:uploadRecord];
            } else {
                return [[PhotoUploadOperation alloc] initWithUploadInfo:uploadInfo uploadRecord:uploadRecord];
            }
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
