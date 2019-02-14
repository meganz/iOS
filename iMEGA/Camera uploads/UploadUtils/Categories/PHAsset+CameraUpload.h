
#import <Photos/Photos.h>

NS_ASSUME_NONNULL_BEGIN

@interface PHAsset (CameraUpload)

- (nullable NSString *)mnz_fileExtensionFromAssetInfo:(nullable NSDictionary *)info;

@end

NS_ASSUME_NONNULL_END
