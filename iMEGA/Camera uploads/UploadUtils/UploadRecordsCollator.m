
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
    
    MEGALogDebug(@"[Camera Upload] %lu non-uploading records to revert back to not stated status", (unsigned long)records.count);
    [CameraUploadRecordManager.shared.backgroundContext performBlock:^{
        for (MOAssetUploadRecord *record in records) {
            [self revertBackToNotStartedForRecord:record];
        }
        [CameraUploadRecordManager.shared saveChangesIfNeededWithError:nil];
    }];
}

- (void)collateUploadingRecords {
    NSArray<MOAssetUploadRecord *> *uploadingRecords = [CameraUploadRecordManager.shared fetchAllUploadRecordsByStatuses:@[@(CameraAssetUploadStatusUploading)] error:nil];
    if (uploadingRecords.count == 0) {
        MEGALogDebug(@"[Camera Upload] no uploading records to collate");
        return;
    }
    
    MEGALogDebug(@"[Camera Upload] %lu uploading records to collate", (unsigned long)uploadingRecords.count);
    NSArray<NSURLSessionUploadTask *> *runningTasks = [TransferSessionManager.shared allRunningUploadTasks];
    NSMutableArray<NSString *> *runningTaskIdentifiers = [NSMutableArray array];
    for (NSURLSessionUploadTask *task in runningTasks) {
        MEGALogDebug(@"[Camera Upload] %@ task state %li", task.taskDescription, task.state);
        if (task.taskDescription.length > 0) {
            [runningTaskIdentifiers addObject:task.taskDescription];
        }
    }
    
    NSComparator localIdComparator = ^(NSString *s1, NSString *s2) {
        return [s1 compare:s2];
    };
    
    [runningTaskIdentifiers sortUsingComparator:localIdComparator];
    
    [CameraUploadRecordManager.shared.backgroundContext performBlock:^{
        for (MOAssetUploadRecord *record in uploadingRecords) {
            NSUInteger index = [runningTaskIdentifiers indexOfObject:record.localIdentifier inSortedRange:NSMakeRange(0, runningTaskIdentifiers.count) options:NSBinarySearchingFirstEqual usingComparator:localIdComparator];
            if (index == NSNotFound) {
                [self revertBackToNotStartedForRecord:record];
            }
        }
        
        [CameraUploadRecordManager.shared saveChangesIfNeededWithError:nil];
    }];
}

- (void)clearErrorRecordsPerLaunch {
    [CameraUploadRecordManager.shared deleteAllErrorRecordsPerLaunchWithError:nil];
}

- (void)revertBackToNotStartedForRecord:(MOAssetUploadRecord *)record {
    MEGALogDebug(@"[Camera Upload] revert record status %@ to not started for %@", [AssetUploadStatus stringForStatus:record.status.unsignedIntegerValue], record.localIdentifier);
    record.status = @(CameraAssetUploadStatusNotStarted);
    [NSFileManager.defaultManager removeItemIfExistsAtURL:[NSURL mnz_assetDirectoryURLForLocalIdentifier:record.localIdentifier]];
}

@end
