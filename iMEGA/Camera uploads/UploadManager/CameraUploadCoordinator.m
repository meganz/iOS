
#import "CameraUploadCoordinator.h"
#import "Helper.h"
#import "MEGAGetThumbnailRequestDelegate.h"
#import "MEGAGetPreviewRequestDelegate.h"
#import "CameraUploadRequestDelegate.h"

@implementation CameraUploadCoordinator

- (void)completeUploadWithInfo:(AssetUploadInfo *)info uploadToken:(NSData *)token success:(void (^)(MEGANode *node))success failure:(void (^)(MEGAError * error))failure {
    // TODO: figure out the new name to avoid same names
    
    CameraUploadRequestDelegate *delegate = [[CameraUploadRequestDelegate alloc] initWithCompletion:^(MEGARequest * _Nonnull request, MEGAError * _Nonnull error) {
        if (error.type) {
            failure(error);
        } else {
            MEGANode *node = [MEGASdkManager.sharedMEGASdk nodeForHandle:request.nodeHandle];
            [self uploadThumbnailForNode:node uploadInfo:info];
            [self uploadPreviewForNode:node uploadInfo:info];
            success(node);
        }
    }];
    
    
    if(![MEGASdkManager.sharedMEGASdk completeBackgroundMediaUpload:info.mediaUpload
                                                           fileName:info.fileName
                                                         parentNode:info.parentNode
                                                        fingerprint:info.fingerprint
                                                originalFingerprint:info.originalFingerprint
                                                              token:token
                                                           delegate:delegate]) {
        failure(nil);
    }
}

- (void)uploadThumbnailForNode:(MEGANode *)node uploadInfo:(AssetUploadInfo *)uploadInfo {
    if (node == nil) {
        return;
    }
    
    __block UIBackgroundTaskIdentifier thumbnailUploadTaskId = [UIApplication.sharedApplication beginBackgroundTaskWithName:@"thumbnailUploadBackgroundTask" expirationHandler:^{
        [UIApplication.sharedApplication endBackgroundTask:thumbnailUploadTaskId];
        thumbnailUploadTaskId = UIBackgroundTaskInvalid;
    }];
    
    NSURL *cachedThumbnailURL = [[Helper urlForSharedSandboxCacheDirectory:@"thumbnailsV3"] URLByAppendingPathComponent:node.base64Handle isDirectory:NO];
    if ([[NSFileManager defaultManager] moveItemAtURL:uploadInfo.thumbnailURL toURL:cachedThumbnailURL error:nil]) {
        [MEGASdkManager.sharedMEGASdk setThumbnailNode:node sourceFilePath:cachedThumbnailURL.path delegate:[[CameraUploadRequestDelegate alloc] initWithCompletion:^(MEGARequest * _Nonnull request, MEGAError * _Nonnull error) {
            if (error.type) {
                MEGALogError(@"[Camera Upload] Upload thumbnail failed for local identifier: %@, node: %llu, error: %ld", uploadInfo.asset.localIdentifier, node.handle, error.type);
            } else {
                MEGALogDebug(@"[Camera Upload] Upload thumbnail success for local identifier: %@, node: %llu", uploadInfo.asset.localIdentifier, node.handle);
                [UIApplication.sharedApplication endBackgroundTask:thumbnailUploadTaskId];
                thumbnailUploadTaskId = UIBackgroundTaskInvalid;
            }
        }]];
    } else {
        MEGALogDebug(@"[Camera Upload] Vove thumbnail to cache failed for node: %llu", node.handle);
        [UIApplication.sharedApplication endBackgroundTask:thumbnailUploadTaskId];
        thumbnailUploadTaskId = UIBackgroundTaskInvalid;
    }
}

- (void)uploadPreviewForNode:(MEGANode *)node uploadInfo:(AssetUploadInfo *)uploadInfo {
    if (node == nil) {
        return;
    }
    
    __block UIBackgroundTaskIdentifier previewUploadTaskId = [UIApplication.sharedApplication beginBackgroundTaskWithName:@"previewUploadBackgroundTask" expirationHandler:^{
        [UIApplication.sharedApplication endBackgroundTask:previewUploadTaskId];
        previewUploadTaskId = UIBackgroundTaskInvalid;
    }];
    
    NSURL *cachedPreviewURL = [[[[[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] firstObject] URLByAppendingPathComponent:@"previewsV3" isDirectory:YES] URLByAppendingPathComponent:node.base64Handle isDirectory:NO];
    if([[NSFileManager defaultManager] moveItemAtURL:uploadInfo.previewURL toURL:cachedPreviewURL error:nil]) {
        [MEGASdkManager.sharedMEGASdk setThumbnailNode:node sourceFilePath:cachedPreviewURL.path delegate:[[CameraUploadRequestDelegate alloc] initWithCompletion:^(MEGARequest * _Nonnull request, MEGAError * _Nonnull error) {
            if (error.type) {
                MEGALogError(@"[Camera Upload] Upload preview failed for node: %llu, error: %ld", node.handle, error.type);
            } else {
                MEGALogDebug(@"[Camera Upload] Upload preview success for node: %llu", node.handle);
                [UIApplication.sharedApplication endBackgroundTask:previewUploadTaskId];
                previewUploadTaskId = UIBackgroundTaskInvalid;
            }
        }]];
    } else {
        MEGALogDebug(@"[Camera Upload] Move preview to cache failed for node: %llu", node.handle);
        [UIApplication.sharedApplication endBackgroundTask:previewUploadTaskId];
        previewUploadTaskId = UIBackgroundTaskInvalid;
    }
}

@end
