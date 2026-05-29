#import <Photos/Photos.h>

NS_ASSUME_NONNULL_BEGIN

@interface PHFetchOptions (CameraUpload)

+ (PHFetchOptions *)mnz_fetchOptionsForCameraUpload;

+ (PHFetchOptions *)mnz_fetchOptionsForLivePhoto;

+ (PHFetchOptions *)mnz_fetchOptionsForCameraUploadWithMediaTypes:(NSArray<NSNumber *> *)mediaTypes;

/// Scan variants of the above that also apply the "upload only new photos" creation-date cutoff.
/// Use only for discovering new assets to enqueue, never for resolving an existing record's asset
/// by local identifier.
+ (PHFetchOptions *)mnz_scanFetchOptionsForCameraUploadWithMediaTypes:(NSArray<NSNumber *> *)mediaTypes;

+ (PHFetchOptions *)mnz_scanFetchOptionsForLivePhoto;

@end

NS_ASSUME_NONNULL_END
