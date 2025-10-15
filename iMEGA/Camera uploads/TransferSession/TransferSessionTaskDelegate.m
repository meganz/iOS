#import "TransferSessionTaskDelegate.h"
#import "CameraUploadCompletionManager.h"
#import "TransferResponseValidator.h"
#import "MEGA-Swift.h"

static const NSUInteger MEGATransferTokenLength = 36;

@interface TransferSessionTaskDelegate ()

@property (strong, nonatomic) NSMutableData *mutableData;
@property (copy, nonatomic) UploadCompletionHandler completion;
@property (strong, nonatomic) TransferResponseValidator *responseValidator;
@property (strong, nonatomic, nullable) CameraUploadTransferProgressOCRepository *transferProgressRepository;

@end

@implementation TransferSessionTaskDelegate

- (instancetype)initWithCompletionHandler:(UploadCompletionHandler)completion {
    self = [super init];
    if (self) {
        _mutableData = [NSMutableData data];
        _completion = completion;
        _responseValidator = [[TransferResponseValidator alloc] init];
        _transferProgressRepository = nil;
    }
    
    return self;
}

- (instancetype)initWithCompletionHandler:(UploadCompletionHandler)completion transferProgressRepository:(nullable CameraUploadTransferProgressOCRepository *)transferProgressRepository {
    self = [self initWithCompletionHandler:completion];
    if (self) {
        _transferProgressRepository = transferProgressRepository;
    }
    
    return self;
}

#pragma mark - task level delegate

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    NSInteger statusCode = 0;
    if ([task.response isKindOfClass:[NSHTTPURLResponse class]]) {
        statusCode = [(NSHTTPURLResponse *)task.response statusCode];
    }
    
    MEGALogInfo(@"[Camera Upload] Session %@ task %@ completed with status %li", session.configuration.identifier, task.taskDescription, (long)statusCode);

    if (self.transferProgressRepository) {
        [self.transferProgressRepository completeTaskWithIdentifier:task.taskIdentifier description:task.taskDescription];
    }
    
    NSData *transferToken = [self.mutableData copy];
    
    if (error) {
        if (self.completion) {
            self.completion(transferToken, error);
        } else {
            [self handleTransferError:error forTask:task];
        }
    } else {
        NSError *responseError;
        [self.responseValidator validateURLResponse:task.response data:transferToken error:&responseError];
        if (self.completion) {
            self.completion(transferToken, responseError);
        } else {
            if (responseError) {
                [self handleTransferError:responseError forTask:task];
            } else {
                [self handleTransferToken:transferToken forTask:task inSession:session];
            }
        }
    }
}

#pragma mark - data level delegate

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
                                didSendBodyData:(int64_t)bytesSent
                                 totalBytesSent:(int64_t)totalBytesSent
                       totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend {
    if (self.transferProgressRepository == nil) {
        return;
    }
    [self.transferProgressRepository updateProgressWithIdentifier:task.taskIdentifier
                                            description:task.taskDescription
                                        didSendBodyData:bytesSent
                                         totalBytesSent:totalBytesSent
                               totalBytesExpectedToSend:totalBytesExpectedToSend];
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    MEGALogDebug(@"[Camera Upload] Session %@ task %@ received data with size: %lu", session.configuration.identifier, dataTask.taskDescription, (unsigned long)data.length);
    [self.mutableData appendData:data];
}

#pragma mark - util methods

- (void)handleTransferError:(NSError *)error forTask:(NSURLSessionTask *)task {
    NSString *localIdentifier = [CameraUploadTaskIdentifierOCWrapper localIdentifierFrom:task.taskDescription];
    MEGALogError(@"[Camera Upload] Session task %@ completed with error %@", localIdentifier, error);
    if (localIdentifier.length == 0) {
        MEGALogError(@"[Camera Upload] Session task description is empty");
        return;
    }
    
    CameraAssetUploadStatus errorStatus = CameraAssetUploadStatusFailed;
    if ([error.domain isEqualToString:NSURLErrorDomain]) {
        errorStatus = CameraAssetUploadStatusCancelled;
    }

    [CameraUploadCompletionManager.shared finishUploadForLocalIdentifier:localIdentifier status:errorStatus];
}

- (void)handleTransferToken:(NSData *)token forTask:(NSURLSessionTask *)task inSession:(NSURLSession *)session {
    NSString *localIdentifier = [CameraUploadTaskIdentifierOCWrapper localIdentifierFrom:task.taskDescription];
    if (localIdentifier.length == 0) {
        MEGALogError(@"[Camera Upload] Session task description is empty");
        return;
    }

    if ([token isChunkUploadToken]) {
        MEGALogDebug(@"[Camera Upload] Session %@ chunk task %@ completed", session.configuration.identifier, localIdentifier);
    } else if (token.length == MEGATransferTokenLength) {
        [CameraUploadCompletionManager.shared handleCompletedTransferWithLocalIdentifier:localIdentifier token:token];
    } else {
        MEGALogError(@"[Camera Upload] Session %@ task %@ completed with bad transfer token %@, URL %@, response %@", session.configuration.identifier, localIdentifier, [[NSString alloc] initWithData:token encoding:NSUTF8StringEncoding], task.response.URL, task.response);
        [CameraUploadCompletionManager.shared finishUploadForLocalIdentifier:localIdentifier status:CameraAssetUploadStatusFailed];
    }
}

@end
