
#import "PHAsset+CameraUpload.h"

@implementation PHAsset (CameraUpload)

- (NSString *)fileExtensionFromAssetInfo:(NSDictionary *)info {
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
                extension = @"jpg";
                break;
            case PHAssetMediaTypeVideo:
                extension = @"mov";
                break;
            default:
                break;
        }
    }
    
    return extension.lowercaseString;
}

@end
