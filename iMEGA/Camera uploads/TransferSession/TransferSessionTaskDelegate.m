
#import "TransferSessionTaskDelegate.h"
#import "TransferSessionManager.h"
#import "CameraUploadCoordinator.h"

@interface TransferSessionTaskDelegate ()

@property (strong, nonatomic) NSMutableData *mutableData;
@property (copy, nonatomic) UploadCompletionHandler completion;
@property (strong, nonatomic) CameraUploadCoordinator *uploadCoordinator;

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

- (CameraUploadCoordinator *)uploadCoordinator {
    if (_uploadCoordinator == nil) {
        _uploadCoordinator = [[CameraUploadCoordinator alloc] init];
    }
    
    return _uploadCoordinator;
}

#pragma mark - task level delegate

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    MEGALogDebug(@"[Camera Upload] Session %@ task %@ did complete with error: %@", session.configuration.identifier, task.originalRequest.URL, error);
    
    NSData *transferToken = [self.mutableData copy];
    
    if (self.completion) {
        self.completion(transferToken, error);
    } else {
        if (error) {
            [self.uploadCoordinator finishUploadForLocalIdentifier:task.taskDescription status:UploadStatusFailed];
            return;
        }
        
        if (transferToken.length > 0) {
            [self.uploadCoordinator handleCompletedTransferWithLocalIdentifier:task.taskDescription token:transferToken];
        }
    }
}

#pragma mark - data level delegate

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    MEGALogDebug(@"[Camera Upload] Session %@ task %@ did receive data with size: %lu", session.configuration.identifier, dataTask.originalRequest.URL, data.length);
    [self.mutableData appendData:data];
}

@end
