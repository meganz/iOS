
#import "LivePhotoUploadOperation.h"
#import "AssetUploadInfo.h"
#import "CameraUploadRecordManager.h"
#import "PHAsset+CameraUpload.h"
#import "MEGAConstants.h"
#import "NSFileManager+MNZCategory.h"
#import "CameraUploadOperation+Utils.h"
@import Photos;

static NSString * const LivePhotoVideoResourceTemporaryName = @"video.mov";

@implementation LivePhotoUploadOperation

- (void)start {
    [super start];
    
    [self requestLivePhoto];
}

- (void)requestLivePhoto {
    __weak __typeof__(self) weakSelf = self;
    
    PHLivePhotoRequestOptions *options = [[PHLivePhotoRequestOptions alloc] init];
    options.networkAccessAllowed = YES;
    options.version = PHImageRequestOptionsVersionOriginal;
    options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
    options.progressHandler = ^(double progress, NSError * _Nullable error, BOOL * _Nonnull stop, NSDictionary * _Nullable info) {
        if (weakSelf.isCancelled) {
            *stop = YES;
            [weakSelf finishOperationWithStatus:CameraAssetUploadStatusCancelled shouldUploadNextAsset:NO];
        }
        
        if (error != nil) {
            MEGALogError(@"[Camera Upload] %@ error when to download images from iCloud: %@", weakSelf, error);
            [weakSelf handleCloudDownloadError:error];
        }
    };
    
    
    [PHImageManager.defaultManager requestLivePhotoForAsset:self.uploadInfo.asset targetSize:PHImageManagerMaximumSize contentMode:PHImageContentModeDefault options:options resultHandler:^(PHLivePhoto * _Nullable livePhoto, NSDictionary * _Nullable info) {
        if (weakSelf.isFinished) {
            return;
        }
        
        if (![info[PHImageResultIsDegradedKey] boolValue]) {
            [weakSelf processLivePhoto:livePhoto];
        }
    }];
}

- (void)processLivePhoto:(nullable PHLivePhoto *)livePhoto {
    if (self.isCancelled) {
        [self finishOperationWithStatus:CameraAssetUploadStatusCancelled shouldUploadNextAsset:NO];
        return;
    }
    
    if (livePhoto == nil) {
        [self finishOperationWithStatus:CameraAssetUploadStatusFailed shouldUploadNextAsset:YES];
        return;
    }
    
    PHAssetResource *resource = [self videoResourceInLivePhoto:livePhoto];
    if (resource == nil) {
        [self finishOperationWithStatus:CameraAssetUploadStatusFailed shouldUploadNextAsset:YES];
        return;
    }
    
    [self writeDataForVideoResource:resource];
}

- (nullable PHAssetResource *)videoResourceInLivePhoto:(PHLivePhoto *)livePhoto {
    for (PHAssetResource *resource in [PHAssetResource assetResourcesForLivePhoto:livePhoto]) {
        if (resource.type == PHAssetResourceTypePairedVideo) {
            return resource;
        }
    }
    
    return nil;
}

- (void)writeDataForVideoResource:(PHAssetResource *)resource {
    if (self.isCancelled) {
        [self finishOperationWithStatus:CameraAssetUploadStatusCancelled shouldUploadNextAsset:NO];
        return;
    }
    
    if ([self fileSizeForResource:resource] > NSFileManager.defaultManager.deviceFreeSize) {
        [self finishUploadWithNoEnoughDiskSpace];
        return;
    }

    NSURL *videoURL = [self.uploadInfo.directoryURL URLByAppendingPathComponent:LivePhotoVideoResourceTemporaryName];
    PHAssetResourceRequestOptions *options = [[PHAssetResourceRequestOptions alloc] init];
    options.networkAccessAllowed = YES;
    [PHAssetResourceManager.defaultManager writeDataForAssetResource:resource toFile:videoURL options:options completionHandler:^(NSError * _Nullable error) {
        if (error) {
            if (error.domain == AVFoundationErrorDomain && error.code == AVErrorDiskFull) {
                [self finishUploadWithNoEnoughDiskSpace];
            } else if (error.domain == NSCocoaErrorDomain && error.code == NSFileWriteOutOfSpaceError) {
                [self finishUploadWithNoEnoughDiskSpace];
            } else {
                [self finishOperationWithStatus:CameraAssetUploadStatusFailed shouldUploadNextAsset:YES];
            }
        } else {
            self.uploadInfo.originalFingerprint = [MEGASdkManager.sharedMEGASdk fingerprintForFilePath:videoURL.path modificationTime:self.uploadInfo.asset.creationDate];
            MEGANode *matchingNode = [self nodeForOriginalFingerprint:self.uploadInfo.originalFingerprint];
            if (matchingNode) {
                MEGALogDebug(@"[Camera Upload] %@ found existing node by original file fingerprint", self);
                [self finishUploadForFingerprintMatchedNode:matchingNode];
                return;
            } else {
                [self exportVideoFromResourceFileURL:videoURL];
            }
        }
    }];
}

- (void)exportVideoFromResourceFileURL:(NSURL *)videoFileURL {
    if (self.isCancelled) {
        [self finishOperationWithStatus:CameraAssetUploadStatusCancelled shouldUploadNextAsset:NO];
        return;
    }
    
    AVURLAsset *urlAsset = [AVURLAsset assetWithURL:videoFileURL];
    AVAssetExportSession *session = [AVAssetExportSession exportSessionWithAsset:urlAsset presetName:AVAssetExportPresetHighestQuality];
    session.outputFileType = AVFileTypeMPEG4;
    self.uploadInfo.fileName = [self mnz_generateLocalLivePhotoFileNameWithExtension:MEGAMP4FileExtension];
    session.outputURL = self.uploadInfo.fileURL;
    session.canPerformMultiplePassesOverSourceMediaData = YES;
    session.shouldOptimizeForNetworkUse = YES;
    session.metadataItemFilter = [AVMetadataItemFilter metadataItemFilterForSharing];
    
    __weak __typeof__(self) weakSelf = self;
    [session exportAsynchronouslyWithCompletionHandler:^{
        switch (session.status) {
            case AVAssetExportSessionStatusCompleted:
                [weakSelf handleProcessedUploadFile];
                break;
            case AVAssetExportSessionStatusCancelled:
                MEGALogDebug(@"[Camera Upload] %@ video exporting got cancelled", weakSelf);
                [weakSelf finishOperationWithStatus:CameraAssetUploadStatusCancelled shouldUploadNextAsset:YES];
                break;
            case AVAssetExportSessionStatusFailed:
                MEGALogError(@"[Camera Upload] %@ got error when to export video %@", weakSelf, session.error)
                if (session.error.domain == AVFoundationErrorDomain && session.error.code == AVErrorDiskFull) {
                    [weakSelf finishUploadWithNoEnoughDiskSpace];
                } else {
                    [weakSelf finishOperationWithStatus:CameraAssetUploadStatusFailed shouldUploadNextAsset:YES];
                }
                break;
            default:
                break;
        }
    }];
}

#pragma mark - util methods

- (unsigned long long)fileSizeForResource:(PHAssetResource *)resource {
    unsigned long long size = 0;
    if ([resource respondsToSelector:@selector(fileSize)]) {
        id resourceSize = [resource valueForKey:@"fileSize"];
        if ([resourceSize respondsToSelector:@selector(unsignedLongLongValue)]) {
            size = [resourceSize unsignedLongLongValue];
        }
    }
    
    return size;
}

@end
