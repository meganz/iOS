
#import "TransferSessionTaskDelegate.h"
#import "TransferSessionManager.h"
#import "CameraUploadCompletionManager.h"

static const NSUInteger MEGATransferTokenLength = 36;

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
    MEGALogDebug(@"[Camera Upload] Session %@ task %@ completed", session.configuration.identifier, task.taskDescription);
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
    MEGALogDebug(@"[Camera Upload] Session %@ task %@ received data with size: %lu", session.configuration.identifier, dataTask.taskDescription, (unsigned long)data.length);
    [self.mutableData appendData:data];
}

#pragma mark - util methods

- (void)handleURLSessionError:(NSError *)error forTask:(NSURLSessionTask *)task {
    MEGALogError(@"[Camera Upload] Session task %@ completed with error %@", task.taskDescription, error);
    CameraAssetUploadStatus errorStatus;
    if (error.code == NSURLErrorCancelled || error.code == NSURLErrorBackgroundSessionWasDisconnected || error.code == NSURLErrorTimedOut) {
        errorStatus = CameraAssetUploadStatusCancelled;
    } else {
        errorStatus = CameraAssetUploadStatusFailed;
    }
    
    [CameraUploadCompletionManager.shared finishUploadForLocalIdentifier:task.taskDescription status:errorStatus];
}

- (void)handleTransferToken:(NSData *)token forTask:(NSURLSessionTask *)task inSession:(NSURLSession *)session {
    if (token.length == 0) {
        MEGALogDebug(@"[Camera Upload] Session %@ task %@ completed with empty token", session.configuration.identifier, task.taskDescription);
    } else if (token.length == MEGATransferTokenLength) {
        [CameraUploadCompletionManager.shared handleCompletedTransferWithLocalIdentifier:task.taskDescription token:token];
    } else {
        MEGALogError(@"[Camera Upload] Session %@ task %@ completed with bad transfer token %@", session.configuration.identifier, task.taskDescription, [[NSString alloc] initWithData:token encoding:NSUTF8StringEncoding]);
        [CameraUploadCompletionManager.shared finishUploadForLocalIdentifier:task.taskDescription status:CameraAssetUploadStatusFailed];
    }
}

@end
