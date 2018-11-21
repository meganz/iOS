
#import "PreviewUploadOperation.h"
#import "Helper.h"
#import "CameraUploadRequestDelegate.h"
#import "NSFileManager+MNZCategory.h"
#import "MEGAError+MNZCategory.h"

@implementation PreviewUploadOperation

- (void)start {
    [super start];
    
    MEGALogDebug(@"[Camera Upload] Start uploading preview %@", self.attributeURL);
    __weak __typeof__(self) weakSelf = self;
    [MEGASdkManager.sharedMEGASdk setPreviewNode:self.node sourceFilePath:self.attributeURL.path delegate:[[CameraUploadRequestDelegate alloc] initWithCompletion:^(MEGARequest * _Nonnull request, MEGAError * _Nonnull error) {
        if (error.type) {
            MEGALogError(@"[Camera Upload] Upload preview failed for node: %llu, error: %@", weakSelf.node.handle, error.nativeError);
        } else {
            MEGALogDebug(@"[Camera Upload] Upload preview succeeded for node: %llu", weakSelf.node.handle);
            [NSFileManager.defaultManager removeItemIfExistsAtURL:weakSelf.attributeURL];
        }
        
        [weakSelf finishOperation];
    }]];
    
    [self cacheAttributeToURL:[[[[NSFileManager.defaultManager URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] firstObject] URLByAppendingPathComponent:@"previewsV3" isDirectory:YES] URLByAppendingPathComponent:self.node.base64Handle isDirectory:NO]];
}

@end
