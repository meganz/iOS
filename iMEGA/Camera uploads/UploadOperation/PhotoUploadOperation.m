
#import "PhotoUploadOperation.h"
#import "MEGASdkManager.h"
#import "NSFileManager+MNZCategory.h"
#import "NSString+MNZCategory.h"
#import "TransferSessionManager.h"
#import "AssetUploadInfo.h"
#import "CameraUploadRecordManager.h"
#import "CameraUploadManager.h"
#import "CameraUploadRequestDelegate.h"

@implementation PhotoUploadOperation

#pragma mark - operation lifecycle

- (void)start {
    [super start];

    [self requestImageData];
}

- (void)dealloc {
    MEGALogDebug(@"photo upload operation gets deallocated");
}

#pragma mark - property

- (NSString *)cameraUploadBackgroundTaskName {
    return @"nz.mega.cameraUpload.photo";
}

- (NSString *)description {
    return [NSString stringWithFormat:@"Photo upload operation %@", self.uploadInfo.asset.localIdentifier];
}

#pragma mark - data processing

- (void)requestImageData {
    MEGALogDebug(@"[Camera Upload] %@ starts requesting image data", self);
    PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
    options.networkAccessAllowed = YES;
    options.version = PHImageRequestOptionsVersionCurrent;
    options.synchronous = YES;
    [[PHImageManager defaultManager] requestImageDataForAsset:self.uploadInfo.asset options:options resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
        if (self.isCancelled) {
            [self finishOperationWithStatus:UploadStatusFailed shouldUploadNextAsset:YES];
            return;
        }
        
        if (imageData) {
            [self processImageData:imageData];
        } else {
            [self finishOperationWithStatus:UploadStatusFailed shouldUploadNextAsset:YES];
        }
    }];
}

- (void)processImageData:(NSData *)imageData {
    MEGALogDebug(@"[Camera Upload] %@ starts processing image data", self);
    self.uploadInfo.originalFingerprint = [[MEGASdkManager sharedMEGASdk] fingerprintForData:imageData modificationTime:self.uploadInfo.asset.creationDate];
    MEGANode *existingNode = [[MEGASdkManager sharedMEGASdk] nodeForFingerprint:self.uploadInfo.originalFingerprint parent:self.uploadInfo.parentNode];
    if (existingNode) {
        [self processExistingNode:existingNode];
        return;
    }
    
    NSData *JPEGData = UIImageJPEGRepresentation([UIImage imageWithData:imageData], 1.0);
    self.uploadInfo.fingerprint = [[MEGASdkManager sharedMEGASdk] fingerprintForData:JPEGData modificationTime:self.uploadInfo.asset.creationDate];
    existingNode = [[MEGASdkManager sharedMEGASdk] nodeForFingerprint:self.uploadInfo.fingerprint parent:self.uploadInfo.parentNode];
    if (existingNode) {
        [self processExistingNode:existingNode];
        return;
    }
    
    NSURL *assetDirectoryURL = [[[NSFileManager defaultManager] cameraUploadURL] URLByAppendingPathComponent:self.uploadInfo.asset.localIdentifier.stringByRemovingInvalidFileCharacters isDirectory:YES];
    if(![[NSFileManager defaultManager] createDirectoryAtURL:assetDirectoryURL withIntermediateDirectories:YES attributes:nil error:nil]) {
        [self finishOperationWithStatus:UploadStatusFailed shouldUploadNextAsset:YES];
        return;
    }
    self.uploadInfo.directoryURL = assetDirectoryURL;
    self.uploadInfo.fileName = [[NSString mnz_fileNameWithDate:self.uploadInfo.asset.creationDate] stringByAppendingPathExtension:@"jpg"];
    if ([JPEGData writeToURL:self.uploadInfo.fileURL atomically:YES]) {
        self.uploadInfo.fileSize = [JPEGData length];
        [self encryptFile];
    } else {
        [self finishOperationWithStatus:UploadStatusFailed shouldUploadNextAsset:YES];
    }
}

- (void)encryptFile {
    self.uploadInfo.mediaUpload = [[MEGASdkManager sharedMEGASdk] backgroundMediaUpload];
    NSString *urlSuffix;
    if ([self.uploadInfo.mediaUpload encryptFileAtPath:self.uploadInfo.fileURL.path startPosition:0 length:self.uploadInfo.fileSize outputFilePath:self.uploadInfo.encryptedURL.path urlSuffix:&urlSuffix]) {
        MEGALogDebug(@"[Camera Upload] %@ got file encrypted with url suffix: %@", self, urlSuffix);
        
        [self createThumbnailAndPreviewFiles];
        
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

- (void)createThumbnailAndPreviewFiles {
    [self.attributesDataSDK createThumbnail:self.uploadInfo.fileURL.path destinatioPath:self.uploadInfo.thumbnailURL.path];
    [self.attributesDataSDK createPreview:self.uploadInfo.fileURL.path destinatioPath:self.uploadInfo.previewURL.path];
    self.attributesDataSDK = nil;
}

@end
