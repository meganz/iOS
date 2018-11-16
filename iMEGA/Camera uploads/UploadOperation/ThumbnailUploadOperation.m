
#import "ThumbnailUploadOperation.h"
#import "Helper.h"
#import "CameraUploadRequestDelegate.h"
#import "NSFileManager+MNZCategory.h"

@implementation ThumbnailUploadOperation

- (void)start {
    [super start];
    
    if (![NSFileManager.defaultManager fileExistsAtPath:self.uploadInfo.thumbnailURL.path]) {
        MEGALogDebug(@"[Camera Upload] No thumbnail file found for asset: %@", self.uploadInfo.asset.localIdentifier);
        [self finishOperation];
        return;
    }
    
    MEGALogDebug(@"[Camera Upload] Start uploading thumbnail for asset %@ %@", self.uploadInfo.asset.localIdentifier, self.uploadInfo.fileName);
    
    NSError *error;
    NSURL *cachedThumbnailURL = [[Helper urlForSharedSandboxCacheDirectory:@"thumbnailsV3"] URLByAppendingPathComponent:self.node.base64Handle isDirectory:NO];
    if (![NSFileManager.defaultManager createDirectoryAtURL:cachedThumbnailURL withIntermediateDirectories:YES attributes:nil error:&error]) {
        MEGALogDebug(@"[Camera Upload] Create thumbnail directory error %@", error);
        [self finishOperation];
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
            
            [self finishOperation];
        }]];
    } else {
        MEGALogDebug(@"[Camera Upload] Move thumbnail to cache failed for asset %@ error %@", self.uploadInfo.asset.localIdentifier, error);
        [self finishOperation];
    }
}

@end
