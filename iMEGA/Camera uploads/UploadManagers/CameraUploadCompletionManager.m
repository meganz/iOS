
#import "CameraUploadCompletionManager.h"
#import "PutNodeOperation.h"
#import "AttributeUploadManager.h"
#import "MEGAConstants.h"
#import "NSURL+CameraUpload.h"
#import "CameraUploadManager.h"
#import "NodesFetchListenerOperation.h"
#import "CameraUploadManager+Settings.h"
#import "NSFileManager+MNZCategory.h"
#import "CameraUploadNodeLoader.h"
#import "NSString+MNZCategory.h"

@interface CameraUploadCompletionManager ()

@property (strong, nonatomic) NSOperationQueue *operationQueue;
@property (strong, nonatomic) CameraUploadNodeLoader *cameraUploadNodeLoader;

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
        _operationQueue = [[NSOperationQueue alloc] init];
        _operationQueue.qualityOfService = NSQualityOfServiceUserInteractive;
    }
    return self;
}

- (CameraUploadNodeLoader *)cameraUploadNodeLoader {
    if (_cameraUploadNodeLoader == nil) {
        _cameraUploadNodeLoader = [[CameraUploadNodeLoader alloc] init];
    }
    
    return _cameraUploadNodeLoader;
}

- (void)waitUnitlAllUploadsAreFinished {
    [self.operationQueue waitUntilAllOperationsAreFinished];
}

#pragma mark - handle transfer completion data

- (void)handleEmptyTransferTokenInSessionTask:(NSURLSessionTask *)task {
    NSURL *archivedURL = [NSURL mnz_archivedURLForLocalIdentifier:task.taskDescription];
    AssetUploadInfo *uploadInfo = [NSKeyedUnarchiver unarchiveObjectWithFile:archivedURL.path];
    if (uploadInfo.encryptedChunksCount == 1) {
        MEGALogError(@"[Camera Upload] empty transfer token for single chunk %@, fileSize: %llu, response %@", task.taskDescription, uploadInfo.fileSize, task.response);
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
    
    NSURL *archivedURL = [NSURL mnz_archivedURLForLocalIdentifier:localIdentifier];
    BOOL isDirectory;
    if ([NSFileManager.defaultManager fileExistsAtPath:archivedURL.path isDirectory:&isDirectory] && !isDirectory) {
        AssetUploadInfo *uploadInfo = [NSKeyedUnarchiver unarchiveObjectWithFile:archivedURL.path];
        if (uploadInfo) {
            if (uploadInfo.parentNode == nil) {
                [self.cameraUploadNodeLoader loadCameraUploadNodeWithCompletion:^(MEGANode * _Nullable cameraUploadNode) {
                    if (cameraUploadNode == nil) {
                        MEGALogError(@"[Camera Upload] no camera upload node can be loaded for %@", localIdentifier);
                        [self finishUploadForLocalIdentifier:localIdentifier status:CameraAssetUploadStatusFailed];
                    } else {
                        MEGALogDebug(@"[Camera Upload] camera upload node loaded for %@", localIdentifier);
                        uploadInfo.parentNode = cameraUploadNode;
                        [self putNodeByUploadInfo:uploadInfo transferToken:token];
                    }
                }];
            } else {
                [self putNodeByUploadInfo:uploadInfo transferToken:token];
            }
        } else {
            MEGALogError(@"[Camera Upload] error when to unarchive upload info for asset: %@", localIdentifier);
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
    for (PutNodeOperation *operation in self.operationQueue.operations) {
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
        if (existingNode.parentHandle != uploadInfo.parentNode.handle) {
            NSString *uniqueName = [uploadInfo.fileName mnz_sequentialFileNameInParentNode:uploadInfo.parentNode];
            [MEGASdkManager.sharedMEGASdk copyNode:existingNode newParent:uploadInfo.parentNode newName:uniqueName];
            MEGALogDebug(@"[Camera Upload] copied existing node %@ with new name %@ for %@", existingNode.name, uniqueName, uploadInfo.savedLocalIdentifier);
        }

        [self finishUploadForLocalIdentifier:uploadInfo.savedLocalIdentifier status:CameraAssetUploadStatusDone];
        return;
    }
    
    [self.operationQueue addOperation:[[PutNodeOperation alloc] initWithUploadInfo:uploadInfo transferToken:token completion:^(MEGANode * _Nullable node, NSError * _Nullable error) {
        if (error) {
            MEGALogError(@"[Camera Upload] error when to complete transfer %@ with token %@ %@", uploadInfo.savedLocalIdentifier, [[NSString alloc] initWithData:token encoding:NSUTF8StringEncoding], error);
            if (error.code == MEGAErrorTypeApiEOverQuota || error.code == MEGAErrorTypeApiEgoingOverquota) {
                [NSNotificationCenter.defaultCenter postNotificationName:MEGAStorageOverQuotaNotificationName object:self];
                [self finishUploadForLocalIdentifier:uploadInfo.savedLocalIdentifier status:CameraAssetUploadStatusCancelled];
            } else {
                [self finishUploadForLocalIdentifier:uploadInfo.savedLocalIdentifier status:CameraAssetUploadStatusFailed];
            }
        } else {
            MEGALogDebug(@"[Camera Upload] put node %@ succeeded for %@", node.name, uploadInfo.savedLocalIdentifier);
            [AttributeUploadManager.shared uploadLocalAttribute:attributeInfo forNode:node];
            [self finishUploadForLocalIdentifier:uploadInfo.savedLocalIdentifier status:CameraAssetUploadStatusDone];
        }
    }]];
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
        
        [NSFileManager.defaultManager removeItemIfExistsAtURL:[NSURL mnz_assetDirectoryURLForLocalIdentifier:localIdentifier]];
        
        [CameraUploadRecordManager.shared refaultObject:record];
        
        if (status == CameraAssetUploadStatusDone) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [NSNotificationCenter.defaultCenter postNotificationName:MEGACameraUploadStatsChangedNotificationName object:nil];
            });
        }
    }];
}

@end
