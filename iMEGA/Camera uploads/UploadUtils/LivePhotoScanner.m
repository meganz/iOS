
#import "LivePhotoScanner.h"
#import "CameraUploadRecordManager.h"
#import "SavedIdentifierParser.h"
#import "PHFetchResult+CameraUpload.h"
#import "PHFetchOptions+CameraUpload.h"
#import "MEGA-Swift.h"

@implementation LivePhotoScanner

- (BOOL)saveInitialLivePhotoRecordsInFetchResult:(PHFetchResult<PHAsset *> *)fetchResult error:(NSError * _Nullable __autoreleasing * _Nullable)error {
    __block NSError *coreDataError = nil;
    [CameraUploadRecordManager.shared.backgroundContext performBlockAndWait:^{
        SavedIdentifierParser *parser = [[SavedIdentifierParser alloc] init];
        for (PHAsset *asset in fetchResult) {
            if (asset.mnz_isLivePhoto) {
                NSString *parsedIdentifier = [parser savedIdentifierForLocalIdentifier:asset.localIdentifier mediaSubtype:PHAssetMediaSubtypePhotoLive];
                [self createLivePhotoRecordForAsset:asset inContext:CameraUploadRecordManager.shared.backgroundContext withParsedIdentifier:parsedIdentifier];
            }
        }
        
        [CameraUploadRecordManager.shared saveChangesIfNeededWithError:&coreDataError];
    }];
    
    if (error != NULL) {
        *error = coreDataError;
    }
    
    return coreDataError == nil;
}

- (void)scanLivePhotosInAssets:(NSArray<PHAsset *> *)assets {
    [CameraUploadRecordManager.shared.backgroundContext performBlockAndWait:^{
        SavedIdentifierParser *parser = [[SavedIdentifierParser alloc] init];
        for (PHAsset *asset in assets) {
            [self insertLivePhotoRecordIfNeededForAsset:asset inContext:CameraUploadRecordManager.shared.backgroundContext withIdentifierParser:parser];
        }
        
        [CameraUploadRecordManager.shared saveChangesIfNeededWithError:nil];
    }];
}

- (BOOL)scanLivePhotosWithError:(NSError * _Nullable __autoreleasing * _Nullable)error {
    PHFetchResult *livePhotoFetchResult = [PHAsset fetchAssetsWithOptions:[PHFetchOptions mnz_fetchOptionsForLivePhoto]];
    if (livePhotoFetchResult.count == 0) {
        return YES;
    }

    __block NSError *coreDataError = nil;
    [CameraUploadRecordManager.shared.backgroundContext performBlockAndWait:^{
        NSArray<MOAssetUploadRecord *> *livePhotoRecords = [CameraUploadRecordManager.shared fetchUploadRecordsByMediaTypes:@[@(PHAssetMediaTypeImage)] additionalMediaSubtypes:PHAssetMediaSubtypePhotoLive error:&coreDataError];
        if (coreDataError) {
            return;
        }
        MEGALogDebug(@"[Camera Upload] saved live photo record count %lu", (unsigned long)livePhotoRecords.count);
        if (livePhotoRecords.count == 0) {
            [self saveInitialLivePhotoRecordsInFetchResult:livePhotoFetchResult error:&coreDataError];
        } else {
            NSArray<PHAsset *> *newAssets = [livePhotoFetchResult findNewLivePhotoAssetsInUploadRecords:livePhotoRecords];
            MEGALogDebug(@"[Camera Upload] new live photo assets scanned count %lu", (unsigned long)newAssets.count);
            if (newAssets.count > 0) {
                SavedIdentifierParser *parser = [[SavedIdentifierParser alloc] init];
                for (PHAsset *asset in newAssets) {
                    NSString *parsedIdentifier = [parser savedIdentifierForLocalIdentifier:asset.localIdentifier mediaSubtype:PHAssetMediaSubtypePhotoLive];
                    [self createLivePhotoRecordForAsset:asset inContext:CameraUploadRecordManager.shared.backgroundContext withParsedIdentifier:parsedIdentifier];
                }
                
                [CameraUploadRecordManager.shared saveChangesIfNeededWithError:&coreDataError];
                
                [NSNotificationCenter.defaultCenter postNotificationName:MEGACameraUploadStatsChangedNotification object:nil];
            }
        }
    }];
    
    if (error != NULL) {
        *error = coreDataError;
    }
    
    return coreDataError == nil;
}

- (void)insertLivePhotoRecordIfNeededForAsset:(PHAsset *)asset inContext:(NSManagedObjectContext *)context withIdentifierParser:(SavedIdentifierParser *)parser {
    MOAssetUploadRecord *livePhotoRecord;
    if (asset.mnz_isLivePhoto) {
        NSString *parsedIdentifier = [parser savedIdentifierForLocalIdentifier:asset.localIdentifier mediaSubtype:PHAssetMediaSubtypePhotoLive];
        NSError *error;
        BOOL hasExistingRecord = [CameraUploadRecordManager.shared fetchUploadRecordsByIdentifier:parsedIdentifier shouldPrefetchErrorRecords:NO error:&error].count > 0;
        if (error) {
            MEGALogError(@"[Camera Upload] error when to fetch record by identifier %@ %@", parsedIdentifier, error);
        } else if (!hasExistingRecord ) {
            livePhotoRecord = [self createLivePhotoRecordForAsset:asset inContext:context withParsedIdentifier:parsedIdentifier];
        }
    }
}

- (MOAssetUploadRecord *)createLivePhotoRecordForAsset:(PHAsset *)asset inContext:(NSManagedObjectContext *)context withParsedIdentifier:(NSString *)parsedIdentifier {
    if (context == nil) return nil;
    
    MOAssetUploadRecord *livePhotoRecord = [NSEntityDescription insertNewObjectForEntityForName:@"AssetUploadRecord" inManagedObjectContext:context];
    livePhotoRecord.localIdentifier = parsedIdentifier;
    livePhotoRecord.status = @(CameraAssetUploadStatusNotStarted);
    livePhotoRecord.creationDate = asset.creationDate;
    livePhotoRecord.mediaType = @(asset.mediaType);
    livePhotoRecord.mediaSubtypes = @(asset.mediaSubtypes);
    livePhotoRecord.additionalMediaSubtypes = @(PHAssetMediaSubtypePhotoLive);
    return livePhotoRecord;
}

@end
