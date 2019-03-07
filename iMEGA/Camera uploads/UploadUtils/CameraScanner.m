
#import "CameraScanner.h"
#import "CameraUploadRecordManager.h"
#import "MOAssetUploadRecord+CoreDataClass.h"
#import "CameraUploadManager.h"
#import "SavedIdentifierParser.h"
#import "CameraUploadManager+Settings.h"
#import "LivePhotoScanner.h"
#import "PHFetchOptions+CameraUpload.h"
#import "PHFetchResult+CameraUpload.h"

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
        
        self.fetchResult = [PHAsset fetchAssetsWithOptions:[PHFetchOptions mnz_fetchOptionsForCameraUploadWithMediaTypes:mediaTypes]];
        if (self.fetchResult.count == 0) {
            if (completion) {
                completion();
            }
            return;
        }
        
        [CameraUploadRecordManager.shared.backgroundContext performBlockAndWait:^{
            if ([CameraUploadRecordManager.shared uploadRecordsCountByMediaTypes:mediaTypes error:nil] == 0) {
                MEGALogDebug(@"[Camera Upload] initial save with asset count %lu", (unsigned long)self.fetchResult.count);
                @autoreleasepool {
                    [CameraUploadRecordManager.shared saveInitialUploadRecordsByAssetFetchResult:self.fetchResult error:nil];
                    if (CameraUploadManager.isLivePhotoSupported) {
                        [self.livePhotoScanner saveInitialLivePhotoRecordsInFetchResult:self.fetchResult];
                    }
                }
            } else {
                @autoreleasepool {
                    NSArray<MOAssetUploadRecord *> *records = [CameraUploadRecordManager.shared fetchUploadRecordsByMediaTypes:mediaTypes includeAdditionalMediaSubtypes:NO error:nil];
                    NSArray<PHAsset *> *newAssets = [self.fetchResult findNewAssetsByUploadRecords:records];
                    MEGALogDebug(@"[Camera Upload] new assets scanned with count %lu", (unsigned long)newAssets.count);
                    if (newAssets.count > 0) {
                        [CameraUploadRecordManager.shared createUploadRecordsByAssets:newAssets shouldCheckExistence:NO];
                        [CameraUploadRecordManager.shared saveChangesIfNeededWithError:nil];
                    }
                    
                    if (CameraUploadManager.isLivePhotoSupported) {
                        [self.livePhotoScanner scanLivePhotosInFetchResult:self.fetchResult];
                    }
                }
            }
            
            MEGALogDebug(@"[Camera Upload] Finish local album scanning");
        }];
        
        if (completion) {
            completion();
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
                    [CameraUploadRecordManager.shared createUploadRecordsByAssets:newAssets shouldCheckExistence:YES];
                    [self.livePhotoScanner scanLivePhotosInAssets:newAssets];
                    [CameraUploadRecordManager.shared saveChangesIfNeededWithError:nil];
                }];
                
                [CameraUploadManager.shared startCameraUploadIfNeeded];
            });
        }
    }
}

@end
