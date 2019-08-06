
#import "AssetResourceUploadOperation.h"
#import "PHAssetResource+CameraUpload.h"
#import "CameraUploadOperation+Utils.h"
#import "NSFileManager+MNZCategory.h"

@interface AssetResourceUploadOperation ()

@property (weak, nonatomic) id<AssetResourcExportDelegate> exportDelegate;

@end

@implementation AssetResourceUploadOperation

- (instancetype)initWithUploadInfo:(AssetUploadInfo *)uploadInfo uploadRecord:(MOAssetUploadRecord *)uploadRecord {
    self = [super initWithUploadInfo:uploadInfo uploadRecord:uploadRecord];
    if (self) {
        _exportDelegate = self;
    }
    
    return self;
}

#pragma mark - export local asset resource

- (void)exportAssetResource:(PHAssetResource *)resource toURL:(NSURL *)URL {
    if (self.isCancelled) {
        [self finishOperationWithStatus:CameraAssetUploadStatusCancelled];
        return;
    }
    
    if (resource.mnz_fileSize > NSFileManager.defaultManager.mnz_fileSystemFreeSize) {
        [self finishUploadWithNoEnoughDiskSpace];
        return;
    }
    
    [self exportLocalAssetResource:resource toURL:URL];
}

- (void)exportLocalAssetResource:(PHAssetResource *)resource toURL:(NSURL *)URL {
    __weak __typeof__(self) weakSelf = self;
    PHAssetResourceRequestOptions *options = [[PHAssetResourceRequestOptions alloc] init];
    options.networkAccessAllowed = NO;
    [PHAssetResourceManager.defaultManager writeDataForAssetResource:resource toFile:URL options:options completionHandler:^(NSError * _Nullable error) {
        [weakSelf localAssetResource:resource didCompleteExportToURL:URL withError:error];
    }];
}

- (void)localAssetResource:(PHAssetResource *)resource didCompleteExportToURL:(NSURL *)URL withError:(NSError *)error {
    if (self.isFinished) {
        return;
    }
    
    if (self.isCancelled) {
        [self finishOperationWithStatus:CameraAssetUploadStatusCancelled];
        return;
    }
    
    if (error) {
        MEGALogDebug(@"[Camera Upload] %@ can not write local asset resource %@", self, error);
        if ([error.domain isEqualToString:AVFoundationErrorDomain] && error.code == AVErrorDiskFull) {
            [self finishUploadWithNoEnoughDiskSpace];
        } else if ([error.domain isEqualToString:NSCocoaErrorDomain] && error.code == NSFileWriteOutOfSpaceError) {
            [self finishUploadWithNoEnoughDiskSpace];
        } else {
            [self exportCloudAssetResource:resource toURL:URL];
        }
    } else {
        [self assetResource:resource exportedToURL:URL];
    }
}

#pragma mark - export iCloud asset resource fall back

- (void)exportCloudAssetResource:(PHAssetResource *)resource toURL:(NSURL *)URL {
    [NSFileManager.defaultManager mnz_removeItemAtPath:URL.path];
    
    __weak __typeof__(self) weakSelf = self;
    PHAssetResourceRequestOptions *options = [[PHAssetResourceRequestOptions alloc] init];
    options.networkAccessAllowed = YES;
    options.progressHandler = ^(double progress) {
        if (weakSelf.isCancelled) {
            [weakSelf finishOperationWithStatus:CameraAssetUploadStatusCancelled];
        }
    };
    [PHAssetResourceManager.defaultManager writeDataForAssetResource:resource toFile:URL options:options completionHandler:^(NSError * _Nullable error) {
        [weakSelf cloudAssetResource:resource didCompleteExportToURL:URL withError:error];
    }];
}

- (void)cloudAssetResource:(PHAssetResource *)resource didCompleteExportToURL:(NSURL *)URL withError:(NSError *)error {
    if (self.isFinished) {
        return;
    }
    
    if (self.isCancelled) {
        [self finishOperationWithStatus:CameraAssetUploadStatusCancelled];
        return;
    }
    
    if (error) {
        if ([self.exportDelegate respondsToSelector:@selector(assetResource:didFailToExportWithError:)]) {
            [self.exportDelegate assetResource:resource didFailToExportWithError:error];
        }
    } else {
        [self assetResource:resource exportedToURL:URL];
    }
}

#pragma mark - export done

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

#pragma mark - Asset Resource Upload Operation Delegate

- (void)assetResource:(PHAssetResource *)resource didExportToURL:(NSURL *)URL { }

- (void)assetResource:(PHAssetResource *)resource didFailToExportWithError:(NSError *)error {
    MEGALogError(@"[Camera Upload] %@ error when to write asset resource %@", self, error);
    [self handleCloudDownloadError:error];
}

@end
