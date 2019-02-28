
#import "LivePhotoScanner.h"
#import "CameraUploadRecordManager.h"
#import "MOAssetUploadRecord+CoreDataClass.h"
#import "SavedIdentifierParser.h"
#import "CameraUploadManager+Settings.h"

@implementation LivePhotoScanner

- (void)saveInitialLivePhotoRecordsByFetchResult:(PHFetchResult<PHAsset *> *)fetchResult {
    [CameraUploadRecordManager.shared.backgroundContext performBlockAndWait:^{
        SavedIdentifierParser *parser = [[SavedIdentifierParser alloc] init];
        for (PHAsset *asset in fetchResult) {
            if (asset.mediaType == PHAssetMediaTypeImage && asset.mediaSubtypes & PHAssetMediaSubtypePhotoLive) {
                NSString *savedIdentifier = [parser savedIdentifierForLocalIdentifier:asset.localIdentifier mediaSubtype:PHAssetMediaSubtypePhotoLive];
                [self createUploadRecordForAsset:asset additionalMediaSubtype:PHAssetMediaSubtypePhotoLive savedIdentifier:savedIdentifier inContext:CameraUploadRecordManager.shared.backgroundContext];
            }
        }
        
        [CameraUploadRecordManager.shared saveChangesIfNeededWithError:nil];
    }];
}

- (void)saveLivePhotoRecordsIfNeededByAssets:(NSArray<PHAsset *> *)assets {
    [CameraUploadRecordManager.shared.backgroundContext performBlockAndWait:^{
        SavedIdentifierParser *parser = [[SavedIdentifierParser alloc] init];
        for (PHAsset *asset in assets) {
            if (asset.mediaType == PHAssetMediaTypeImage && asset.mediaSubtypes & PHAssetMediaSubtypePhotoLive) {
                NSString *savedIdentifier = [parser savedIdentifierForLocalIdentifier:asset.localIdentifier mediaSubtype:PHAssetMediaSubtypePhotoLive];
                if ([CameraUploadRecordManager.shared fetchUploadRecordsByIdentifier:savedIdentifier shouldPrefetchErrorRecords:NO error:nil].count == 0) {
                    [self createUploadRecordForAsset:asset additionalMediaSubtype:PHAssetMediaSubtypePhotoLive savedIdentifier:savedIdentifier inContext:CameraUploadRecordManager.shared.backgroundContext];
                }
            }
        }
        
        [CameraUploadRecordManager.shared saveChangesIfNeededWithError:nil];
    }];
}

- (void)scanLivePhotosWithCompletion:(void (^)(void))completion {
    [CameraUploadRecordManager.shared.backgroundContext performBlockAndWait:^{
        NSArray<MOAssetUploadRecord *> *photoRecords = [CameraUploadRecordManager.shared fetchUploadRecordsByMediaTypes:@[@(PHAssetMediaTypeImage)] includeAdditionalMediaSubtypes:NO error:nil];
        [CameraUploadRecordManager.shared createAdditionalRecordsIfNeededForRecords:photoRecords withMediaSubtype:PHAssetMediaSubtypePhotoLive];
        [CameraUploadRecordManager.shared saveChangesIfNeededWithError:nil];
    }];
    
    if (completion) {
        completion();
    }
}

- (MOAssetUploadRecord *)createUploadRecordForAsset:(PHAsset *)asset additionalMediaSubtype:(PHAssetMediaSubtype)subtype savedIdentifier:(NSString *)identifier inContext:(NSManagedObjectContext *)context {
    MOAssetUploadRecord *subtypeRecord = [NSEntityDescription insertNewObjectForEntityForName:@"AssetUploadRecord" inManagedObjectContext:context];
    subtypeRecord.localIdentifier = identifier;
    subtypeRecord.status = @(CameraAssetUploadStatusNotStarted);
    subtypeRecord.creationDate = asset.creationDate;
    subtypeRecord.mediaType = @(asset.mediaType);
    subtypeRecord.additionalMediaSubtype = @(subtype);
    return subtypeRecord;
}

@end
