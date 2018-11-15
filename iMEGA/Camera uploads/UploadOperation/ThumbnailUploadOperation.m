
#import "ThumbnailUploadOperation.h"
#import "Helper.h"
#import "CameraUploadRequestDelegate.h"
#import "NSFileManager+MNZCategory.h"

static NSString * const ThumbnailErrorDomain = @"nz.mega.cameraUpload.thumbnailUpload";
static NSString * const ThumbnailErrorKey = @"message";

@interface ThumbnailUploadOperation ()

@property (strong, nonatomic) MEGANode *node;
@property (strong, nonatomic) AssetUploadInfo *uploadInfo;
@property (nonatomic) UIBackgroundTaskIdentifier backgroundTaskId;

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
        [self finishOperationWithError:[NSError errorWithDomain:ThumbnailErrorDomain code:0 userInfo:@{ThumbnailErrorKey : [NSString stringWithFormat:@"No thumbnail file found for asset: %@", self.uploadInfo.asset.localIdentifier]}]];
        return;
    }
    
    self.backgroundTaskId = [UIApplication.sharedApplication beginBackgroundTaskWithName:@"thumbnailUploadBackgroundTask" expirationHandler:^{
        [self finishOperationWithError:[NSError errorWithDomain:ThumbnailErrorDomain code:0 userInfo:@{ThumbnailErrorKey : [NSString stringWithFormat:@"Background task expired in uploading thumbnail for asset: %@", self.uploadInfo.asset.localIdentifier]}]];
    }];
    
    MEGALogDebug(@"[Camera Upload] Start uploading thumbnail for asset %@ %@", self.uploadInfo.asset.localIdentifier, self.uploadInfo.fileName);
    
    NSError *error;
    NSURL *cachedThumbnailURL = [[Helper urlForSharedSandboxCacheDirectory:@"thumbnailsV3"] URLByAppendingPathComponent:self.node.base64Handle isDirectory:NO];
    if (![NSFileManager.defaultManager createDirectoryAtURL:cachedThumbnailURL withIntermediateDirectories:YES attributes:nil error:&error]) {
        MEGALogDebug(@"[Camera Upload] Create thumbnail directory error %@", error);
        [self finishOperationWithError:error];
        return;
    }
    
    [NSFileManager.defaultManager removeItemIfExistsAtURL:cachedThumbnailURL];
    
    if ([[NSFileManager defaultManager] moveItemAtURL:self.uploadInfo.thumbnailURL toURL:cachedThumbnailURL error:&error]) {
        __weak __typeof__(self) weakSelf = self;
        [MEGASdkManager.sharedMEGASdk setThumbnailNode:self.node sourceFilePath:cachedThumbnailURL.path delegate:[[CameraUploadRequestDelegate alloc] initWithCompletion:^(MEGARequest * _Nonnull request, MEGAError * _Nonnull error) {
            if (error.type) {
                MEGALogError(@"[Camera Upload] Upload thumbnail failed for local identifier: %@, node: %llu, error: %ld", weakSelf.uploadInfo.asset.localIdentifier, weakSelf.node.handle, error.type);
            } else {
                MEGALogDebug(@"[Camera Upload] Upload thumbnail success for local identifier: %@, node: %llu", weakSelf.uploadInfo.asset.localIdentifier, weakSelf.node.handle);
            }
            
            [weakSelf finishOperationWithError:nil];
        }]];
    } else {
        MEGALogDebug(@"[Camera Upload] Move thumbnail to cache failed for asset %@ error %@", self.uploadInfo.asset.localIdentifier, error);
        [self finishOperationWithError:error];
    }
}

- (void)expireOperation {
    [self finishOperationWithError:[NSError errorWithDomain:ThumbnailErrorDomain code:0 userInfo:@{ThumbnailErrorKey : @"operation gets expired"}]];
}

- (void)finishOperationWithError:(NSError *)error {
    [self finishOperation];
    
    MEGALogDebug(@"[Camera Upload] thumbnail operation finished with error: %@", error);
    
    [UIApplication.sharedApplication endBackgroundTask:self.backgroundTaskId];
    self.backgroundTaskId = UIBackgroundTaskInvalid;
}


@end
