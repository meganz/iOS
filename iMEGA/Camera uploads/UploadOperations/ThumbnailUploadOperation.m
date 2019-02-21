
#import "ThumbnailUploadOperation.h"
#import "Helper.h"
#import "CameraUploadRequestDelegate.h"
#import "MEGAError+MNZCategory.h"
#import "NSFileManager+MNZCategory.h"

@implementation ThumbnailUploadOperation

- (void)start {
    [super start];
    
    __weak __typeof__(self) weakSelf = self;
    [MEGASdkManager.sharedMEGASdk setThumbnailNode:self.node sourceFilePath:self.attributeURL.path delegate:[[CameraUploadRequestDelegate alloc] initWithCompletion:^(MEGARequest * _Nonnull request, MEGAError * _Nonnull error) {
        if (error.type) {
            MEGALogError(@"[Camera Upload] Upload thumbnail failed for node: %@, error: %@", weakSelf.node.name, error.nativeError);
            if (error.type == MEGAErrorTypeApiEExist) {
                [weakSelf cacheAttributeFile];
            }
        } else {
            MEGALogDebug(@"[Camera Upload] Upload thumbnail succeeded for node %@", weakSelf.node.name);
            [weakSelf cacheAttributeFile];
        }
        
        [weakSelf finishOperation];
    }]];
}

- (void)cacheAttributeFile {
    [self moveAttributeToDirectoryURL:[Helper urlForSharedSandboxCacheDirectory:@"thumbnailsV3"] newFileName:self.node.base64Handle];
}

@end
