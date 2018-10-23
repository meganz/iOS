
#import "AssetUploadOperation.h"
#import "MEGASdkManager.h"
#import "NSFileManager+MNZCategory.h"
#import "NSString+MNZCategory.h"
#import "TransferSessionManager.h"
#import "AssetUploadFile.h"
#import "MEGAGetThumbnailRequestDelegate.h"
#import "MEGAGetPreviewRequestDelegate.h"
#import "AssetUploadRecordCoreDataManager.h"
#import "CameraUploadManager.h"
@import Photos;

static NSString * const cameraUploadBackgroundTaskName = @"mega.nz.cameraUpload";

@interface AssetUploadOperation () <MEGARequestDelegate>

@property (strong, nonatomic) PHAsset *asset;
@property (strong, nonatomic) AssetUploadFile *uploadFile;
@property (strong, nonatomic) MEGABackgroundMediaUpload *mediaUploader;
@property (strong, nonatomic) MEGANode *cameraUploadNode;
@property (nonatomic) UIBackgroundTaskIdentifier uploadTaskIdentifier;

@end

@implementation AssetUploadOperation

- (instancetype)initWithAsset:(PHAsset *)asset cameraUploadNode:(MEGANode *)node {
    self = [super init];
    if (self) {
        _asset = asset;
        _cameraUploadNode = node;
        _uploadFile = [[AssetUploadFile alloc] init];
    }
    
    return self;
}

- (instancetype)initWithLocalIdentifier:(NSString *)localIdentifier cameraUploadNode:(MEGANode *)node {
    PHAsset *asset = [[PHAsset fetchAssetsWithLocalIdentifiers:@[localIdentifier] options:nil] firstObject];
    return [self initWithAsset:asset cameraUploadNode:node];
}

- (void)start {
    [super start];
    
    if (self.asset == nil) {
        [[AssetUploadRecordCoreDataManager shared] deleteRecordsByLocalIdentifiers:@[self.asset.localIdentifier] error:nil];
        [self finishOperation];
        return;
    }
    
    self.uploadTaskIdentifier = [UIApplication.sharedApplication beginBackgroundTaskWithName:cameraUploadBackgroundTaskName expirationHandler:^{
        [UIApplication.sharedApplication endBackgroundTask:self.uploadTaskIdentifier];
        self.uploadTaskIdentifier = UIBackgroundTaskInvalid;
    }];
    
    [[AssetUploadRecordCoreDataManager shared] updateStatus:uploadStatusUploading forLocalIdentifier:self.asset.localIdentifier error:nil];
    
    PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
    options.networkAccessAllowed = YES;
    options.version = PHImageRequestOptionsVersionCurrent;
    options.synchronous = YES;
    [[PHImageManager defaultManager] requestImageDataForAsset:self.asset options:options resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
        if (self.isCancelled) {
            [self finishOperationWithStatus:uploadStatusFailed];
            return;
        }
        
        if (imageData) {
            [self processImageData:imageData];
        } else {
            [self finishOperationWithStatus:uploadStatusFailed];
        }
    }];
}

- (void)processImageData:(NSData *)imageData {
    self.uploadFile.originalFingerprint = [[MEGASdkManager sharedMEGASdk] fingerprintForData:imageData modificationTime:self.asset.modificationDate];
    MEGANode *existingNode = [[MEGASdkManager sharedMEGASdk] nodeForFingerprint:self.uploadFile.originalFingerprint parent:self.cameraUploadNode];
    if (existingNode) {
        [self processExistingNode:existingNode];
        return;
    }
    
    NSData *JPEGData = UIImageJPEGRepresentation([UIImage imageWithData:imageData], 1.0);
    self.uploadFile.fingerprint = [[MEGASdkManager sharedMEGASdk] fingerprintForData:JPEGData modificationTime:self.asset.modificationDate];
    existingNode = [[MEGASdkManager sharedMEGASdk] nodeForFingerprint:self.uploadFile.fingerprint parent:self.cameraUploadNode];
    if (existingNode) {
        [self processExistingNode:existingNode];
        return;
    }

    NSURL *assetURL = [[[NSFileManager defaultManager] cameraUploadURL] URLByAppendingPathComponent:self.asset.localIdentifier isDirectory:YES];
    if(![[NSFileManager defaultManager] createDirectoryAtURL:assetURL withIntermediateDirectories:YES attributes:nil error:nil]) {
        [self finishOperationWithStatus:uploadStatusFailed];
        return;
    }
    
    self.uploadFile.fileName = [[NSString mnz_fileNameWithDate:self.asset.creationDate] stringByAppendingPathExtension:@"jpg"];
    if ([JPEGData writeToURL:self.uploadFile.fileURL atomically:YES]) {
        self.uploadFile.fileSize = [JPEGData length];
        [self processUploadFile];
    } else {
        [self finishOperationWithStatus:uploadStatusFailed];
    }
}

- (void)processUploadFile {
    self.mediaUploader = [[MEGASdkManager sharedMEGASdk] backgroundMediaUpload];
    NSString *urlSuffix;
    if ([self.mediaUploader encryptFileAtPath:self.uploadFile.fileURL.path startPosition:0 length:self.uploadFile.fileSize outputFilePath:self.uploadFile.encryptedURL.path urlSuffix:&urlSuffix]) {
        MEGALogDebug(@"url suffix %@", urlSuffix);
        self.uploadFile.uploadURLStringSuffix = urlSuffix;
        [[MEGASdkManager sharedMEGASdk] requestBackgroundUploadURLWithFileSize:self.uploadFile.fileSize mediaUpload:self.mediaUploader delegate:self];
        [[MEGASdkManager sharedMEGASdk] createThumbnail:self.uploadFile.fileURL.path destinatioPath:self.uploadFile.thumbnailURL.path];
        [[MEGASdkManager sharedMEGASdk] createPreview:self.uploadFile.fileURL.path destinatioPath:self.uploadFile.previewURL.path];
    } else {
        MEGALogError(@"file encryption failed for asset: %@", self.asset);
        [self finishOperationWithStatus:uploadStatusFailed];
    }
}

- (void)processExistingNode:(MEGANode *)node {
    if (node.parentHandle != self.cameraUploadNode.handle) {
        [[MEGASdkManager sharedMEGASdk] copyNode:node newParent:self.cameraUploadNode];
    }
    
    [self finishOperationWithStatus:uploadStatusDone];
}

#pragma mark - MEGARequestDelegate

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    if (error.type) {
        MEGALogError(@"camera upload sdk request failed");
        [self finishOperationWithStatus:uploadStatusFailed];
    } else {
        switch (request.type) {
            case MEGARequestTypeGetBackgroundUploadURL:
                self.uploadFile.uploadURLString = [self.mediaUploader uploadURLString];
                MEGALogDebug(@"upload url string: %@", self.uploadFile.uploadURLString);
                [self startUploading];
                break;
            case MEGARequestTypeCompleteBackgroundUpload:
                MEGALogDebug(@"complete background upload finishes");
                [self completeUploadForNode:[[MEGASdkManager sharedMEGASdk] nodeForHandle:request.nodeHandle]];
                break;
            default: break;
        }
    }
}

#pragma mark - transfer tasks

- (void)startUploading {
    if (self.uploadFile.uploadURL == nil) {
        [self finishOperationWithStatus:uploadStatusFailed];
        return;
    }
    
    NSURLSessionUploadTask *uploadTask = [[TransferSessionManager shared] photoUploadTaskWithURL:self.uploadFile.uploadURL fromFile:self.uploadFile.encryptedURL completion:^(NSData * _Nullable token, NSError * _Nullable error) {
        if (error) {
            MEGALogDebug(@"error when to upload photo: %@", error);
            [self finishOperationWithStatus:uploadStatusFailed];
        } else {
            [self showUpUploadWithToken:token];
        }
    }];
    
    uploadTask.taskDescription = [NSString stringWithFormat:@"%@-$@", self.asset.localIdentifier, self.uploadFile.fileURL];
    // TODO: save information to upload task to use when the task gets restored from background
    [uploadTask resume];
}

- (void)showUpUploadWithToken:(NSData *)token {
    // TODO: figure out the new name to avoid same names
    
    if(![[MEGASdkManager sharedMEGASdk] completeBackgroundMediaUpload:self.mediaUploader fileName:self.uploadFile.fileName parentNode:self.cameraUploadNode fingerprint:self.uploadFile.fingerprint originalFingerprint:self.uploadFile.originalFingerprint token:token delegate:self]) {
        [self finishOperationWithStatus:uploadStatusFailed];
    }
}

#pragma mark - finish up transfer

- (void)completeUploadForNode:(MEGANode *)node {
    if (node) {
        // TODO: move thumbnail and preview to cache before upload
        [[MEGASdkManager sharedMEGASdk] setThumbnailNode:node sourceFilePath:self.uploadFile.thumbnailURL.path delegate:[[MEGAGetThumbnailRequestDelegate alloc] initWithCompletion:^(MEGARequest *request) {
            MEGALogDebug(@"set thumbnail done");
        }]];
        [[MEGASdkManager sharedMEGASdk] setPreviewNode:node sourceFilePath:self.uploadFile.previewURL.path delegate:[[MEGAGetPreviewRequestDelegate alloc] initWithCompletion:^(MEGARequest *request) {
            MEGALogDebug(@"set preview done");
        }]];
    }
    
    [self finishOperationWithStatus:uploadStatusDone];
}

#pragma mark - helper methods

- (void)finishOperationWithStatus:(NSString *)status {
    [[AssetUploadRecordCoreDataManager shared] updateStatus:status forLocalIdentifier:self.asset.localIdentifier error:nil];
    
    if (self.uploadTaskIdentifier != UIBackgroundTaskInvalid) {
        [UIApplication.sharedApplication endBackgroundTask:self.uploadTaskIdentifier];
        self.uploadTaskIdentifier = UIBackgroundTaskInvalid;
    }
    
    [[CameraUploadManager shared] uploadNextPhoto];
    
    [self finishOperation];
}

- (void)cleanUpLocalCache {
    [[NSFileManager defaultManager] removeItemAtURL:self.uploadFile.directoryURL error:nil];
}

@end
