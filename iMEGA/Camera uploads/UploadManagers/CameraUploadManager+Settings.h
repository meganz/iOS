
#import "CameraUploadManager.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, CameraUploadVideoQuality) {
    CameraUploadVideoQualityLow = 0,
    CameraUploadVideoQualityMedium = 1,
    CameraUploadVideoQualityHigh = 2,
    CameraUploadVideoQualityOriginal = 3
};

@interface CameraUploadManager (Settings)

@property (class, readonly) BOOL shouldShowCameraUploadBoardingScreen;
@property (class, getter=isCameraUploadEnabled) BOOL cameraUploadEnabled;
@property (class, getter=isVideoUploadEnabled) BOOL videoUploadEnabled;
@property (class, getter=isCellularUploadAllowed) BOOL cellularUploadAllowed;
@property (class, getter=isCellularUploadForVideosAllowed) BOOL cellularUploadForVideosAllowed;
@property (class, getter=shouldConvertHEICPhoto) BOOL convertHEICPhoto;
@property (class, getter=shouldConvertHEVCVideo) BOOL convertHEVCVideo;
@property (class, getter=isBackgroundUploadAllowed) BOOL backgroundUploadAllowed;
@property (class) CameraUploadVideoQuality HEVCToH264CompressionQuality;

@property (class, readonly) BOOL shouldShowPhotoAndVideoFormat;
@property (class, readonly) BOOL canBackgroundUploadBeStarted;

+ (void)clearLocalSettings;

+ (void)migrateOldCameraUploadsSettings;

@end

NS_ASSUME_NONNULL_END
