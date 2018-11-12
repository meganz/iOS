
#import "VideoUploadOperation.h"
#import "MEGASdkManager.h"
#import "NSFileManager+MNZCategory.h"
#import "NSString+MNZCategory.h"
#import "TransferSessionManager.h"
#import "AssetUploadInfo.h"
#import "CameraUploadRecordManager.h"
#import "CameraUploadManager.h"
#import "CameraUploadRequestDelegate.h"

@implementation VideoUploadOperation

#pragma mark - operation lifecycle

- (void)start {
    [super start];
    
    [self requestVideoData];
}

- (void)dealloc {
    MEGALogDebug(@"video upload operation gets deallocated");
}

#pragma mark - property

- (NSString *)cameraUploadBackgroundTaskName {
    return @"nz.mega.cameraUpload.video";
}

- (NSString *)description {
    return [NSString stringWithFormat:@"Video operation %@ %@", self.uploadInfo.asset.localIdentifier, self.uploadInfo.fileName];
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
        self.uploadInfo.directoryURL = [self URLForAssetFolder];
        self.uploadInfo.fileName = [[NSString mnz_fileNameWithDate:self.uploadInfo.asset.creationDate] stringByAppendingPathExtension:@"mp4"];
        
        if (compatible) {
            if ([session.asset isMemberOfClass:[AVURLAsset class]]) {
                AVURLAsset *urlAsset = (AVURLAsset *)session.asset;
                
                MEGALogDebug("[Camera Upload] %@ phasset creation time %@, phasset modification time %@, file creation time %@, file modification time %@, url content mtime: %@", self, self.uploadInfo.asset.creationDate, self.uploadInfo.asset.modificationDate, [NSFileManager.defaultManager attributesOfItemAtPath:urlAsset.URL.path error:nil].fileCreationDate, [NSFileManager.defaultManager attributesOfItemAtPath:urlAsset.URL.path error:nil].fileModificationDate, [urlAsset.URL resourceValuesForKeys:@[NSURLContentModificationDateKey] error:nil][NSURLContentModificationDateKey]);
                
                self.uploadInfo.originalFingerprint = [MEGASdkManager.sharedMEGASdk fingerprintForFilePath:urlAsset.URL.path modificationTime:self.uploadInfo.asset.creationDate];
                MEGANode *matchingNode = [self nodeForOriginalFingerprint:self.uploadInfo.originalFingerprint];
                if (matchingNode) {
                    MEGALogDebug(@"[Camera Upload] %@ finds existing node by original fingerprint", self);
                    [self copyToParentNodeIfNeededForMatchingNode:matchingNode];
                    [self finishOperationWithStatus:UploadStatusDone shouldUploadNextAsset:YES];
                    return;
                } else {
                    MEGALogDebug(@"[Camera Upload] %@ original file size: %lld M", self, [NSFileManager.defaultManager attributesOfItemAtPath:urlAsset.URL.path error:nil].fileSize / 1024 / 1024);
                    [self compressVideoByExportSession:session];
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
    MEGALogDebug(@"[Camera Upload] %@ starts compressing video data with original dimensions: %@", self, NSStringFromCGSize([self dimensionsForAVAsset:session.asset]));
    
    session.outputURL = self.uploadInfo.fileURL;
    session.canPerformMultiplePassesOverSourceMediaData = YES;
    session.shouldOptimizeForNetworkUse = YES;
    
    __weak __typeof__(self) weakSelf = self;
    [session exportAsynchronouslyWithCompletionHandler:^{
        switch (session.status) {
            case AVAssetExportSessionStatusCompleted:
                MEGALogDebug(@"[Camera Upload] %@ has finished video compression", weakSelf);
                [weakSelf handleCompressedVideoFile];
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

- (void)handleCompressedVideoFile {
    NSError *error;
    [NSFileManager.defaultManager setAttributes:@{NSFileModificationDate : self.uploadInfo.asset.creationDate} ofItemAtPath:self.uploadInfo.fileURL.path error:&error];
    if (error) {
        MEGALogError(@"[Camera Upload] %@ gets error when to rewrite the file creation date %@", self, error);
        [self finishOperationWithStatus:UploadStatusFailed shouldUploadNextAsset:YES];
        return;
    }
    
    self.uploadInfo.fingerprint = [MEGASdkManager.sharedMEGASdk fingerprintForFilePath:self.uploadInfo.fileURL.path modificationTime:self.uploadInfo.asset.creationDate];
    MEGANode *existingNode = [MEGASdkManager.sharedMEGASdk nodeForFingerprint:self.uploadInfo.fingerprint parent:self.uploadInfo.parentNode];
    if (existingNode) {
        MEGALogDebug(@"[Camera Upload] %@ finds existing node by fingerprint", self);
        [self copyToParentNodeIfNeededForMatchingNode:existingNode];
        [self finishOperationWithStatus:UploadStatusDone shouldUploadNextAsset:YES];
        return;
    } else {
        [self createThumbnailAndPreviewFiles];
        [self encryptsFile];
    }
}

- (void)encryptsFile {
    NSError *error;
     self.uploadInfo.fileSize = [NSFileManager.defaultManager attributesOfItemAtPath:self.uploadInfo.fileURL.path error:&error].fileSize;
    if (error) {
        MEGALogDebug(@"[Camera Upload] %@ got error when to get compressed file attributes %@", self, error)
        [self finishOperationWithStatus:UploadStatusFailed shouldUploadNextAsset:YES];
        return;
    }
    
    self.uploadInfo.mediaUpload = [MEGASdkManager.sharedMEGASdk backgroundMediaUpload];
    
    MEGALogDebug(@"[Camera Upload] %@ starts encryption with file size %@", self, @(self.uploadInfo.fileSize));
    
    NSString *urlSuffix;
    if ([self.uploadInfo.mediaUpload encryptFileAtPath:self.uploadInfo.fileURL.path startPosition:0 length:self.uploadInfo.fileSize outputFilePath:self.uploadInfo.encryptedURL.path urlSuffix:&urlSuffix]) {
        MEGALogDebug(@"[Camera Upload] %@ got file encrypted with url suffix: %@", self, urlSuffix);
        
        self.uploadInfo.uploadURLStringSuffix = urlSuffix;
        [[MEGASdkManager sharedMEGASdk] requestBackgroundUploadURLWithFileSize:self.uploadInfo.fileSize mediaUpload:self.uploadInfo.mediaUpload delegate:[[CameraUploadRequestDelegate alloc] initWithCompletion:^(MEGARequest * _Nonnull request, MEGAError * _Nonnull error) {
            if (error.type) {
                MEGALogError(@"[Camera Upload] %@ requests upload url failed with error type: %ld", self, error.type);
                [self finishOperationWithStatus:UploadStatusFailed shouldUploadNextAsset:YES];
            } else {
                self.uploadInfo.uploadURLString = [self.uploadInfo.mediaUpload uploadURLString];
                if (self.uploadInfo.uploadURL) {
                    [self uploadFileToServer];
                } else {
                    [self finishOperationWithStatus:UploadStatusFailed shouldUploadNextAsset:YES];
                }
            }
        }]];
    } else {
        MEGALogError(@"[Camera Upload] %@ encrypts file failed", self);
        [self finishOperationWithStatus:UploadStatusFailed shouldUploadNextAsset:YES];
    }
}

#pragma mark - util methods

- (CGSize)dimensionsForAVAsset:(AVAsset *)asset {
    AVAssetTrack *videoTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] firstObject];
    CGSize size = CGSizeApplyAffineTransform(videoTrack.naturalSize, videoTrack.preferredTransform);
    return CGSizeMake(fabs(size.width), fabs(size.height));
}

@end
