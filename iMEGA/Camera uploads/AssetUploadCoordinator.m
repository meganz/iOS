
#import "AssetUploadCoordinator.h"
#import "Helper.h"
#import "MEGAGetThumbnailRequestDelegate.h"
#import "MEGAGetPreviewRequestDelegate.h"

@interface AssetUploadCoordinator () <MEGARequestDelegate>

@property (strong, nonatomic) AssetUploadInfo *uploadInfo;
@property (copy, nonatomic) void (^uploadSuccess)(MEGANode *node);
@property (copy, nonatomic) void (^uploadFailure)(MEGAError * error);

@end

@implementation AssetUploadCoordinator

- (void)completeUploadWithInfo:(AssetUploadInfo *)info uploadToken:(NSData *)token success:(void (^)(MEGANode *node))success failure:(void (^)(MEGAError * error))failure {
    // TODO: figure out the new name to avoid same names
    if(![[MEGASdkManager sharedMEGASdk] completeBackgroundMediaUpload:info.mediaUpload fileName:info.fileName parentNode:[MEGASdkManager.sharedMEGASdk nodeForHandle:info.parentHandle] fingerprint:info.fingerprint originalFingerprint:info.originalFingerprint token:token delegate:self]) {
        failure(nil);
    } else {
        self.uploadInfo = info;
        self.uploadSuccess = success;
        self.uploadFailure = failure;
    }
    
}

- (void)uploadFinishForNode:(MEGANode *)node {
    [self uploadThumbnailForNode:node];
    [self uploadPreviewForNode:node];
    self.uploadSuccess(node);
}

- (void)uploadThumbnailForNode:(MEGANode *)node {
    if (node == nil) {
        return;
    }
    
    __block UIBackgroundTaskIdentifier thumbnailUploadTaskId = [UIApplication.sharedApplication beginBackgroundTaskWithName:@"thumbnailUploadBackgroundTask" expirationHandler:^{
        [UIApplication.sharedApplication endBackgroundTask:thumbnailUploadTaskId];
        thumbnailUploadTaskId = UIBackgroundTaskInvalid;
    }];
    
    NSURL *cachedThumbnailURL = [[Helper urlForSharedSandboxCacheDirectory:@"thumbnailsV3"] URLByAppendingPathComponent:node.base64Handle isDirectory:NO];
    if ([[NSFileManager defaultManager] moveItemAtURL:self.uploadInfo.thumbnailURL toURL:cachedThumbnailURL error:nil]) {
        [[MEGASdkManager sharedMEGASdk] setThumbnailNode:node sourceFilePath:cachedThumbnailURL.path delegate:[[MEGAGetThumbnailRequestDelegate alloc] initWithCompletion:^(MEGARequest *request) {
            MEGALogDebug(@"Upload thumbnail success for node: %llu", node.handle);
            [UIApplication.sharedApplication endBackgroundTask:thumbnailUploadTaskId];
            thumbnailUploadTaskId = UIBackgroundTaskInvalid;
        }]];
    } else {
        MEGALogDebug(@"move thumbnail to cache failed for node: %llu", node.handle);
        [UIApplication.sharedApplication endBackgroundTask:thumbnailUploadTaskId];
        thumbnailUploadTaskId = UIBackgroundTaskInvalid;
    }
}

- (void)uploadPreviewForNode:(MEGANode *)node {
    if (node == nil) {
        return;
    }
    
    __block UIBackgroundTaskIdentifier previewUploadTaskId = [UIApplication.sharedApplication beginBackgroundTaskWithName:@"previewUploadBackgroundTask" expirationHandler:^{
        [UIApplication.sharedApplication endBackgroundTask:previewUploadTaskId];
        previewUploadTaskId = UIBackgroundTaskInvalid;
    }];
    
    NSURL *cachedPreviewURL = [[[[[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] firstObject] URLByAppendingPathComponent:@"previewsV3" isDirectory:YES] URLByAppendingPathComponent:node.base64Handle isDirectory:NO];
    if([[NSFileManager defaultManager] moveItemAtURL:self.uploadInfo.previewURL toURL:cachedPreviewURL error:nil]) {
        [[MEGASdkManager sharedMEGASdk] setPreviewNode:node sourceFilePath:cachedPreviewURL.path delegate:[[MEGAGetPreviewRequestDelegate alloc] initWithCompletion:^(MEGARequest *request) {
            MEGALogDebug(@"Upload preview success for node: %llu", node.handle);
            [UIApplication.sharedApplication endBackgroundTask:previewUploadTaskId];
            previewUploadTaskId = UIBackgroundTaskInvalid;
        }]];
    } else {
        MEGALogDebug(@"move preview to cache failed for node: %llu", node.handle);
        [UIApplication.sharedApplication endBackgroundTask:previewUploadTaskId];
        previewUploadTaskId = UIBackgroundTaskInvalid;
    }
}

#pragma mark - mega request delegate

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    if (error.type) {
        MEGALogError(@"Complete upload failed with error type: %ld", error.type);
        self.uploadFailure(error);
    } else {
        MEGANode *node = [MEGASdkManager.sharedMEGASdk nodeForHandle:request.nodeHandle];
        if (node) {
            [self uploadFinishForNode:node];
        } else {
            self.uploadFailure(nil);
        }
    }
}

@end
