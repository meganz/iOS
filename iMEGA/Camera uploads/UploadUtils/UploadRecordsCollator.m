
#import "UploadRecordsCollator.h"
#import "CameraUploadRecordManager.h"
#import "NSURL+CameraUpload.h"
#import "NSFileManager+MNZCategory.h"
#import "TransferSessionManager.h"

@implementation UploadRecordsCollator

- (void)collateUploadRecords {
    [self collateNonUploadingRecords];
    [self collateUploadingRecords];
    [self clearErrorRecordsPerLaunch];
}

- (void)collateNonUploadingRecords {
    NSArray<MOAssetUploadRecord *> *records = [CameraUploadRecordManager.shared fetchAllUploadRecordsByStatuses:AssetUploadStatus.nonUploadingStatusesToCollate error:nil];
    if (records.count == 0) {
        MEGALogDebug(@"[Camera Upload] no non-uploading records to collate");
        return;
    }
    
    MEGALogDebug(@"[Camera Upload] %lu non-uploading records to collate", (unsigned long)records.count);
    for (MOAssetUploadRecord *record in records) {
        [self revertBackToNotStartedForRecord:record];
    }
    
    [CameraUploadRecordManager.shared saveChangesIfNeededWithError:nil];
}

- (void)collateUploadingRecords {
    NSArray<MOAssetUploadRecord *> *uploadingRecords = [CameraUploadRecordManager.shared fetchAllUploadRecordsByStatuses:@[@(CameraAssetUploadStatusUploading)] error:nil];
    if (uploadingRecords.count == 0) {
        MEGALogDebug(@"[Camera Upload] no uploading records to collate");
        return;
    }
    
    MEGALogDebug(@"[Camera Upload] %lu uploading records to collate", (unsigned long)uploadingRecords.count);
    NSArray<NSURLSessionUploadTask *> *runningTasks = [TransferSessionManager.shared allRunningUploadTasks];
    NSMutableArray<NSString *> *identifiers = [NSMutableArray array];
    for (NSURLSessionUploadTask *task in runningTasks) {
        if (task.taskDescription.length > 0) {
            [identifiers addObject:task.taskDescription];
        }
    }
    
    NSComparator localIdComparator = ^(NSString *s1, NSString *s2) {
        return [s1 compare:s2];
    };
    
    [identifiers sortUsingComparator:localIdComparator];
    
    for (MOAssetUploadRecord *record in uploadingRecords) {
        NSUInteger index = [identifiers indexOfObject:record.localIdentifier inSortedRange:NSMakeRange(0, identifiers.count) options:NSBinarySearchingFirstEqual usingComparator:localIdComparator];
        if (index == NSNotFound) {
            [self revertBackToNotStartedForRecord:record];
        }
    }
    
    [CameraUploadRecordManager.shared saveChangesIfNeededWithError:nil];
}

- (void)clearErrorRecordsPerLaunch {
    [CameraUploadRecordManager.shared deleteAllErrorRecordsPerLaunchWithError:nil];
}

- (void)revertBackToNotStartedForRecord:(MOAssetUploadRecord *)record {
    record.status = @(CameraAssetUploadStatusNotStarted);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        if (record.localIdentifier) {
            [NSFileManager.defaultManager removeItemIfExistsAtURL:[NSURL mnz_assetDirectoryURLForLocalIdentifier:record.localIdentifier]];
        }
    });
}

@end
