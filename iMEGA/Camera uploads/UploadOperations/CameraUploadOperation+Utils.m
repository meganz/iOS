
#import "CameraUploadOperation+Utils.h"
#import "CameraUploadRecordManager.h"
#import "NSString+MNZCategory.h"
#import "MEGAConstants.h"
#import "MEGAReachabilityManager.h"
#import "NSFileManager+MNZCategory.h"
#import "NSDate+MNZCategory.h"
#import "LivePhotoUploadOperation.h"

static NSString * const CameraUploadLivePhotoExtension = @"live";
static NSString * const CameraUploadBurstPhotoExtension = @"burst";

@implementation CameraUploadOperation (Utils)

#pragma mark - handle fingerprint

- (void)copyToParentNodeIfNeededForMatchingNode:(MEGANode *)node localFileName:(NSString *)fileName {
    if (node.parentHandle != self.uploadInfo.parentNode.handle) {
        NSString *uniqueFileName = [fileName mnz_sequentialFileNameInParentNode:self.uploadInfo.parentNode];
        [MEGASdkManager.sharedMEGASdk copyNode:node newParent:self.uploadInfo.parentNode newName:uniqueFileName];
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
    NSString *localFileName = [self mnz_generateLocalFileNamewithExtension:node.name.pathExtension];
    [self copyToParentNodeIfNeededForMatchingNode:node localFileName:localFileName];
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
    if ([error.domain isEqualToString:AVFoundationErrorDomain] && error.code == AVErrorDiskFull) {
        [self finishUploadWithNoEnoughDiskSpace];
    } else if ([error.domain isEqualToString:NSCocoaErrorDomain] && error.code == NSFileWriteOutOfSpaceError) {
        [self finishUploadWithNoEnoughDiskSpace];
    } else if (!MEGAReachabilityManager.isReachable) {
        [self finishOperationWithStatus:CameraAssetUploadStatusNotReady shouldUploadNextAsset:YES];
    } else if (NSFileManager.defaultManager.deviceFreeSize < MEGACameraUploadLowDiskStorageSizeInBytes) {
        [self finishUploadWithNoEnoughDiskSpace];
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
