
#import "CameraUploadOperation+Utils.h"
#import "CameraUploadRecordManager.h"
#import "NSString+MNZCategory.h"
#import "MEGASdkManager.h"
#import "MEGAConstants.h"
#import "MEGAReachabilityManager.h"
#import "NSFileManager+MNZCategory.h"
#import "NSDate+MNZCategory.h"

static NSString * const CameraUploadLivePhotoExtension = @"live";

@implementation CameraUploadOperation (Utils)

#pragma mark - handle fingerprint

- (void)copyToParentNodeIfNeededForMatchingNode:(MEGANode *)node {
    if (node == nil) {
        return;
    }
    
    if (node.parentHandle != self.uploadInfo.parentNode.handle) {
        [[MEGASdkManager sharedMEGASdk] copyNode:node newParent:self.uploadInfo.parentNode];
    }
}

- (MEGANode *)nodeForOriginalFingerprint:(NSString *)fingerprint {
    MEGANode *matchingNode = [MEGASdkManager.sharedMEGASdk nodeForFingerprint:fingerprint];
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
    [self copyToParentNodeIfNeededForMatchingNode:node];
    [self finishOperationWithStatus:CameraAssetUploadStatusDone shouldUploadNextAsset:YES];
}

#pragma mark - disk space

- (void)finishUploadWithNoEnoughDiskSpace {
    if (self.uploadInfo.asset.mediaType == PHAssetMediaTypeVideo) {
        [NSNotificationCenter.defaultCenter postNotificationName:MEGACameraUploadVideoUploadLocalDiskFullNotificationName object:nil];
    } else {
        [NSNotificationCenter.defaultCenter postNotificationName:MEGACameraUploadPhotoUploadLocalDiskFullNotificationName object:nil];
    }
    
    [self finishOperationWithStatus:CameraAssetUploadStatusCancelled shouldUploadNextAsset:NO];
}

#pragma mark - icloud download error handing

- (void)handleCloudDownloadError:(NSError *)error {
    if (!MEGAReachabilityManager.isReachable) {
        [self finishOperationWithStatus:CameraAssetUploadStatusNotReady shouldUploadNextAsset:YES];
    } else if (NSFileManager.defaultManager.deviceFreeSize < MEGACameraUploadLowDiskStorageSizeInBytes) {
        [self finishUploadWithNoEnoughDiskSpace];
    } else {
        [self finishOperationWithStatus:CameraAssetUploadStatusFailed shouldUploadNextAsset:YES];
    }
}

#pragma mark - generate local file name

- (NSString *)mnz_generateLocalFileNamewithExtension:(NSString *)extension {
    NSString *originalFileName = [[self.uploadInfo.asset.creationDate mnz_formattedDefaultNameForMedia] stringByAppendingPathExtension:extension];
    return [CameraUploadRecordManager.shared.fileNameCoordinator generateUniqueLocalFileNameForUploadRecord:self.uploadRecord withOriginalFileName:originalFileName];
}

- (NSString *)mnz_generateLocalLivePhotoFileNameWithExtension:(NSString *)extension {
    NSString *originalFileName = [[[self.uploadInfo.asset.creationDate mnz_formattedDefaultNameForMedia] stringByAppendingPathExtension:CameraUploadLivePhotoExtension] stringByAppendingPathExtension:extension];
    return [CameraUploadRecordManager.shared.fileNameCoordinator generateUniqueLocalFileNameForUploadRecord:self.uploadRecord withOriginalFileName:originalFileName];
}

@end
