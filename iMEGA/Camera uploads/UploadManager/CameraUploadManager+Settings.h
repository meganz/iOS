
#import "CameraUploadManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface CameraUploadManager (Settings)

@property (class, nonatomic, getter=isCameraUploadEnabled) BOOL cameraUploadEnabled;
@property (class, nonatomic, getter=isVideoUploadEnabled) BOOL videoUploadEnabled;
@property (class, nonatomic, getter=isCellularUploadAllowed) BOOL cellularUploadAllowed;
@property (class, nonatomic, getter=shuoldConvertHEIFPhoto) BOOL convertHEIFPhoto;
@property (class, nonatomic, getter=shouldConvertHEVCVideo) BOOL convertHEVCVideo;

+ (void)clearLocalSettings;

@end

NS_ASSUME_NONNULL_END
