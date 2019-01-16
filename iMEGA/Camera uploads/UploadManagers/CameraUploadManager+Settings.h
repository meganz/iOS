
#import "CameraUploadManager.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, CameraUploadVideoQuality) {
    CameraUploadVideoQualityLow = 0,
    CameraUploadVideoQualityMedium = 1,
    CameraUploadVideoQualityHigh = 2,
    CameraUploadVideoQualityOriginal = 3
};

@interface CameraUploadManager (Settings)

@property (class, nonatomic, readonly) BOOL shouldShowCameraUploadBoardingScreen;
@property (class, nonatomic, getter=isCameraUploadEnabled) BOOL cameraUploadEnabled;
@property (class, nonatomic, getter=isVideoUploadEnabled) BOOL videoUploadEnabled;
@property (class, nonatomic, getter=isCellularUploadAllowed) BOOL cellularUploadAllowed;
@property (class, nonatomic, getter=isCellularUploadForVideosAllowed) BOOL cellularUploadForVideosAllowed;
@property (class, nonatomic, getter=shouldConvertHEICPhoto) BOOL convertHEICPhoto;
@property (class, nonatomic, getter=shouldConvertHEVCVideo) BOOL convertHEVCVideo;
@property (class, nonatomic, getter=isBackgroundUploadAllowed) BOOL backgroundUploadAllowed;
@property (class, nonatomic) CameraUploadVideoQuality HEVCToH264CompressionQuality;

@property (class, nonatomic, readonly) BOOL shouldShowPhotoAndVideoFormat;

+ (void)clearLocalSettings;

@end

NS_ASSUME_NONNULL_END
