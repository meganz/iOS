
#import "CameraUploadCoordinator.h"
#import "CompleteUploadOperation.h"
#import "AttributeUploadManager.h"
#import "MEGAConstants.h"
#import "NSURL+CameraUpload.h"

@implementation CameraUploadCoordinator

- (void)handleCompletedTransferWithLocalIdentifier:(NSString *)localIdentifier token:(NSData *)token {
    NSURL *archivedURL = [NSURL archivedURLForLocalIdentifier:localIdentifier];
    BOOL isDirectory;
    if ([NSFileManager.defaultManager fileExistsAtPath:archivedURL.path isDirectory:&isDirectory] && !isDirectory) {
        AssetUploadInfo *uploadInfo = [NSKeyedUnarchiver unarchiveObjectWithFile:archivedURL.path];
        if (uploadInfo) {
            MEGALogDebug(@"[Camera Upload] Resumed upload info from serialized data for asset: %@", uploadInfo);
            [self showUploadedNodeWithUploadInfo:uploadInfo localIdentifier:localIdentifier transferToken:token];
        } else {
            MEGALogError(@"[Camera Upload] Error when to unarchive upload info for asset: %@", localIdentifier);
            [self finishUploadForLocalIdentifier:localIdentifier status:CameraAssetUploadStatusFailed];
        }
    } else {
        MEGALogError(@"[Camera Upload] Session task completes without any handler: %@", localIdentifier);
        [self finishUploadForLocalIdentifier:localIdentifier status:CameraAssetUploadStatusFailed];
    }
}

- (void)showUploadedNodeWithUploadInfo:(AssetUploadInfo *)uploadInfo localIdentifier:(NSString *)localIdentifier transferToken:(NSData *)token {
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    CompleteUploadOperation *operation = [[CompleteUploadOperation alloc] initWithUploadInfo:uploadInfo transferToken:token completion:^(MEGANode * _Nullable node, NSError * _Nullable error) {
        if (error) {
            MEGALogDebug(@"[Camera Upload] error when to complete transfer %@", error);
            [self finishUploadForLocalIdentifier:localIdentifier status:CameraAssetUploadStatusFailed];
        } else {
            [AttributeUploadManager.shared uploadFileAtURL:uploadInfo.thumbnailURL withAttributeType:MEGAAttributeTypeThumbnail forNode:node];
            [AttributeUploadManager.shared uploadFileAtURL:uploadInfo.previewURL withAttributeType:MEGAAttributeTypePreview forNode:node];
            [AttributeUploadManager.shared uploadCoordinateAtLocation:uploadInfo.location forNode:node];
            [self finishUploadForLocalIdentifier:localIdentifier status:CameraAssetUploadStatusDone];
        }
    }];
    
    [queue addOperation:operation];
    [queue waitUntilAllOperationsAreFinished];
}

- (void)finishUploadForLocalIdentifier:(NSString *)localIdentifier status:(NSString *)status {
    if (localIdentifier.length == 0) {
        return;
    }
    
    [CameraUploadRecordManager.shared updateRecordOfLocalIdentifier:localIdentifier withStatus:status error:nil];
    NSURL *uploadDirectory = [NSURL assetDirectoryURLForLocalIdentifier:localIdentifier];
    [NSFileManager.defaultManager removeItemAtURL:uploadDirectory error:nil];
    MEGALogDebug(@"[Camera Upload] Background Upload finishes with session task %@ and status: %@", localIdentifier, status);
    
    if ([status isEqualToString:CameraAssetUploadStatusDone]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [NSNotificationCenter.defaultCenter postNotificationName:MEGACameraUploadAssetUploadDoneNotificationName object:nil];
        });
    }
}

@end
