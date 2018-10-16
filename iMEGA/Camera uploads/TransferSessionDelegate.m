
#import "TransferSessionDelegate.h"
#import "TransferSessionManager.h"

@implementation TransferSessionDelegate

- (instancetype)initWithManager:(TransferSessionManager *)manager {
    self = [super init];
    if (self) {
        _manager = manager;
    }
    
    return self;
}

#pragma mark - session level delegate
- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(NSError *)error {
    MEGALogDebug(@"SessionDelegat - session didBecomeInvalidWithError: %@", error);
}

- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session {
    MEGALogDebug(@"SessionDelegat - URLSessionDidFinishEventsForBackgroundURLSession: %@", session);
    
    [self.manager didFinishEventsForBackgroundURLSession:session];
}

#pragma mark - task level delegate
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    MEGALogDebug(@"SessionDelegat - task: %@, url: %@, didCompleteWithError: %@", task, task.originalRequest.URL, error);
//    NSURLComponents *components = [NSURLComponents componentsWithURL:task.originalRequest.URL resolvingAgainstBaseURL:YES];
//    NSString *fileName = components.queryItems.firstObject.value;
//    if (fileName) {
//        NSString *uploadFolder = [[NSFileManager defaultManager] uploadsDirectory];
//        NSString *filePath = [NSString stringWithFormat:@"%@/%@", uploadFolder, fileName];
//        [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
//        NSLog(@"SessionDelegat - removed file: %@", filePath);
//    }
}

#pragma mark - data level delegate
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    MEGALogDebug(@"SessionDelegat - dataTask: %@, didReceiveData: %@", dataTask, data);
}

@end
