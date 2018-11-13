
#import "PreviewUploadOperation.h"
#import "Helper.h"
#import "CameraUploadRequestDelegate.h"

@interface PreviewUploadOperation ()

@property (strong, nonatomic) MEGANode *node;
@property (strong, nonatomic) AssetUploadInfo *uploadInfo;
@property (nonatomic) UIBackgroundTaskIdentifier backgroundTaskId;

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
    
    self.backgroundTaskId = [UIApplication.sharedApplication beginBackgroundTaskWithName:@"previewUploadBackgroundTask" expirationHandler:^{
        MEGALogDebug(@"[Camera Upload] Background task expired in uploading preview for asset: %@", self.uploadInfo.asset.localIdentifier);
        [self finishOperation];
    }];
    
    MEGALogDebug(@"[Camera Upload] Start uploading preview for asset %@ %@", self.uploadInfo.asset.localIdentifier, self.uploadInfo.fileName);
    
    NSError *error;
    NSURL *cachedPreviewURL = [[[[NSFileManager.defaultManager URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] firstObject] URLByAppendingPathComponent:@"previewsV3" isDirectory:YES] URLByAppendingPathComponent:self.node.base64Handle isDirectory:NO];
    if(![NSFileManager.defaultManager createDirectoryAtURL:cachedPreviewURL withIntermediateDirectories:YES attributes:nil error:&error]) {
        MEGALogDebug(@"[Camera Upload] Create preview directory error %@", error);
        [self finishOperation];
        return;
    }
    
    if([[NSFileManager defaultManager] moveItemAtURL:self.uploadInfo.previewURL toURL:cachedPreviewURL error:&error]) {
        [MEGASdkManager.sharedMEGASdk setPreviewNode:self.node sourceFilePath:cachedPreviewURL.path delegate:[[CameraUploadRequestDelegate alloc] initWithCompletion:^(MEGARequest * _Nonnull request, MEGAError * _Nonnull error) {
            if (error.type) {
                MEGALogError(@"[Camera Upload] Upload preview failed for node: %llu, error: %ld", self.node.handle, error.type);
            } else {
                MEGALogDebug(@"[Camera Upload] Upload preview success for node: %llu", self.node.handle);
            }
            
            [self finishOperation];
        }]];
    } else {
        MEGALogDebug(@"[Camera Upload] Move preview to cache failed for asset %@ error %@", self.uploadInfo.asset.localIdentifier, error);
        [self finishOperation];
    }
}

- (void)finishOperation {
    [super finishOperation];
    [UIApplication.sharedApplication endBackgroundTask:self.backgroundTaskId];
    self.backgroundTaskId = UIBackgroundTaskInvalid;
}

@end
