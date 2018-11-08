
#import "PreviewUploadOperation.h"
#import "Helper.h"
#import "CameraUploadRequestDelegate.h"

@interface PreviewUploadOperation ()

@property (strong, nonatomic) MEGANode *node;
@property (strong, nonatomic) AssetUploadInfo *uploadInfo;

@end

@implementation PreviewUploadOperation

- (instancetype)initWithNode:(MEGANode *)node uploadInfo:(AssetUploadInfo *)uploadInfo {
    self = [super init];
    if (self) {
        _node = node;
        _uploadInfo = uploadInfo;
    }
    
    return self;
}

- (void)start {
    [super start];
    
    if (![NSFileManager.defaultManager fileExistsAtPath:self.uploadInfo.previewURL.path]) {
        MEGALogError(@"[Camera Upload] No preview file found for asset: %@", self.uploadInfo.asset.localIdentifier);
        [self finishOperation];
        return;
    }
    
    __block UIBackgroundTaskIdentifier previewUploadTaskId = [UIApplication.sharedApplication beginBackgroundTaskWithName:@"previewUploadBackgroundTask" expirationHandler:^{
        MEGALogDebug(@"[Camera Upload] background task expired in uploading preview for asset: %@", self.uploadInfo.asset.localIdentifier);
        [self finishOperation];
        [UIApplication.sharedApplication endBackgroundTask:previewUploadTaskId];
        previewUploadTaskId = UIBackgroundTaskInvalid;
    }];
    
    NSURL *cachedPreviewURL = [[[[[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] firstObject] URLByAppendingPathComponent:@"previewsV3" isDirectory:YES] URLByAppendingPathComponent:self.node.base64Handle isDirectory:NO];
    
    if([[NSFileManager defaultManager] moveItemAtURL:self.uploadInfo.previewURL toURL:cachedPreviewURL error:nil]) {
        [MEGASdkManager.sharedMEGASdk setPreviewNode:self.node sourceFilePath:cachedPreviewURL.path delegate:[[CameraUploadRequestDelegate alloc] initWithCompletion:^(MEGARequest * _Nonnull request, MEGAError * _Nonnull error) {
            if (error.type) {
                MEGALogError(@"[Camera Upload] Upload preview failed for node: %llu, error: %ld", self.node.handle, error.type);
            } else {
                MEGALogDebug(@"[Camera Upload] Upload preview success for node: %llu", self.node.handle);
            }
            
            [self finishOperation];
            [UIApplication.sharedApplication endBackgroundTask:previewUploadTaskId];
            previewUploadTaskId = UIBackgroundTaskInvalid;
        }]];
    } else {
        MEGALogDebug(@"[Camera Upload] Move preview to cache failed for asset %@", self.uploadInfo.asset.localIdentifier);
        [self finishOperation];
        [UIApplication.sharedApplication endBackgroundTask:previewUploadTaskId];
        previewUploadTaskId = UIBackgroundTaskInvalid;
    }
}

@end
