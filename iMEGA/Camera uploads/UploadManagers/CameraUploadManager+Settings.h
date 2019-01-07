
#import "CameraUploadManager.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, CameraUploadVideoQuality) {
    CameraUploadVideoQualityMedium = 0,
    CameraUploadVideoQualityLow = 1,
    CameraUploadVideoQualityHigh = 2,
    CameraUploadVideoQualityOriginal = 3
};

@interface CameraUploadManager (Settings)

@property (class, nonatomic, getter=isCameraUploadEnabled) BOOL cameraUploadEnabled;
@property (class, nonatomic, getter=isVideoUploadEnabled) BOOL videoUploadEnabled;
@property (class, nonatomic, getter=isCellularUploadAllowed) BOOL cellularUploadAllowed;
@property (class, nonatomic, getter=shouldConvertHEIFPhoto) BOOL convertHEIFPhoto;
@property (class, nonatomic, getter=shouldConvertHEVCVideo) BOOL convertHEVCVideo;
@property (class, nonatomic) CameraUploadVideoQuality HEVCToH264CompressionQuality;

+ (void)clearLocalSettings;

@end

NS_ASSUME_NONNULL_END
