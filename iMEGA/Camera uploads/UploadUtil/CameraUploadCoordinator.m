
#import "CameraUploadCoordinator.h"
#import "CameraUploadRequestDelegate.h"
#import "ThumbnailUploadOperation.h"
#import "PreviewUploadOperation.h"
#import "NSString+MNZCategory.h"

@implementation CameraUploadCoordinator

- (void)completeUploadWithInfo:(AssetUploadInfo *)info uploadToken:(NSData *)token success:(void (^)(MEGANode *node))success failure:(void (^)(MEGAError * error))failure {
    CameraUploadRequestDelegate *delegate = [[CameraUploadRequestDelegate alloc] initWithCompletion:^(MEGARequest * _Nonnull request, MEGAError * _Nonnull error) {
        if (error.type) {
            failure(error);
        } else {
            MEGANode *node = [MEGASdkManager.sharedMEGASdk nodeForHandle:request.nodeHandle];
            NSOperationQueue *operation = [[NSOperationQueue alloc] init];
            [operation addOperation:[[ThumbnailUploadOperation alloc] initWithNode:node uploadInfo:info expiresAfterTimeInterval:60]];
            [operation addOperation:[[PreviewUploadOperation alloc] initWithNode:node uploadInfo:info expiresAfterTimeInterval:60]];
            [operation waitUntilAllOperationsAreFinished];
            success(node);
        }
    }];
    
    NSString *serverUniqueFileName = [info.fileName mnz_sequentialFileNameInParentNode:info.parentNode];
    
    if(![MEGASdkManager.sharedMEGASdk completeBackgroundMediaUpload:info.mediaUpload
                                                           fileName:serverUniqueFileName
                                                         parentNode:info.parentNode
                                                        fingerprint:info.fingerprint
                                                originalFingerprint:info.originalFingerprint
                                                              token:token
                                                           delegate:delegate]) {
        failure(nil);
    }
}

@end
