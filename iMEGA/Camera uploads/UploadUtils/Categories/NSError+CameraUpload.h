
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString * const CameraUploadErrorDomain;

typedef NS_ENUM(NSUInteger, CameraUploadError) {
    CameraUploadErrorNoFileWritePermission,
    CameraUploadErrorNoEnoughDiskFreeSpace,
    CameraUploadErrorCalculateEncryptionChunkPositions,
    CameraUploadErrorEncryptionFailed,
    CameraUploadErrorEncryptionCancelled,
    CameraUploadErrorFailedToCreateCompleteUploadRequest,
    CameraUploadErrorBackgroundTaskExpired,
    CameraUploadErrorOperationCancelled,
    CameraUploadErrorCameraUploadNodeIsNotFound,
    CameraUploadErrorChunksMissing,
};

@interface NSError (CameraUpload)

/**
 return a NSError object with CameraUploadErrorNoEnoughDiskFreeSpace error code for camera upload when there is no encough free space in device
 */
@property (class, readonly) NSError *mnz_cameraUploadNoEnoughDiskSpaceError;

/**
 return a NSError object with CameraUploadErrorBackgroundTaskExpired error code for camera upload when a background task gets expired
 */
@property (class, readonly) NSError *mnz_cameraUploadBackgroundTaskExpiredError;

/**
 return a NSError object with CameraUploadErrorOperationCancelled error code if one camera upload operation gets cancelled
 */
@property (class, readonly) NSError *mnz_cameraUploadOperationCancelledError;

/**
 return a NSError object with CameraUploadErrrorCameraUploadNodeIsNotFound error code if camera upload node is not found
 */
@property (class, readonly) NSError *mnz_cameraUploadNodeIsNotFoundError;

/**
 return a NSError object with CameraUploadErrorEncryptionCancelled error code if file encryption gets cancelled
 */
@property (class, readonly) NSError *mnz_cameraUploadEncryptionCancelledError;

/**
 return a NSError object with CameraUploadErrorChunksMissing error code if we can not find required file chunks
 */
@property (class, readonly) NSError *mnz_cameraUploadChunkMissingError;

/**
 creates a NSError object if we don't have write permission to a file in camera upload

 @param URL the URL of the file we are trying to write
 @return a NSError object with CameraUploadErrorNoFileWritePermission error code
 */
+ (NSError *)mnz_cameraUploadNoWritePermissionErrorForFileURL:(NSURL *)URL;


/**
 creates a NSError object when encryption failed

 @param URL the URL of the file to be encrypted
 @return a NSError object with CameraUploadErrorEncryption error code
 */
+ (NSError *)mnz_cameraUploadEncryptionErrorForFileURL:(NSURL *)URL;

@end

NS_ASSUME_NONNULL_END
