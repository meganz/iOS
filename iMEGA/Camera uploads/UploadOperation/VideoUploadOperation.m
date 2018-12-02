
#import "VideoUploadOperation.h"
#import "MEGASdkManager.h"
#import "NSFileManager+MNZCategory.h"
#import "NSString+MNZCategory.h"
#import "TransferSessionManager.h"
#import "AssetUploadInfo.h"
#import "CameraUploadRecordManager.h"
#import "CameraUploadManager.h"
#import "CameraUploadRequestDelegate.h"
#import "CameraUploadFileNameRecordManager.h"

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
    
    // TODO: the preset should configurable in settings
    __weak __typeof__(self) weakSelf = self;
    [PHImageManager.defaultManager requestExportSessionForVideo:self.uploadInfo.asset options:options exportPreset:AVAssetExportPresetHighestQuality resultHandler:^(AVAssetExportSession * _Nullable exportSession, NSDictionary * _Nullable info) {
        if (exportSession) {
            [weakSelf processRequestedVideoExportSession:exportSession];
        } else {
            MEGALogError(@"[Camera Upload] %@ error when to request export session %@", weakSelf, info);
            [weakSelf finishOperationWithStatus:UploadStatusFailed shouldUploadNextAsset:YES];
        }
    }];
}

- (void)processRequestedVideoExportSession:(AVAssetExportSession *)session {
    // TODO: the format should be configurate, between HEVC and H.264
    session.outputFileType = AVFileTypeMPEG4;
    [AVAssetExportSession determineCompatibilityOfExportPreset:session.presetName withAsset:session.asset outputFileType:session.outputFileType completionHandler:^(BOOL compatible) {
        if (compatible) {
            if ([session.asset isMemberOfClass:[AVURLAsset class]]) {
                AVURLAsset *urlAsset = (AVURLAsset *)session.asset;
                
                MEGALogDebug("[Camera Upload] %@ phasset creation time %@, phasset modification time %@, file creation time %@, file modification time %@", self, self.uploadInfo.asset.creationDate, self.uploadInfo.asset.modificationDate, [NSFileManager.defaultManager attributesOfItemAtPath:urlAsset.URL.path error:nil].fileCreationDate, [NSFileManager.defaultManager attributesOfItemAtPath:urlAsset.URL.path error:nil].fileModificationDate);
                
                self.uploadInfo.originalFingerprint = [MEGASdkManager.sharedMEGASdk fingerprintForFilePath:urlAsset.URL.path modificationTime:self.uploadInfo.asset.creationDate];
                MEGANode *matchingNode = [self nodeForOriginalFingerprint:self.uploadInfo.originalFingerprint];
                if (matchingNode) {
                    MEGALogDebug(@"[Camera Upload] %@ finds existing node by original fingerprint", self);
                    [self copyToParentNodeIfNeededForMatchingNode:matchingNode];
                    [self finishOperationWithStatus:UploadStatusDone shouldUploadNextAsset:YES];
                    return;
                } else {
                    MEGALogDebug(@"[Camera Upload] %@ original file size: %.2f M", self, [NSFileManager.defaultManager attributesOfItemAtPath:urlAsset.URL.path error:nil].fileSize / 1024.0f / 1024.0f);
//                    [self compressVideoByExportSession:session];
                    [self processOriginalURLAsset:urlAsset];
                }
            } else {
                [self compressVideoByExportSession:session];
            }
        } else {
            MEGALogError(@"[Camera Upload] %@ doesn't compatible with preset %@ and output file type %@", self, session.presetName, session.outputFileType);
        }
    }];
}

- (void)compressVideoByExportSession:(AVAssetExportSession *)session {
    MEGALogDebug(@"[Camera Upload] video estimate duration: %.2f, max duration: %.2f, estimate size: %.2f M", CMTimeGetSeconds(session.asset.duration), CMTimeGetSeconds(session.maxDuration), session.estimatedOutputFileLength / 1024.0f / 1024.0f)
    
    MEGALogDebug(@"[Camera Upload] %@ starts compressing video data with original dimensions: %@", self, NSStringFromCGSize([self dimensionsForAVAsset:session.asset]));

    NSString *proposedFileName = [[NSString mnz_fileNameWithDate:self.uploadInfo.asset.creationDate] stringByAppendingPathExtension:@"mp4"];
    self.uploadInfo.fileName = [CameraUploadFileNameRecordManager.shared localUniqueFileNameForAssetLocalIdentifier:self.uploadInfo.asset.localIdentifier proposedFileName:proposedFileName];
    
    session.outputURL = self.uploadInfo.fileURL;
    session.canPerformMultiplePassesOverSourceMediaData = YES;
    session.shouldOptimizeForNetworkUse = YES;
    session.metadataItemFilter = [AVMetadataItemFilter metadataItemFilterForSharing];
    
    __weak __typeof__(self) weakSelf = self;
    [session exportAsynchronouslyWithCompletionHandler:^{
        switch (session.status) {
            case AVAssetExportSessionStatusCompleted:
                MEGALogDebug(@"[Camera Upload] %@ has finished video compression", weakSelf);
                [weakSelf processCompressedVideoFile];
                break;
            case AVAssetExportSessionStatusCancelled:
                MEGALogDebug(@"[Camera Upload] %@ video compression got cancelled", weakSelf);
                [weakSelf finishOperationWithStatus:UploadStatusFailed shouldUploadNextAsset:YES];
                break;
            default:
                MEGALogError(@"[Camera Upload] %@ got error when to compress video %@", weakSelf, session.error)
                [weakSelf finishOperationWithStatus:UploadStatusFailed shouldUploadNextAsset:YES];
                break;
        }
    }];
}

- (void)processCompressedVideoFile {
    self.uploadInfo.fingerprint = [MEGASdkManager.sharedMEGASdk fingerprintForFilePath:self.uploadInfo.fileURL.path modificationTime:self.uploadInfo.asset.creationDate];
    MEGANode *existingNode = [MEGASdkManager.sharedMEGASdk nodeForFingerprint:self.uploadInfo.fingerprint parent:self.uploadInfo.parentNode];
    if (existingNode) {
        MEGALogDebug(@"[Camera Upload] %@ finds existing node by fingerprint", self);
        [self copyToParentNodeIfNeededForMatchingNode:existingNode];
        [self finishOperationWithStatus:UploadStatusDone shouldUploadNextAsset:YES];
        return;
    } else {
        [self encryptsFile];
    }
}

- (void)processOriginalURLAsset:(AVURLAsset *)asset {
    NSString *proposedFileName = [[NSString mnz_fileNameWithDate:self.uploadInfo.asset.creationDate] stringByAppendingPathExtension:asset.URL.pathExtension];
    self.uploadInfo.fileName = [CameraUploadFileNameRecordManager.shared localUniqueFileNameForAssetLocalIdentifier:self.uploadInfo.asset.localIdentifier proposedFileName:proposedFileName];
    self.uploadInfo.fingerprint = self.uploadInfo.originalFingerprint;
    NSError *error;
    [NSFileManager.defaultManager copyItemAtURL:asset.URL toURL:self.uploadInfo.fileURL error:&error];
    if (error) {
        MEGALogDebug(@"[Camera Upload] %@ got error when to copy original item %@", self, error);
        [self finishOperationWithStatus:UploadStatusFailed shouldUploadNextAsset:YES];
        return;
    }

    [self encryptsFile];
}

#pragma mark - util methods

- (CGSize)dimensionsForAVAsset:(AVAsset *)asset {
    AVAssetTrack *videoTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] firstObject];
    CGSize size = CGSizeApplyAffineTransform(videoTrack.naturalSize, videoTrack.preferredTransform);
    return CGSizeMake(fabs(size.width), fabs(size.height));
}

@end
