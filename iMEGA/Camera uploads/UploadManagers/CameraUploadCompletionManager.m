
#import "CameraUploadCompletionManager.h"
#import "UploadCompletionOperation.h"
#import "AttributeUploadManager.h"
#import "MEGAConstants.h"
#import "NSURL+CameraUpload.h"

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
    }
    return self;
}

- (void)waitUnitlAllUploadsAreCompleted {
    [self.operationQueue waitUntilAllOperationsAreFinished];
    [AttributeUploadManager.shared waitUnitlAllAttributeUploadsAreFinished];
}

- (void)handleCompletedTransferWithLocalIdentifier:(NSString *)localIdentifier token:(NSData *)token {
    NSURL *archivedURL = [NSURL mnz_archivedURLForLocalIdentifier:localIdentifier];
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
    UploadCompletionOperation *operation = [[UploadCompletionOperation alloc] initWithUploadInfo:uploadInfo transferToken:token completion:^(MEGANode * _Nullable node, NSError * _Nullable error) {
        if (error) {
            MEGALogDebug(@"[Camera Upload] error when to complete transfer %@", error);
            [self finishUploadForLocalIdentifier:localIdentifier status:CameraAssetUploadStatusFailed];
        } else {
            MEGALogDebug(@"[Camera Upload] upload succeeded!");
            [AttributeUploadManager.shared uploadCoordinateAtLocation:uploadInfo.location forNode:node];
            [AttributeUploadManager.shared uploadFileAtURL:uploadInfo.thumbnailURL withAttributeType:MEGAAttributeTypeThumbnail forNode:node];
            [AttributeUploadManager.shared uploadFileAtURL:uploadInfo.previewURL withAttributeType:MEGAAttributeTypePreview forNode:node];
            [self finishUploadForLocalIdentifier:localIdentifier status:CameraAssetUploadStatusDone];
        }
    }];
    
    [self.operationQueue addOperation:operation];
}

- (void)finishUploadForLocalIdentifier:(NSString *)localIdentifier status:(NSString *)status {
    if (localIdentifier.length == 0) {
        return;
    }
    
    [CameraUploadRecordManager.shared updateRecordOfLocalIdentifier:localIdentifier withStatus:status error:nil];
    NSURL *uploadDirectory = [NSURL mnz_assetDirectoryURLForLocalIdentifier:localIdentifier];
    [NSFileManager.defaultManager removeItemAtURL:uploadDirectory error:nil];
    MEGALogDebug(@"[Camera Upload] Background Upload finishes with session task %@ and status: %@", localIdentifier, status);
    
    if ([status isEqualToString:CameraAssetUploadStatusDone]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [NSNotificationCenter.defaultCenter postNotificationName:MEGACameraUploadAssetUploadDoneNotificationName object:nil];
        });
    }
}

@end
