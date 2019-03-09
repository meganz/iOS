
#import "LivePhotoScanner.h"
#import "CameraUploadRecordManager.h"
#import "MOAssetUploadRecord+CoreDataClass.h"
#import "SavedIdentifierParser.h"
#import "CameraUploadManager+Settings.h"
#import "PHAsset+CameraUpload.h"
#import "PHFetchResult+CameraUpload.h"
#import "MEGAConstants.h"

@implementation LivePhotoScanner

- (void)saveInitialLivePhotoRecordsInFetchResult:(PHFetchResult<PHAsset *> *)fetchResult {
    [CameraUploadRecordManager.shared.backgroundContext performBlockAndWait:^{
        SavedIdentifierParser *parser = [[SavedIdentifierParser alloc] init];
        for (PHAsset *asset in fetchResult) {
            if (asset.mnz_isLivePhoto) {
                NSString *parsedIdentifier = [parser savedIdentifierForLocalIdentifier:asset.localIdentifier mediaSubtype:PHAssetMediaSubtypePhotoLive];
                [self createLivePhotoRecordForAsset:asset inContext:CameraUploadRecordManager.shared.backgroundContext withParsedIdentifier:parsedIdentifier];
            }
        }
        
        [CameraUploadRecordManager.shared saveChangesIfNeededWithError:nil];
    }];
}

- (void)scanLivePhotosInAssets:(NSArray<PHAsset *> *)assets {
    [CameraUploadRecordManager.shared.backgroundContext performBlockAndWait:^{
        SavedIdentifierParser *parser = [[SavedIdentifierParser alloc] init];
        for (PHAsset *asset in assets) {
            [self createLivePhotoRecordIfNeededForAsset:asset inContext:CameraUploadRecordManager.shared.backgroundContext withIdentifierParser:parser];
        }
        
        [CameraUploadRecordManager.shared saveChangesIfNeededWithError:nil];
    }];
}

- (void)scanLivePhotosInFetchResult:(PHFetchResult<PHAsset *> *)result {
    [CameraUploadRecordManager.shared.backgroundContext performBlockAndWait:^{
        NSArray<MOAssetUploadRecord *> *livePhotoRecords = [CameraUploadRecordManager.shared fetchUploadRecordsByMediaTypes:@[@(PHAssetMediaTypeImage)] additionalMediaSubtypes:PHAssetMediaSubtypePhotoLive error:nil];
        MEGALogDebug(@"[Camera Upload] saved live photo record count %lu", (unsigned long)livePhotoRecords.count);
        
        NSArray<PHAsset *> *newAssets = [result findNewLivePhotoAssetsByUploadRecords:livePhotoRecords];
        MEGALogDebug(@"[Camera Upload] new live photo assets scanned count %lu", (unsigned long)newAssets.count);
        
        if (newAssets.count > 0) {
            SavedIdentifierParser *parser = [[SavedIdentifierParser alloc] init];
            for (PHAsset *asset in newAssets) {
                NSString *parsedIdentifier = [parser savedIdentifierForLocalIdentifier:asset.localIdentifier mediaSubtype:PHAssetMediaSubtypePhotoLive];
                [self createLivePhotoRecordForAsset:asset inContext:CameraUploadRecordManager.shared.backgroundContext withParsedIdentifier:parsedIdentifier];
            }
            
            [CameraUploadRecordManager.shared saveChangesIfNeededWithError:nil];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [NSNotificationCenter.defaultCenter postNotificationName:MEGACameraUploadStatsChangedNotificationName object:nil];
            });
        }
    }];
}

- (MOAssetUploadRecord *)createLivePhotoRecordIfNeededForAsset:(PHAsset *)asset inContext:(NSManagedObjectContext *)context withIdentifierParser:(SavedIdentifierParser *)parser {
    MOAssetUploadRecord *livePhotoRecord;
    if (asset.mnz_isLivePhoto) {
        NSString *parsedIdentifier = [parser savedIdentifierForLocalIdentifier:asset.localIdentifier mediaSubtype:PHAssetMediaSubtypePhotoLive];
        if ([CameraUploadRecordManager.shared fetchUploadRecordsByIdentifier:parsedIdentifier shouldPrefetchErrorRecords:NO error:nil].count == 0) {
            livePhotoRecord = [self createLivePhotoRecordForAsset:asset inContext:context withParsedIdentifier:parsedIdentifier];
        }
    }
    
    return livePhotoRecord;
}

- (MOAssetUploadRecord *)createLivePhotoRecordForAsset:(PHAsset *)asset inContext:(NSManagedObjectContext *)context withParsedIdentifier:(NSString *)parsedIdentifier {
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
