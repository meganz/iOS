
#import "AssetUploadOperation.h"
#import "MEGASdkManager.h"
#import "NSFileManager+MNZCategory.h"
#import "NSString+MNZCategory.h"
#import "TransferSessionManager.h"
#import "AssetUploadFile.h"
@import Photos;

@interface AssetUploadOperation () <MEGARequestDelegate>

@property (strong, nonatomic) PHAsset *asset;
@property (strong, nonatomic) AssetUploadFile *uploadFile;
@property (strong, nonatomic) MEGABackgroundMediaUpload *mediaUploader;
@property (strong, nonatomic) MEGANode *cameraUploadNode;

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
        // TODO: delete the local upload record
        [self finishOperation];
        return;
    }
    
    PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
    options.networkAccessAllowed = YES;
    options.version = PHImageRequestOptionsVersionCurrent;
    options.synchronous = YES;
    [[PHImageManager defaultManager] requestImageDataForAsset:self.asset options:options resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
        if (self.isCancelled) {
            [self finishOperation];
            return;
        }
        
        if (imageData) {
            [self processImageData:imageData];
        } else {
            // TODO: make the job as failed or not started
            [self finishOperation];
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
    
    self.uploadFile.fileName = [[NSString mnz_fileNameWithDate:self.asset.creationDate] stringByAppendingPathExtension:@"jpg"];
    self.uploadFile.fileURL = [[[NSFileManager defaultManager] cameraUploadURL] URLByAppendingPathComponent:self.uploadFile.fileName];
    if ([JPEGData writeToURL:self.uploadFile.fileURL atomically:YES]) {
        [self processUploadFile];
    } else {
        // TODO: make the job as failed or not started
        [self finishOperation];
    }
}

- (void)processUploadFile {
    self.mediaUploader = [[MEGASdkManager sharedMEGASdk] prepareBackgroundMediaUploadWithDelegate:self];
    NSString *urlSuffix;
    if ([self.mediaUploader encryptFileAtPath:[self.uploadFile.fileURL path] outputFilePath:[self.uploadFile.encryptedURL path] urlSuffix:&urlSuffix]) {
        MEGALogDebug(@"url suffix %@", urlSuffix);
        self.uploadFile.uploadURLStringSuffix = urlSuffix;
        [self.mediaUploader requestUploadURLString];
    } else {
        MEGALogError(@"file encryption failed for asset: %@", self.asset);
        [self finishOperation];
    }
}

- (void)processExistingNode:(MEGANode *)node {
    if (node.parentHandle != self.cameraUploadNode.handle) {
        [[MEGASdkManager sharedMEGASdk] copyNode:node newParent:self.cameraUploadNode];
    }
    
    // TODO: mark the status of the asset record
    [self finishOperation];
}

#pragma mark - MEGARequestDelegate

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    if (error.type) {
        MEGALogError(@"camera upload sdk request failed");
        // TODO: update local record status
        [self finishOperation];
    } else {
        switch (request.type) {
            case MEGARequestTypeGetBackgroundUploadURL:
                self.uploadFile.uploadURLString = [self.mediaUploader uploadURLString];
                MEGALogDebug(@"upload url string: %@", self.uploadFile.uploadURLString);
                [self startUploading];
                break;
            case MEGARequestTypeCompleteBackgroundUpload:
                MEGALogDebug(@"complete background upload finishes");
                break;
            default:
                break;
        }
    }
}

#pragma mark - transfer tasks

- (void)startUploading {
    if (self.uploadFile.uploadURL == nil) {
        // TODO: update status
        [self finishOperation];
        return;
    }
    
    NSURLSessionUploadTask *uploadTask = [[TransferSessionManager shared] photoUploadTaskWithURL:self.uploadFile.uploadURL fromFile:self.uploadFile.encryptedURL completion:^(NSData * _Nullable token, NSError * _Nullable error) {
        if (error) {
            // TODO: error handling and status update
            MEGALogDebug(@"error when to upload photo: %@", error);
            [self finishOperation];
        } else {
            [self completeUploadWithToken:token];
        }
    }];
    
    // TODO: save information to upload task to use when the task gets restored from background
    [uploadTask resume];
}

- (void)completeUploadWithToken:(NSData *)token {
    // TODO: figure out the new name to avoid same names
    
    [self.mediaUploader completeBackgroundUploadWithFileName:self.uploadFile.fileName parentNode:self.cameraUploadNode fingerprint:self.uploadFile.fingerprint originalFingerprint:self.uploadFile.originalFingerprint uploadToken:token];
}

@end
