
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

@implementation VideoUploadOperation

#pragma mark - operation lifecycle

- (void)start {
    [super start];
    
    [self requestVideoData];
}

#pragma mark - data processing

- (void)requestVideoData {
    MEGALogDebug(@"[Camera Upload] %@ starts requesting video data", self);
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
    
    
    [PHImageManager.defaultManager requestAVAssetForVideo:self.uploadInfo.asset options:options resultHandler:^(AVAsset * _Nullable asset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
        if (weakSelf.isFinished) {
            return;
        }
        
        if ([asset isMemberOfClass:[AVURLAsset class]]) {
            AVURLAsset *urlAsset = (AVURLAsset *)asset;
            weakSelf.uploadInfo.originalFingerprint = [MEGASdkManager.sharedMEGASdk fingerprintForFilePath:urlAsset.URL.path modificationTime:weakSelf.uploadInfo.asset.creationDate];
            MEGANode *matchingNode = [weakSelf nodeForOriginalFingerprint:weakSelf.uploadInfo.originalFingerprint];
            if (matchingNode) {
                MEGALogDebug(@"[Camera Upload] %@ finds existing node by original fingerprint", weakSelf);
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
    
    if (CameraUploadManager.shouldConvertHEVCVideo && asset.mnz_containsHEVCCodec) {
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
    
    MEGALogDebug(@"[Camera Upload] %@ starts exporting video data with original dimensions: %@", self, NSStringFromCGSize(asset.mnz_dimensions));
    
    [AVAssetExportSession determineCompatibilityOfExportPreset:preset withAsset:asset outputFileType:outputFileType completionHandler:^(BOOL compatible) {
        if (compatible) {
            AVAssetExportSession *session = [AVAssetExportSession exportSessionWithAsset:asset presetName:preset];
            session.outputFileType = outputFileType;
            session.canPerformMultiplePassesOverSourceMediaData = YES;
            session.shouldOptimizeForNetworkUse = YES;
            session.metadataItemFilter = [AVMetadataItemFilter metadataItemFilterForSharing];
            
            self.uploadInfo.fileName = [self.uploadInfo.asset mnz_cameraUploadFileNameWithExtension:extension];
            session.outputURL = self.uploadInfo.fileURL;
            
            __weak __typeof__(self) weakSelf = self;
            [session exportAsynchronouslyWithCompletionHandler:^{
                switch (session.status) {
                    case AVAssetExportSessionStatusCompleted:
                        MEGALogDebug(@"[Camera Upload] %@ has finished video compression", weakSelf);
                        [weakSelf handleProcessedUploadFile];
                        break;
                    case AVAssetExportSessionStatusCancelled:
                        MEGALogDebug(@"[Camera Upload] %@ video compression got cancelled", weakSelf);
                        [weakSelf finishOperationWithStatus:CameraAssetUploadStatusCancelled shouldUploadNextAsset:YES];
                        break;
                    case AVAssetExportSessionStatusFailed:
                        MEGALogError(@"[Camera Upload] %@ got error when to compress video %@", weakSelf, session.error)
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
        } else {
            MEGALogError(@"[Camera Upload] %@ doesn't compatible with preset %@ and output file type %@", self, preset, outputFileType);
            [self finishOperationWithStatus:CameraAssetUploadStatusFailed shouldUploadNextAsset:YES];
        }
    }];
}

- (void)uploadVideoAtURL:(NSURL *)URL {
    if (self.isCancelled) {
        [self finishOperationWithStatus:CameraAssetUploadStatusCancelled shouldUploadNextAsset:NO];
        return;
    }
    
    unsigned long long videoSize = [NSFileManager.defaultManager attributesOfItemAtPath:self.uploadInfo.fileURL.path error:nil].fileSize;
    if (videoSize > NSFileManager.defaultManager.deviceFreeSize) {
        [self finishUploadWithNoEnoughDiskSpace];
        return;
    }
    
    self.uploadInfo.fileName = [self.uploadInfo.asset mnz_cameraUploadFileNameWithExtension:URL.pathExtension.lowercaseString];
    NSError *error;
    [NSFileManager.defaultManager copyItemAtURL:URL toURL:self.uploadInfo.fileURL error:&error];
    if (error) {
        MEGALogDebug(@"[Camera Upload] %@ got error when to copy original item %@", self, error);
        if (error.domain == NSCocoaErrorDomain && error.code == NSFileWriteOutOfSpaceError) {
            [self finishUploadWithNoEnoughDiskSpace];
        } else {
            [self finishOperationWithStatus:CameraAssetUploadStatusFailed shouldUploadNextAsset:YES];
        }

        return;
    }
    
    [self handleProcessedUploadFile];
}

@end
