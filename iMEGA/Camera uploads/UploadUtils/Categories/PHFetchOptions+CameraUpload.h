#import <Photos/Photos.h>

NS_ASSUME_NONNULL_BEGIN

@interface PHFetchOptions (CameraUpload)

+ (PHFetchOptions *)mnz_fetchOptionsForCameraUpload;

+ (PHFetchOptions *)mnz_fetchOptionsForLivePhoto;

+ (PHFetchOptions *)mnz_fetchOptionsForCameraUploadWithMediaTypes:(NSArray<NSNumber *> *)mediaTypes;

@end

NS_ASSUME_NONNULL_END
