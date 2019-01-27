
#import <Photos/Photos.h>

NS_ASSUME_NONNULL_BEGIN

@interface PHAsset (CameraUpload)

- (nullable NSString *)mnz_fileExtensionFromAssetInfo:(nullable NSDictionary *)info;

- (NSString *)mnz_cameraUploadFileNameWithExtension:(NSString *)extension;

- (NSString *)mnz_cameraUploadLivePhotoFileNameWithExtension:(NSString *)extension;

@end

NS_ASSUME_NONNULL_END
