
#import "PHFetchOptions+CameraUpload.h"

@implementation PHFetchOptions (CameraUpload)

+ (PHFetchOptions *)mnz_fetchOptionsForCameraUpload {
    return [self mnz_fetchOptionsForCameraUploadWithMediaTypes:@[@(PHAssetMediaTypeImage), @(PHAssetMediaTypeVideo)]];
}

+ (PHFetchOptions *)mnz_fetchOptionsForCameraUploadWithMediaTypes:(NSArray<NSNumber *> *)mediaTypes {
    PHFetchOptions *fetchOptions = [[PHFetchOptions alloc] init];
    fetchOptions.includeAssetSourceTypes = PHAssetSourceTypeUserLibrary | PHAssetSourceTypeCloudShared | PHAssetSourceTypeiTunesSynced;
    fetchOptions.includeHiddenAssets = YES;
    fetchOptions.includeAllBurstAssets = YES;
    fetchOptions.predicate = [NSPredicate predicateWithFormat:@"mediaType IN %@", mediaTypes];
    return fetchOptions;
}

@end
