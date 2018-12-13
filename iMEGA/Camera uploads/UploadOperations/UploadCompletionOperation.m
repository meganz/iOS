
#import "UploadCompletionOperation.h"
#import "CameraUploadRequestDelegate.h"
#import "NSString+MNZCategory.h"
#import "MEGAError+MNZCategory.h"
#import "NSError+CameraUpload.h"

@interface UploadCompletionOperation ()

@property (strong, nonatomic) AssetUploadInfo *uploadInfo;
@property (strong, nonatomic) NSData *transferToken;
@property (copy, nonatomic) UploadCompletionHandler completion;

@end

@implementation UploadCompletionOperation

- (instancetype)initWithUploadInfo:(AssetUploadInfo *)info transferToken:(NSData *)token completion:(UploadCompletionHandler)completion backgroundTaskExpirationHandler:(void (^)(void))expirationHandler {
    self = [super initWithBackgroundTaskExpirationHandler:expirationHandler];
    if (self) {
        _uploadInfo = info;
        _transferToken = token;
        _completion = completion;
    }
    
    return self;
}

- (void)start {
    [super start];
    
    CameraUploadRequestDelegate *delegate = [[CameraUploadRequestDelegate alloc] initWithCompletion:^(MEGARequest * _Nonnull request, MEGAError * _Nonnull error) {
        if (error.type) {
            self.completion(nil, [error nativeError]);
        } else {
            MEGANode *node = [MEGASdkManager.sharedMEGASdk nodeForHandle:request.nodeHandle];
            self.completion(node, nil);
        }
        
        [self finishOperation];
    }];
    
    NSString *serverUniqueFileName = [self.uploadInfo.fileName mnz_sequentialFileNameInParentNode:self.uploadInfo.parentNode];
    
    BOOL didCreateRequestSuccess =
    [MEGASdkManager.sharedMEGASdk completeBackgroundMediaUpload:self.uploadInfo.mediaUpload
                                                       fileName:serverUniqueFileName
                                                     parentNode:self.uploadInfo.parentNode
                                                    fingerprint:self.uploadInfo.fingerprint
                                            originalFingerprint:self.uploadInfo.originalFingerprint
                                                          token:self.transferToken
                                                       delegate:delegate];
    if (!didCreateRequestSuccess) {
        self.completion(nil, [NSError errorWithDomain:CameraUploadErrorDomain code:CameraUploadErrorFailedToCreateCompleteUploadRequest userInfo:@{NSLocalizedDescriptionKey : [NSString stringWithFormat:@"Failed to create complete upload request for file %@", self.uploadInfo.fileName]}]);
        [self finishOperation];
    }
}

@end
