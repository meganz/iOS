#import "PreviewUploadOperation.h"
#import "CameraUploadRequestDelegate.h"
#import "NSFileManager+MNZCategory.h"
#import "MEGAError+MNZCategory.h"
#import "NSURL+CameraUpload.h"

@implementation PreviewUploadOperation

- (void)start {
    [super start];
    
    if (self.isFinished) {
        return;
    }
    
    if (self.isCancelled) {
        [self finishOperation];
        return;
    }
    
    if (self.node.hasPreview) {
        [self cacheAttributeFile];
        [self finishOperation];
        return;
    }
    
    __weak __typeof__(self) weakSelf = self;
    [MEGASdkManager.sharedMEGASdk setPreviewNode:self.node sourceFilePath:self.attributeURL.path delegate:[[CameraUploadRequestDelegate alloc] initWithCompletion:^(MEGARequest * _Nonnull request, MEGAError * _Nonnull error) {
        if (error.type) {
            MEGALogError(@"[Camera Upload] Upload preview failed %@ error: %@", weakSelf, error.nativeError);
            if (error.type == MEGAErrorTypeApiEExist) {
                [weakSelf cacheAttributeFile];
            }
        } else {
            MEGALogDebug(@"[Camera Upload] Upload preview succeeded %@", weakSelf);
            [weakSelf cacheAttributeFile];
        }
        
        [weakSelf finishOperation];
    }]];
}

- (void)cacheAttributeFile {
    [self.attributeURL mnz_cachePreviewForNode:self.node];
}

@end
