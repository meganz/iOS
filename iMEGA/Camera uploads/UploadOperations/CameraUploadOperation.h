
#import <UIKit/UIKit.h>
#import "MEGAOperation.h"
#import "AssetUploadInfo.h"
#import "MEGABackgroundTaskOperation.h"
#import "AssetUploadStatus.h"

NS_ASSUME_NONNULL_BEGIN

@class MOAssetUploadRecord;

typedef NS_ENUM(NSUInteger, UploadQueueType) {
    UploadQueueTypePhoto,
    UploadQueueTypeVideo,
};

/**
 A base class for camera upload operation. It's supposed to be subclassed.
 */
@interface CameraUploadOperation : MEGABackgroundTaskOperation

@property (strong, nonatomic) AssetUploadInfo *uploadInfo;
@property (strong, nonatomic) MOAssetUploadRecord *uploadRecord;

- (instancetype)initWithUploadInfo:(AssetUploadInfo *)uploadInfo uploadRecord:(MOAssetUploadRecord *)uploadRecord;

- (void)handleProcessedFileWithMediaType:(PHAssetMediaType)type;

- (void)finishOperationWithStatus:(CameraAssetUploadStatus)status;

/// Subclass needs to override to specify the upload queue type needed
- (UploadQueueType)uploadQueueType;

@end

NS_ASSUME_NONNULL_END
