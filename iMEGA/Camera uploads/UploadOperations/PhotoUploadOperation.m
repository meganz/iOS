
#import "PhotoUploadOperation.h"
#import "NSFileManager+MNZCategory.h"
#import "CameraUploadManager+Settings.h"
#import "PHAsset+CameraUpload.h"
#import "MEGAConstants.h"
#import "ImageExportManager.h"
#import "CameraUploadOperation+Utils.h"
@import CoreServices;

static const NSInteger PhotoExportDiskSizeScalingFactor = 2;
static NSString * const PhotoExportTempName = @"photoExportTemp";

@interface PhotoUploadOperation ()

@property (nonatomic) PHImageRequestID imageRequestId;

@end

@implementation PhotoUploadOperation

#pragma mark - operation lifecycle

- (void)start {
    [super start];
    
    if (self.isFinished) {
        return;
    }
    
    if (self.isCancelled) {
        [self finishOperationWithStatus:CameraAssetUploadStatusCancelled shouldUploadNextAsset:NO];
        return;
    }
    
    [self requestImageData];
}

#pragma mark - data processing

- (void)requestImageData {
    if (self.isCancelled) {
        [self finishOperationWithStatus:CameraAssetUploadStatusCancelled shouldUploadNextAsset:NO];
        return;
    }
    
    __weak __typeof__(self) weakSelf = self;
    PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
    options.networkAccessAllowed = YES;
    options.version = PHImageRequestOptionsVersionCurrent;
    options.synchronous = YES;
    options.progressHandler = ^(double progress, NSError * _Nullable error, BOOL * _Nonnull stop, NSDictionary * _Nullable info) {
        if (weakSelf.isCancelled) {
            *stop = YES;
            [weakSelf finishOperationWithStatus:CameraAssetUploadStatusCancelled shouldUploadNextAsset:NO];
        }
        
        if (error) {
            MEGALogError(@"[Camera Upload] %@ error when to download images from iCloud: %@", weakSelf, error);
            [weakSelf handleCloudDownloadError:error];
        }
    };
    
    self.imageRequestId = [[PHImageManager defaultManager] requestImageDataForAsset:self.uploadInfo.asset options:options resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
        if (weakSelf.isFinished) {
            return;
        }
        
        if (weakSelf.isCancelled) {
            [weakSelf finishOperationWithStatus:CameraAssetUploadStatusCancelled shouldUploadNextAsset:NO];
            return;
        }
        
        NSError *error = info[PHImageErrorKey];
        if (error) {
            MEGALogError(@"[Camera Upload] %@ error when to request photo %@", weakSelf, error);
            [weakSelf finishOperationWithStatus:CameraAssetUploadStatusFailed shouldUploadNextAsset:YES];
            return;
        }
        
        if ([info[PHImageCancelledKey] boolValue]) {
            MEGALogDebug(@"[Camera Upload] %@ photo request is cancelled", weakSelf);
            [weakSelf finishOperationWithStatus:CameraAssetUploadStatusCancelled shouldUploadNextAsset:NO];
            return;
        }
        
        [weakSelf processImageData:imageData dataUTI:dataUTI dataInfo:info];
    }];
}

- (void)processImageData:(NSData *)imageData dataUTI:(NSString *)dataUTI dataInfo:(NSDictionary *)dataInfo {
    if (self.isCancelled) {
        [self finishOperationWithStatus:CameraAssetUploadStatusCancelled shouldUploadNextAsset:NO];
        return;
    }
    
    if (imageData == nil) {
        MEGALogError(@"[Camera Upload] %@ the requested image data is empty", self);
        [self finishOperationWithStatus:CameraAssetUploadStatusFailed shouldUploadNextAsset:YES];
        return;
    }
    
    if (imageData.length * PhotoExportDiskSizeScalingFactor > NSFileManager.defaultManager.mnz_fileSystemFreeSize) {
        [self finishUploadWithNoEnoughDiskSpace];
        return;
    }
    
    NSURL *imageURL = [self.uploadInfo.directoryURL URLByAppendingPathComponent:PhotoExportTempName];
    if (![imageData writeToURL:imageURL atomically:YES]) {
        [self finishOperationWithStatus:CameraAssetUploadStatusFailed shouldUploadNextAsset:YES];
        return;
    }
    
    self.uploadInfo.originalFingerprint = [MEGASdkManager.sharedMEGASdk fingerprintForFilePath:imageURL.path modificationTime:self.uploadInfo.asset.creationDate];
    MEGANode *matchingNode = [self nodeForOriginalFingerprint:self.uploadInfo.originalFingerprint];
    if (matchingNode) {
        MEGALogDebug(@"[Camera Upload] %@ found node by original fingerprint", self);
        [self finishUploadForFingerprintMatchedNode:matchingNode];
        return;
    }
    
    [self exportImageAtURL:imageURL dataUTI:dataUTI dataInfo:dataInfo];
}

- (void)exportImageAtURL:(NSURL *)URL dataUTI:(NSString *)dataUTI dataInfo:(NSDictionary *)dataInfo {
    if (self.isCancelled) {
        [self finishOperationWithStatus:CameraAssetUploadStatusCancelled shouldUploadNextAsset:NO];
        return;
    }
    
    NSString *outputTypeUTI;
    if ([self shouldConvertToJPGForUTI:dataUTI]) {
        self.uploadInfo.fileName = [self mnz_generateLocalFileNamewithExtension:MEGAJPGFileExtension];
        outputTypeUTI = (__bridge NSString *)kUTTypeJPEG;
    } else {
        NSString *fileExtension = [self.uploadInfo.asset mnz_fileExtensionFromAssetInfo:dataInfo];
        self.uploadInfo.fileName = [self mnz_generateLocalFileNamewithExtension:fileExtension];
    }
    
    __weak __typeof__(self) weakSelf = self;
    [ImageExportManager.shared exportImageAtURL:URL dataTypeUTI:dataUTI toURL:self.uploadInfo.fileURL outputTypeUTI:outputTypeUTI shouldStripGPSInfo:YES completion:^(BOOL succeeded) {
        if (weakSelf.isCancelled) {
            [weakSelf finishOperationWithStatus:CameraAssetUploadStatusCancelled shouldUploadNextAsset:NO];
            return;
        }
        
        if (succeeded && [NSFileManager.defaultManager isReadableFileAtPath:weakSelf.uploadInfo.fileURL.path]) {
            [NSFileManager.defaultManager mnz_removeItemAtPath:URL.path];
            [weakSelf handleProcessedFileWithMediaType:PHAssetMediaTypeImage];
        } else {
            MEGALogError(@"[Camera Upload] %@ error when to export image to file %@", weakSelf, weakSelf.uploadInfo.fileName);
            [weakSelf finishOperationWithStatus:CameraAssetUploadStatusFailed shouldUploadNextAsset:YES];
        }
    }];
}

- (BOOL)shouldConvertToJPGForUTI:(NSString *)dataUTI {
    if (@available(iOS 11.0, *)) {
        return [CameraUploadManager shouldConvertHEICPhoto] && UTTypeConformsTo((__bridge CFStringRef)dataUTI, (__bridge CFStringRef)AVFileTypeHEIC);
    } else {
        return NO;
    }
}

#pragma mark - cancel operation

- (void)cancel {
    [super cancel];
    
    if (self.imageRequestId != PHInvalidImageRequestID) {
        MEGALogDebug(@"[Camera Upload] %@ cancel photo data request with request Id %d", self, self.imageRequestId);
        [PHImageManager.defaultManager cancelImageRequest:self.imageRequestId];
    }
}

@end
