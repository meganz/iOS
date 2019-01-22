
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
    
    [PhotoExportManager.shared exportPhotoData:imageData dataTypeUTI:dataUTI outputURL:self.uploadInfo.fileURL outputTypeUTI:outputTypeUTI shouldStripGPSInfo:YES completion:^(BOOL succeeded) {
        if (succeeded && [NSFileManager.defaultManager fileExistsAtPath:self.uploadInfo.fileURL.path]) {
            [self checkFingerprintAndEncryptFileIfNeeded];
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
