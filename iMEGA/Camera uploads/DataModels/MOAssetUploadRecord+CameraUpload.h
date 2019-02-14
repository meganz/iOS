
#import "MOAssetUploadRecord+CoreDataClass.h"

NS_ASSUME_NONNULL_BEGIN

@interface MOAssetUploadRecord (CameraUpload)

- (NSString *)mnz_localFileNameWithExtension:(NSString *)extension;

- (NSString *)mnz_localLivePhotoFileNameWithExtension:(NSString *)extension;

@end

NS_ASSUME_NONNULL_END
