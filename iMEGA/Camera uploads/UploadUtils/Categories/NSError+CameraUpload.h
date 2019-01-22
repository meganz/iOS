
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
    CameraUploadOperationCancelled
} CameraUploadError;

@interface NSError (CameraUpload)

/**
 return a NSError object for camera upload when there is no encough free space in device
 */
@property (class, readonly) NSError *mnz_cameraUploadNoEnoughFreeSpaceError;


/**
 return a NSError object for camera upload when a background task gets expired
 */
@property (class, readonly) NSError *mnz_cameraUploadBackgroundTaskExpiredError;


/**
 return a NSError object if one camera upload operation gets cancelled
 */
@property (class, readonly) NSError *mnz_cameraUploadOperationCancelled;

@end

NS_ASSUME_NONNULL_END
