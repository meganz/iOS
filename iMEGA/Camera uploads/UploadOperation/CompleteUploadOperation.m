
#import "CompleteUploadOperation.h"
#import "CameraUploadRequestDelegate.h"
#import "NSString+MNZCategory.h"
#import "MEGAError+MNZCategory.h"

@interface CompleteUploadOperation ()

@property (strong, nonatomic) AssetUploadInfo *uploadInfo;
@property (strong, nonatomic) NSData *transferToken;
@property (copy, nonatomic) CompleteUploadCompletionHandler completion;

@end

@implementation CompleteUploadOperation

- (instancetype)initWithUploadInfo:(AssetUploadInfo *)info transferToken:(NSData *)token completion:(CompleteUploadCompletionHandler)completion {
    self = [super init];
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
            [self finishOperation];
        } else {
            MEGANode *node = [MEGASdkManager.sharedMEGASdk nodeForHandle:request.nodeHandle];
            self.completion(node, nil);
            [self finishOperation];
        }
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
        [self finishOperation];
    }
}


@end
