
#import "CameraUploadManager.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, CameraUploadVideoQuality) {
    CameraUploadVideoQualityLow = 0,
    CameraUploadVideoQualityMedium = 1,
    CameraUploadVideoQualityHigh = 2,
    CameraUploadVideoQualityOriginal = 3
};

@interface CameraUploadManager (Settings)

#pragma mark - camera settings

@property (class, getter=isCameraUploadEnabled) BOOL cameraUploadEnabled;
@property (class, getter=isBackgroundUploadAllowed) BOOL backgroundUploadAllowed;

#pragma mark - photo settings

@property (class, getter=isCellularUploadAllowed) BOOL cellularUploadAllowed;
@property (class, getter=shouldConvertHEICPhoto) BOOL convertHEICPhoto;
@property (class, getter=shouldUploadLivePhoto) BOOL uploadLivePhoto;

#pragma mark - video settings

@property (class, getter=isVideoUploadEnabled) BOOL videoUploadEnabled;
@property (class, getter=shouldConvertHEVCVideo) BOOL convertHEVCVideo;
@property (class, getter=isCellularUploadForVideosAllowed) BOOL cellularUploadForVideosAllowed;
@property (class) CameraUploadVideoQuality HEVCToH264CompressionQuality;

#pragma mark - readonly properties

@property (class, readonly) BOOL isLivePhotoSupported;
@property (class, readonly) BOOL shouldShowCameraUploadBoardingScreen;
@property (class, readonly) BOOL isHEVCFormatSupported;
@property (class, readonly) BOOL canBackgroundUploadBeStarted;

+ (void)clearLocalSettings;

+ (void)migrateOldCameraUploadsSettings;

@end

NS_ASSUME_NONNULL_END
