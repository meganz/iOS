
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
                [self createLivePhotoRecordForAsset:asset withSavedIdentifier:savedIdentifier inContext:CameraUploadRecordManager.shared.backgroundContext];
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
                    [self createLivePhotoRecordForAsset:asset withSavedIdentifier:savedIdentifier inContext:CameraUploadRecordManager.shared.backgroundContext];
                }
            }
        }
        
        [CameraUploadRecordManager.shared saveChangesIfNeededWithError:nil];
    }];
}

- (void)scanLivePhotosWithCompletion:(void (^)(void))completion {
    [CameraUploadRecordManager.shared.backgroundContext performBlockAndWait:^{
        NSArray<MOAssetUploadRecord *> *livePhotoRecords = [CameraUploadRecordManager.shared fetchUploadRecordsByMediaTypes:@[@(PHAssetMediaTypeImage)] mediaSubtypes:PHAssetMediaSubtypePhotoLive includeAdditionalMediaSubtypes:NO error:nil];
        [CameraUploadRecordManager.shared createAdditionalRecordsIfNeededForRecords:livePhotoRecords withMediaSubtype:PHAssetMediaSubtypePhotoLive];
        [CameraUploadRecordManager.shared saveChangesIfNeededWithError:nil];
    }];
    
    if (completion) {
        completion();
    }
}

- (MOAssetUploadRecord *)createLivePhotoRecordForAsset:(PHAsset *)asset withSavedIdentifier:(NSString *)identifier inContext:(NSManagedObjectContext *)context {
    MOAssetUploadRecord *livePhotoRecord = [NSEntityDescription insertNewObjectForEntityForName:@"AssetUploadRecord" inManagedObjectContext:context];
    livePhotoRecord.localIdentifier = identifier;
    livePhotoRecord.status = @(CameraAssetUploadStatusNotStarted);
    livePhotoRecord.creationDate = asset.creationDate;
    livePhotoRecord.mediaType = @(asset.mediaType);
    livePhotoRecord.mediaSubtypes = @(asset.mediaSubtypes);
    livePhotoRecord.additionalMediaSubtypes = @(PHAssetMediaSubtypePhotoLive);
    return livePhotoRecord;
}

@end
