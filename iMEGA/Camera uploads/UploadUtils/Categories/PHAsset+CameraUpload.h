
#import <Photos/Photos.h>

NS_ASSUME_NONNULL_BEGIN

@interface PHAsset (CameraUpload)

@property (readonly) BOOL mnz_isLivePhoto;

- (nullable NSString *)mnz_fileExtensionFromAssetInfo:(nullable NSDictionary *)info;


/**
 search asset resource for the asset by passed resource types, and return the first one if the type matches.

 @param types an array of types to search. We will search one type after another according to the order in the types array.
 @return the first asset resource which matches the searching types
 */
- (nullable PHAssetResource *)searchAssetResourceByTypes:(NSArray<NSNumber *> *)types;

@end

NS_ASSUME_NONNULL_END
