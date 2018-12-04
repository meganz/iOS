
#import "UploadRecordsCollator.h"
#import "CameraUploadRecordManager.h"
#import "NSURL+CameraUpload.h"
#import "NSFileManager+MNZCategory.h"

@implementation UploadRecordsCollator

- (void)collateUploadRecords {
    [self collateInterrupptedRecords];
}

- (void)collateInterrupptedRecords {
    NSArray<MOAssetUploadRecord *> *records = [CameraUploadRecordManager.shared fetchUploadRecordsByStatuses:@[CameraAssetUploadStatusQueuedUp, CameraAssetUploadStatusProcessing] error:nil];
    if (records.count == 0) {
        return;
    }
    
    for (MOAssetUploadRecord *record in records) {
        record.status = CameraAssetUploadStatusNotStarted;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            if (record.localIdentifier) {
                [NSFileManager.defaultManager removeItemIfExistsAtURL:[NSURL assetDirectoryURLForLocalIdentifier:record.localIdentifier]];
            }
        });
    }
    
    [CameraUploadRecordManager.shared saveChangesIfNeeded:nil];
}

@end
