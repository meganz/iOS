
#import "ThumbnailUploadOperation.h"
#import "Helper.h"
#import "CameraUploadRequestDelegate.h"

@interface ThumbnailUploadOperation ()

@property (strong, nonatomic) MEGANode *node;
@property (strong, nonatomic) AssetUploadInfo *uploadInfo;

@end

@implementation ThumbnailUploadOperation

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
    
    if (![NSFileManager.defaultManager fileExistsAtPath:self.uploadInfo.thumbnailURL.path]) {
        MEGALogError(@"[Camera Upload] No thumbnail file found for asset: %@", self.uploadInfo.asset.localIdentifier);
        [self finishOperation];
        return;
    }
    
    __block UIBackgroundTaskIdentifier thumbnailUploadTaskId = [UIApplication.sharedApplication beginBackgroundTaskWithName:@"thumbnailUploadBackgroundTask" expirationHandler:^{
        MEGALogDebug(@"[Camera Upload] background task expired in uploading thumbnail for asset: %@", self.uploadInfo.asset.localIdentifier);
        [self finishOperation];
        [UIApplication.sharedApplication endBackgroundTask:thumbnailUploadTaskId];
        thumbnailUploadTaskId = UIBackgroundTaskInvalid;
    }];
    
    MEGALogDebug(@"[Camera Upload] start uploading thumbnail for asset %@ %@", self.uploadInfo.asset.localIdentifier, self.uploadInfo.fileName);
    
    NSURL *cachedThumbnailURL = [[Helper urlForSharedSandboxCacheDirectory:@"thumbnailsV3"] URLByAppendingPathComponent:self.node.base64Handle isDirectory:NO];
    
    if ([[NSFileManager defaultManager] moveItemAtURL:self.uploadInfo.thumbnailURL toURL:cachedThumbnailURL error:nil]) {
        [MEGASdkManager.sharedMEGASdk setThumbnailNode:self.node sourceFilePath:cachedThumbnailURL.path delegate:[[CameraUploadRequestDelegate alloc] initWithCompletion:^(MEGARequest * _Nonnull request, MEGAError * _Nonnull error) {
            if (error.type) {
                MEGALogError(@"[Camera Upload] Upload thumbnail failed for local identifier: %@, node: %llu, error: %ld", self.uploadInfo.asset.localIdentifier, self.node.handle, error.type);
            } else {
                MEGALogDebug(@"[Camera Upload] Upload thumbnail success for local identifier: %@, node: %llu", self.uploadInfo.asset.localIdentifier, self.node.handle);
            }
            
            [self finishOperation];
            [UIApplication.sharedApplication endBackgroundTask:thumbnailUploadTaskId];
            thumbnailUploadTaskId = UIBackgroundTaskInvalid;
        }]];
    } else {
        MEGALogDebug(@"[Camera Upload] moves thumbnail to cache failed for asset %@", self.uploadInfo.asset.localIdentifier);
        [self finishOperation];
        [UIApplication.sharedApplication endBackgroundTask:thumbnailUploadTaskId];
        thumbnailUploadTaskId = UIBackgroundTaskInvalid;
    }
}


@end
