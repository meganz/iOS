
#import "CameraScanner.h"
#import "CameraUploadRecordManager.h"
#import "MOAssetUploadRecord+CoreDataClass.h"
#import "CameraUploadManager.h"
#import "SavedIdentifierParser.h"
#import "CameraUploadManager+Settings.h"
#import "LivePhotoScanner.h"
#import "PHFetchOptions+CameraUpload.h"
#import "PHFetchResult+CameraUpload.h"
#import "MEGAConstants.h"

@interface CameraScanner () <PHPhotoLibraryChangeObserver>

@property (strong, nonatomic) NSOperationQueue *operationQueue;
@property (strong, nonatomic) PHFetchResult<PHAsset *> *fetchResult;
@property (strong, nonatomic) LivePhotoScanner *livePhotoScanner;

@end

@implementation CameraScanner

- (instancetype)init {
    self = [super init];
    if (self) {
        _operationQueue = [[NSOperationQueue alloc] init];
        _operationQueue.maxConcurrentOperationCount = 1;
        _operationQueue.qualityOfService = NSQualityOfServiceBackground;
        _livePhotoScanner = [[LivePhotoScanner alloc] init];
    }
    return self;
}

- (void)dealloc {
    [self unobservePhotoLibraryChanges];
}

#pragma mark - scan camera rolls

- (void)scanMediaTypes:(NSArray<NSNumber *> *)mediaTypes completion:(void (^)(NSError * _Nullable))completion {
    [self.operationQueue addOperationWithBlock:^{
        MEGALogDebug(@"[Camera Upload] Start local album scanning for media types %@", mediaTypes);
        
        self.fetchResult = [PHAsset fetchAssetsWithOptions:[PHFetchOptions mnz_fetchOptionsForCameraUploadWithMediaTypes:mediaTypes]];
        MEGALogDebug(@"[Camera Upload] total local asset count %lu", (unsigned long)self.fetchResult.count);
        if (self.fetchResult.count == 0) {
            if (completion) {
                completion(nil);
            }

            return;
        }
        
        __block NSError *error;
        [CameraUploadRecordManager.shared.backgroundContext performBlockAndWait:^{
            NSUInteger totalCount = [CameraUploadRecordManager.shared totalRecordsCountByMediaTypes:mediaTypes includeUploadErrorRecords:YES error:&error];
            if (error) {
                return;
            }
            
            if (totalCount == 0) {
                MEGALogDebug(@"[Camera Upload] initial save with asset count %lu", (unsigned long)self.fetchResult.count);
                @autoreleasepool {
                    [self saveInitialUploadRecordsByAssetFetchResult:self.fetchResult error:&error];
                    
                    if (error) {
                        return;
                    }
                    
                    if (CameraUploadManager.isLivePhotoSupported && [mediaTypes containsObject:@(PHAssetMediaTypeImage)]) {
                        [self.livePhotoScanner saveInitialLivePhotoRecordsInFetchResult:self.fetchResult error:&error];
                    }
                }
            } else {
                @autoreleasepool {
                    NSArray<MOAssetUploadRecord *> *records = [CameraUploadRecordManager.shared fetchUploadRecordsByMediaTypes:mediaTypes includeAdditionalMediaSubtypes:NO error:&error];
                    if (error) {
                        return;
                    }
                    
                    MEGALogDebug(@"[Camera Upload] saved upload record count %lu", (unsigned long)records.count);
                    NSArray<PHAsset *> *newAssets = [self.fetchResult findNewAssetsByUploadRecords:records];
                    MEGALogDebug(@"[Camera Upload] new assets scanned count %lu", (unsigned long)newAssets.count);
                    if (newAssets.count > 0) {
                        [self createUploadRecordsByAssets:newAssets shouldCheckExistence:NO];
                        [CameraUploadRecordManager.shared saveChangesIfNeededWithError:&error];
                        
                        if (error) {
                            return;
                        }
                        
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [NSNotificationCenter.defaultCenter postNotificationName:MEGACameraUploadStatsChangedNotificationName object:nil];
                        });
                    }
                    
                    if (CameraUploadManager.isLivePhotoSupported && [mediaTypes containsObject:@(PHAssetMediaTypeImage)]) {
                        [self.livePhotoScanner scanLivePhotosInFetchResult:self.fetchResult error:&error];
                    }
                }
            }
            
            MEGALogDebug(@"[Camera Upload] Finish local album scanning");
        }];
        
        if (completion) {
            completion(error);
        }
    }];
}

#pragma mark - PHPhotoLibraryChangeObserver

- (void)observePhotoLibraryChanges {
    [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
}

- (void)unobservePhotoLibraryChanges {
    [[PHPhotoLibrary sharedPhotoLibrary] unregisterChangeObserver:self];
}

- (void)photoLibraryDidChange:(PHChange *)changeInstance {
    PHFetchResultChangeDetails *changes = [changeInstance changeDetailsForFetchResult:self.fetchResult];
    if (changes) {
        self.fetchResult = changes.fetchResultAfterChanges;
        if ([changes hasIncrementalChanges]) {
            NSArray<PHAsset *> *newAssets = [changes insertedObjects];
            if (newAssets.count == 0) {
                return;
            }
            
            dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
                MEGALogDebug(@"[Camera Upload] new assets detected: %@", newAssets);
                [CameraUploadRecordManager.shared.backgroundContext performBlockAndWait:^{
                    [self createUploadRecordsByAssets:newAssets shouldCheckExistence:YES];
                    [self.livePhotoScanner scanLivePhotosInAssets:newAssets];
                    [CameraUploadRecordManager.shared saveChangesIfNeededWithError:nil];
                }];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [NSNotificationCenter.defaultCenter postNotificationName:MEGACameraUploadStatsChangedNotificationName object:nil];
                });
                
                [CameraUploadManager.shared startCameraUploadIfNeeded];
            });
        }
    }
}

#pragma mark - create and save records

- (BOOL)saveInitialUploadRecordsByAssetFetchResult:(PHFetchResult<PHAsset *> *)result error:(NSError * _Nullable __autoreleasing * _Nullable)error {
    __block NSError *coreDataError = nil;
    if (result.count > 0) {
        [CameraUploadRecordManager.shared.backgroundContext performBlockAndWait:^{
            for (PHAsset *asset in result) {
                [self createUploadRecordFromAsset:asset];
            }
            
            [CameraUploadRecordManager.shared saveChangesIfNeededWithError:&coreDataError];
        }];
    }
    
    if (error != NULL) {
        *error = coreDataError;
    }
    
    return coreDataError == nil;
}

- (void)createUploadRecordsByAssets:(NSArray<PHAsset *> *)assets shouldCheckExistence:(BOOL)checkExistence {
    if (assets.count == 0) {
        return;
    }
    
    [CameraUploadRecordManager.shared.backgroundContext performBlockAndWait:^{
        for (PHAsset *asset in assets) {
            if (checkExistence) {
                NSError *error;
                BOOL hasExistingRecord = [CameraUploadRecordManager.shared fetchUploadRecordsByIdentifier:asset.localIdentifier shouldPrefetchErrorRecords:NO error:&error].count > 0;
                if (error) {
                    MEGALogError(@"[Camera Upload] error when to fetch record by identifier %@ %@", asset.localIdentifier, error);
                } else if (!hasExistingRecord) {
                    [self createUploadRecordFromAsset:asset];
                }
            } else {
                [self createUploadRecordFromAsset:asset];
            }
        }
    }];
}

- (MOAssetUploadRecord *)createUploadRecordFromAsset:(PHAsset *)asset {
    if (asset.localIdentifier.length == 0) {
        return nil;
    }
    
    MOAssetUploadRecord *record = [NSEntityDescription insertNewObjectForEntityForName:@"AssetUploadRecord" inManagedObjectContext:CameraUploadRecordManager.shared.backgroundContext];
    record.localIdentifier = asset.localIdentifier;
    record.status = @(CameraAssetUploadStatusNotStarted);
    record.creationDate = asset.creationDate;
    record.mediaType = @(asset.mediaType);
    record.mediaSubtypes = @(asset.mediaSubtypes);
    record.additionalMediaSubtypes = nil;
    
    return record;
}

@end
