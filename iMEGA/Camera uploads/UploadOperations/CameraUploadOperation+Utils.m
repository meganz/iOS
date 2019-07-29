
#import "CameraUploadOperation+Utils.h"
#import "CameraUploadRecordManager.h"
#import "NSString+MNZCategory.h"
#import "MEGAConstants.h"
#import "MEGAReachabilityManager.h"
#import "NSFileManager+MNZCategory.h"
#import "NSDate+MNZCategory.h"
#import "LivePhotoUploadOperation.h"
#import "CameraUploadRequestDelegate.h"
#import "MEGAError+MNZCategory.h"

static NSString * const CameraUploadLivePhotoExtension = @"live";
static NSString * const CameraUploadBurstPhotoExtension = @"burst";

@implementation CameraUploadOperation (Utils)

#pragma mark - handle fingerprint

- (void)copyToParentNodeIfNeededForMatchingNode:(MEGANode *)node localFileName:(NSString *)fileName {
    if (node.parentHandle != self.uploadInfo.parentNode.handle) {
        NSString *uniqueFileName = [fileName mnz_sequentialFileNameInParentNode:self.uploadInfo.parentNode];
        [MEGASdkManager.sharedMEGASdk copyNode:node newParent:self.uploadInfo.parentNode newName:uniqueFileName delegate:[[CameraUploadRequestDelegate alloc] initWithCompletion:^(MEGARequest * _Nonnull request, MEGAError * _Nonnull error) {
            if (self.isCancelled) {
                [self finishOperationWithStatus:CameraAssetUploadStatusCancelled shouldUploadNextAsset:NO];
                return;
            }
            
            if (error.type) {
                MEGALogError(@"[Camera Upload] %@ error when to copy node %@", self, error.nativeError);
                [self handleMEGARequestError:error];
            } else {
                [self finishOperationWithStatus:CameraAssetUploadStatusDone shouldUploadNextAsset:YES];
            }
        }]];
    } else {
        [self finishOperationWithStatus:CameraAssetUploadStatusDone shouldUploadNextAsset:YES];
    }
}

- (MEGANode *)nodeForOriginalFingerprint:(NSString *)fingerprint {
    MEGANode *matchingNode = [MEGASdkManager.sharedMEGASdk nodeForFingerprint:fingerprint parent:self.uploadInfo.parentNode];
    if (matchingNode == nil) {
        MEGANodeList *nodeList = [MEGASdkManager.sharedMEGASdk nodesForOriginalFingerprint:fingerprint];
        if (nodeList.size.integerValue > 0) {
            matchingNode = [self firstNodeInNodeList:nodeList hasParentNode:self.uploadInfo.parentNode];
            if (matchingNode == nil) {
                matchingNode = [nodeList nodeAtIndex:0];
            }
        }
    }
    
    return matchingNode;
}

- (MEGANode *)firstNodeInNodeList:(MEGANodeList *)nodeList hasParentNode:(MEGANode *)parent {
    for (NSInteger i = 0; i < nodeList.size.integerValue; i++) {
        MEGANode *node = [nodeList nodeAtIndex:i];
        if (node.parentHandle == parent.handle) {
            return node;
        }
    }
    
    return nil;
}

- (void)finishUploadForFingerprintMatchedNode:(MEGANode *)node {
    NSString *localFileName = [self mnz_generateLocalFileNamewithExtension:node.name.pathExtension];
    [self copyToParentNodeIfNeededForMatchingNode:node localFileName:localFileName];
}

#pragma mark - disk space

- (void)finishUploadWithNoEnoughDiskSpace {
    if (self.uploadInfo.asset.mediaType == PHAssetMediaTypeVideo) {
        [NSNotificationCenter.defaultCenter postNotificationName:MEGACameraUploadVideoUploadLocalDiskFullNotification object:nil];
    } else {
        [NSNotificationCenter.defaultCenter postNotificationName:MEGACameraUploadPhotoUploadLocalDiskFullNotification object:nil];
    }
    
    [self finishOperationWithStatus:CameraAssetUploadStatusCancelled shouldUploadNextAsset:NO];
}

#pragma mark - error handings

- (void)handleCloudDownloadError:(NSError *)error {
    if ([error.domain isEqualToString:AVFoundationErrorDomain] && error.code == AVErrorDiskFull) {
        [self finishUploadWithNoEnoughDiskSpace];
    } else if ([error.domain isEqualToString:NSCocoaErrorDomain] && error.code == NSFileWriteOutOfSpaceError) {
        [self finishUploadWithNoEnoughDiskSpace];
    } else if (!MEGAReachabilityManager.isReachable) {
        [self finishOperationWithStatus:CameraAssetUploadStatusNotReady shouldUploadNextAsset:YES];
    } else if (NSFileManager.defaultManager.mnz_fileSystemFreeSize < MEGACameraUploadLowDiskStorageSizeInBytes) {
        [self finishUploadWithNoEnoughDiskSpace];
    } else {
        [self finishOperationWithStatus:CameraAssetUploadStatusFailed shouldUploadNextAsset:YES];
    }
}

- (void)handleMEGARequestError:(MEGAError *)error {
    if (error.type == MEGAErrorTypeApiEOverQuota || error.type == MEGAErrorTypeApiEgoingOverquota) {
        [NSNotificationCenter.defaultCenter postNotificationName:MEGAStorageOverQuotaNotification object:self];
        [self finishOperationWithStatus:CameraAssetUploadStatusCancelled shouldUploadNextAsset:NO];
    } else {
        [self finishOperationWithStatus:CameraAssetUploadStatusFailed shouldUploadNextAsset:YES];
    }
}

#pragma mark - generate local file name

- (NSString *)mnz_generateLocalFileNamewithExtension:(NSString *)extension {
    NSString *originalFileName = [self.uploadInfo.asset.creationDate mnz_formattedDefaultNameForMedia];
    
    if ([self isKindOfClass:[LivePhotoUploadOperation class]]) {
        originalFileName = [originalFileName stringByAppendingPathExtension:CameraUploadLivePhotoExtension];
    } else if (self.uploadInfo.asset.burstIdentifier.length > 0) {
        originalFileName = [originalFileName stringByAppendingPathExtension:CameraUploadBurstPhotoExtension];
    }
    
    originalFileName = [originalFileName stringByAppendingPathExtension:extension];
    
    return [CameraUploadRecordManager.shared.fileNameCoordinator generateUniqueLocalFileNameForUploadRecord:self.uploadRecord withOriginalFileName:originalFileName];
}

@end
