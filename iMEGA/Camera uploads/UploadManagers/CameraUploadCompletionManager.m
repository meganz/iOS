
#import "CameraUploadCompletionManager.h"
#import "PutNodeOperation.h"
#import "AttributeUploadManager.h"
#import "NSURL+CameraUpload.h"
#import "NodesFetchListenerOperation.h"
#import "CameraUploadManager+Settings.h"
#import "NSFileManager+MNZCategory.h"
#import "NSString+MNZCategory.h"
#import "CameraUploadRequestDelegate.h"
#import "MEGAError+MNZCategory.h"
#import "MEGA-Swift.h"

@interface CameraUploadCompletionManager ()

@property (strong, nonatomic) NSOperationQueue *putNodeQueue;

@end

@implementation CameraUploadCompletionManager

+ (instancetype)shared {
    static id sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _putNodeQueue = [[NSOperationQueue alloc] init];
        _putNodeQueue.name = @"putNodeQueue";
        _putNodeQueue.qualityOfService = NSQualityOfServiceUserInteractive;
    }
    return self;
}

#pragma mark - handle transfer completion data

- (void)handleChunkUploadTask:(NSURLSessionTask *)task {
    NSURL *archivedURL = [NSURL mnz_archivedUploadInfoURLForLocalIdentifier:task.taskDescription];
    NSError *error;
    AssetUploadInfo *uploadInfo = [NSKeyedUnarchiver unarchivedObjectOfClass:AssetUploadInfo.class fromData:[NSData dataWithContentsOfURL:archivedURL] error:&error];
    if (error) {
        MEGALogError(@"[Camera Upload] failed to unarchive data with error: %@", error);
        [self finishUploadForLocalIdentifier:uploadInfo.savedLocalIdentifier status:CameraAssetUploadStatusFailed];
    } else if (uploadInfo.encryptedChunksCount == 1) {
        MEGALogError(@"[Camera Upload] chunk task for single file %@, fileSize: %llu, response %@", task.taskDescription, uploadInfo.fileSize, task.response);
        [self finishUploadForLocalIdentifier:uploadInfo.savedLocalIdentifier status:CameraAssetUploadStatusFailed];
    }
}

- (void)handleCompletedTransferWithLocalIdentifier:(NSString *)localIdentifier token:(NSData *)token {
    if (!CameraUploadManager.isCameraUploadEnabled) {
        return;
    }
    
    if (!CameraUploadManager.shared.isNodeTreeCurrent) {
        NodesFetchListenerOperation *nodesFetchListenerOperation = [[NodesFetchListenerOperation alloc] init];
        [nodesFetchListenerOperation start];
        [nodesFetchListenerOperation waitUntilFinished];
        MEGALogDebug(@"[Camera Upload] %@ waiting for nodes fetching", localIdentifier);
    }
    
    MEGALogDebug(@"[Camera Upload] %@ starts putting nodes as nodes fetch is done", localIdentifier);
    
    NSURL *archivedURL = [NSURL mnz_archivedUploadInfoURLForLocalIdentifier:localIdentifier];
    BOOL isDirectory;
    if ([NSFileManager.defaultManager fileExistsAtPath:archivedURL.path isDirectory:&isDirectory] && !isDirectory) {
        NSError *error;
        AssetUploadInfo *uploadInfo = [NSKeyedUnarchiver unarchivedObjectOfClass:AssetUploadInfo.class fromData:[NSData dataWithContentsOfURL:archivedURL] error:&error];
        if (uploadInfo.mediaUpload) {
            [CameraUploadNodeAccess.shared loadNodeWithCompletion:^(MEGANode * _Nullable cameraUploadNode, NSError * _Nullable error) {
                if (error || cameraUploadNode == nil) {
                    MEGALogError(@"[Camera Upload] no camera upload node can be loaded for %@ %@", localIdentifier, error);
                    [self finishUploadForLocalIdentifier:localIdentifier status:CameraAssetUploadStatusFailed];
                } else {
                    MEGALogDebug(@"[Camera Upload] camera upload node loaded for %@", localIdentifier);
                    uploadInfo.parentNode = cameraUploadNode;
                    [self putNodeByUploadInfo:uploadInfo transferToken:token];
                }
            }];
        } else {
            MEGALogError(@"[Camera Upload] error when to unarchive upload info for asset: %@, error %@", localIdentifier, error);
            [self finishUploadForLocalIdentifier:localIdentifier status:CameraAssetUploadStatusFailed];
        }
    } else {
        MEGALogError(@"[Camera Upload] no archived upload info file found for %@", localIdentifier);
        [self finishUploadForLocalIdentifier:localIdentifier status:CameraAssetUploadStatusFailed];
    }
}

#pragma mark - put node

- (void)putNodeByUploadInfo:(AssetUploadInfo *)uploadInfo transferToken:(NSData *)token {
    BOOL hasExistingPutNode = NO;
    for (PutNodeOperation *operation in self.putNodeQueue.operations) {
        if ([operation.uploadInfo.savedLocalIdentifier isEqualToString:uploadInfo.savedLocalIdentifier]) {
            hasExistingPutNode = YES;
            break;
        }
    }
    
    if (hasExistingPutNode) {
        MEGALogError(@"[Camera Upload] existing put node found for %@ with token %@", uploadInfo.savedLocalIdentifier, [[NSString alloc] initWithData:token encoding:NSUTF8StringEncoding]);
        return;
    }
    
    NSError *attributesError;
    AssetLocalAttribute *attributeInfo = [AttributeUploadManager.shared saveAttributesForUploadInfo:uploadInfo error:&attributesError];
    if (attributesError) {
        MEGALogError(@"[Camera Upload] error when to save attributes for %@ %@", uploadInfo.savedLocalIdentifier, attributesError);
        [self finishUploadForLocalIdentifier:uploadInfo.savedLocalIdentifier status:CameraAssetUploadStatusFailed];
        return;
    }
    
    MEGANode *existingNode = [MEGASdkManager.sharedMEGASdk nodeForFingerprint:uploadInfo.fingerprint parent:uploadInfo.parentNode];
    if (existingNode) {
        MEGALogInfo(@"[Camera Upload] existing node %@ found for %@ by fingerprint match", existingNode.name, uploadInfo.savedLocalIdentifier);
        [self copyToParentNodeIfNeededForMatchingNode:existingNode uploadInfo:uploadInfo];
        return;
    }
    
    [self.putNodeQueue addOperation:[[PutNodeOperation alloc] initWithUploadInfo:uploadInfo transferToken:token completion:^(MEGANode * _Nullable node, NSError * _Nullable error) {
        if (error) {
            MEGALogError(@"[Camera Upload] error when to complete transfer %@ with token %@ %@", uploadInfo.savedLocalIdentifier, [[NSString alloc] initWithData:token encoding:NSUTF8StringEncoding], error);
            if (error.code == MEGAErrorTypeApiEOverQuota || error.code == MEGAErrorTypeApiEgoingOverquota) {
                [NSNotificationCenter.defaultCenter postNotificationName:MEGAStorageOverQuotaNotification object:self];
                [self finishUploadForLocalIdentifier:uploadInfo.savedLocalIdentifier status:CameraAssetUploadStatusCancelled];
            } else {
                [self finishUploadForLocalIdentifier:uploadInfo.savedLocalIdentifier status:CameraAssetUploadStatusFailed];
            }
        } else {
            MEGALogDebug(@"[Camera Upload] put node %@ succeeded for %@", node.name, uploadInfo.savedLocalIdentifier);
            [AttributeUploadManager.shared uploadLocalAttribute:attributeInfo forNode:node];
            [self finishUploadForLocalIdentifier:uploadInfo.savedLocalIdentifier status:CameraAssetUploadStatusDone];
            [NSNotificationCenter.defaultCenter postNotificationName:MEGACameraUploadNodeUploadCompleteNotification object:nil userInfo:@{MEGANodeHandleKey : @(node.handle)}];
        }
    }]];
    
    MEGALogDebug(@"[Camera Upload] put node added for %@, total put node count %lu", uploadInfo.savedLocalIdentifier, (unsigned long)self.putNodeQueue.operationCount);
}

- (void)copyToParentNodeIfNeededForMatchingNode:(MEGANode *)node uploadInfo:(AssetUploadInfo *)uploadInfo {
    if (node.parentHandle != uploadInfo.parentNode.handle) {
        NSString *uniqueName = [uploadInfo.fileName mnz_sequentialFileNameInParentNode:uploadInfo.parentNode];
        [MEGASdkManager.sharedMEGASdk copyNode:node newParent:uploadInfo.parentNode newName:uniqueName delegate:[[CameraUploadRequestDelegate alloc] initWithCompletion:^(MEGARequest * _Nonnull request, MEGAError * _Nonnull error) {
            if (error.type) {
                MEGALogError(@"[Camera Upload] %@ error when to copy node %@", self, error.nativeError);
                if (error.type == MEGAErrorTypeApiEOverQuota || error.type == MEGAErrorTypeApiEgoingOverquota) {
                    [NSNotificationCenter.defaultCenter postNotificationName:MEGAStorageOverQuotaNotification object:self];
                }
                [self finishUploadForLocalIdentifier:uploadInfo.savedLocalIdentifier status:CameraAssetUploadStatusFailed];
            } else {
                [self finishUploadForLocalIdentifier:uploadInfo.savedLocalIdentifier status:CameraAssetUploadStatusDone];
                [NSNotificationCenter.defaultCenter postNotificationName:MEGACameraUploadNodeUploadCompleteNotification object:nil userInfo:@{MEGANodeHandleKey : @(node.handle)}];
            }
        }]];
    } else {
        [self finishUploadForLocalIdentifier:uploadInfo.savedLocalIdentifier status:CameraAssetUploadStatusDone];
        [NSNotificationCenter.defaultCenter postNotificationName:MEGACameraUploadNodeUploadCompleteNotification object:nil userInfo:@{MEGANodeHandleKey : @(node.handle)}];
    }
}

#pragma mark - update status

- (void)finishUploadForLocalIdentifier:(NSString *)localIdentifier status:(CameraAssetUploadStatus)status {
    if (!CameraUploadManager.isCameraUploadEnabled) {
        return;
    }
    
    [CameraUploadRecordManager.shared.backgroundContext performBlockAndWait:^{
        MEGALogDebug(@"[Camera Upload] background Upload finishes with session task %@ and status: %@", localIdentifier, [AssetUploadStatus stringForStatus:status]);
        if (localIdentifier.length == 0) {
            return;
        }
        
        if (!CameraUploadManager.isCameraUploadEnabled) {
            return;
        }
        
        MOAssetUploadRecord *record = [[CameraUploadRecordManager.shared fetchUploadRecordsByIdentifier:localIdentifier shouldPrefetchErrorRecords:YES error:nil] firstObject];
        if (record.status.integerValue != CameraAssetUploadStatusUploading || record == nil) {
            MEGALogDebug(@"[Camera Upload] %@ record status: %@ is not uploading", localIdentifier, [AssetUploadStatus stringForStatus:record.status.integerValue]);
            return;
        }
        
        [CameraUploadRecordManager.shared updateUploadRecord:record withStatus:status error:nil];
        
        [NSFileManager.defaultManager mnz_removeItemAtPath:[NSURL mnz_assetURLForLocalIdentifier:localIdentifier].path];
        
        [CameraUploadRecordManager.shared refaultObject:record];
        
        if (status == CameraAssetUploadStatusDone) {
            [NSNotificationCenter.defaultCenter postNotificationName:MEGACameraUploadStatsChangedNotification object:nil];
        }
    }];
}

@end
