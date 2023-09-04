#import "AssetUploadStatus.h"

@implementation AssetUploadStatus

+ (NSArray<NSNumber *> *)statusesReadyToQueueUp {
    return @[@(CameraAssetUploadStatusNotStarted),
             @(CameraAssetUploadStatusFailed),
             @(CameraAssetUploadStatusCancelled)];
}

+ (NSArray<NSNumber *> *)allStatusesToQueueUp {
    return @[@(CameraAssetUploadStatusNotStarted),
             @(CameraAssetUploadStatusNotReady),
             @(CameraAssetUploadStatusFailed),
             @(CameraAssetUploadStatusCancelled)];
}

+ (NSArray<NSNumber *> *)nonUploadingStatusesToCollate {
    return @[@(CameraAssetUploadStatusNotReady),
             @(CameraAssetUploadStatusQueuedUp),
             @(CameraAssetUploadStatusProcessing)];
}

+ (NSString *)stringForStatus:(CameraAssetUploadStatus)status {
    NSString *statusString;
    switch (status) {
        case CameraAssetUploadStatusUnknown:
            statusString = @"Unknown";
            break;
        case CameraAssetUploadStatusNotStarted:
            statusString = @"NotStarted";
            break;
        case CameraAssetUploadStatusNotReady:
            statusString = @"NotReady";
            break;
        case CameraAssetUploadStatusQueuedUp:
            statusString = @"QueuedUp";
            break;
        case CameraAssetUploadStatusProcessing:
            statusString = @"Processing";
            break;
        case CameraAssetUploadStatusUploading:
            statusString = @"Uploading";
            break;
        case CameraAssetUploadStatusCancelled:
            statusString = @"Cancelled";
            break;
        case CameraAssetUploadStatusFailed:
            statusString = @"Failed";
            break;
        case CameraAssetUploadStatusDone:
            statusString = @"Done";
            break;
        default:
            break;
    }
    
    return statusString;
}

@end
