
#import "RestoreUploadTaskOperation.h"

@interface RestoreUploadTaskOperation ()

@property (strong, nonatomic) NSURLSession *session;
@property (copy, nonatomic) RestoreSessionCompletionHandler completion;

@end

@implementation RestoreUploadTaskOperation

- (instancetype)initWithSession:(NSURLSession *)session completion:(RestoreSessionCompletionHandler)completion {
    self = [super init];
    if (self) {
        _session = session;
        _completion = completion;
    }
    return self;
}

- (void)start {
    if (self.isFinished) {
        return;
    }
    
    if (self.isCancelled) {
        self.completion(@[]);
        
        [self finishOperation];
        return;
    }
    
    [self startExecuting];
    
    [self.session getTasksWithCompletionHandler:^(NSArray<NSURLSessionDataTask *> * _Nonnull dataTasks, NSArray<NSURLSessionUploadTask *> * _Nonnull uploadTasks, NSArray<NSURLSessionDownloadTask *> * _Nonnull downloadTasks) {
        MEGALogDebug(@"[Camera Upload] session %@ restored tasks count %lu", self.session.configuration.identifier, (unsigned long)uploadTasks.count);
        self.completion(uploadTasks);
        [self finishOperation];
    }];
}


@end
