
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
#import "CameraUploadManager+Settings.h"
#import "PHAsset+CameraUpload.h"
#import "MEGAConstants.h"
#import "ImageExportManager.h"
#import "CameraUploadOperation+Utils.h"
#import "PHAssetResource+CameraUpload.h"
@import CoreServices;

static const NSInteger PhotoExportDiskSizeScalingFactor = 2;
static NSString * const OriginalPhotoName = @"originalPhotoFile";

@implementation PhotoUploadOperation

#pragma mark - operation lifecycle

- (void)start {
    [super start];

    [self requestImageData];
}

#pragma mark - image resource

- (void)requestImageData {
    if (self.isCancelled) {
        [self finishOperationWithStatus:CameraAssetUploadStatusCancelled shouldUploadNextAsset:NO];
        return;
    }
    
    PHAssetResource *photoResource = [self findPhotoResource];
    if (photoResource) {
        [self writeDataForResource:photoResource];
    } else {
        MEGALogError(@"[Camera Upload] %@ can not find photo resource", self);
        [self finishOperationWithStatus:CameraAssetUploadStatusFailed shouldUploadNextAsset:YES];
    }
}

- (nullable PHAssetResource *)findPhotoResource {
    PHAssetResource *photoResource = nil;
    for (PHAssetResource *resource in [PHAssetResource assetResourcesForAsset:self.uploadInfo.asset]) {
        if (resource.type == PHAssetResourceTypeFullSizePhoto) { // maps to PHImageRequestOptionsVersionCurrent
            photoResource = resource;
            break;
        }
    }
    
    if (photoResource == nil) {
        for (PHAssetResource *resource in [PHAssetResource assetResourcesForAsset:self.uploadInfo.asset]) {
            if (resource.type == PHAssetResourceTypePhoto) { // maps to PHImageRequestOptionsVersionOriginal
                photoResource = resource;
                break;
            }
        }
    }
    
    if (photoResource == nil) {
        for (PHAssetResource *resource in [PHAssetResource assetResourcesForAsset:self.uploadInfo.asset]) {
            if (resource.type == PHAssetResourceTypeAlternatePhoto) { // maps to PHImageRequestOptionsVersionOriginal
                photoResource = resource;
                break;
            }
        }
    }
    
    if (photoResource == nil) {
        for (PHAssetResource *resource in [PHAssetResource assetResourcesForAsset:self.uploadInfo.asset]) {
            if (resource.type == PHAssetResourceTypeAdjustmentBasePhoto) { // maps to PHImageRequestOptionsVersionUnadjusted
                photoResource = resource;
                break;
            }
        }
    }
    
    return photoResource;
}

#pragma mark - write data

- (void)writeDataForResource:(PHAssetResource *)resource {
    if (self.isCancelled) {
        [self finishOperationWithStatus:CameraAssetUploadStatusCancelled shouldUploadNextAsset:NO];
        return;
    }
    
    if (resource.mnz_fileSize * PhotoExportDiskSizeScalingFactor > NSFileManager.defaultManager.deviceFreeSize) {
        [self finishUploadWithNoEnoughDiskSpace];
        return;
    }
    
    NSURL *imageURL = [self.uploadInfo.directoryURL URLByAppendingPathComponent:OriginalPhotoName];
    PHAssetResourceRequestOptions *options = [[PHAssetResourceRequestOptions alloc] init];
    options.networkAccessAllowed = YES;
    __weak __typeof__(self) weakSelf = self;
    [PHAssetResourceManager.defaultManager writeDataForAssetResource:resource toFile:imageURL options:options completionHandler:^(NSError * _Nullable error) {
        [weakSelf resource:resource writeDataToURL:imageURL completedWithError:error];
    }];
}

- (void)resource:(PHAssetResource *)resource writeDataToURL:(NSURL *)URL completedWithError:(NSError *)error {
    if (self.isCancelled) {
        [self finishOperationWithStatus:CameraAssetUploadStatusCancelled shouldUploadNextAsset:NO];
        return;
    }
    
    if (error) {
        MEGALogError(@"[Camera Upload] %@ error when to write resource %@", self, error);
        if ([error.domain isEqualToString:AVFoundationErrorDomain] && error.code == AVErrorDiskFull) {
            [self finishUploadWithNoEnoughDiskSpace];
        } else if ([error.domain isEqualToString:NSCocoaErrorDomain] && error.code == NSFileWriteOutOfSpaceError) {
            [self finishUploadWithNoEnoughDiskSpace];
        } else {
            [self finishOperationWithStatus:CameraAssetUploadStatusFailed shouldUploadNextAsset:YES];
        }
    } else {
        self.uploadInfo.originalFingerprint = [MEGASdkManager.sharedMEGASdk fingerprintForFilePath:URL.path modificationTime:self.uploadInfo.asset.creationDate];
        MEGANode *matchingNode = [self nodeForOriginalFingerprint:self.uploadInfo.originalFingerprint];
        if (matchingNode) {
            MEGALogDebug(@"[Camera Upload] %@ found existing node by original file fingerprint", self);
            [self finishUploadForFingerprintMatchedNode:matchingNode];
            return;
        } else {
            [self exportImageAtURL:URL withResource:resource];
        }
    }
}

- (void)exportImageAtURL:(NSURL *)imageURL withResource:(PHAssetResource *)resource {
    if (self.isCancelled) {
        [self finishOperationWithStatus:CameraAssetUploadStatusCancelled shouldUploadNextAsset:NO];
        return;
    }
    
    NSString *outputTypeUTI;
    if ([self shouldConvertToJPGForUTI:resource.uniformTypeIdentifier]) {
        self.uploadInfo.fileName = [self mnz_generateLocalFileNamewithExtension:MEGAJPGFileExtension];
        outputTypeUTI = (__bridge NSString *)kUTTypeJPEG;
    } else {
        self.uploadInfo.fileName = [self mnz_generateLocalFileNamewithExtension:resource.originalFilename.pathExtension];
    }
    
    __weak __typeof__(self) weakSelf = self;
    [ImageExportManager.shared exportImageAtURL:imageURL dataTypeUTI:resource.uniformTypeIdentifier toURL:self.uploadInfo.fileURL outputTypeUTI:outputTypeUTI shouldStripGPSInfo:YES completion:^(BOOL succeeded) {
        if (weakSelf.isCancelled) {
            [weakSelf finishOperationWithStatus:CameraAssetUploadStatusCancelled shouldUploadNextAsset:NO];
            return;
        }
        
        if (succeeded && [NSFileManager.defaultManager isReadableFileAtPath:weakSelf.uploadInfo.fileURL.path]) {
            [NSFileManager.defaultManager removeItemIfExistsAtURL:imageURL];
            [weakSelf handleProcessedImageFile];
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

@end
