
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
    return [NSString stringWithFormat:@"Video upload operation %@", self.uploadInfo.asset.localIdentifier];
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
            [weakSelf processVideoExportSession:exportSession];
        } else {
            MEGALogError(@"[Camera Upload] %@ error when to request export session %@", weakSelf, info);
            [weakSelf finishOperationWithStatus:UploadStatusFailed shouldUploadNextAsset:YES];
        }
    }];
}

- (void)processVideoExportSession:(AVAssetExportSession *)session {
    // TODO: the format should be configurate, between HEVC and H.264
    session.outputFileType = AVFileTypeMPEG4;
    [AVAssetExportSession determineCompatibilityOfExportPreset:session.presetName withAsset:session.asset outputFileType:session.outputFileType completionHandler:^(BOOL compatible) {
        self.uploadInfo.directoryURL = [self URLForAssetFolder];
        self.uploadInfo.fileName = [[NSString mnz_fileNameWithDate:self.uploadInfo.asset.creationDate] stringByAppendingPathExtension:@"mp4"];
        
        if (compatible) {
            if ([session.asset isMemberOfClass:[AVURLAsset class]]) {
                AVURLAsset *urlAsset = (AVURLAsset *)session.asset;
                NSError *error;
                [NSFileManager.defaultManager copyItemAtURL:urlAsset.URL toURL:self.uploadInfo.originalURL error:&error];
                if (error) {
                    MEGALogError(@"[Camera Upload] %@ gets error when to copy original asset file %@", self, error);
                    [self finishOperationWithStatus:UploadStatusFailed shouldUploadNextAsset:YES];
                    return;
                }
                
                [NSFileManager.defaultManager setAttributes:@{NSFileModificationDate : self.uploadInfo.asset.creationDate} ofItemAtPath:self.uploadInfo.originalURL.path error:&error];
                if (error) {
                    MEGALogError(@"[Camera Upload] %@ gets error when to rewrite the file creation date %@", self, error);
                    [self finishOperationWithStatus:UploadStatusFailed shouldUploadNextAsset:YES];
                    return;
                }
                
                self.uploadInfo.originalFingerprint = [MEGASdkManager.sharedMEGASdk fingerprintForFilePath:self.uploadInfo.originalURL.path];
                MEGANodeList *matchingNodeList = [MEGASdkManager.sharedMEGASdk nodesForOriginalFingerprint:self.uploadInfo.originalFingerprint];
                if (matchingNodeList.size.integerValue > 0) {
                    [self copyToParentNodeIfNeededForMatchingNodeList:matchingNodeList];
                    [self finishOperationWithStatus:UploadStatusDone shouldUploadNextAsset:YES];
                    return;
                } else {
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
    MEGALogError(@"[Camera Upload] %@ starts compressing video data", self);
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
    
    self.uploadInfo.fingerprint = [MEGASdkManager.sharedMEGASdk fingerprintForFilePath:self.uploadInfo.fileURL.path];
    MEGANode *existingNode = [MEGASdkManager.sharedMEGASdk nodeForFingerprint:self.uploadInfo.fingerprint parent:self.uploadInfo.parentNode];
    if (existingNode) {
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
    NSNumber *fileSize = [NSFileManager.defaultManager attributesOfItemAtPath:self.uploadInfo.fileURL.path error:&error][NSFileSize];
    if (error) {
        MEGALogDebug(@"[Camera Upload] %@ got error when to get compressed file attributes %@", self, error)
        [self finishOperationWithStatus:UploadStatusFailed shouldUploadNextAsset:YES];
        return;
    }

    self.uploadInfo.fileSize = [fileSize unsignedIntegerValue];
    self.uploadInfo.mediaUpload = [MEGASdkManager.sharedMEGASdk backgroundMediaUpload];
    
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

@end
