
#import "PhotoUploadOperation.h"
#import "NSFileManager+MNZCategory.h"
#import "CameraUploadManager+Settings.h"
#import "ImageExportManager.h"
#import "CameraUploadOperation+Utils.h"
#import "MEGA-Swift.h"
@import CoreServices;
@import FirebaseCrashlytics;

static const NSInteger PhotoExportDiskSizeScalingFactor = 2;
static NSString * const PhotoExportTempName = @"photoExportTemp";

@interface PhotoUploadOperation ()

@property (nonatomic) PHImageRequestID imageRequestId;

@end

@implementation PhotoUploadOperation

#pragma mark - operation lifecycle

- (void)start {
    [super start];
    
    [self requestImageData];
}

#pragma mark - data processing

- (void)requestImageData {
    if (self.isCancelled) {
        [self finishOperationWithStatus:CameraAssetUploadStatusCancelled];
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
            [weakSelf finishOperationWithStatus:CameraAssetUploadStatusCancelled];
        }
        
        if (error) {
            MEGALogError(@"[Camera Upload] %@ error when to download images from iCloud: %@", weakSelf, error);
            *stop = YES;
            [weakSelf handleAssetDownloadError:error];
        }
    };
    
    self.imageRequestId = [[PHImageManager defaultManager] requestImageDataAndOrientationForAsset:self.uploadInfo.asset options:options resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, CGImagePropertyOrientation orientation, NSDictionary * _Nullable info) {
        if (weakSelf.isFinished) {
            return;
        }
        
        if (weakSelf.isCancelled) {
            [weakSelf finishOperationWithStatus:CameraAssetUploadStatusCancelled];
            return;
        }
        
        NSError *error = info[PHImageErrorKey];
        if (error) {
            MEGALogError(@"[Camera Upload] %@ error when to request photo %@", weakSelf, error);
            [weakSelf finishOperationWithStatus:CameraAssetUploadStatusFailed];
            return;
        }
        
        if ([info[PHImageCancelledKey] boolValue]) {
            MEGALogDebug(@"[Camera Upload] %@ photo request is cancelled", weakSelf);
            [weakSelf finishOperationWithStatus:CameraAssetUploadStatusCancelled];
            return;
        }
        
        [weakSelf processImageData:imageData dataUTI:dataUTI dataInfo:info];
    }];
}

- (void)processImageData:(NSData *)imageData dataUTI:(NSString *)dataUTI dataInfo:(NSDictionary *)dataInfo {
    if (self.isCancelled) {
        [self finishOperationWithStatus:CameraAssetUploadStatusCancelled];
        return;
    }
    
    if (imageData == nil) {
        MEGALogError(@"[Camera Upload] %@ the requested image data is empty", self);
        [self finishOperationWithStatus:CameraAssetUploadStatusFailed];
        return;
    }
    
    if (imageData.length * PhotoExportDiskSizeScalingFactor > NSFileManager.defaultManager.mnz_fileSystemFreeSize) {
        [self finishUploadWithNoEnoughDiskSpace];
        return;
    }
    
    NSURL *imageURL = [self.uploadInfo.directoryURL URLByAppendingPathComponent:PhotoExportTempName];
    if (![imageData writeToURL:imageURL atomically:YES]) {
        [self finishOperationWithStatus:CameraAssetUploadStatusFailed];
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
        [self finishOperationWithStatus:CameraAssetUploadStatusCancelled];
        return;
    }
    
    NSString *outputTypeUTI;
    NSError *error;
    if ([self shouldConvertToJPGForUTI:dataUTI]) {
        self.uploadInfo.fileName = [self mnz_generateLocalFileNamewithExtension:MEGAJPGFileExtension error:&error];
        outputTypeUTI = (__bridge NSString *)kUTTypeJPEG;
    } else {
        NSString *fileExtension = [self.uploadInfo.asset mnz_fileExtensionFromAssetInfo:dataInfo uniformTypeIdentifier:dataUTI];
        self.uploadInfo.fileName = [self mnz_generateLocalFileNamewithExtension:fileExtension error:&error];
    }
    
    if (error) {
        MEGALogError(@"[Camera Upload] %@ error when to generate local unique file name %@", self, error);
        [[FIRCrashlytics crashlytics] recordError:error];
        [self finishOperationWithStatus:CameraAssetUploadStatusFailed];
        return;
    }
    
    __weak __typeof__(self) weakSelf = self;
    [ImageExportManager.shared exportImageAtURL:URL dataTypeUTI:dataUTI toURL:self.uploadInfo.fileURL outputTypeUTI:outputTypeUTI shouldStripGPSInfo:!CameraUploadManager.shouldIncludeGPSTags completion:^(BOOL succeeded) {
        if (weakSelf.isCancelled) {
            [weakSelf finishOperationWithStatus:CameraAssetUploadStatusCancelled];
            return;
        }
        
        if (succeeded && [NSFileManager.defaultManager isReadableFileAtPath:weakSelf.uploadInfo.fileURL.path]) {
            [NSFileManager.defaultManager mnz_removeItemAtPath:URL.path];
            [weakSelf handleProcessedFileWithMediaType:PHAssetMediaTypeImage];
        } else {
            MEGALogError(@"[Camera Upload] %@ error when to export image to file %@", weakSelf, weakSelf.uploadInfo.fileName);
            [weakSelf finishOperationWithStatus:CameraAssetUploadStatusFailed];
        }
    }];
}

- (BOOL)shouldConvertToJPGForUTI:(NSString *)dataUTI {
    return [CameraUploadManager shouldConvertHEICPhoto] && UTTypeConformsTo((__bridge CFStringRef)dataUTI, (__bridge CFStringRef)AVFileTypeHEIC);
}

- (UploadQueueType)uploadQueueType {
    return UploadQueueTypePhoto;
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
