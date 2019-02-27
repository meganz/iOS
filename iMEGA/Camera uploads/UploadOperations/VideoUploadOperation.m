
#import "VideoUploadOperation.h"
#import "MEGASdkManager.h"
#import "NSFileManager+MNZCategory.h"
#import "NSString+MNZCategory.h"
#import "TransferSessionManager.h"
#import "AssetUploadInfo.h"
#import "CameraUploadRecordManager.h"
#import "CameraUploadManager.h"
#import "CameraUploadRequestDelegate.h"
#import "CameraUploadManager+Settings.h"
#import "AVAsset+CameraUpload.h"
#import "AVURLAsset+CameraUpload.h"
#import "MEGAConstants.h"
#import "PHAsset+CameraUpload.h"
#import "CameraUploadOperation+Utils.h"

@interface VideoUploadOperation ()

@property (strong, nonatomic) AVAssetExportSession *exportSession;
@property (nonatomic) PHImageRequestID videoRequestId;

@end

@implementation VideoUploadOperation

#pragma mark - operation lifecycle

- (void)start {
    [super start];

    [self requestVideoData];
}

#pragma mark - data processing

- (void)requestVideoData {
    __weak __typeof__(self) weakSelf = self;
    PHVideoRequestOptions *options = [[PHVideoRequestOptions alloc] init];
    options.version = PHVideoRequestOptionsVersionCurrent;
    options.deliveryMode = PHVideoRequestOptionsDeliveryModeHighQualityFormat;
    options.networkAccessAllowed = YES;
    options.progressHandler = ^(double progress, NSError * _Nullable error, BOOL * _Nonnull stop, NSDictionary * _Nullable info) {
        if (weakSelf.isCancelled) {
            *stop = YES;
            [weakSelf finishOperationWithStatus:CameraAssetUploadStatusCancelled shouldUploadNextAsset:NO];
        }
        
        if (error != nil) {
            MEGALogError(@"[Camera Upload] %@ error when to download video from iCloud: %@", weakSelf, error);
            [weakSelf handleCloudDownloadError:error];
        }
    };
    
    
    self.videoRequestId = [PHImageManager.defaultManager requestAVAssetForVideo:self.uploadInfo.asset options:options resultHandler:^(AVAsset * _Nullable asset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
        if (weakSelf.isFinished) {
            return;
        }
        
        if ([asset isMemberOfClass:[AVURLAsset class]]) {
            AVURLAsset *urlAsset = (AVURLAsset *)asset;
            weakSelf.uploadInfo.originalFingerprint = [MEGASdkManager.sharedMEGASdk fingerprintForFilePath:urlAsset.URL.path modificationTime:weakSelf.uploadInfo.asset.creationDate];
            MEGANode *matchingNode = [weakSelf nodeForOriginalFingerprint:weakSelf.uploadInfo.originalFingerprint];
            if (matchingNode) {
                MEGALogDebug(@"[Camera Upload] %@ found existing node by original file fingerprint", weakSelf);
                [weakSelf finishUploadForFingerprintMatchedNode:matchingNode];
                return;
            }
        }
        
        [weakSelf processVideoAsset:asset];
    }];
}

- (void)processVideoAsset:(nullable AVAsset *)asset {
    if (self.isCancelled) {
        [self finishOperationWithStatus:CameraAssetUploadStatusCancelled shouldUploadNextAsset:NO];
        return;
    }
    
    if (CameraUploadManager.isHEVCFormatSupported && CameraUploadManager.shouldConvertHEVCVideo && asset.mnz_containsHEVCCodec) {
        [self transcodeHEVCVideoAsset:asset];
    } else if ([asset isMemberOfClass:[AVURLAsset class]]) {
        [self exportURLAsset:(AVURLAsset *)asset];
    } else if ([asset isMemberOfClass:[AVComposition class]]) {
        [self exportAsset:asset withPreset:AVAssetExportPresetHighestQuality outputFileType:AVFileTypeMPEG4 outputFileExtension:MEGAMP4FileExtension];
    } else {
        MEGALogError(@"[Camera Upload] %@ request video asset failed", self);
        [self finishOperationWithStatus:CameraAssetUploadStatusFailed shouldUploadNextAsset:YES];
    }
}

- (void)transcodeHEVCVideoAsset:(AVAsset *)asset {
    NSString *preset;
    switch (CameraUploadManager.HEVCToH264CompressionQuality) {
        case CameraUploadVideoQualityOriginal:
            preset = AVAssetExportPresetHighestQuality;
            break;
        case CameraUploadVideoQualityHigh:
            preset = AVAssetExportPreset1920x1080;
            break;
        case CameraUploadVideoQualityMedium:
            preset = AVAssetExportPreset1280x720;
            break;
        case CameraUploadVideoQualityLow:
            preset = AVAssetExportPreset640x480;
            break;
    }
    
    [self exportAsset:asset withPreset:preset outputFileType:AVFileTypeMPEG4 outputFileExtension:MEGAMP4FileExtension];
}

- (void)exportURLAsset:(AVURLAsset *)asset {
    if (self.uploadInfo.location) {
        NSString *preset = AVAssetExportPresetPassthrough;
        NSArray<NSString *> *compatiblePresets = [AVAssetExportSession exportPresetsCompatibleWithAsset:asset];
        if (![compatiblePresets containsObject:preset]) {
            preset = AVAssetExportPresetHighestQuality;
        }
        
        AVFileType outputFileType;
        NSString *extension;
        if (asset.mnz_isQuickTimeMovie) {
            outputFileType = AVFileTypeQuickTimeMovie;
            extension = asset.URL.pathExtension.lowercaseString;
        } else {
            outputFileType = AVFileTypeMPEG4;
            extension = MEGAMP4FileExtension;
        }
        [self exportAsset:asset withPreset:preset outputFileType:outputFileType outputFileExtension:extension];
    } else {
        [self uploadVideoAtURL:asset.URL];
    }
}

- (void)exportAsset:(AVAsset *)asset withPreset:(NSString *)preset outputFileType:(AVFileType)outputFileType outputFileExtension:(NSString *)extension {
    if (self.isCancelled) {
        [self finishOperationWithStatus:CameraAssetUploadStatusCancelled shouldUploadNextAsset:NO];
        return;
    }
    
    MEGALogDebug(@"[Camera Upload] %@ starts exporting video %@, %@, %@", self, preset, outputFileType, extension);
    if ([asset isMemberOfClass:[AVURLAsset class]]) {
        MEGALogDebug(@"[Camera Upload] %@ original video size %llu MB", self, [NSFileManager.defaultManager attributesOfItemAtPath:[(AVURLAsset *)asset URL].path error:nil].fileSize / 1024 / 1024);
    }
    
    [AVAssetExportSession determineCompatibilityOfExportPreset:preset withAsset:asset outputFileType:outputFileType completionHandler:^(BOOL compatible) {
        if (compatible) {
            AVAssetExportSession *session = [AVAssetExportSession exportSessionWithAsset:asset presetName:preset];
            self.exportSession = session;
            session.outputFileType = outputFileType;
            session.canPerformMultiplePassesOverSourceMediaData = YES;
            session.shouldOptimizeForNetworkUse = YES;
            session.metadataItemFilter = [AVMetadataItemFilter metadataItemFilterForSharing];
            
            self.uploadInfo.fileName = [self mnz_generateLocalFileNamewithExtension:extension];
            session.outputURL = self.uploadInfo.fileURL;
            
            __weak __typeof__(self) weakSelf = self;
            [session exportAsynchronouslyWithCompletionHandler:^{
                if (weakSelf.isCancelled) {
                    [weakSelf finishOperationWithStatus:CameraAssetUploadStatusCancelled shouldUploadNextAsset:NO];
                    return;
                }
                
                switch (session.status) {
                    case AVAssetExportSessionStatusCompleted:
                        MEGALogDebug(@"[Camera Upload] %@ finished exporting video to file %@", weakSelf, weakSelf.uploadInfo.fileName);
                        [weakSelf handleProcessedUploadFile];
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
        } else {
            MEGALogError(@"[Camera Upload] %@ not compatible with preset %@ and output type %@", self, preset, outputFileType);
            [self finishOperationWithStatus:CameraAssetUploadStatusFailed shouldUploadNextAsset:YES];
        }
    }];
}



- (void)uploadVideoAtURL:(NSURL *)URL {
    if (self.isCancelled) {
        [self finishOperationWithStatus:CameraAssetUploadStatusCancelled shouldUploadNextAsset:NO];
        return;
    }
    
    unsigned long long videoSize = [NSFileManager.defaultManager attributesOfItemAtPath:URL.path error:nil].fileSize;
    if (videoSize > NSFileManager.defaultManager.deviceFreeSize) {
        [self finishUploadWithNoEnoughDiskSpace];
        return;
    }
    
    self.uploadInfo.fileName = [self mnz_generateLocalFileNamewithExtension:URL.pathExtension.lowercaseString];
    NSError *error;
    [NSFileManager.defaultManager copyItemAtURL:URL toURL:self.uploadInfo.fileURL error:&error];
    if (error) {
        MEGALogError(@"[Camera Upload] %@ got error when to copy original item %@", self, error);
        if ([error.domain isEqualToString:NSCocoaErrorDomain] && error.code == NSFileWriteOutOfSpaceError) {
            [self finishUploadWithNoEnoughDiskSpace];
        } else {
            [self finishOperationWithStatus:CameraAssetUploadStatusFailed shouldUploadNextAsset:YES];
        }

        return;
    }
    
    [self handleProcessedUploadFile];
}

#pragma mark - cancel video exporting

- (void)cancelPendingTasks {
    [super cancelPendingTasks];
    
    if (self.videoRequestId != PHInvalidImageRequestID) {
        MEGALogDebug(@"[Camera Upload] %@ cancel video data request with request Id %d", self, self.videoRequestId);
        [PHImageManager.defaultManager cancelImageRequest:self.videoRequestId];
    }
    
    switch (self.exportSession.status) {
        case AVAssetExportSessionStatusWaiting:
        case AVAssetExportSessionStatusExporting:
            MEGALogDebug(@"[Camera Upload] %@ cancel video exporting as the operation is cancelled", self);
            [self.exportSession cancelExport];
            break;
        default:
            break;
    }
}

@end
