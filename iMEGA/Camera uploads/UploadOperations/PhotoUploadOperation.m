
#import <Foundation/Foundation.h>
#import "PhotoUploadOperation.h"
#import "MEGASdkManager.h"
#import "NSFileManager+MNZCategory.h"
#import "NSString+MNZCategory.h"
#import "TransferSessionManager.h"
#import "AssetUploadInfo.h"
#import "CameraUploadRecordManager.h"
#import "CameraUploadManager.h"
#import "CameraUploadRequestDelegate.h"
#import "NSData+CameraUpload.h"
#import "CameraUploadManager+Settings.h"
#import "PHAsset+CameraUpload.h"
#import "MEGAConstants.h"
#import "PhotoExportManager.h"
#import "CameraUploadOperation+Utils.h"
@import CoreServices;

const NSInteger PhotoExportDiskSizeMultiplicationFactor = 2;

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
        
        if (error != nil) {
            MEGALogError(@"[Camera Upload] %@ error when to download images from iCloud: %@", weakSelf, error);
            [weakSelf handleCloudDownloadError:error];
        }
    };
    
    self.imageRequestId = [[PHImageManager defaultManager] requestImageDataForAsset:self.uploadInfo.asset options:options resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
        if (weakSelf.isFinished) {
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
        [self finishOperationWithStatus:CameraAssetUploadStatusFailed shouldUploadNextAsset:YES];
        return;
    }

    self.uploadInfo.originalFingerprint = [[MEGASdkManager sharedMEGASdk] fingerprintForData:imageData modificationTime:self.uploadInfo.asset.creationDate];
    MEGANode *matchingNode = [self nodeForOriginalFingerprint:self.uploadInfo.originalFingerprint];
    if (matchingNode) {
        MEGALogDebug(@"[Camera Upload] %@ found existing node by original file fingerprint", self);
        [self finishUploadForFingerprintMatchedNode:matchingNode];
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
    
    if (imageData.length * PhotoExportDiskSizeMultiplicationFactor > NSFileManager.defaultManager.deviceFreeSize) {
        [self finishUploadWithNoEnoughDiskSpace];
        return;
    }
    
    __weak __typeof__(self) weakSelf = self;
    [PhotoExportManager.shared exportPhotoData:imageData dataTypeUTI:dataUTI outputURL:self.uploadInfo.fileURL outputTypeUTI:outputTypeUTI shouldStripGPSInfo:YES completion:^(BOOL succeeded) {
        if (weakSelf.isCancelled) {
            [weakSelf finishOperationWithStatus:CameraAssetUploadStatusCancelled shouldUploadNextAsset:NO];
            return;
        }
        
        if (succeeded && [NSFileManager.defaultManager isReadableFileAtPath:self.uploadInfo.fileURL.path]) {
            [weakSelf handleProcessedUploadFile];
        } else {
            MEGALogError(@"[Camera Upload] error when to export image to URL %@", self.uploadInfo.fileURL);
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

#pragma mark - cancel pending tasks

- (void)cancelPendingTasks {
    [super cancelPendingTasks];
    
    if (self.imageRequestId != PHInvalidImageRequestID) {
        MEGALogDebug(@"[Camera Upload] %@ cancel photo data request with request Id %d", self, self.imageRequestId);
        [PHImageManager.defaultManager cancelImageRequest:self.imageRequestId];
    }
}

@end
