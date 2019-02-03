
#import "LivePhotoUploadOperation.h"
#import "AssetUploadInfo.h"
#import "CameraUploadRecordManager.h"
#import "PHAsset+CameraUpload.h"
#import "MEGAConstants.h"
@import Photos;

@implementation LivePhotoUploadOperation

- (void)start {
    [super start];
    
    [self requestLivePhoto];
}

- (void)requestLivePhoto {
    PHLivePhotoRequestOptions *options = [[PHLivePhotoRequestOptions alloc] init];
    options.networkAccessAllowed = YES;
    options.version = PHImageRequestOptionsVersionOriginal;
    options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
    __weak __typeof__(self) weakSelf = self;
    [PHImageManager.defaultManager requestLivePhotoForAsset:self.uploadInfo.asset targetSize:PHImageManagerMaximumSize contentMode:PHImageContentModeDefault options:options resultHandler:^(PHLivePhoto * _Nullable livePhoto, NSDictionary * _Nullable info) {
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
    
    NSURL *videoURL = [self.uploadInfo.directoryURL URLByAppendingPathComponent:@"video.mov"];
    PHAssetResourceRequestOptions *options = [[PHAssetResourceRequestOptions alloc] init];
    options.networkAccessAllowed = YES;
    [PHAssetResourceManager.defaultManager writeDataForAssetResource:resource toFile:videoURL options:options completionHandler:^(NSError * _Nullable error) {
        if (error) {
            [self finishOperationWithStatus:CameraAssetUploadStatusFailed shouldUploadNextAsset:YES];
        } else {
            self.uploadInfo.originalFingerprint = [MEGASdkManager.sharedMEGASdk fingerprintForFilePath:videoURL.path modificationTime:self.uploadInfo.asset.creationDate];
            MEGANode *matchingNode = [self nodeForOriginalFingerprint:self.uploadInfo.originalFingerprint];
            if (matchingNode) {
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
    self.uploadInfo.fileName = [self.uploadInfo.asset mnz_cameraUploadLivePhotoVideoFileNameWithExtension:MEGAMP4FileExtension];
    session.outputURL = self.uploadInfo.fileURL;
    session.canPerformMultiplePassesOverSourceMediaData = YES;
    session.shouldOptimizeForNetworkUse = YES;
    session.metadataItemFilter = [AVMetadataItemFilter metadataItemFilterForSharing];
    
    __weak __typeof__(self) weakSelf = self;
    [session exportAsynchronouslyWithCompletionHandler:^{
        switch (session.status) {
            case AVAssetExportSessionStatusCompleted:
                MEGALogDebug(@"[Camera Upload] %@ has finished video compression", weakSelf);
                [weakSelf checkFingerprintAndEncryptFileIfNeeded];
                break;
            case AVAssetExportSessionStatusCancelled:
                MEGALogDebug(@"[Camera Upload] %@ video compression got cancelled", weakSelf);
                [weakSelf finishOperationWithStatus:CameraAssetUploadStatusCancelled shouldUploadNextAsset:YES];
                break;
            default:
                MEGALogError(@"[Camera Upload] %@ got error when to compress video %@", weakSelf, session.error)
                [weakSelf finishOperationWithStatus:CameraAssetUploadStatusFailed shouldUploadNextAsset:YES];
                break;
        }
    }];
}

@end
