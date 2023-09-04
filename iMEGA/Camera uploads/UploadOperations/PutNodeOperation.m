#import "PutNodeOperation.h"
#import "CameraUploadRequestDelegate.h"
#import "NSString+MNZCategory.h"
#import "MEGAError+MNZCategory.h"
#import "NSError+CameraUpload.h"

@interface PutNodeOperation ()

@property (strong, nonatomic) NSData *transferToken;
@property (copy, nonatomic) PutNodeCompletionHandler completion;

@end

@implementation PutNodeOperation

- (NSString *)description {
    return [NSString stringWithFormat:@"%@ %@", NSStringFromClass([self class]), self.uploadInfo.savedLocalIdentifier];
}

- (instancetype)initWithUploadInfo:(AssetUploadInfo *)info transferToken:(NSData *)token completion:(PutNodeCompletionHandler)completion {
    self = [super init];
    if (self) {
        _uploadInfo = info;
        _transferToken = token;
        _completion = completion;
    }
    
    return self;
}

- (void)start {
    if (self.isCancelled) {
        self.completion(nil, NSError.mnz_cameraUploadOperationCancelledError);
        [self finishOperation];
        
        return;
    }
    
    [self startExecuting];
    
    [self beginBackgroundTask];

    CameraUploadRequestDelegate *delegate = [[CameraUploadRequestDelegate alloc] initWithCompletion:^(MEGARequest * _Nonnull request, MEGAError * _Nonnull error) {
        if (error.type) {
            self.completion(nil, [error nativeError]);
        } else {
            MEGANode *node = [MEGASdkManager.sharedMEGASdk nodeForHandle:request.nodeHandle];
            self.completion(node, nil);
        }
        
        [self finishOperation];
    }];
    
    NSString *originalFingerPrint = [self.uploadInfo.originalFingerprint isEqualToString:self.uploadInfo.fingerprint] ? nil : self.uploadInfo.originalFingerprint;
    NSString *serverUniqueFileName = [self.uploadInfo.fileName mnz_sequentialFileNameInParentNode:self.uploadInfo.parentNode];
    [MEGASdkManager.sharedMEGASdk completeBackgroundMediaUpload:self.uploadInfo.mediaUpload
                                                       fileName:serverUniqueFileName
                                                     parentNode:self.uploadInfo.parentNode
                                                    fingerprint:self.uploadInfo.fingerprint
                                            originalFingerprint:originalFingerPrint
                                              binaryUploadToken:self.transferToken
                                                       delegate:delegate];
}

@end
