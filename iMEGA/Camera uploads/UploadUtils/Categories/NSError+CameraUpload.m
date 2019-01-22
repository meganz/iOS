
#import "NSError+CameraUpload.h"

NSString * const CameraUploadErrorDomain = @"nz.mega.cameraUpload";

@implementation NSError (CameraUpload)

+ (NSError *)mnz_cameraUploadNoEnoughFreeSpaceError {
    return [NSError errorWithDomain:CameraUploadErrorDomain code:CameraUploadErrorNoEnoughDiskFreeSpace userInfo:@{NSLocalizedDescriptionKey : @"no enough disk free space on device"}];
}

+ (NSError *)mnz_cameraUploadBackgroundTaskExpiredError {
    return [NSError errorWithDomain:CameraUploadErrorDomain code:CameraUploadErrorBackgroundTaskExpired userInfo:@{NSLocalizedDescriptionKey : @"background task is expired"}];
}

+ (NSError *)mnz_cameraUploadOperationCancelled {
    return [NSError errorWithDomain:CameraUploadErrorDomain code:CameraUploadOperationCancelled userInfo:@{NSLocalizedDescriptionKey : @"operation gets cancelled"}];
}

@end
