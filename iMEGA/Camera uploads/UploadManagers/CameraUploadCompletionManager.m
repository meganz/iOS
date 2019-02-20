
#import "CameraUploadCompletionManager.h"
#import "UploadCompletionOperation.h"
#import "AttributeUploadManager.h"
#import "MEGAConstants.h"
#import "NSURL+CameraUpload.h"
#import "CameraUploadManager.h"
#import "NodesFetchListenerOperation.h"
#import "CameraUploadManager+Settings.h"
#import "NSFileManager+MNZCategory.h"

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
        _operationQueue.qualityOfService = NSQualityOfServiceUserInteractive;
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
            [self putNodeWithUploadInfo:uploadInfo localIdentifier:localIdentifier transferToken:token];
        } else {
            MEGALogError(@"[Camera Upload] error when to unarchive upload info for asset: %@", localIdentifier);
            [self finishUploadForLocalIdentifier:localIdentifier status:CameraAssetUploadStatusFailed];
        }
    } else {
        MEGALogError(@"[Camera Upload] session task completes without any archived upload info: %@", localIdentifier);
        [self finishUploadForLocalIdentifier:localIdentifier status:CameraAssetUploadStatusFailed];
    }
}

- (void)putNodeWithUploadInfo:(AssetUploadInfo *)uploadInfo localIdentifier:(NSString *)localIdentifier transferToken:(NSData *)token {
    UploadCompletionOperation *operation = [[UploadCompletionOperation alloc] initWithUploadInfo:uploadInfo transferToken:token completion:^(MEGANode * _Nullable node, NSError * _Nullable error) {
        if (error) {
            MEGALogError(@"[Camera Upload] error when to complete transfer %@ with token %@ %@", localIdentifier, [[NSString alloc] initWithData:token encoding:NSUTF8StringEncoding], error);
            if (error.code == MEGAErrorTypeApiEOverQuota || error.code == MEGAErrorTypeApiEgoingOverquota) {
                [NSNotificationCenter.defaultCenter postNotificationName:MEGAStorageOverQuotaNotificationName object:self];
                [self finishUploadForLocalIdentifier:localIdentifier status:CameraAssetUploadStatusCancelled];
            } else {
                [self finishUploadForLocalIdentifier:localIdentifier status:CameraAssetUploadStatusFailed];
            }
        } else {
            MEGALogDebug(@"[Camera Upload] put node succeeded!");
            [AttributeUploadManager.shared uploadCoordinateLocation:uploadInfo.location forNode:node];
            [AttributeUploadManager.shared uploadFile:uploadInfo.thumbnailURL withAttributeType:MEGAAttributeTypeThumbnail forNode:node];
            [AttributeUploadManager.shared uploadFile:uploadInfo.previewURL withAttributeType:MEGAAttributeTypePreview forNode:node];
            [self finishUploadForLocalIdentifier:localIdentifier status:CameraAssetUploadStatusDone];
        }
    }];
    
    [self.operationQueue addOperation:operation];
}

- (void)finishUploadForLocalIdentifier:(NSString *)localIdentifier status:(CameraAssetUploadStatus)status {
    MEGALogDebug(@"[Camera Upload] background Upload finishes with session task %@ and status: %@", localIdentifier, [AssetUploadStatus stringForStatus:status]);
    if (localIdentifier.length == 0) {
        return;
    }
    
    if ([self shouldUpdateStatus:status forLocalIdentifier:localIdentifier]) {
        [CameraUploadRecordManager.shared updateUploadRecordByLocalIdentifier:localIdentifier withStatus:status error:nil];
    }
    
    [NSFileManager.defaultManager removeItemIfExistsAtURL:[NSURL mnz_assetDirectoryURLForLocalIdentifier:localIdentifier]];
    
    if (status == CameraAssetUploadStatusDone) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [NSNotificationCenter.defaultCenter postNotificationName:MEGACameraUploadAssetUploadDoneNotificationName object:nil];
        });
    }
}

- (BOOL)shouldUpdateStatus:(CameraAssetUploadStatus)status forLocalIdentifier:(NSString *)localIdentifier {
    BOOL shouldUpdate = YES;
    
    NSURL *assetDirectory = [NSURL mnz_assetDirectoryURLForLocalIdentifier:localIdentifier];
    BOOL isDirectory;
    if (!([NSFileManager.defaultManager fileExistsAtPath:assetDirectory.path isDirectory:&isDirectory] && isDirectory)) {
        if (status == CameraAssetUploadStatusFailed && [CameraUploadRecordManager.shared uploadStatusForLocalIdentifier:localIdentifier] == CameraAssetUploadStatusFailed) {
            shouldUpdate = NO;
            MEGALogDebug(@"[Camera Upload] do not update record status as it was marked by another chunk background session task");
        }
    }
    
    return shouldUpdate;
}

@end
