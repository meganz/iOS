
#import "NSError+CameraUpload.h"

NSString * const CameraUploadErrorDomain = @"nz.mega.cameraUpload";

@implementation NSError (CameraUpload)

+ (NSError *)cameraUploadNoEnoughFreeSpaceError {
    return [NSError errorWithDomain:CameraUploadErrorDomain code:CameraUploadErrorNoEnoughDiskFreeSpace userInfo:@{NSLocalizedDescriptionKey : @"no enough disk free space on device"}];
}

@end
