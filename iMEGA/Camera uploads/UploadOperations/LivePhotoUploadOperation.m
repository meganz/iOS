
#import "LivePhotoUploadOperation.h"
#import "CameraUploadOperation+Utils.h"
#import "PHAssetResource+CameraUpload.h"
#import "CameraUploadManager+Settings.h"
#import "MEGA-Swift.h"
@import Photos;
@import CoreServices;
@import FirebaseCrashlytics;

static NSString * const LivePhotoVideoResourceExportName = @"livePhotoVideoResource.mov";

@interface LivePhotoUploadOperation () <AssetResourcExportDelegate>

@property (strong, nonatomic) AVAssetExportSession *exportSession;

@end

@implementation LivePhotoUploadOperation

- (void)start {
    [super start];
    
    [self requestLivePhotoResource];
}

- (void)requestLivePhotoResource {
    if (self.isCancelled) {
        [self finishOperationWithStatus:CameraAssetUploadStatusCancelled];
        return;
    }

    PHAssetResource *videoResource = self.uploadInfo.asset.mnz_livePhotoResource;
    if (videoResource) {
        NSURL *videoURL = [self.uploadInfo.directoryURL URLByAppendingPathComponent:LivePhotoVideoResourceExportName];
        [self exportAssetResource:videoResource toURL:videoURL delegate:self];
    } else {
        MEGALogError(@"[Camera Upload] %@ can not find the video resource in live photo", self);
        [self finishOperationWithStatus:CameraAssetUploadStatusFailed];
    }
}

- (UploadQueueType)uploadQueueType {
    return UploadQueueTypeVideo;
}

#pragma mark - asset resource export delegate

- (void)assetResource:(PHAssetResource *)resource didExportToURL:(NSURL *)URL {
    MEGALogDebug(@"[Camera Upload] %@ starts exporting live photo to video", self);
    
    AVURLAsset *urlAsset = [AVURLAsset assetWithURL:URL];
    AVAssetExportSession *session = [AVAssetExportSession exportSessionWithAsset:urlAsset presetName:AVAssetExportPresetHighestQuality];
    self.exportSession = session;
    session.outputFileType = AVFileTypeMPEG4;
    
    NSError *error;
    self.uploadInfo.fileName = [self mnz_generateLocalFileNamewithExtension:MEGAMP4FileExtension error:&error];
    if (error) {
        MEGALogError(@"[Camera Upload] %@ error when to generate local unique file name %@", self, error);
        [[FIRCrashlytics crashlytics] recordError:error];
        [self finishOperationWithStatus:CameraAssetUploadStatusFailed];
        return;
    }
    
    session.outputURL = self.uploadInfo.fileURL;
    session.canPerformMultiplePassesOverSourceMediaData = YES;
    session.shouldOptimizeForNetworkUse = YES;
    
    if (!CameraUploadManager.shouldIncludeGPSTags) {
        session.metadataItemFilter = [AVMetadataItemFilter metadataItemFilterForSharing];
    }
    
    __weak __typeof__(self) weakSelf = self;
    [session exportAsynchronouslyWithCompletionHandler:^{
        if (weakSelf.isCancelled) {
            [weakSelf finishOperationWithStatus:CameraAssetUploadStatusCancelled];
            return;
        }
        
        switch (session.status) {
            case AVAssetExportSessionStatusCompleted:
                MEGALogDebug(@"[Camera Upload] %@ finished exporting video to file %@", weakSelf, weakSelf.uploadInfo.fileName);
                [weakSelf handleProcessedFileWithMediaType:PHAssetMediaTypeVideo];
                break;
            case AVAssetExportSessionStatusCancelled:
                MEGALogDebug(@"[Camera Upload] %@ video exporting got cancelled", weakSelf);
                [weakSelf finishOperationWithStatus:CameraAssetUploadStatusCancelled];
                break;
            case AVAssetExportSessionStatusFailed:
                MEGALogError(@"[Camera Upload] %@ error when to export video %@", weakSelf, session.error)
                if ([session.error.domain isEqualToString:AVFoundationErrorDomain] && session.error.code == AVErrorDiskFull) {
                    [weakSelf finishUploadWithNoEnoughDiskSpace];
                } else {
                    [weakSelf finishOperationWithStatus:CameraAssetUploadStatusFailed];
                }
                break;
            default:
                break;
        }
    }];
}

#pragma mark - cancel operation

- (void)cancel {
    [super cancel];
    
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
