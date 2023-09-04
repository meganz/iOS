#import <Foundation/Foundation.h>
@import Photos;

NS_ASSUME_NONNULL_BEGIN

extern NSString * const CameraUploadErrorDomain;

typedef NS_ENUM(NSUInteger, CameraUploadError) {
    CameraUploadErrorNoFileWritePermission,
    CameraUploadErrorNoEnoughDiskFreeSpace,
    CameraUploadErrorCalculateEncryptionChunkPositions,
    CameraUploadErrorEncryptionFailed,
    CameraUploadErrorEncryptionCancelled,
    CameraUploadErrorBackgroundTaskExpired,
    CameraUploadErrorOperationCancelled,
    CameraUploadErrorCameraUploadNodeIsNotFound,
    CameraUploadErrorChunksMissing,
    CameraUploadErrorDataTransfer,
    CameraUploadErrorEmptyLocalIdentifier,
    CameraUploadErrorNoMediaAssetFetched,
    CameraUploadErrorUnknownMediaType,
    CameraUploadErrorDisabledMediaSubtype,
    CameraUploadErrorEmptyFileName,
    CameraUploadErrorFileHandleException,
    CameraUploadErrorCoreDataException
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
 return a NSError object with CameraUploadErrorEmptyLocalIdentifier error code if the local identifier is empty
 */
@property (class, readonly) NSError *mnz_cameraUploadEmptyLocalIdentifierError;

/**
 return a NSError object with CameraUploadErrorEmptyFileName error code if the we can not generate a local file name
 */
@property (class, readonly) NSError *mnz_cameraUploadEmptyFileNameError;

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

/**
 create a NSError object when error happended in data transfer

 @param userInfo user info dictionary to describle the error details
 @return a NSError object with CameraUploadErrorDataTransfer error code
 */
+ (NSError *)mnz_cameraUploadDataTransferErrorWithUserInfo:(NSDictionary *)userInfo;

/**
 create a NSError object when we can not fetch a local media asset by a given identifier

 @param identifier media file local identifier
 @return a NSError object with CameraUploadErrorNoMediaAssetFetched error code
 */
+ (NSError *)mnz_cameraUploadNoMediaAssetFetchedWithIdentifier:(NSString *)identifier;

/**
 create a NSError object when we encountered an unknown media type

 @param mediaType the media type we can not recognised
 @return a NSError object with CameraUploadErrorUnknownMediaType error code
 */
+ (NSError *)mnz_cameraUploadUnknownMediaType:(PHAssetMediaType)mediaType;

/**
 create a NSError object when we encountered an media subtype disabled by the current user

 @param mediaSubtype the media subtype gets disabled
 @return a NSError object with CameraUploadErrorDisabledMediaSubtype error code
 */
+ (NSError *)mnz_cameraUploadDisabledMediaSubtype:(PHAssetMediaSubtype)mediaSubtype;

/**
 create a NSError object when we encountered a file handle exception

 @param exception the exception throw from a file handle
 @return a NSError object with CameraUploadErrorFileHandleException error code
 */
+ (NSError *)mnz_cameraUploadFileHandleException:(NSException *)exception;

/**
 create a NSError object when we encountered a core data exception

 @param exception the exception throw from core data
 @return a NSError object with CameraUploadErrorCoreDataException error code
 */
+ (NSError *)mnz_cameraUploadCoreDataException:(NSException *)exception;

@end

NS_ASSUME_NONNULL_END
