#import "NSError+CameraUpload.h"

NSString * const CameraUploadErrorDomain = @"nz.mega.cameraUpload";

@implementation NSError (CameraUpload)

+ (NSError *)mnz_cameraUploadNoEnoughDiskSpaceError {
    return [NSError errorWithDomain:CameraUploadErrorDomain code:CameraUploadErrorNoEnoughDiskFreeSpace userInfo:@{NSLocalizedDescriptionKey : @"no enough disk free space on device"}];
}

+ (NSError *)mnz_cameraUploadBackgroundTaskExpiredError {
    return [NSError errorWithDomain:CameraUploadErrorDomain code:CameraUploadErrorBackgroundTaskExpired userInfo:@{NSLocalizedDescriptionKey : @"background task is expired"}];
}

+ (NSError *)mnz_cameraUploadOperationCancelledError {
    return [NSError errorWithDomain:CameraUploadErrorDomain code:CameraUploadErrorOperationCancelled userInfo:@{NSLocalizedDescriptionKey : @"operation gets cancelled"}];
}

+ (NSError *)mnz_cameraUploadEncryptionCancelledError {
    return [NSError errorWithDomain:CameraUploadErrorDomain code:CameraUploadErrorEncryptionCancelled userInfo:@{NSLocalizedDescriptionKey : @"encryption gets cancelled"}];
}

+ (NSError *)mnz_cameraUploadNodeIsNotFoundError {
    return [NSError errorWithDomain:CameraUploadErrorDomain code:CameraUploadErrorCameraUploadNodeIsNotFound userInfo:@{NSLocalizedDescriptionKey : @"camera upload node is not found"}];
}

+ (NSError *)mnz_cameraUploadChunkMissingError {
    return [NSError errorWithDomain:CameraUploadErrorDomain code:CameraUploadErrorChunksMissing userInfo:@{NSLocalizedDescriptionKey : @"file chunk is not found"}];
}

+ (NSError *)mnz_cameraUploadEmptyFileNameError {
    return [NSError errorWithDomain:CameraUploadErrorDomain code:CameraUploadErrorEmptyFileName userInfo:@{NSLocalizedDescriptionKey : @"empty local file name"}];
}

+ (NSError *)mnz_cameraUploadNoWritePermissionErrorForFileURL:(NSURL *)URL {
    return [NSError errorWithDomain:CameraUploadErrorDomain code:CameraUploadErrorNoFileWritePermission userInfo:@{NSLocalizedDescriptionKey : [NSString stringWithFormat:@"no write permission for file %@", URL]}];
}

+ (NSError *)mnz_cameraUploadEncryptionErrorForFileURL:(NSURL *)URL {
    return [NSError errorWithDomain:CameraUploadErrorDomain code:CameraUploadErrorEncryptionFailed userInfo:@{NSLocalizedDescriptionKey : [NSString stringWithFormat:@"error occurred when to encrypt file URL %@", URL]}];
}

+ (NSError *)mnz_cameraUploadDataTransferErrorWithUserInfo:(NSDictionary *)userInfo {
    return [NSError errorWithDomain:CameraUploadErrorDomain code:CameraUploadErrorDataTransfer userInfo:userInfo];
}

+ (NSError *)mnz_cameraUploadEmptyLocalIdentifierError {
    return [NSError errorWithDomain:CameraUploadErrorDomain code:CameraUploadErrorEmptyLocalIdentifier   userInfo:@{NSLocalizedDescriptionKey : @"local identifier is empty"}];
}

+ (NSError *)mnz_cameraUploadUnknownMediaType:(PHAssetMediaType)mediaType {
    return [NSError errorWithDomain:CameraUploadErrorDomain code:CameraUploadErrorUnknownMediaType   userInfo:@{NSLocalizedDescriptionKey : [NSString stringWithFormat:@"%li media type can not be recognised", (long)mediaType]}];
}

+ (NSError *)mnz_cameraUploadNoMediaAssetFetchedWithIdentifier:(NSString *)identifier {
    return [NSError errorWithDomain:CameraUploadErrorDomain code:CameraUploadErrorNoMediaAssetFetched   userInfo:@{NSLocalizedDescriptionKey : [NSString stringWithFormat:@"no media asset fetched for %@", identifier]}];
}

+ (NSError *)mnz_cameraUploadDisabledMediaSubtype:(PHAssetMediaSubtype)mediaSubtype {
    return [NSError errorWithDomain:CameraUploadErrorDomain code:CameraUploadErrorDisabledMediaSubtype userInfo:@{NSLocalizedDescriptionKey : [NSString stringWithFormat:@"the media subtype %lu currently is disabled", (unsigned long)mediaSubtype]}];
}

+ (NSError *)mnz_cameraUploadFileHandleException:(NSException *)exception {
    return [NSError errorWithDomain:CameraUploadErrorDomain code:CameraUploadErrorFileHandleException userInfo:@{
        NSLocalizedDescriptionKey : exception.name ?: @"",
        NSLocalizedFailureReasonErrorKey : exception.reason ?: @"file handle exception",
        NSLocalizedRecoverySuggestionErrorKey : exception.userInfo ?: @{}
    }];
}

+ (NSError *)mnz_cameraUploadCoreDataException:(NSException *)exception {
    return [NSError errorWithDomain:CameraUploadErrorDomain code:CameraUploadErrorCoreDataException userInfo:@{
        NSLocalizedDescriptionKey : exception.name ?: @"",
        NSLocalizedFailureReasonErrorKey : exception.reason ?: @"core data exception",
        NSLocalizedRecoverySuggestionErrorKey : exception.userInfo ?: @{}
    }];
}

@end
