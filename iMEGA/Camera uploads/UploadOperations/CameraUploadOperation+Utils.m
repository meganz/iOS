#import "CameraUploadOperation+Utils.h"
#import "CameraUploadOperation+Telemetry.h"
#import "CameraUploadRecordManager.h"
#import "NSString+MNZCategory.h"
#import "MEGAReachabilityManager.h"
#import "NSFileManager+MNZCategory.h"
#import "NSDate+MNZCategory.h"
#import "LivePhotoUploadOperation.h"
#import "CameraUploadRequestDelegate.h"
#import "MEGAError+MNZCategory.h"
#import "NSError+CameraUpload.h"
#import "MEGANode+MNZCategory.h"
#import "MEGA-Swift.h"
@import FirebaseCrashlytics;

static NSString * const CameraUploadLivePhotoExtension = @"live";
static NSString * const CameraUploadBurstPhotoExtension = @"burst";

@implementation CameraUploadOperation (Utils)

#pragma mark - handle fingerprint

- (void)copyToParentNodeIfNeededForMatchingNode:(MEGANode *)node localFileName:(NSString *)fileName {
    if (node.parentHandle != self.uploadInfo.parentNode.handle) {
        NSString *uniqueFileName = [fileName mnz_sequentialFileNameInParentNode:self.uploadInfo.parentNode];
        [MEGASdk.shared copyNode:node newParent:self.uploadInfo.parentNode newName:uniqueFileName delegate:[[CameraUploadRequestDelegate alloc] initWithCompletion:^(MEGARequest * _Nonnull request, MEGAError * _Nonnull error) {
            if (self.isCancelled) {
                [self finishOperationWithStatus:CameraAssetUploadStatusCancelled];
                return;
            }
            
            if (error.type) {
                MEGALogError(@"[Camera Upload] %@ error when to copy node %@", self, error.nativeError);
                [self handleMEGARequestError:error];
            } else {
                [self finishOperationWithStatus:CameraAssetUploadStatusDone];
                [NSNotificationCenter.defaultCenter postNotificationName:MEGACameraUploadNodeUploadCompleteNotification object:nil userInfo:@{MEGANodeHandleKey : @(node.handle)}];
            }
        }]];
    } else {
        [self finishOperationWithStatus:CameraAssetUploadStatusDone];
        [NSNotificationCenter.defaultCenter postNotificationName:MEGACameraUploadNodeUploadCompleteNotification object:nil userInfo:@{MEGANodeHandleKey : @(node.handle)}];
    }
}

- (MEGANode *)nodeForOriginalFingerprint:(NSString *)fingerprint {
    MEGANode *parentNode = self.uploadInfo.parentNode;
    MEGANode *matchingNode = [MEGASdk.shared nodeForFingerprint:fingerprint parent:parentNode];
    if (matchingNode != nil && matchingNode.parentHandle == parentNode.handle) {
        return matchingNode;
    }

    NSMutableArray<MEGANode *> *candidates = [NSMutableArray array];
    if (matchingNode != nil) {
        [candidates addObject:matchingNode];
    }
    MEGANodeList *nodeList = [MEGASdk.shared nodesForOriginalFingerprint:fingerprint];
    for (NSInteger i = 0; i < nodeList.size; i++) {
        [candidates addObject:[nodeList nodeAtIndex:i]];
    }

    for (MEGANode *node in candidates) {
        if (node.parentHandle == parentNode.handle) {
            return node;
        }
    }

    // A node the user deleted from the parent wins over copies elsewhere, so it is not brought back.
    for (MEGANode *node in candidates) {
        if ([node mnz_isDeletedFromParentNode:parentNode]) {
            return node;
        }
    }

    return candidates.firstObject;
}

- (void)finishUploadForFingerprintMatchedNode:(MEGANode *)node {
    if ([node mnz_isDeletedFromParentNode:self.uploadInfo.parentNode]) {
        MEGALogInfo(@"[Camera Upload] %@ skips the upload as matching node %@ was deleted from the camera uploads folder", self, node.base64Handle);
        [self finishOperationWithStatus:CameraAssetUploadStatusDone];
        return;
    }

    NSError *error;
    NSString *localFileName = [self mnz_generateLocalFileNamewithExtension:node.name.pathExtension error:&error];
    if (error) {
        MEGALogError(@"[Camera Upload] %@ error when to generate local unique file name %@", self, error);
        [[FIRCrashlytics crashlytics] recordError:error];
        [self finishOperationWithStatus:CameraAssetUploadStatusFailed];
        return;
    }
    
    [self copyToParentNodeIfNeededForMatchingNode:node localFileName:localFileName];
}

#pragma mark - disk space

- (void)finishUploadWithNoEnoughDiskSpace {
    [CameraUploadTelemetry.shared filePutAside:CameraUploadPutAsideReasonDiskFull];
    if (self.uploadInfo.asset.mediaType == PHAssetMediaTypeVideo) {
        [NSNotificationCenter.defaultCenter postNotificationName:MEGACameraUploadVideoUploadLocalDiskFullNotification object:nil];
    } else {
        [NSNotificationCenter.defaultCenter postNotificationName:MEGACameraUploadPhotoUploadLocalDiskFullNotification object:nil];
    }
    
    [self finishOperationWithStatus:CameraAssetUploadStatusCancelled];
}

#pragma mark - error handings

- (void)handleAssetDownloadError:(NSError *)error {
    if ([error.domain isEqualToString:AVFoundationErrorDomain] && error.code == AVErrorDiskFull) {
        [self finishUploadWithNoEnoughDiskSpace];
    } else if ([error.domain isEqualToString:NSCocoaErrorDomain] && error.code == NSFileWriteOutOfSpaceError) {
        [self finishUploadWithNoEnoughDiskSpace];
    } else if (!MEGAReachabilityManager.isReachable) {
        [CameraUploadTelemetry.shared filePutAside:CameraUploadPutAsideReasonOffline];
        [self finishOperationWithStatus:CameraAssetUploadStatusNotReady];
    } else if (NSFileManager.defaultManager.mnz_fileSystemFreeSize < MEGACameraUploadLowDiskStorageSizeInBytes) {
        [self finishUploadWithNoEnoughDiskSpace];
    } else {
        [self finishOperationWithStatus:CameraAssetUploadStatusFailed error:error];
    }
}

- (void)handleMEGARequestError:(MEGAError *)error {
    if (error.type == MEGAErrorTypeApiEOverQuota || error.type == MEGAErrorTypeApiEgoingOverquota) {
        [CameraUploadTelemetry.shared filePutAside:CameraUploadPutAsideReasonOverQuota];
        [NSNotificationCenter.defaultCenter postNotificationName:MEGAStorageOverQuotaNotification object:self];
        [self finishOperationWithStatus:CameraAssetUploadStatusCancelled];
    } else {
        [self finishOperationWithStatus:CameraAssetUploadStatusFailed error:error.nativeError];
    }
}

#pragma mark - generate local file name

- (nullable NSString *)mnz_generateLocalFileNamewithExtension:(NSString *)extension error:(NSError * __autoreleasing _Nullable *)error {
    // Intentional fallback: when creationDate is nil we use modificationDate or now.
    // LocalFileNameGenerator dedupes collisions by suffixing "_N", so reused dates do not produce duplicate file names.
    NSDate *nameDate = self.uploadInfo.asset.creationDate
        ?: self.uploadInfo.asset.modificationDate
        ?: [NSDate date];
    NSString *originalFileName = [nameDate mnz_formattedDefaultNameForMedia];
    
    if ([self isKindOfClass:[LivePhotoUploadOperation class]]) {
        originalFileName = [originalFileName stringByAppendingPathExtension:CameraUploadLivePhotoExtension];
    } else if (self.uploadInfo.asset.burstIdentifier.length > 0) {
        originalFileName = [originalFileName stringByAppendingPathExtension:CameraUploadBurstPhotoExtension];
    }
    
    originalFileName = [originalFileName stringByAppendingPathExtension:extension];
    
    if (originalFileName == nil) {
        if (error != NULL) {
            *error = [NSError mnz_cameraUploadEmptyFileNameError];
        }
        
        return nil;
    }

    NSString *localFileName = [CameraUploadRecordManager.shared.fileNameCoordinator generateUniqueLocalFileNameForUploadRecord:self.uploadRecord withOriginalFileName:originalFileName];
    if (localFileName == nil && error != NULL) {
        *error = [NSError mnz_cameraUploadEmptyFileNameError];
    }

    return localFileName;
}

@end
