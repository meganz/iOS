
#import "CameraUploadOperation.h"
#import "MEGASdkManager.h"
#import "NSFileManager+MNZCategory.h"
#import "NSString+MNZCategory.h"
#import "TransferSessionManager.h"
#import "AssetUploadInfo.h"
#import "CameraUploadRecordManager.h"
#import "CameraUploadManager.h"
#import "CameraUploadRequestDelegate.h"
#import "FileEncrypter.h"
#import "NSURL+CameraUpload.h"
#import "MEGAConstants.h"
#import "PHAsset+CameraUpload.h"
#import "CameraUploadManager+Settings.h"
#import "NSError+CameraUpload.h"
#import "MEGAReachabilityManager.h"
#import "MEGAError+MNZCategory.h"
#import "CameraUploadOperation+Utils.h"
#import "NSDate+MNZCategory.h"
@import Photos;

@interface CameraUploadOperation ()

@property (strong, nonatomic, nullable) MEGASdk *attributesDataSDK;

@end

@implementation CameraUploadOperation

#pragma mark - initializers

- (instancetype)initWithUploadInfo:(AssetUploadInfo *)uploadInfo uploadRecord:(MOAssetUploadRecord *)uploadRecord {
    self = [super init];
    if (self) {
        _uploadInfo = uploadInfo;
        _uploadRecord = uploadRecord;
    }
    
    return self;
}

#pragma mark - properties

- (MEGASdk *)attributesDataSDK {
    if (_attributesDataSDK == nil) {
        _attributesDataSDK = [MEGASdkManager createMEGASdk];
    }
    
    return _attributesDataSDK;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@ %@ %@ %@", NSStringFromClass(self.class), [self.uploadInfo.asset.creationDate mnz_formattedDefaultNameForMedia], self.uploadInfo.fileName, self.uploadInfo.savedRecordLocalIdentifier];
}

#pragma mark - start operation

- (void)start {
    if (self.isCancelled) {
        [self finishOperationWithStatus:CameraAssetUploadStatusCancelled shouldUploadNextAsset:NO];
        return;
    }
    
    [self startExecuting];

    [self beginBackgroundTaskWithExpirationHandler:^{
        [self cancel];
    }];
    
    MEGALogDebug(@"[Camera Upload] %@ starts processing", self);
    [CameraUploadRecordManager.shared updateUploadRecord:self.uploadRecord withStatus:CameraAssetUploadStatusProcessing error:nil];
    
    self.uploadInfo.directoryURL = [self URLForAssetFolder];
}

#pragma mark - data processing

- (NSURL *)URLForAssetFolder {
    NSURL *assetDirectoryURL = [NSURL mnz_assetDirectoryURLForLocalIdentifier:self.uploadInfo.savedRecordLocalIdentifier];
    [NSFileManager.defaultManager removeItemIfExistsAtURL:assetDirectoryURL];
    [[NSFileManager defaultManager] createDirectoryAtURL:assetDirectoryURL withIntermediateDirectories:YES attributes:nil error:nil];
    return assetDirectoryURL;
}

- (BOOL)createThumbnailAndPreviewFiles {
    BOOL thumbnailCreated = [self.attributesDataSDK createThumbnail:self.uploadInfo.fileURL.path destinatioPath:self.uploadInfo.thumbnailURL.path];
    if (!thumbnailCreated) {
        MEGALogError(@"[Camera Upload] %@ error when to create thumbnail", self);
    }
    BOOL previewCreated = [self.attributesDataSDK createPreview:self.uploadInfo.fileURL.path destinatioPath:self.uploadInfo.previewURL.path];
    if (!previewCreated) {
        MEGALogError(@"[Camera Upload] %@ error when to create preview", self);
    }
    self.attributesDataSDK = nil;
    return thumbnailCreated && previewCreated;
}

#pragma mark - upload task

- (void)handleProcessedUploadFile {
    if (self.isCancelled) {
        [self finishOperationWithStatus:CameraAssetUploadStatusCancelled shouldUploadNextAsset:NO];
        return;
    }
    
    self.uploadInfo.fingerprint = [MEGASdkManager.sharedMEGASdk fingerprintForFilePath:self.uploadInfo.fileURL.path modificationTime:self.uploadInfo.asset.creationDate];
    MEGANode *matchingNode = [MEGASdkManager.sharedMEGASdk nodeForFingerprint:self.uploadInfo.fingerprint parent:self.uploadInfo.parentNode];
    if (matchingNode) {
        MEGALogDebug(@"[Camera Upload] %@ found existing node by file fingerprint", self);
        [self finishUploadForFingerprintMatchedNode:matchingNode];
        return;
    }
    
    if (![self createThumbnailAndPreviewFiles]) {
        [self finishOperationWithStatus:CameraAssetUploadStatusFailed shouldUploadNextAsset:YES];
        return;
    }
    
    self.uploadInfo.mediaUpload = [MEGASdkManager.sharedMEGASdk backgroundMediaUpload];
    [self.uploadInfo.mediaUpload analyseMediaInfoForFileAtPath:self.uploadInfo.fileURL.path];
    
    [self encryptFile];
}

- (void)encryptFile {
    FileEncrypter *encrypter = [[FileEncrypter alloc] initWithMediaUpload:self.uploadInfo.mediaUpload outputDirectoryURL:self.uploadInfo.encryptionDirectoryURL shouldTruncateInputFile:YES];
    [encrypter encryptFileAtURL:self.uploadInfo.fileURL completion:^(BOOL success, unsigned long long fileSize, NSDictionary<NSString *,NSURL *> * _Nonnull chunkURLsKeyedByUploadSuffix, NSError * _Nonnull error) {
        if (success) {
            self.uploadInfo.fileSize = fileSize;
            self.uploadInfo.encryptedChunkURLsKeyedByUploadSuffix = chunkURLsKeyedByUploadSuffix;
            [self requestUploadURL];
        } else {
            MEGALogError(@"[Camera Upload] %@ error when to encrypt file %@", self, error);
            if (error.domain == CameraUploadErrorDomain && error.code == CameraUploadErrorNoEnoughDiskFreeSpace) {
                [self finishUploadWithNoEnoughDiskSpace];
            } else if (error.domain == NSCocoaErrorDomain && error.code == NSFileWriteOutOfSpaceError) {
                [self finishUploadWithNoEnoughDiskSpace];
            } else {
                [self finishOperationWithStatus:CameraAssetUploadStatusFailed shouldUploadNextAsset:YES];
            }
            return;
        }
    }];
}

- (void)requestUploadURL {
    if (self.isCancelled) {
        [self finishOperationWithStatus:CameraAssetUploadStatusCancelled shouldUploadNextAsset:NO];
        return;
    }
    
    [[MEGASdkManager sharedMEGASdk] requestBackgroundUploadURLWithFileSize:self.uploadInfo.fileSize mediaUpload:self.uploadInfo.mediaUpload delegate:[[CameraUploadRequestDelegate alloc] initWithCompletion:^(MEGARequest * _Nonnull request, MEGAError * _Nonnull error) {
        if (error.type) {
            MEGALogError(@"[Camera Upload] %@ error when to requests upload url %@", self, error.nativeError);
            if (error.type == MEGAErrorTypeApiEOverQuota || error.type == MEGAErrorTypeApiEgoingOverquota) {
                [NSNotificationCenter.defaultCenter postNotificationName:MEGAStorageOverQuotaNotificationName object:self];
                [self finishOperationWithStatus:CameraAssetUploadStatusCancelled shouldUploadNextAsset:NO];
            } else {
                [self finishOperationWithStatus:CameraAssetUploadStatusFailed shouldUploadNextAsset:YES];
            }
        } else {
            self.uploadInfo.uploadURLString = [self.uploadInfo.mediaUpload uploadURLString];
            if ([self archiveUploadInfoDataForBackgroundTransfer]) {
                [self uploadEncryptedChunksToServer];
            } else {
                [self finishOperationWithStatus:CameraAssetUploadStatusFailed shouldUploadNextAsset:YES];
            }
        }
    }]];
}

- (void)uploadEncryptedChunksToServer {
    if (self.isCancelled) {
        [self finishOperationWithStatus:CameraAssetUploadStatusCancelled shouldUploadNextAsset:NO];
        return;
    }
    
    for (NSString *uploadSuffix in self.uploadInfo.encryptedChunkURLsKeyedByUploadSuffix.allKeys) {
        NSURL *serverURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", self.uploadInfo.uploadURLString, uploadSuffix]];
        NSURL *chunkURL = self.uploadInfo.encryptedChunkURLsKeyedByUploadSuffix[uploadSuffix];
        if ([NSFileManager.defaultManager isReadableFileAtPath:chunkURL.path]) {
            NSURLSessionUploadTask *uploadTask;
            if (self.uploadInfo.asset.mediaType == PHAssetMediaTypeVideo) {
                uploadTask = [TransferSessionManager.shared videoUploadTaskWithURL:serverURL fromFile:chunkURL completion:nil];
            } else {
                uploadTask = [[TransferSessionManager shared] photoUploadTaskWithURL:serverURL fromFile:chunkURL completion:nil];
            }
            uploadTask.taskDescription = self.uploadInfo.savedRecordLocalIdentifier;
            [uploadTask resume];
        } else {
            MEGALogError(@"[Camera Upload] %@ error when to upload chunk as file doesn't exist at %@", self, chunkURL);
            [self finishOperationWithStatus:CameraAssetUploadStatusFailed shouldUploadNextAsset:YES];
            return;
        }
    }
    
    [self finishOperationWithStatus:CameraAssetUploadStatusUploading shouldUploadNextAsset:YES];
}

#pragma mark - archive upload info

- (BOOL)archiveUploadInfoDataForBackgroundTransfer {
    NSURL *archivedURL = [NSURL mnz_archivedURLForLocalIdentifier:self.uploadInfo.savedRecordLocalIdentifier];
    return [NSKeyedArchiver archiveRootObject:self.uploadInfo toFile:archivedURL.path];
}

#pragma mark - finish operation

- (void)finishOperationWithStatus:(CameraAssetUploadStatus)status shouldUploadNextAsset:(BOOL)uploadNextAsset {
    [self finishOperation];
    
    MEGALogDebug(@"[Camera Upload] %@ finishes with status: %@", self, [AssetUploadStatus stringForStatus:status]);
    [CameraUploadRecordManager.shared updateUploadRecord:self.uploadRecord withStatus:status error:nil];
    
    if (status != CameraAssetUploadStatusUploading) {
        [NSFileManager.defaultManager removeItemAtURL:self.uploadInfo.directoryURL error:nil];
    }
    
    if (status == CameraAssetUploadStatusDone) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [NSNotificationCenter.defaultCenter postNotificationName:MEGACameraUploadAssetUploadDoneNotificationName object:nil];
        });
    }
    
    if (uploadNextAsset) {
        [CameraUploadManager.shared uploadNextAssetWithMediaType:self.uploadInfo.asset.mediaType];
    }
}

@end
