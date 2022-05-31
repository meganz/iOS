
#import "AssetResourceUploadOperation.h"
#import "PHAssetResource+CameraUpload.h"
#import "CameraUploadOperation+Utils.h"
#import "NSFileManager+MNZCategory.h"

@interface AssetResourceUploadOperation ()

@property (weak, nonatomic) id<AssetResourcExportDelegate> exportDelegate;

@end

@implementation AssetResourceUploadOperation

#pragma mark - export local asset resource

- (void)exportAssetResource:(PHAssetResource *)resource toURL:(NSURL *)URL delegate:(id<AssetResourcExportDelegate>)delegate {
    if (self.isCancelled) {
        [self finishOperationWithStatus:CameraAssetUploadStatusCancelled];
        return;
    }
    
    if (resource.mnz_fileSize > NSFileManager.defaultManager.mnz_fileSystemFreeSize) {
        [self finishUploadWithNoEnoughDiskSpace];
        return;
    }
    
    self.exportDelegate = delegate;
    [self writeAssetResource:resource toURL:URL];
}

- (void)writeAssetResource:(PHAssetResource *)resource toURL:(NSURL *)URL {
    __weak __typeof__(self) weakSelf = self;
    PHAssetResourceRequestOptions *options = [[PHAssetResourceRequestOptions alloc] init];
    options.networkAccessAllowed = YES;
    options.progressHandler = ^(double progress) {
        if (weakSelf.isCancelled) {
            [weakSelf finishOperationWithStatus:CameraAssetUploadStatusCancelled];
        }
    };
    [PHAssetResourceManager.defaultManager writeDataForAssetResource:resource toFile:URL options:options completionHandler:^(NSError * _Nullable error) {
        [weakSelf assetResource:resource didCompleteExportToURL:URL withError:error];
    }];
}

#pragma mark - export done

- (void)assetResource:(PHAssetResource *)resource didCompleteExportToURL:(NSURL *)URL withError:(NSError *)error {
    if (self.isFinished) {
        return;
    }
    
    if (self.isCancelled) {
        [self finishOperationWithStatus:CameraAssetUploadStatusCancelled];
        return;
    }
    
    if (error) {
        MEGALogError(@"[Camera Upload] %@ error when to write asset resource %@", self, error);
        [self handleAssetDownloadError:error];
    } else {
        [self assetResource:resource exportedToURL:URL];
    }
}

- (void)assetResource:(PHAssetResource *)resource exportedToURL:(NSURL *)URL {
    self.uploadInfo.originalFingerprint = [MEGASdkManager.sharedMEGASdk fingerprintForFilePath:URL.path modificationTime:self.uploadInfo.asset.creationDate];
    MEGANode *matchingNode = [self nodeForOriginalFingerprint:self.uploadInfo.originalFingerprint];
    if (matchingNode) {
        MEGALogDebug(@"[Camera Upload] %@ found existing node by original file fingerprint", self);
        [self finishUploadForFingerprintMatchedNode:matchingNode];
    } else {
        [self.exportDelegate assetResource:resource didExportToURL:URL];
    }
}

@end
