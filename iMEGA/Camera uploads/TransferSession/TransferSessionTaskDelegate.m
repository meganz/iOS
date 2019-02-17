
#import "TransferSessionTaskDelegate.h"
#import "TransferSessionManager.h"
#import "CameraUploadCompletionManager.h"

@interface TransferSessionTaskDelegate ()

@property (strong, nonatomic) NSMutableData *mutableData;
@property (copy, nonatomic) UploadCompletionHandler completion;

@end

@implementation TransferSessionTaskDelegate

- (instancetype)initWithCompletionHandler:(UploadCompletionHandler)completion {
    self = [super init];
    if (self) {
        _mutableData = [NSMutableData data];
        _completion = completion;
    }
    
    return self;
}

#pragma mark - task level delegate

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    MEGALogDebug(@"[Camera Upload] Session %@ task %@ did complete with error: %@", session.configuration.identifier, task.taskDescription, error);
    
    NSData *transferToken = [self.mutableData copy];
    
    if (self.completion) {
        self.completion(transferToken, error);
    } else {
        if (error) {
            [self handleURLSessionError:error forTask:task];
        } else {
            [self handleTransferToken:transferToken forTask:task inSession:session];
        }
    }
}

#pragma mark - data level delegate

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    MEGALogDebug(@"[Camera Upload] Session %@ task %@ did receive data with size: %lu", session.configuration.identifier, dataTask.taskDescription, (unsigned long)data.length);
    [self.mutableData appendData:data];
}

#pragma mark - util methods

- (void)handleURLSessionError:(NSError *)error forTask:(NSURLSessionTask *)task {
    CameraAssetUploadStatus errorStatus;
    if (error.code == NSURLErrorCancelled) {
        errorStatus = CameraAssetUploadStatusCancelled;
    } else {
        errorStatus = CameraAssetUploadStatusFailed;
    }
    
    [CameraUploadCompletionManager.shared finishUploadForLocalIdentifier:task.taskDescription status:errorStatus];
}

- (void)handleTransferToken:(NSData *)token forTask:(NSURLSessionTask *)task inSession:(NSURLSession *)session {
    if (token.length > 0) {
        [CameraUploadCompletionManager.shared handleCompletedTransferWithLocalIdentifier:task.taskDescription token:token];
    } else {
        MEGALogDebug(@"[Camera Upload] Session %@ task %@ finishes with empty transfer token", session.configuration.identifier, task.taskDescription);
    }
}

@end
