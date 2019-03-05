
#import "TransferSessionDelegate.h"
#import "TransferSessionTaskDelegate.h"
#import "TransferSessionManager.h"

@interface TransferSessionDelegate ()

@property (strong, nonatomic) NSMutableDictionary<NSNumber *, TransferSessionTaskDelegate *> *taskDelegateDict;
@property (weak, nonatomic) TransferSessionManager *manager;
@property (strong, nonatomic) dispatch_queue_t serialQueue;

@end

@implementation TransferSessionDelegate

- (instancetype)initWithSessionManager:(TransferSessionManager *)manager {
    self = [super init];
    if (self) {
        _manager = manager;
        _taskDelegateDict = [NSMutableDictionary dictionary];
        _serialQueue = dispatch_queue_create("nz.mega.sessionManager.cameraUpload.sessionDelegate", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

#pragma mark - session task delegate

- (TransferSessionTaskDelegate *)delegateForTask:(NSURLSessionTask *)task {
    __block TransferSessionTaskDelegate *taskDelegate;
    dispatch_sync(self.serialQueue, ^{
        taskDelegate = self.taskDelegateDict[@(task.taskIdentifier)];
    });
    return taskDelegate;
}

- (void)removeDelegateForTask:(NSURLSessionTask *)task {
    dispatch_sync(self.serialQueue, ^{
        [self.taskDelegateDict removeObjectForKey:@(task.taskIdentifier)];
    });
}

- (void)addDelegate:(TransferSessionTaskDelegate *)delegate forTask:(NSURLSessionTask *)task {
    dispatch_sync(self.serialQueue, ^{
        self.taskDelegateDict[@(task.taskIdentifier)] = delegate;
    });
}

#pragma mark - session level delegate

- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(NSError *)error {
    MEGALogError(@"[Camera Upload] Session %@ did become invalid with error: %@", session.configuration.identifier, error);
}

- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session {
    MEGALogInfo(@"[Camera Upload] Session %@ did finish events for background URL Session", session.configuration.identifier);
    [self.manager finishEventsForBackgroundURLSession:session];
}

- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler {
    MEGALogInfo(@"[Camera Upload] Session %@ did receive challenge for protection space: %@", session.configuration.identifier, challenge.protectionSpace);
    if (challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust) {
#warning add public key matching check here to improve the security
        SecTrustRef trust = challenge.protectionSpace.serverTrust;
        completionHandler(NSURLSessionAuthChallengeUseCredential, [NSURLCredential credentialForTrust:trust]);
    } else {
        completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
    }
}

#pragma mark - task level delegate

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    [[self delegateForTask:task] URLSession:session task:task didCompleteWithError:error];
    [self removeDelegateForTask:task];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didSendBodyData:(int64_t)bytesSent totalBytesSent:(int64_t)totalBytesSent totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend {
    [[self delegateForTask:task] URLSession:session task:task didSendBodyData:bytesSent totalBytesSent:totalBytesSent totalBytesExpectedToSend:totalBytesExpectedToSend];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task willPerformHTTPRedirection:(NSHTTPURLResponse *)response newRequest:(NSURLRequest *)request completionHandler:(void (^)(NSURLRequest * _Nullable))completionHandler {
    MEGALogDebug(@"[Camera Upload] Session %@ task %@ willPerformHTTPRedirection", session.configuration.identifier, task.taskDescription);
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task needNewBodyStream:(void (^)(NSInputStream * _Nullable))completionHandler {
    MEGALogDebug(@"[Camera Upload] Session %@ task %@ needNewBodyStream", session.configuration.identifier, task.taskDescription);
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didFinishCollectingMetrics:(NSURLSessionTaskMetrics *)metrics {
    MEGALogDebug(@"[Camera Upload] Session %@ task %@ didFinishCollectingMetrics %@", session.configuration.identifier, task.taskDescription, metrics);
}

#pragma mark - data level delegate

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    [[self delegateForTask:dataTask] URLSession:session dataTask:dataTask didReceiveData:data];
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didBecomeStreamTask:(NSURLSessionStreamTask *)streamTask {
    MEGALogDebug(@"[Camera Upload] Session %@ task %@ didBecomeStreamTask", session.configuration.identifier, dataTask.taskDescription);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didBecomeDownloadTask:(NSURLSessionDownloadTask *)downloadTask {
    MEGALogDebug(@"[Camera Upload] Session %@ task %@ didBecomeDownloadTask", session.configuration.identifier, dataTask.taskDescription);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask willCacheResponse:(NSCachedURLResponse *)proposedResponse completionHandler:(void (^)(NSCachedURLResponse * _Nullable))completionHandler {
    MEGALogDebug(@"[Camera Upload] Session %@ task %@ willCacheResponse", session.configuration.identifier, dataTask.taskDescription);
}

@end
