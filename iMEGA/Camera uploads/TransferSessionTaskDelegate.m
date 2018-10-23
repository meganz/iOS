
#import "TransferSessionTaskDelegate.h"
#import "TransferSessionManager.h"

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
    MEGALogDebug(@"session task delegate - task: %@, request: %@, didCompleteWithError: %@", task, task.originalRequest, error);
    if (error) {
        MEGALogError(@"error happened when to upload asset: %@", error);
        NSLog(@"%@", error);
    }
    
    MEGALogDebug(@"session task description: %@", task.description);
    
    if (self.completion) {
        self.completion([self.mutableData copy], error);
    }
}

// TODO: remove the didSendBodyData which is only for debugging purpose
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didSendBodyData:(int64_t)bytesSent totalBytesSent:(int64_t)totalBytesSent totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend {
    MEGALogDebug(@"session task delegate - task: body data, bytes sent: %lld, total Sent: %lld, total Bytes: %lld", bytesSent, totalBytesSent, totalBytesExpectedToSend);
    if (totalBytesExpectedToSend == totalBytesSent) {
        MEGALogDebug(@"Session - all data sent");
    }
}

#pragma mark - data level delegate

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    MEGALogDebug(@"session task delegate - dataTask: %@, didReceiveData: %@", dataTask, data);
    [self.mutableData appendData:data];
}

@end
