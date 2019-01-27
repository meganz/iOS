
#import "PHAsset+CameraUpload.h"
#import "MEGAConstants.h"
#import "CameraUploadFileNameRecordManager.h"
#import "NSString+MNZCategory.h"

static NSString * const CameraUploadLivePhotoExtension = @"live";

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

- (NSString *)mnz_cameraUploadFileNameWithExtension:(NSString *)extension {
    NSString *proposedFileName = [[NSString mnz_fileNameWithDate:self.creationDate] stringByAppendingPathExtension:extension];
    return [CameraUploadFileNameRecordManager.shared localUniqueFileNameForAssetLocalIdentifier:self.localIdentifier proposedFileName:proposedFileName];
}

- (NSString *)mnz_cameraUploadLivePhotoFileNameWithExtension:(NSString *)extension {
    NSString *proposedFileName = [[[NSString mnz_fileNameWithDate:self.creationDate] stringByAppendingPathExtension:CameraUploadLivePhotoExtension] stringByAppendingPathExtension:extension];
    return [CameraUploadFileNameRecordManager.shared localUniqueFileNameForAssetLocalIdentifier:self.localIdentifier proposedFileName:proposedFileName];
}

@end
