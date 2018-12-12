
#import "NSError+CameraUpload.h"

NSString * const CameraUploadErrorDomain = @"nz.mega.cameraUpload";

@implementation NSError (CameraUpload)

+ (NSError *)mnz_cameraUploadNoEnoughFreeSpaceError {
    return [NSError errorWithDomain:CameraUploadErrorDomain code:CameraUploadErrorNoEnoughDiskFreeSpace userInfo:@{NSLocalizedDescriptionKey : @"no enough disk free space on device"}];
}

@end
