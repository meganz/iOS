
#import "PutNodeOperation.h"
#import "CameraUploadRequestDelegate.h"
#import "NSString+MNZCategory.h"
#import "MEGAError+MNZCategory.h"
#import "NSError+CameraUpload.h"
#import "CameraUploadManager.h"
#import "CameraUploadNodeLoader.h"

@interface PutNodeOperation ()

@property (strong, nonatomic) NSData *transferToken;
@property (copy, nonatomic) PutNodeCompletionHandler completion;
@property (strong, nonatomic) CameraUploadNodeLoader *cameraUploadNodeLoader;

@end

@implementation PutNodeOperation

- (instancetype)initWithUploadInfo:(AssetUploadInfo *)info transferToken:(NSData *)token completion:(PutNodeCompletionHandler)completion {
    self = [super init];
    if (self) {
        _uploadInfo = info;
        _transferToken = token;
        _completion = completion;
    }
    
    return self;
}

- (CameraUploadNodeLoader *)cameraUploadNodeLoader {
    if (_cameraUploadNodeLoader == nil) {
        _cameraUploadNodeLoader = [[CameraUploadNodeLoader alloc] init];
    }
    
    return _cameraUploadNodeLoader;
}

- (void)start {
    if (self.isCancelled) {
        self.completion(nil, NSError.mnz_cameraUploadOperationCancelledError);
        [self finishOperation];
        
        return;
    }
    
    [self startExecuting];

    CameraUploadRequestDelegate *delegate = [[CameraUploadRequestDelegate alloc] initWithCompletion:^(MEGARequest * _Nonnull request, MEGAError * _Nonnull error) {
        if (error.type) {
            self.completion(nil, [error nativeError]);
        } else {
            MEGANode *node = [MEGASdkManager.sharedMEGASdk nodeForHandle:request.nodeHandle];
            self.completion(node, nil);
        }
        
        [self finishOperation];
    }];
    
    if (self.uploadInfo.parentNode == nil) {
        [self.cameraUploadNodeLoader loadCameraUploadNodeWithCompletion:^(MEGANode * _Nullable cameraUploadNode) {
            if (cameraUploadNode == nil) {
                self.completion(nil, NSError.mnz_cameraUploadNodeIsNotFoundError);
                [self finishOperation];
            } else {
                self.uploadInfo.parentNode = cameraUploadNode;
                [self putNodeWithDelegate:delegate];
            }
        }];
    } else {
        [self putNodeWithDelegate:delegate];
    }
}

- (void)putNodeWithDelegate:(id<MEGARequestDelegate>)delegate {
    NSString *serverUniqueFileName = [self.uploadInfo.fileName mnz_sequentialFileNameInParentNode:self.uploadInfo.parentNode];
    BOOL didCreateRequestSuccess =
    [MEGASdkManager.sharedMEGASdk completeBackgroundMediaUpload:self.uploadInfo.mediaUpload
                                                       fileName:serverUniqueFileName
                                                     parentNode:self.uploadInfo.parentNode
                                                    fingerprint:self.uploadInfo.fingerprint
                                            originalFingerprint:self.uploadInfo.originalFingerprint
                                              binaryUploadToken:self.transferToken
                                                       delegate:delegate];
    if (!didCreateRequestSuccess) {
        self.completion(nil, [NSError errorWithDomain:CameraUploadErrorDomain code:CameraUploadErrorFailedToCreateCompleteUploadRequest userInfo:@{NSLocalizedDescriptionKey : [NSString stringWithFormat:@"Failed to create complete upload request for file %@", self.uploadInfo.fileName]}]);
        [self finishOperation];
    }
}

@end
