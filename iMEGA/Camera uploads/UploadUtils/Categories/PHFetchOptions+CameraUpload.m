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

#pragma mark - scan fetch options

// Scan variants used when discovering NEW assets to enqueue: they additionally AND-compose the
// "upload only new photos" cutoff onto the media-type / live-photo filter.
// Do NOT use these to resolve an asset by local identifier for an existing upload record — the
// cutoff would filter out a pre-cutoff asset (see UploadOperationFactory), which must keep using
// the cutoff-free `mnz_fetchOptionsForCameraUpload`.
+ (PHFetchOptions *)mnz_scanFetchOptionsForCameraUploadWithMediaTypes:(NSArray<NSNumber *> *)mediaTypes {
    PHFetchOptions *fetchOptions = [self mnz_fetchOptionsForCameraUploadWithMediaTypes:mediaTypes];
    fetchOptions.predicate = [self mnz_predicateByAppendingUploadOnlyNewPhotosClauseTo:fetchOptions.predicate];
    return fetchOptions;
}

+ (PHFetchOptions *)mnz_scanFetchOptionsForLivePhoto {
    PHFetchOptions *fetchOptions = [self mnz_fetchOptionsForLivePhoto];
    fetchOptions.predicate = [self mnz_predicateByAppendingUploadOnlyNewPhotosClauseTo:fetchOptions.predicate];
    return fetchOptions;
}

// AND-composes the "upload only new photos" cutoff clause onto the given predicate when the
// preference is enabled and a cutoff is set. Returns the original predicate unchanged otherwise.
+ (NSPredicate *)mnz_predicateByAppendingUploadOnlyNewPhotosClauseTo:(NSPredicate *)predicate {
    if (!CameraUploadManager.shouldUploadOnlyNewPhotos) {
        return predicate;
    }

    NSDate *cutoff = CameraUploadManager.uploadOnlyNewPhotosCutoff;
    if (cutoff == nil) {
        return predicate;
    }

    NSPredicate *datePredicate = [NSPredicate predicateWithFormat:@"creationDate >= %@", cutoff];
    return [NSCompoundPredicate andPredicateWithSubpredicates:@[predicate, datePredicate]];
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
