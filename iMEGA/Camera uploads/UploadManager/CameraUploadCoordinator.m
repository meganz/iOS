
#import "CameraUploadCoordinator.h"
#import "CameraUploadRequestDelegate.h"
#import "ThumbnailUploadOperation.h"
#import "PreviewUploadOperation.h"

@implementation CameraUploadCoordinator

- (void)completeUploadWithInfo:(AssetUploadInfo *)info uploadToken:(NSData *)token success:(void (^)(MEGANode *node))success failure:(void (^)(MEGAError * error))failure {
    // TODO: figure out the new name to avoid same names
    
    CameraUploadRequestDelegate *delegate = [[CameraUploadRequestDelegate alloc] initWithCompletion:^(MEGARequest * _Nonnull request, MEGAError * _Nonnull error) {
        if (error.type) {
            failure(error);
        } else {
            MEGANode *node = [MEGASdkManager.sharedMEGASdk nodeForHandle:request.nodeHandle];
            NSOperationQueue *operation = [[NSOperationQueue alloc] init];
            [operation addOperation:[[ThumbnailUploadOperation alloc] initWithNode:node uploadInfo:info]];
            [operation addOperation:[[PreviewUploadOperation alloc] initWithNode:node uploadInfo:info]];
            [operation waitUntilAllOperationsAreFinished];
            success(node);
        }
    }];
    
    
    if(![MEGASdkManager.sharedMEGASdk completeBackgroundMediaUpload:info.mediaUpload
                                                           fileName:info.fileName
                                                         parentNode:info.parentNode
                                                        fingerprint:info.fingerprint
                                                originalFingerprint:info.originalFingerprint
                                                              token:token
                                                           delegate:delegate]) {
        failure(nil);
    }
}

@end
