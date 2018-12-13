
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString * const CameraUploadErrorDomain;

typedef enum : NSUInteger {
    CameraUploadErrorNoFileWritePermission,
    CameraUploadErrorNoEnoughDiskFreeSpace,
    CameraUploadErrorCalculateEncryptionChunkPositions,
    CameraUploadErrorEncryption,
    CameraUploadErrorFailedToCreateCompleteUploadRequest,
    CameraUploadErrorBackgroundTaskExpired,
} CameraUploadError;

@interface NSError (CameraUpload)

/**
 return a NSError object for camera upload when there is no encough free space in device
 
 @return error showing no enough free space
 */
+ (NSError *)mnz_cameraUploadNoEnoughFreeSpaceError;


/**
 return a NSError object for camera upload when a background task gets expired

 @return error showing background task expired
 */
+ (NSError *)mnz_cameraUploadBackgroundTaskExpiredError;

@end

NS_ASSUME_NONNULL_END
