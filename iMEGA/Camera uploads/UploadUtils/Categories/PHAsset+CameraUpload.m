
#import "PHAsset+CameraUpload.h"
#import "MEGAConstants.h"

@implementation PHAsset (CameraUpload)

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

@end
