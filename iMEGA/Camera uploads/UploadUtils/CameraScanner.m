
#import "CameraScanner.h"
#import "CameraUploadRecordManager.h"
#import "MOAssetUploadRecord+CoreDataClass.h"
#import "CameraUploadManager.h"
#import "SavedIdentifierParser.h"
#import "CameraUploadManager+Settings.h"
#import "LivePhotoScanner.h"

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
        _operationQueue.qualityOfService = NSQualityOfServiceUserInitiated;
        _livePhotoScanner = [[LivePhotoScanner alloc] init];
    }
    return self;
}

- (void)dealloc {
    [self unobservePhotoLibraryChanges];
}

#pragma mark - scan camera rolls

- (void)scanMediaTypes:(NSArray<NSNumber *> *)mediaTypes completion:(void (^)(void))completion {
    [self.operationQueue addOperationWithBlock:^{
        MEGALogDebug(@"[Camera Upload] Start local album scanning for media types %@", mediaTypes);
        
        PHFetchOptions *fetchOptions = [[PHFetchOptions alloc] init];
        fetchOptions.includeAssetSourceTypes = PHAssetSourceTypeUserLibrary | PHAssetSourceTypeCloudShared | PHAssetSourceTypeiTunesSynced;
        fetchOptions.predicate = [NSPredicate predicateWithFormat:@"mediaType IN %@", mediaTypes];
        self.fetchResult = [PHAsset fetchAssetsWithOptions:fetchOptions];
        if (self.fetchResult.count == 0) {
            if (completion) {
                completion();
            }
            return;
        }
        
        [CameraUploadRecordManager.shared.backgroundContext performBlockAndWait:^{
            NSArray<MOAssetUploadRecord *> *records = [[CameraUploadRecordManager shared] fetchAllUploadRecords:nil];
            if (records.count == 0) {
                MEGALogDebug(@"[Camera Upload] initial save with asset count %lu", (unsigned long)self.fetchResult.count);
                [CameraUploadRecordManager.shared saveInitialUploadRecordsByAssetFetchResult:self.fetchResult error:nil];
                if (CameraUploadManager.isLivePhotoSupported) {
                    [self.livePhotoScanner saveInitialLivePhotoRecordsByFetchResult:self.fetchResult];
                }
            } else {
                NSArray<PHAsset *> *newAssets = [self findNewAssetsByComparingFetchResult:self.fetchResult uploadRecords:records];
                MEGALogDebug(@"[Camera Upload] new assets scanned with count %lu", (unsigned long)newAssets.count);
                if (newAssets.count > 0) {
                    [CameraUploadRecordManager.shared createUploadRecordsIfNeededByAssets:newAssets];
                    [CameraUploadRecordManager.shared saveChangesIfNeededWithError:nil];
                }
                
                if (CameraUploadManager.isLivePhotoSupported) {
                    [self.livePhotoScanner scanLivePhotosWithCompletion:nil];
                }
            }
            
            NSArray *livePhotoRecords = [CameraUploadRecordManager.shared fetchUploadRecordsByMediaTypes:@[@(PHAssetMediaTypeImage)] additionalMediaSubtypes:PHAssetMediaSubtypePhotoLive error:nil];
            MEGALogDebug(@"[Camera Upload] scan live photo count %lu and records %@", livePhotoRecords.count, livePhotoRecords);
            
            MEGALogDebug(@"[Camera Upload] Finish local album scanning");
        }];
        
        if (completion) {
            completion();
        }
    }];
}

- (NSArray<PHAsset *> *)findNewAssetsByComparingFetchResult:(PHFetchResult<PHAsset *> *)result uploadRecords:(NSArray<MOAssetUploadRecord *> *)records {
    if (result.count == 0) {
        return @[];
    }
    
    NSMutableArray<NSString *> *scannedLocalIds = [NSMutableArray arrayWithCapacity:records.count];
    for (MOAssetUploadRecord *record in records) {
        NSString *identifier = [CameraUploadRecordManager.shared savedIdentifierInRecord:record];
        if (identifier) {
            [scannedLocalIds addObject:identifier];
        }
    }
    NSComparator localIdComparator = ^(NSString *s1, NSString *s2) {
        return [s1 compare:s2];
    };
    
    NSArray<NSString *> *sortedLocalIds = [scannedLocalIds sortedArrayUsingComparator:localIdComparator];

    NSMutableArray<PHAsset *> *newAssets = [NSMutableArray array];
    for (PHAsset *asset in result) {
        NSUInteger matchingIndex = [sortedLocalIds indexOfObject:asset.localIdentifier inSortedRange:NSMakeRange(0, sortedLocalIds.count) options:NSBinarySearchingFirstEqual usingComparator:localIdComparator];
        if (matchingIndex == NSNotFound) {
            [newAssets addObject:asset];
        }
    }
    
    return [newAssets copy];
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
                    [CameraUploadRecordManager.shared createUploadRecordsIfNeededByAssets:newAssets];
                    [self.livePhotoScanner saveLivePhotoRecordsIfNeededByAssets:newAssets];
                    [CameraUploadRecordManager.shared saveChangesIfNeededWithError:nil];
                    
                    NSArray *livePhotoRecords = [CameraUploadRecordManager.shared fetchUploadRecordsByMediaTypes:@[@(PHAssetMediaTypeImage)] additionalMediaSubtypes:PHAssetMediaSubtypePhotoLive error:nil];
                    MEGALogDebug(@"[Camera Upload] scan live photo count %lu and records %@", livePhotoRecords.count, livePhotoRecords);
                }];
                
                [CameraUploadManager.shared startCameraUploadIfNeeded];
            });
        }
    }
}

@end
