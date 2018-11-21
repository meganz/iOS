
#import "ThumbnailUploadOperation.h"
#import "Helper.h"
#import "CameraUploadRequestDelegate.h"
#import "MEGAError+MNZCategory.h"
#import "NSFileManager+MNZCategory.h"

@implementation ThumbnailUploadOperation

- (void)start {
    [super start];

    MEGALogDebug(@"[Camera Upload] Start uploading thumbnail at URL %@", self.attributeURL);
    __weak __typeof__(self) weakSelf = self;
    [MEGASdkManager.sharedMEGASdk setThumbnailNode:self.node sourceFilePath:self.attributeURL.path delegate:[[CameraUploadRequestDelegate alloc] initWithCompletion:^(MEGARequest * _Nonnull request, MEGAError * _Nonnull error) {
        if (error.type) {
            MEGALogError(@"[Camera Upload] Upload thumbnail failed for node: %llu, error: %@", weakSelf.node.handle, error.nativeError);
        } else {
            MEGALogDebug(@"[Camera Upload] Upload thumbnail succeeded for node: %llu", weakSelf.node.handle);
            [NSFileManager.defaultManager removeItemIfExistsAtURL:weakSelf.attributeURL];
        }
        
        [weakSelf finishOperation];
    }]];
    
    [self cacheAttributeToURL:[[Helper urlForSharedSandboxCacheDirectory:@"thumbnailsV3"] URLByAppendingPathComponent:self.node.base64Handle isDirectory:NO]];
}

@end
