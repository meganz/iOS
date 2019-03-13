
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

static NSString * const PhotoResourceExportName = @"photoResourceExport";

@implementation PhotoUploadOperation

#pragma mark - operation lifecycle

- (void)start {
    [super start];

    [self requestImageResource];
}

#pragma mark - image resource

- (void)requestImageResource {
    if (self.isCancelled) {
        [self finishOperationWithStatus:CameraAssetUploadStatusCancelled shouldUploadNextAsset:NO];
        return;
    }
    
    PHAssetResource *photoResource = [self.uploadInfo.asset searchAssetResourceByTypes:@[@(PHAssetResourceTypeFullSizePhoto), @(PHAssetResourceTypePhoto), @(PHAssetResourceTypeAdjustmentBasePhoto), @(PHAssetResourceTypeAlternatePhoto)]];
    if (photoResource) {
        NSURL *imageURL = [self.uploadInfo.directoryURL URLByAppendingPathComponent:PhotoResourceExportName];
        [self exportAssetResource:photoResource toURL:imageURL];
    } else {
        MEGALogError(@"[Camera Upload] %@ can not find photo resource", self);
        [self finishOperationWithStatus:CameraAssetUploadStatusFailed shouldUploadNextAsset:YES];
    }
}

#pragma mark - AssetResourceUploadOperationDelegate

- (void)assetResource:(PHAssetResource *)resource didExportToURL:(NSURL *)URL {
    [super assetResource:resource didExportToURL:URL];
    
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
    [ImageExportManager.shared exportImageAtURL:URL dataTypeUTI:resource.uniformTypeIdentifier toURL:self.uploadInfo.fileURL outputTypeUTI:outputTypeUTI shouldStripGPSInfo:YES completion:^(BOOL succeeded) {
        if (weakSelf.isCancelled) {
            [weakSelf finishOperationWithStatus:CameraAssetUploadStatusCancelled shouldUploadNextAsset:NO];
            return;
        }
        
        if (succeeded && [NSFileManager.defaultManager isReadableFileAtPath:weakSelf.uploadInfo.fileURL.path]) {
            [NSFileManager.defaultManager removeItemIfExistsAtURL:URL];
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
