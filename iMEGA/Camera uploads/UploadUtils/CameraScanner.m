
#import "CameraScanner.h"
#import "CameraUploadRecordManager.h"
#import "MOAssetUploadRecord+CoreDataClass.h"

@interface CameraScanner () <PHPhotoLibraryChangeObserver>

@property (strong, nonatomic) NSOperationQueue *operationQueue;
@property (strong, nonatomic) PHFetchResult<PHAsset *> *fetchResult;

@end

@implementation CameraScanner

- (instancetype)init {
    self = [super init];
    if (self) {
        _operationQueue = [[NSOperationQueue alloc] init];
    }
    return self;
}

- (void)dealloc {
    [[PHPhotoLibrary sharedPhotoLibrary] unregisterChangeObserver:self];
}

#pragma mark - camera scanning

- (void)scanMediaType:(PHAssetMediaType)mediaType completion:(void (^)(void))completion {
    [self.operationQueue addOperationWithBlock:^{
        MEGALogDebug(@"[Camera Upload] Start local album scanning at: %@", [NSDateFormatter localizedStringFromDate:[NSDate date] dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterFullStyle]);
        
        PHFetchOptions *fetchOptions = [[PHFetchOptions alloc] init];
        fetchOptions.includeAssetSourceTypes = PHAssetSourceTypeUserLibrary | PHAssetSourceTypeCloudShared | PHAssetSourceTypeiTunesSynced;
        fetchOptions.predicate = [NSPredicate predicateWithFormat:@"mediaType == %@", @(mediaType)];
        self.fetchResult = [PHAsset fetchAssetsWithOptions:fetchOptions];
        if (self.fetchResult.count == 0) {
            return;
        }
        
        NSError *error = nil;
        NSArray<MOAssetUploadRecord *> *records = [[CameraUploadRecordManager shared] fetchAllRecords:&error];
        if (records.count == 0) {
            [[CameraUploadRecordManager shared] saveAssetFetchResult:self.fetchResult error:nil];
        } else {
            NSArray<PHAsset *> *newAssets = [self findNewAssetsByComparingFetchResult:self.fetchResult uploadRecords:records];
            [[CameraUploadRecordManager shared] saveAssets:newAssets error:nil];
        }
        
        MEGALogDebug(@"[Camera Upload] Finish local album scanning at: %@", [NSDateFormatter localizedStringFromDate:[NSDate date] dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterFullStyle]);
        
        completion();
    }];
    
    [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
}

- (NSArray<PHAsset *> *)findNewAssetsByComparingFetchResult:(PHFetchResult<PHAsset *> *)result uploadRecords:(NSArray<MOAssetUploadRecord *> *)records {
    if (result.count == 0) {
        return @[];
    }
    
    NSMutableArray<NSString *> *scannedLocalIds = [NSMutableArray arrayWithCapacity:records.count];
    for (MOAssetUploadRecord *record in records) {
        [scannedLocalIds addObject:record.localIdentifier];
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

- (void)photoLibraryDidChange:(PHChange *)changeInstance {
    PHFetchResultChangeDetails *changes = [changeInstance changeDetailsForFetchResult:self.fetchResult];
    self.fetchResult = changes.fetchResultAfterChanges;
    NSArray<PHAsset *> *newAssets = [changes insertedObjects];
    [[CameraUploadRecordManager shared] saveAssets:newAssets error:nil];
}

@end
