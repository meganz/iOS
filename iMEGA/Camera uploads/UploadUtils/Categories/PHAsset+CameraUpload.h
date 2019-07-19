
#import <Photos/Photos.h>

NS_ASSUME_NONNULL_BEGIN

@interface PHAsset (CameraUpload)

@property (readonly) BOOL mnz_isLivePhoto;

- (nullable NSString *)mnz_fileExtensionFromAssetInfo:(nullable NSDictionary *)info;


/**
 search asset resource for the asset by resource types, and return the first one if the type matches.
 
 The resource type will be searched one by one according to their indexes in the passed array.

 @param types an array of types to search. The first type in the array will be searched first.
 @return the first asset resource which matches the searching types
 */
- (nullable PHAssetResource *)searchAssetResourceByTypes:(NSArray<NSNumber *> *)types;

@end

NS_ASSUME_NONNULL_END
