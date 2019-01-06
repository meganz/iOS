
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
#import "CameraUploadFileNameRecordManager.h"
#import "NSData+ImageIO.h"
#import "CameraUploadManager+Settings.h"
#import "PHAsset+CameraUpload.h"
@import CoreServices;

static NSString * const kUTITypeHEICImage = @"public.heic";

@implementation PhotoUploadOperation

#pragma mark - operation lifecycle

- (void)start {
    [super start];

    [self requestImageData];
}

#pragma mark - data processing

- (void)requestImageData {
    MEGALogDebug(@"[Camera Upload] %@ starts requesting image data", self);
    PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
    options.networkAccessAllowed = YES;
    options.version = PHImageRequestOptionsVersionCurrent;
    options.synchronous = YES;
    
    __weak __typeof__(self) weakSelf = self;
    [[PHImageManager defaultManager] requestImageDataForAsset:self.uploadInfo.asset options:options resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
        if (weakSelf.isCancelled) {
            [weakSelf finishOperationWithStatus:CameraAssetUploadStatusFailed shouldUploadNextAsset:YES];
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
    MEGALogDebug(@"[Camera Upload] %@ starts processing image data", self);
    self.uploadInfo.originalFingerprint = [[MEGASdkManager sharedMEGASdk] fingerprintForData:imageData modificationTime:self.uploadInfo.asset.creationDate];
    MEGANode *matchingNode = [self nodeForOriginalFingerprint:self.uploadInfo.originalFingerprint];
    if (matchingNode) {
        [self copyToParentNodeIfNeededForMatchingNode:matchingNode];
        [self finishOperationWithStatus:CameraAssetUploadStatusDone shouldUploadNextAsset:YES];
        return;
    }
    
    NSString *fileExtension;
    NSData *processedImageData;
    if ([CameraUploadManager shouldConvertHEIFPhoto] && UTTypeConformsTo((__bridge CFStringRef)dataUTI, (__bridge CFStringRef)kUTITypeHEICImage)) {
        processedImageData = [imageData mnz_dataByConvertingToType:(__bridge NSString *)kUTTypeJPEG shouldStripGPSInfo:YES];
        fileExtension = @"jpg";
    } else {
        processedImageData = [imageData mnz_dataByStrippingOffGPSIfNeeded];
        fileExtension = [self.uploadInfo.asset fileExtensionFromAssetInfo:dataInfo];
    }
    
    self.uploadInfo.fingerprint = [[MEGASdkManager sharedMEGASdk] fingerprintForData:processedImageData modificationTime:self.uploadInfo.asset.creationDate];
    matchingNode = [[MEGASdkManager sharedMEGASdk] nodeForFingerprint:self.uploadInfo.fingerprint parent:self.uploadInfo.parentNode];
    if (matchingNode) {
        [self copyToParentNodeIfNeededForMatchingNode:matchingNode];
        [self finishOperationWithStatus:CameraAssetUploadStatusDone shouldUploadNextAsset:YES];
        return;
    }

    NSString *proposedFileName = [[NSString mnz_fileNameWithDate:self.uploadInfo.asset.creationDate] stringByAppendingPathExtension:fileExtension];
    self.uploadInfo.fileName = [CameraUploadFileNameRecordManager.shared localUniqueFileNameForAssetLocalIdentifier:self.uploadInfo.asset.localIdentifier proposedFileName:proposedFileName];
    
    if ([processedImageData writeToURL:self.uploadInfo.fileURL atomically:YES]) {
        [self encryptsFile];
    } else {
        [self finishOperationWithStatus:CameraAssetUploadStatusFailed shouldUploadNextAsset:YES];
    }
}

@end
