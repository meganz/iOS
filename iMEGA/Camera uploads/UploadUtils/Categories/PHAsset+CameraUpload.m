
#import "PHAsset+CameraUpload.h"

@implementation PHAsset (CameraUpload)

- (BOOL)mnz_isLivePhoto {
    return self.mediaType == PHAssetMediaTypeImage && self.mediaSubtypes & PHAssetMediaSubtypePhotoLive;
}

- (NSString *)mnz_fileExtensionFromAssetInfo:(NSDictionary *)info {
    NSString *extension = [info[@"PHImageFileURLKey"] pathExtension];
    if (extension.length == 0) {
        extension = [info[@"PHImageFileSandboxExtensionTokenKey"] pathExtension];
    }
    
    if (extension.length == 0) {
        extension = [info[@"PHImageFileUTIKey"] pathExtension];
    }
    
    if (extension.length == 0) {
        switch (self.mediaType) {
            case PHAssetMediaTypeImage:
                extension = MEGAJPGFileExtension;
                break;
            case PHAssetMediaTypeVideo:
                extension = MEGAQuickTimeFileExtension;
                break;
            default:
                break;
        }
    }
    
    return extension.lowercaseString;
}

- (PHAssetResource *)searchAssetResourceByTypes:(NSArray<NSNumber *> *)types {
    NSArray<PHAssetResource *> *resources = [PHAssetResource assetResourcesForAsset:self];
    for (NSNumber *type in types) {
        for (PHAssetResource *resource in resources) {
            if (resource.type == type.integerValue) {
                return resource;
            }
        }
    }
    
    return nil;
}

@end
