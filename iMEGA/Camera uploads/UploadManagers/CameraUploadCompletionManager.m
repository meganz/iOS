
#import "CameraUploadCompletionManager.h"
#import "UploadCompletionOperation.h"
#import "AttributeUploadManager.h"
#import "MEGAConstants.h"
#import "NSURL+CameraUpload.h"
#import "CameraUploadManager.h"
#import "NodesFetchListenerOperation.h"
#import "CameraUploadManager+Settings.h"

@interface CameraUploadCompletionManager ()

@property (strong, nonatomic) NSOperationQueue *operationQueue;

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
        _operationQueue.qualityOfService = NSQualityOfServiceUserInitiated;
    }
    return self;
}

- (void)waitUnitlAllUploadsAreFinished {
    [self.operationQueue waitUntilAllOperationsAreFinished];
    [AttributeUploadManager.shared waitUnitlAllAttributeUploadsAreFinished];
}

- (void)handleCompletedTransferWithLocalIdentifier:(NSString *)localIdentifier token:(NSData *)token {
    if (!CameraUploadManager.isCameraUploadEnabled) {
        return;
    }
    
    if (!CameraUploadManager.shared.isNodesFetchDone) {
        NodesFetchListenerOperation *nodesFetchListenerOperation = [[NodesFetchListenerOperation alloc] init];
        [nodesFetchListenerOperation start];
        [nodesFetchListenerOperation waitUntilFinished];
        MEGALogDebug(@"[Camera Upload] waiting for nodes fetching");
    }
    
    MEGALogDebug(@"[Camera Upload] Start putting nodes as nodes fetch is done");
    
    NSURL *archivedURL = [NSURL mnz_archivedURLForLocalIdentifier:localIdentifier];
    BOOL isDirectory;
    if ([NSFileManager.defaultManager fileExistsAtPath:archivedURL.path isDirectory:&isDirectory] && !isDirectory) {
        AssetUploadInfo *uploadInfo = [NSKeyedUnarchiver unarchiveObjectWithFile:archivedURL.path];
        if (uploadInfo) {
            [self showUploadedNodeWithUploadInfo:uploadInfo localIdentifier:localIdentifier transferToken:token];
        } else {
            MEGALogError(@"[Camera Upload] error when to unarchive upload info for asset: %@", localIdentifier);
            [self finishUploadForLocalIdentifier:localIdentifier status:CameraAssetUploadStatusFailed];
        }
    } else {
        MEGALogError(@"[Camera Upload] session task completes without any archived upload info: %@", localIdentifier);
        [self finishUploadForLocalIdentifier:localIdentifier status:CameraAssetUploadStatusFailed];
    }
}

- (void)showUploadedNodeWithUploadInfo:(AssetUploadInfo *)uploadInfo localIdentifier:(NSString *)localIdentifier transferToken:(NSData *)token {
    UploadCompletionOperation *operation = [[UploadCompletionOperation alloc] initWithUploadInfo:uploadInfo transferToken:token completion:^(MEGANode * _Nullable node, NSError * _Nullable error) {
        if (error) {
            MEGALogDebug(@"[Camera Upload] error when to complete transfer %@", error);
            if (error.code == MEGAErrorTypeApiEOverQuota || error.code == MEGAErrorTypeApiEgoingOverquota) {
                [NSNotificationCenter.defaultCenter postNotificationName:MEGAStorageOverQuotaNotificationName object:self];
                [self finishUploadForLocalIdentifier:localIdentifier status:CameraAssetUploadStatusCancelled];
            } else {
                [self finishUploadForLocalIdentifier:localIdentifier status:CameraAssetUploadStatusFailed];
            }
        } else {
            MEGALogDebug(@"[Camera Upload] put node succeeded!");
            [AttributeUploadManager.shared uploadCoordinateAtLocation:uploadInfo.location forNode:node];
            [AttributeUploadManager.shared uploadFileAtURL:uploadInfo.thumbnailURL withAttributeType:MEGAAttributeTypeThumbnail forNode:node];
            [AttributeUploadManager.shared uploadFileAtURL:uploadInfo.previewURL withAttributeType:MEGAAttributeTypePreview forNode:node];
            [self finishUploadForLocalIdentifier:localIdentifier status:CameraAssetUploadStatusDone];
        }
    }];
    
    [self.operationQueue addOperation:operation];
}

- (void)finishUploadForLocalIdentifier:(NSString *)localIdentifier status:(CameraAssetUploadStatus)status {
    if (localIdentifier.length == 0) {
        return;
    }
    
    [CameraUploadRecordManager.shared updateUploadRecordByLocalIdentifier:localIdentifier withStatus:status error:nil];
    NSURL *uploadDirectory = [NSURL mnz_assetDirectoryURLForLocalIdentifier:localIdentifier];
    [NSFileManager.defaultManager removeItemAtURL:uploadDirectory error:nil];
    MEGALogDebug(@"[Camera Upload] Background Upload finishes with session task %@ and status: %@", localIdentifier, [AssetUploadStatus stringForStatus:status]);
    
    if (status == CameraAssetUploadStatusDone) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [NSNotificationCenter.defaultCenter postNotificationName:MEGACameraUploadAssetUploadDoneNotificationName object:nil];
        });
    }
}

@end
