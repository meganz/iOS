
#import "AssetResourceUploadOperation.h"
#import "PHAssetResource+CameraUpload.h"
#import "CameraUploadOperation+Utils.h"
#import "NSFileManager+MNZCategory.h"

@interface AssetResourceUploadOperation ()

@property (weak, nonatomic) id<AssetResourceUploadOperationDelegate> delegate;

@end

@implementation AssetResourceUploadOperation

- (instancetype)initWithUploadInfo:(AssetUploadInfo *)uploadInfo uploadRecord:(MOAssetUploadRecord *)uploadRecord {
    self = [super initWithUploadInfo:uploadInfo uploadRecord:uploadRecord];
    if (self) {
        _delegate = self;
    }
    
    return self;
}

- (void)exportAssetResource:(PHAssetResource *)resource toURL:(NSURL *)URL {
    if (self.isCancelled) {
        [self finishOperationWithStatus:CameraAssetUploadStatusCancelled shouldUploadNextAsset:NO];
        return;
    }
    
    if (resource.mnz_fileSize > NSFileManager.defaultManager.deviceFreeSize) {
        [self finishUploadWithNoEnoughDiskSpace];
        return;
    }
    
    __weak __typeof__(self) weakSelf = self;
    PHAssetResourceRequestOptions *options = [[PHAssetResourceRequestOptions alloc] init];
    options.networkAccessAllowed = YES;
    options.progressHandler = ^(double progress) {
        if (weakSelf.isCancelled) {
            [weakSelf finishOperationWithStatus:CameraAssetUploadStatusCancelled shouldUploadNextAsset:NO];
        }
    };
    [PHAssetResourceManager.defaultManager writeDataForAssetResource:resource toFile:URL options:options completionHandler:^(NSError * _Nullable error) {
        [weakSelf assetResource:resource didCompleteExportToURL:URL withError:error];
    }];
}

- (void)assetResource:(PHAssetResource *)resource didCompleteExportToURL:(NSURL *)URL withError:(NSError *)error {
    if (self.isFinished) {
        return;
    }

    if (self.isCancelled) {
        [self finishOperationWithStatus:CameraAssetUploadStatusCancelled shouldUploadNextAsset:NO];
        return;
    }
    
    if (error) {
        if ([self.delegate respondsToSelector:@selector(assetResource:didFailToExportWithError:)]) {
            [self.delegate assetResource:resource didFailToExportWithError:error];
        }
    } else {
        self.uploadInfo.originalFingerprint = [MEGASdkManager.sharedMEGASdk fingerprintForFilePath:URL.path modificationTime:self.uploadInfo.asset.creationDate];
        MEGANode *matchingNode = [self nodeForOriginalFingerprint:self.uploadInfo.originalFingerprint];
        if (matchingNode) {
            MEGALogDebug(@"[Camera Upload] %@ found existing node by original file fingerprint", self);
            [self finishUploadForFingerprintMatchedNode:matchingNode];
        } else {
            [self.delegate assetResource:resource didExportToURL:URL];
        }
    }
}

#pragma mark - AssetResourceUploadOperationDelegate

- (void)assetResource:(PHAssetResource *)resource didExportToURL:(NSURL *)URL { }

- (void)assetResource:(PHAssetResource *)resource didFailToExportWithError:(NSError *)error {
    MEGALogError(@"[Camera Upload] %@ error when to write resource %@", self, error);
    if ([error.domain isEqualToString:AVFoundationErrorDomain] && error.code == AVErrorDiskFull) {
        [self finishUploadWithNoEnoughDiskSpace];
    } else if ([error.domain isEqualToString:NSCocoaErrorDomain] && error.code == NSFileWriteOutOfSpaceError) {
        [self finishUploadWithNoEnoughDiskSpace];
    } else {
        [self handleCloudDownloadError:error];
    }
}

@end
