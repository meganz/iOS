
#import "PreviewUploadOperation.h"
#import "Helper.h"
#import "CameraUploadRequestDelegate.h"
#import "NSFileManager+MNZCategory.h"
#import "MEGAError+MNZCategory.h"

@implementation PreviewUploadOperation

- (void)start {
    [super start];
    
    __weak __typeof__(self) weakSelf = self;
    [MEGASdkManager.sharedMEGASdk setPreviewNode:self.node sourceFilePath:self.attributeURL.path delegate:[[CameraUploadRequestDelegate alloc] initWithCompletion:^(MEGARequest * _Nonnull request, MEGAError * _Nonnull error) {
        if (error.type) {
            MEGALogError(@"[Camera Upload] Upload preview failed for node: %@, error: %@", weakSelf.node.name, error.nativeError);
        } else {
            MEGALogDebug(@"[Camera Upload] Upload preview succeeded for node %@", weakSelf.node.name);
            NSURL *cacheDirectory = [[NSFileManager.defaultManager URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] firstObject];
            [weakSelf moveAttributeToDirectoryURL:[cacheDirectory URLByAppendingPathComponent:@"previewsV3"] newFileName:weakSelf.node.base64Handle];
        }
        
        [weakSelf finishOperation];
    }]];
}

@end
