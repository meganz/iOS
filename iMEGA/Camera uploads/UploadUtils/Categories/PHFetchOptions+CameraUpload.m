#import "PHFetchOptions+CameraUpload.h"
#import "CameraUploadManager+Settings.h"

@implementation PHFetchOptions (CameraUpload)

+ (PHFetchOptions *)mnz_fetchOptionsForCameraUpload {
    return [self mnz_fetchOptionsForCameraUploadWithMediaTypes:@[@(PHAssetMediaTypeImage), @(PHAssetMediaTypeVideo)]];
}

+ (PHFetchOptions *)mnz_fetchOptionsForCameraUploadWithMediaTypes:(NSArray<NSNumber *> *)mediaTypes {
    PHFetchOptions *fetchOptions = [self mnz_shardFetchOptionsForCameraUpload];
    fetchOptions.predicate = [NSPredicate predicateWithFormat:@"mediaType IN %@", mediaTypes];
    return fetchOptions;
}

+ (PHFetchOptions *)mnz_fetchOptionsForLivePhoto {
    PHFetchOptions *fetchOptions = [self mnz_shardFetchOptionsForCameraUpload];
    fetchOptions.predicate = [NSPredicate predicateWithFormat:@"(mediaType == %d) AND ((mediaSubtype & %d) == %d)", PHAssetMediaTypeImage, PHAssetMediaSubtypePhotoLive, PHAssetMediaSubtypePhotoLive];
    return fetchOptions;
}

+ (PHFetchOptions *)mnz_shardFetchOptionsForCameraUpload {
    PHFetchOptions *fetchOptions = [[PHFetchOptions alloc] init];
    PHAssetSourceType sourceTypes = PHAssetSourceTypeUserLibrary;
    if (CameraUploadManager.shouldUploadSharedAlbums) {
        sourceTypes |= PHAssetSourceTypeCloudShared;
    }
    if (CameraUploadManager.shouldUploadSyncedAlbums) {
        sourceTypes |= PHAssetSourceTypeiTunesSynced;
    }
    
    fetchOptions.includeAssetSourceTypes = sourceTypes;
    fetchOptions.includeAllBurstAssets = CameraUploadManager.shouldUploadAllBurstPhotos;
    fetchOptions.includeHiddenAssets = CameraUploadManager.shouldUploadHiddenAlbum;
    return fetchOptions;
}

@end
