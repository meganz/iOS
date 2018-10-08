
#import "AssetManager.h"
#import "AssetUploadStatusCoreDataManager.h"
@import Photos;

@interface AssetManager () <PHPhotoLibraryChangeObserver>

@property (strong, nonatomic) NSOperationQueue *operationQueue;
@property (strong, nonatomic) AssetUploadStatusCoreDataManager *assetUploadStatusManager;
@property (strong, nonatomic) PHFetchResult<PHAsset *> *fetchResult;

@end

@implementation AssetManager

+ (instancetype)shared {
    static id sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _operationQueue = [[NSOperationQueue alloc] init];
        _assetUploadStatusManager = [[AssetUploadStatusCoreDataManager alloc] init];
    }
    return self;
}

- (void)dealloc {
    [[PHPhotoLibrary sharedPhotoLibrary] unregisterChangeObserver:self];
}

#pragma mark - camera scanning

- (void)startScanningWithCompletion:(void (^)(NSArray<MOAssetUploadStatus *> *))completion {
    [self.operationQueue addOperationWithBlock:^{
        PHFetchOptions *fetchOptions = [[PHFetchOptions alloc] init];
        fetchOptions.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:YES]];
        fetchOptions.includeAssetSourceTypes = PHAssetSourceTypeUserLibrary | PHAssetSourceTypeCloudShared | PHAssetSourceTypeiTunesSynced;
        self.fetchResult = [PHAsset fetchAssetsWithMediaType:PHAssetMediaTypeImage options:fetchOptions];
        if (self.fetchResult.count == 0) {
            return;
        }
        
        NSError *error = nil;
        NSArray<MOAssetUploadStatus *> *statues = [self.assetUploadStatusManager fetchAllAssetsUploadStatus:&error];
        if (statues.count == 0) {
            [self.assetUploadStatusManager saveAssetFetchResult:self.fetchResult error:nil];
        } else {
            NSArray<PHAsset *> *newAssets = [self findNewAssetsFromFetchResult:self.fetchResult scannedUploadStatuses:statues];
            [self.assetUploadStatusManager saveAssets:newAssets error:nil];
        }
        
        completion(statues);
    }];
    
    [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
}

- (NSArray<PHAsset *> *)findNewAssetsFromFetchResult:(PHFetchResult<PHAsset *> *)result scannedUploadStatuses:(NSArray<MOAssetUploadStatus *> *)statuses {
    if (result.count == 0) {
        return @[];
    }
    
    NSMutableArray<NSString *> *scannedLocalIds = [NSMutableArray arrayWithCapacity:statuses.count];
    for (NSString *localId in statuses) {
        [scannedLocalIds addObject:localId];
    }
    NSComparator localIdComparator = ^(NSString *s1, NSString *s2) {
        return [s1 compare:s2];
    };
    
    NSArray<NSString *> *sortedLocalIds = [scannedLocalIds sortedArrayUsingComparator:localIdComparator];

    NSMutableArray<PHAsset *> *newAssets = [NSMutableArray array];
    for (PHAsset *asset in result) {
        NSUInteger matchingIndex = [sortedLocalIds indexOfObject:asset.localIdentifier inSortedRange:NSMakeRange(0, sortedLocalIds.count) options:NSBinarySearchingFirstEqual usingComparator:localIdComparator];
        if (matchingIndex != NSNotFound) {
            [newAssets addObject:asset];
        }
    }
    
    return [newAssets copy];
}

#pragma mark - PHPhotoLibraryChangeObserver

- (void)photoLibraryDidChange:(PHChange *)changeInstance {
    PHFetchResultChangeDetails *changes = [changeInstance changeDetailsForFetchResult:self.fetchResult];
    self.fetchResult = changes.fetchResultAfterChanges;
    NSArray<PHAsset *> *newAssets = [changes insertedObjects];
    [self.assetUploadStatusManager saveAssets:newAssets error:nil];
}

@end
