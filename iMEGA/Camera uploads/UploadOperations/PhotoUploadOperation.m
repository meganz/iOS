
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
@import CoreServices;

const NSInteger PhotoExportDiskSizeMultiplicationFactor = 2;

@implementation PhotoUploadOperation

#pragma mark - operation lifecycle

- (void)start {
    [super start];

    [self requestImageData];
}

#pragma mark - data processing

- (void)requestImageData {
    MEGALogDebug(@"[Camera Upload] %@ starts requesting image data", self);
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
            [weakSelf finishOperationWithStatus:CameraAssetUploadStatusFailed shouldUploadNextAsset:YES];
        }
    };
    
    [[PHImageManager defaultManager] requestImageDataForAsset:self.uploadInfo.asset options:options resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
        if (weakSelf.isFinished) {
            return;
        }
        
        if (imageData) {
            [weakSelf processImageData:imageData dataUTI:dataUTI dataInfo:info];
        } else {
            [weakSelf finishOperationWithStatus:CameraAssetUploadStatusFailed shouldUploadNextAsset:YES];
        }
    }];
}

- (void)processImageData:(NSData *)imageData dataUTI:(NSString *)dataUTI dataInfo:(NSDictionary *)dataInfo {
    if (self.isCancelled) {
        [self finishOperationWithStatus:CameraAssetUploadStatusCancelled shouldUploadNextAsset:NO];
        return;
    }
    
    MEGALogDebug(@"[Camera Upload] %@ starts processing image data", self);
    self.uploadInfo.originalFingerprint = [[MEGASdkManager sharedMEGASdk] fingerprintForData:imageData modificationTime:self.uploadInfo.asset.creationDate];
    MEGANode *matchingNode = [self nodeForOriginalFingerprint:self.uploadInfo.originalFingerprint];
    if (matchingNode) {
        [self finishUploadForFingerprintMatchedNode:matchingNode];
        return;
    }
    
    NSString *outputTypeUTI;
    if ([self shouldConvertToJPGForUTI:dataUTI]) {
        self.uploadInfo.fileName = [self.uploadInfo.asset mnz_cameraUploadFileNameWithExtension:MEGAJPGFileExtension];
        outputTypeUTI = (__bridge NSString *)kUTTypeJPEG;
    } else {
        NSString *fileExtension = [self.uploadInfo.asset mnz_fileExtensionFromAssetInfo:dataInfo];
        self.uploadInfo.fileName = [self.uploadInfo.asset mnz_cameraUploadFileNameWithExtension:fileExtension];
    }
    
    if (imageData.length * PhotoExportDiskSizeMultiplicationFactor > NSFileManager.defaultManager.deviceFreeSize) {
        [self finishUploadWithNoEnoughDiskSpace];
        return;
    }
    
    [PhotoExportManager.shared exportPhotoData:imageData dataTypeUTI:dataUTI outputURL:self.uploadInfo.fileURL outputTypeUTI:outputTypeUTI shouldStripGPSInfo:YES completion:^(BOOL succeeded) {
        if (succeeded && [NSFileManager.defaultManager isReadableFileAtPath:self.uploadInfo.fileURL.path]) {
            [self handleProcessedUploadFile];
        } else {
            [self finishOperationWithStatus:CameraAssetUploadStatusFailed shouldUploadNextAsset:YES];
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

@end
