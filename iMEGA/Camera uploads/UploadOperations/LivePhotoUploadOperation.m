
#import "LivePhotoUploadOperation.h"
#import "AssetUploadInfo.h"
#import "CameraUploadRecordManager.h"
#import "PHAsset+CameraUpload.h"
#import "MEGAConstants.h"
#import "NSFileManager+MNZCategory.h"
#import "CameraUploadOperation+Utils.h"
#import "PHAssetResource+CameraUpload.h"
@import Photos;
@import CoreServices;

static NSString * const LivePhotoVideoResourceTemporaryName = @"video.mov";

@interface LivePhotoUploadOperation ()

@property (strong, nonatomic) AVAssetExportSession *exportSession;

@end

@implementation LivePhotoUploadOperation

- (void)start {
    [super start];
    
    [self requestLivePhoto];
}

- (void)requestLivePhoto {
    if (self.isCancelled) {
        [self finishOperationWithStatus:CameraAssetUploadStatusCancelled shouldUploadNextAsset:NO];
        return;
    }
    
    PHAssetResource *videoResource = [self.uploadInfo.asset searchAssetResourceByTypes:@[@(PHAssetResourceTypeFullSizePairedVideo), @(PHAssetResourceTypePairedVideo), @(PHAssetResourceTypeAdjustmentBasePairedVideo)]];
    if (videoResource) {
        [self writeDataForResource:videoResource];
    } else {
        MEGALogError(@"[Camera Upload] %@ can not find the video resource in live photo", self);
        [self finishOperationWithStatus:CameraAssetUploadStatusFailed shouldUploadNextAsset:YES];
    }
}

#pragma mark - write video resource to file

- (void)writeDataForResource:(PHAssetResource *)resource {
    if (self.isCancelled) {
        [self finishOperationWithStatus:CameraAssetUploadStatusCancelled shouldUploadNextAsset:NO];
        return;
    }
    
    if (resource.mnz_fileSize > NSFileManager.defaultManager.deviceFreeSize) {
        [self finishUploadWithNoEnoughDiskSpace];
        return;
    }

    NSURL *videoURL = [self.uploadInfo.directoryURL URLByAppendingPathComponent:LivePhotoVideoResourceTemporaryName];
    PHAssetResourceRequestOptions *options = [[PHAssetResourceRequestOptions alloc] init];
    options.networkAccessAllowed = YES;
    __weak __typeof__(self) weakSelf = self;
    [PHAssetResourceManager.defaultManager writeDataForAssetResource:resource toFile:videoURL options:options completionHandler:^(NSError * _Nullable error) {
        [weakSelf handleResourceWritingCompletionWithFileURL:videoURL error:error];
    }];
}

- (void)handleResourceWritingCompletionWithFileURL:(NSURL *)URL error:(NSError *)error {
    if (self.isCancelled) {
        [self finishOperationWithStatus:CameraAssetUploadStatusCancelled shouldUploadNextAsset:NO];
        return;
    }
    
    if (error) {
        MEGALogError(@"[Camera Upload] %@ error when to write resource %@", self, error);
        if ([error.domain isEqualToString:AVFoundationErrorDomain] && error.code == AVErrorDiskFull) {
            [self finishUploadWithNoEnoughDiskSpace];
        } else if ([error.domain isEqualToString:NSCocoaErrorDomain] && error.code == NSFileWriteOutOfSpaceError) {
            [self finishUploadWithNoEnoughDiskSpace];
        } else {
            [self finishOperationWithStatus:CameraAssetUploadStatusFailed shouldUploadNextAsset:YES];
        }
    } else {
        self.uploadInfo.originalFingerprint = [MEGASdkManager.sharedMEGASdk fingerprintForFilePath:URL.path modificationTime:self.uploadInfo.asset.creationDate];
        MEGANode *matchingNode = [self nodeForOriginalFingerprint:self.uploadInfo.originalFingerprint];
        if (matchingNode) {
            MEGALogDebug(@"[Camera Upload] %@ found existing node by original file fingerprint", self);
            [self finishUploadForFingerprintMatchedNode:matchingNode];
            return;
        } else {
            [self exportVideoFromResourceFileURL:URL];
        }
    }
}

#pragma mark - export video from resource file

- (void)exportVideoFromResourceFileURL:(NSURL *)videoFileURL {
    if (self.isCancelled) {
        [self finishOperationWithStatus:CameraAssetUploadStatusCancelled shouldUploadNextAsset:NO];
        return;
    }
    
    MEGALogDebug(@"[Camera Upload] %@ starts exporting live photo to video", self);
    
    AVURLAsset *urlAsset = [AVURLAsset assetWithURL:videoFileURL];
    AVAssetExportSession *session = [AVAssetExportSession exportSessionWithAsset:urlAsset presetName:AVAssetExportPresetHighestQuality];
    self.exportSession = session;
    session.outputFileType = AVFileTypeMPEG4;
    self.uploadInfo.fileName = [self mnz_generateLocalFileNamewithExtension:MEGAMP4FileExtension];
    session.outputURL = self.uploadInfo.fileURL;
    session.canPerformMultiplePassesOverSourceMediaData = YES;
    session.shouldOptimizeForNetworkUse = YES;
    session.metadataItemFilter = [AVMetadataItemFilter metadataItemFilterForSharing];
    
    __weak __typeof__(self) weakSelf = self;
    [session exportAsynchronouslyWithCompletionHandler:^{
        if (weakSelf.isCancelled) {
            [weakSelf finishOperationWithStatus:CameraAssetUploadStatusCancelled shouldUploadNextAsset:NO];
            return;
        }
        
        switch (session.status) {
            case AVAssetExportSessionStatusCompleted:
                MEGALogDebug(@"[Camera Upload] %@ finished exporting video to file %@", weakSelf, weakSelf.uploadInfo.fileName);
                [weakSelf handleProcessedVideoFile];
                break;
            case AVAssetExportSessionStatusCancelled:
                MEGALogDebug(@"[Camera Upload] %@ video exporting got cancelled", weakSelf);
                [weakSelf finishOperationWithStatus:CameraAssetUploadStatusCancelled shouldUploadNextAsset:NO];
                break;
            case AVAssetExportSessionStatusFailed:
                MEGALogError(@"[Camera Upload] %@ error when to export video %@", weakSelf, session.error)
                if ([session.error.domain isEqualToString:AVFoundationErrorDomain] && session.error.code == AVErrorDiskFull) {
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

#pragma mark - cancel live photo exporting

- (void)cancelPendingTasks {
    [super cancelPendingTasks];
    
    switch (self.exportSession.status) {
        case AVAssetExportSessionStatusWaiting:
        case AVAssetExportSessionStatusExporting:
            MEGALogDebug(@"[Camera Upload] %@ cancel live photo video exporting as the operation is cancelled", self);
            [self.exportSession cancelExport];
            break;
        default:
            break;
    }
}


@end
