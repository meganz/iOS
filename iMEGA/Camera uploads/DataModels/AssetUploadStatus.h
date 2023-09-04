#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, CameraAssetUploadStatus) {
    CameraAssetUploadStatusUnknown = -15,
    CameraAssetUploadStatusNotStarted = 0,
    CameraAssetUploadStatusNotReady = 15,
    CameraAssetUploadStatusQueuedUp = 30,
    CameraAssetUploadStatusProcessing = 45,
    CameraAssetUploadStatusUploading = 60,
    CameraAssetUploadStatusCancelled = 75,
    CameraAssetUploadStatusFailed = 90,
    CameraAssetUploadStatusDone = 100
};

NS_ASSUME_NONNULL_BEGIN

@interface AssetUploadStatus : NSObject

@property (class, readonly) NSArray<NSNumber *> *statusesReadyToQueueUp;
@property (class, readonly) NSArray<NSNumber *> *allStatusesToQueueUp;
@property (class, readonly) NSArray<NSNumber *> *nonUploadingStatusesToCollate;

+ (NSString *)stringForStatus:(CameraAssetUploadStatus)status;

@end

NS_ASSUME_NONNULL_END
