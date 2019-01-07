
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
    PHVideoRequestOptions *options = [[PHVideoRequestOptions alloc] init];
    options.version = PHVideoRequestOptionsVersionCurrent;
    options.deliveryMode = PHVideoRequestOptionsDeliveryModeHighQualityFormat;
    options.networkAccessAllowed = YES;
    
    __weak __typeof__(self) weakSelf = self;
    [PHImageManager.defaultManager requestAVAssetForVideo:self.uploadInfo.asset options:options resultHandler:^(AVAsset * _Nullable asset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
        if (asset) {
            if ([asset isMemberOfClass:[AVURLAsset class]]) {
                AVURLAsset *urlAsset = (AVURLAsset *)asset;
                self.uploadInfo.originalFingerprint = [MEGASdkManager.sharedMEGASdk fingerprintForFilePath:urlAsset.URL.path modificationTime:self.uploadInfo.asset.creationDate];
                MEGANode *matchingNode = [self nodeForOriginalFingerprint:self.uploadInfo.originalFingerprint];
                if (matchingNode) {
                    MEGALogDebug(@"[Camera Upload] %@ finds existing node by original fingerprint", self);
                    [self finishUploadForFingerprintMatchedNode:matchingNode];
                    return;
                }
            }
            
            [weakSelf processVideoAsset:asset];
        } else {
            MEGALogError(@"[Camera Upload] %@ request video asset failed", weakSelf);
            [weakSelf finishOperationWithStatus:CameraAssetUploadStatusFailed shouldUploadNextAsset:YES];
        }
    }];
}

- (void)processVideoAsset:(AVAsset *)asset {
    if (CameraUploadManager.shouldConvertHEVCVideo && asset.mnz_containsHEVCCodec) {
        [self transcodeHEVCVideoAsset:asset];
    } else if ([asset isMemberOfClass:[AVURLAsset class]]) {
        AVURLAsset *urlAsset = (AVURLAsset *)asset;
        if (self.uploadInfo.location) {
            if (urlAsset.mnz_isQuickTimeMovie) {
                [self exportAsset:asset withPreset:AVAssetExportPresetPassthrough outputFileType:AVFileTypeQuickTimeMovie outputFileExtension:urlAsset.URL.pathExtension];
            } else {
                [self exportAsset:asset withPreset:AVAssetExportPresetPassthrough outputFileType:AVFileTypeMPEG4 outputFileExtension:MEGAMP4FileExtension];
            }
        } else {
            [self uploadVideoAtURL:urlAsset.URL];
        }
    } else {
        [self exportAsset:asset withPreset:AVAssetExportPresetPassthrough outputFileType:AVFileTypeQuickTimeMovie outputFileExtension:MEGAQuickTimeFileExtension];
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

- (void)exportAsset:(AVAsset *)asset withPreset:(NSString *)preset outputFileType:(AVFileType)outputFileType outputFileExtension:(NSString *)extension {
    MEGALogDebug(@"[Camera Upload] %@ starts exporting video data with original dimensions: %@", self, NSStringFromCGSize(asset.mnz_dimensions));
    
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
                [weakSelf checkAndEncryptVideoFile];
                break;
            case AVAssetExportSessionStatusCancelled:
                MEGALogDebug(@"[Camera Upload] %@ video compression got cancelled", weakSelf);
                [weakSelf finishOperationWithStatus:CameraAssetUploadStatusFailed shouldUploadNextAsset:YES];
                break;
            default:
                MEGALogError(@"[Camera Upload] %@ got error when to compress video %@", weakSelf, session.error)
                [weakSelf finishOperationWithStatus:CameraAssetUploadStatusFailed shouldUploadNextAsset:YES];
                break;
        }
    }];
}

- (void)uploadVideoAtURL:(NSURL *)URL {
    self.uploadInfo.fileName = [self.uploadInfo.asset mnz_cameraUploadFileNameWithExtension:URL.pathExtension];
    NSError *error;
    [NSFileManager.defaultManager copyItemAtURL:URL toURL:self.uploadInfo.fileURL error:&error];
    if (error) {
        MEGALogDebug(@"[Camera Upload] %@ got error when to copy original item %@", self, error);
        [self finishOperationWithStatus:CameraAssetUploadStatusFailed shouldUploadNextAsset:YES];
        return;
    }
    
    [self checkAndEncryptVideoFile];
}

- (void)checkAndEncryptVideoFile {
    self.uploadInfo.fingerprint = [MEGASdkManager.sharedMEGASdk fingerprintForFilePath:self.uploadInfo.fileURL.path modificationTime:self.uploadInfo.asset.creationDate];
    MEGANode *matchingNode = [MEGASdkManager.sharedMEGASdk nodeForFingerprint:self.uploadInfo.fingerprint parent:self.uploadInfo.parentNode];
    if (matchingNode) {
        [self finishUploadForFingerprintMatchedNode:matchingNode];
        return;
    }
    
    [self encryptsFile];
}

@end
