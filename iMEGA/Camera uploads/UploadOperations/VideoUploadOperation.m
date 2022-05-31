
#import "VideoUploadOperation.h"
#import "NSFileManager+MNZCategory.h"
#import "CameraUploadManager+Settings.h"
#import "AVAsset+CameraUpload.h"
#import "AVURLAsset+CameraUpload.h"
#import "CameraUploadOperation+Utils.h"
#import "MEGA-Swift.h"
@import FirebaseCrashlytics;

@interface VideoUploadOperation ()

@property (strong, nonatomic) AVAssetExportSession *exportSession;
@property (nonatomic) PHImageRequestID videoRequestId;

@end

@implementation VideoUploadOperation

#pragma mark - operation lifecycle

- (void)start {
    [super start];

    [self requestVideoDataByVersion:PHVideoRequestOptionsVersionOriginal];
}

#pragma mark - data processing

- (UploadQueueType)uploadQueueType {
    return UploadQueueTypeVideo;
}

- (void)requestVideoDataByVersion:(PHVideoRequestOptionsVersion)version {
    if (self.isCancelled) {
        [self finishOperationWithStatus:CameraAssetUploadStatusCancelled];
        return;
    }
    
    __weak __typeof__(self) weakSelf = self;
    PHVideoRequestOptions *options = [[PHVideoRequestOptions alloc] init];
    options.version = version;
    options.deliveryMode = PHVideoRequestOptionsDeliveryModeHighQualityFormat;
    options.networkAccessAllowed = YES;
    options.progressHandler = ^(double progress, NSError * _Nullable error, BOOL * _Nonnull stop, NSDictionary * _Nullable info) {
        if (weakSelf.isCancelled) {
            *stop = YES;
            [weakSelf finishOperationWithStatus:CameraAssetUploadStatusCancelled];
        }
        
        if (error) {
            MEGALogError(@"[Camera Upload] %@ error when to download video from iCloud: %@", weakSelf, error);
            *stop = YES;
            [weakSelf handleAssetDownloadError:error];
        }
    };
    
    
    self.videoRequestId = [PHImageManager.defaultManager requestAVAssetForVideo:self.uploadInfo.asset options:options resultHandler:^(AVAsset * _Nullable asset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
        if (weakSelf.isFinished) {
            return;
        }
        
        if (weakSelf.isCancelled) {
            [weakSelf finishOperationWithStatus:CameraAssetUploadStatusCancelled];
            return;
        }
        
        NSError *error = info[PHImageErrorKey];
        if (error) {
            MEGALogError(@"[Camera Upload] %@ error when to request video %@", weakSelf, error);
            [weakSelf finishOperationWithStatus:CameraAssetUploadStatusFailed];
            return;
        }
        
        if ([info[PHImageCancelledKey] boolValue]) {
            MEGALogDebug(@"[Camera Upload] %@ video request is cancelled", weakSelf);
            [weakSelf finishOperationWithStatus:CameraAssetUploadStatusCancelled];
            return;
        }
        
        [weakSelf handleRequestedAsset:asset version:version];
    }];
}

- (void)handleRequestedAsset:(nullable AVAsset *)asset version:(PHVideoRequestOptionsVersion)version {
    if (self.isCancelled) {
        [self finishOperationWithStatus:CameraAssetUploadStatusCancelled];
        return;
    }
    
    if (asset == nil) {
        [self finishOperationWithStatus:CameraAssetUploadStatusFailed];
        return;
    }
    
    if (version == PHVideoRequestOptionsVersionOriginal) {
        if ([asset isKindOfClass:[AVURLAsset class]]) {
            AVURLAsset *urlAsset = (AVURLAsset *)asset;
            self.uploadInfo.originalFingerprint = [MEGASdkManager.sharedMEGASdk fingerprintForFilePath:urlAsset.URL.path modificationTime:self.uploadInfo.asset.creationDate];
            MEGANode *matchingNode = [self nodeForOriginalFingerprint:self.uploadInfo.originalFingerprint];
            if (matchingNode) {
                MEGALogDebug(@"[Camera Upload] %@ found existing node by original file fingerprint", self);
                [self finishUploadForFingerprintMatchedNode:matchingNode];
                return;
            }
        }
        
        [self requestVideoDataByVersion:PHVideoRequestOptionsVersionCurrent];
    } else {
        [self exportVideoAsset:asset];
    }
}

- (void)exportVideoAsset:(nullable AVAsset *)asset {
    if (self.isCancelled) {
        [self finishOperationWithStatus:CameraAssetUploadStatusCancelled];
        return;
    }
    
    if (CameraUploadManager.shouldConvertHEVCVideo && asset.mnz_containsHEVCCodec) {
        [self transcodeHEVCVideoAsset:asset];
    } else if ([asset isKindOfClass:[AVURLAsset class]]) {
        [self exportAsset:asset withPreset:AVAssetExportPresetPassthrough outputFileType:AVFileTypeMPEG4 outputFileExtension:MEGAMP4FileExtension enableExportOptions:YES];
    } else if ([asset isKindOfClass:[AVComposition class]]) {
        [self exportAsset:asset withPreset:AVAssetExportPresetHighestQuality outputFileType:AVFileTypeMPEG4 outputFileExtension:MEGAMP4FileExtension enableExportOptions:YES];
    } else {
        MEGALogError(@"[Camera Upload] %@ request video asset failed", self);
        [self finishOperationWithStatus:CameraAssetUploadStatusFailed];
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
    
    [self exportAsset:asset withPreset:preset outputFileType:AVFileTypeMPEG4 outputFileExtension:MEGAMP4FileExtension enableExportOptions:YES];
}

- (void)exportAsset:(AVAsset *)asset withPreset:(NSString *)preset outputFileType:(AVFileType)outputFileType outputFileExtension:(NSString *)extension enableExportOptions:(BOOL)exportOptionsEnabled {
    if (self.isCancelled) {
        [self finishOperationWithStatus:CameraAssetUploadStatusCancelled];
        return;
    }
    
    MEGALogDebug(@"[Camera Upload] %@ starts exporting video %@, %@, %@", self, preset, outputFileType, extension);
    if ([asset isKindOfClass:[AVURLAsset class]]) {
        MEGALogDebug(@"[Camera Upload] %@ original video size %llu MB", self, [NSFileManager.defaultManager attributesOfItemAtPath:[(AVURLAsset *)asset URL].path error:nil].fileSize / 1024 / 1024);
    }
    
    [AVAssetExportSession determineCompatibilityOfExportPreset:preset withAsset:asset outputFileType:outputFileType completionHandler:^(BOOL compatible) {
        if (compatible) {
            AVAssetExportSession *session = [AVAssetExportSession exportSessionWithAsset:asset presetName:preset];
            self.exportSession = session;
            session.outputFileType = outputFileType;
            
            if (!CameraUploadManager.shouldIncludeGPSTags) {
                session.metadataItemFilter = [AVMetadataItemFilter metadataItemFilterForSharing];
            }
            
            if (exportOptionsEnabled) {
                session.canPerformMultiplePassesOverSourceMediaData = YES;
                session.shouldOptimizeForNetworkUse = YES;
            }
            
            NSError *error;
            self.uploadInfo.fileName = [self mnz_generateLocalFileNamewithExtension:extension error:&error];
            if (error) {
                MEGALogError(@"[Camera Upload] %@ error when to generate local unique file name %@", self, error);
                [[FIRCrashlytics crashlytics] recordError:error];
                [self finishOperationWithStatus:CameraAssetUploadStatusFailed];
                return;
            }
            
            session.outputURL = self.uploadInfo.fileURL;
            
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
                        } else if (exportOptionsEnabled) {
                            MEGALogDebug(@"[Camera Upload] %@ export options enabled, Now try disabling export options and try exporting", weakSelf);
                            [weakSelf exportAsset:asset withPreset:preset outputFileType:outputFileType outputFileExtension:extension enableExportOptions:NO];
                        } else {
                            [weakSelf finishOperationWithStatus:CameraAssetUploadStatusFailed];
                        }
                        
                        break;
                    default:
                        break;
                }
            }];
        } else {
            MEGALogError(@"[Camera Upload] %@ not compatible with preset %@ and output type %@", self, preset, outputFileType);
            if ([asset isKindOfClass:[AVURLAsset class]]) {
                [self uploadVideoAtURL: [(AVURLAsset *)asset URL]];
            } else {
                [self finishOperationWithStatus:CameraAssetUploadStatusFailed];
            }
        }
    }];
}

- (void)uploadVideoAtURL:(NSURL *)URL {
    if (self.isCancelled) {
        [self finishOperationWithStatus:CameraAssetUploadStatusCancelled];
        return;
    }
    
    unsigned long long videoSize = [NSFileManager.defaultManager attributesOfItemAtPath:URL.path error:nil].fileSize;
    if (videoSize > NSFileManager.defaultManager.mnz_fileSystemFreeSize) {
        [self finishUploadWithNoEnoughDiskSpace];
        return;
    }
    
    NSError *fileNameError;
    self.uploadInfo.fileName = [self mnz_generateLocalFileNamewithExtension:URL.pathExtension.lowercaseString error:&fileNameError];
    if (fileNameError) {
        MEGALogError(@"[Camera Upload] %@ error when to generate local unique file name %@", self, fileNameError);
        [[FIRCrashlytics crashlytics] recordError:fileNameError];
        [self finishOperationWithStatus:CameraAssetUploadStatusFailed];
        return;
    }
    
    NSError *error;
    [NSFileManager.defaultManager copyItemAtURL:URL toURL:self.uploadInfo.fileURL error:&error];
    if (error) {
        MEGALogError(@"[Camera Upload] %@ got error when to copy original item %@", self, error);
        if ([error.domain isEqualToString:NSCocoaErrorDomain] && error.code == NSFileWriteOutOfSpaceError) {
            [self finishUploadWithNoEnoughDiskSpace];
        } else {
            [self finishOperationWithStatus:CameraAssetUploadStatusFailed];
        }

        return;
    }
    
    [self handleProcessedFileWithMediaType:PHAssetMediaTypeVideo];
}

#pragma mark - cancel operation

- (void)cancel {
    [super cancel];
    
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
