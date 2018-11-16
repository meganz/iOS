
#import "PreviewUploadOperation.h"
#import "Helper.h"
#import "CameraUploadRequestDelegate.h"
#import "NSFileManager+MNZCategory.h"

@implementation PreviewUploadOperation

- (void)start {
    [super start];
    
    if (![NSFileManager.defaultManager fileExistsAtPath:self.uploadInfo.previewURL.path]) {
        [self finishOperationWithError:[self errorWithMessage:[NSString stringWithFormat:@"No preview file found for asset: %@", self.uploadInfo.asset.localIdentifier]]];
        return;
    }

    MEGALogDebug(@"[Camera Upload] Start uploading preview for asset %@ %@", self.uploadInfo.asset.localIdentifier, self.uploadInfo.fileName);
    
    NSError *error;
    NSURL *cachedPreviewURL = [[[[NSFileManager.defaultManager URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] firstObject] URLByAppendingPathComponent:@"previewsV3" isDirectory:YES] URLByAppendingPathComponent:self.node.base64Handle isDirectory:NO];
    if(![NSFileManager.defaultManager createDirectoryAtURL:cachedPreviewURL withIntermediateDirectories:YES attributes:nil error:&error]) {
        MEGALogDebug(@"[Camera Upload] Create preview directory error %@", error);
        [self finishOperationWithError:error];
        return;
    }
    
    [NSFileManager.defaultManager removeItemIfExistsAtURL:cachedPreviewURL];
    
    if([[NSFileManager defaultManager] moveItemAtURL:self.uploadInfo.previewURL toURL:cachedPreviewURL error:&error]) {
        [MEGASdkManager.sharedMEGASdk setPreviewNode:self.node sourceFilePath:cachedPreviewURL.path delegate:[[CameraUploadRequestDelegate alloc] initWithCompletion:^(MEGARequest * _Nonnull request, MEGAError * _Nonnull error) {
            if (error.type) {
                MEGALogError(@"[Camera Upload] Upload preview failed for node: %llu, error: %ld", self.node.handle, error.type);
            } else {
                MEGALogDebug(@"[Camera Upload] Upload preview success for node: %llu", self.node.handle);
            }
            
            [self finishOperationWithError:nil];
        }]];
    } else {
        MEGALogDebug(@"[Camera Upload] Move preview to cache failed for asset %@ error %@", self.uploadInfo.asset.localIdentifier, error);
        [self finishOperationWithError:error];
    }
}

@end
