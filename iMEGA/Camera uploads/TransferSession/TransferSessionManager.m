
#import "TransferSessionManager.h"
#import "TransferSessionDelegate.h"
#import "TransferSessionTaskDelegate.h"
#import "CameraUploadManager.h"

NSString * const photoTransferSessionId = @"nz.mega.photoTransfer";
NSString * const videoTransferSessionId = @"nz.mega.videoTransfer";

@interface TransferSessionManager () <NSURLSessionDataDelegate>

@property (strong, nonatomic) dispatch_queue_t serialQueue;
@property (strong, nonatomic) TransferSessionDelegate *photoSessionDelegate;
@property (strong, nonatomic) TransferSessionDelegate *videoSessionDelegate;

@end

@implementation TransferSessionManager

+ (instancetype)shared {
    static id sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _serialQueue = dispatch_queue_create("nz.mega.sessionManager.cameraUploadSessionSerialQueue", DISPATCH_QUEUE_SERIAL);
        _photoSessionDelegate = [[TransferSessionDelegate alloc] initWithSessionManager:self];
        _videoSessionDelegate = [[TransferSessionDelegate alloc] initWithSessionManager:self];
    }
    return self;
}

#pragma mark - photo and video session

- (NSURLSession *)photoSession {
    dispatch_sync(self.serialQueue, ^{
        if (self->_photoSession == nil) {
            self->_photoSession = [self createBackgroundSessionWithIdentifier:photoTransferSessionId];
        }
    });
    
    return _photoSession;
}

- (void)restorePhotoSessionIfNeeded {
    if (_photoSession == nil) {
        _photoSession = [self createBackgroundSessionWithIdentifier:photoTransferSessionId];
        [self restoreTaskDelegatesForSession:_photoSession];
    }
}

- (NSURLSession *)videoSession {
    dispatch_sync(self.serialQueue, ^{
        if (self->_videoSession == nil) {
            self->_videoSession = [self createBackgroundSessionWithIdentifier:videoTransferSessionId];
        }
    });
    
    return _videoSession;
}

- (void)restoreVideoSessionIfNeeded {
    if (_videoSession == nil) {
        _videoSession = [self createBackgroundSessionWithIdentifier:videoTransferSessionId];
        [self restoreTaskDelegatesForSession:_videoSession];
    }
}

- (void)restoreTaskDelegatesForSession:(NSURLSession *)session {
    [session getTasksWithCompletionHandler:^(NSArray<NSURLSessionDataTask *> * _Nonnull dataTasks, NSArray<NSURLSessionUploadTask *> * _Nonnull uploadTasks, NSArray<NSURLSessionDownloadTask *> * _Nonnull downloadTasks) {
        for (NSURLSessionUploadTask *task in uploadTasks) {
            [self addDelegateForTask:task inSession:session completion:nil];
        }
    }];
}


- (NSURLSession *)createBackgroundSessionWithIdentifier:(NSString *)identifier {
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:identifier];
    configuration.discretionary = YES;
    configuration.sessionSendsLaunchEvents = YES;
    NSURLSession *session;
    if ([identifier isEqualToString:photoTransferSessionId]) {
        session = [NSURLSession sessionWithConfiguration:configuration delegate:self.photoSessionDelegate delegateQueue:nil];
    } else if ([identifier isEqualToString:videoTransferSessionId]) {
        session = [NSURLSession sessionWithConfiguration:configuration delegate:self.videoSessionDelegate delegateQueue:nil];
    }
    
    return session;
}

#pragma mark - task creation

- (NSURLSessionUploadTask *)photoUploadTaskWithURL:(NSURL *)requestURL fromFile:(NSURL *)fileURL completion:(UploadCompletionHandler)completion {
    return [self backgroundUploadTaskInSession:self.photoSession withURL:requestURL fromFile:fileURL completion:completion];
}

- (NSURLSessionUploadTask *)videoUploadTaskWithURL:(NSURL *)requestURL fromFile:(NSURL *)fileURL completion:(UploadCompletionHandler)completion {
    return [self backgroundUploadTaskInSession:self.videoSession withURL:requestURL fromFile:fileURL completion:completion];
}

- (NSURLSessionUploadTask *)backgroundUploadTaskInSession:(NSURLSession *)session withURL:(NSURL *)requestURL fromFile:(NSURL *)fileURL completion:(UploadCompletionHandler)completion {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:requestURL];
    request.HTTPMethod = @"POST";
    NSURLSessionUploadTask *task = [session uploadTaskWithRequest:request fromFile:fileURL];
    
    [self addDelegateForTask:task inSession:session completion:completion];
    
    return task;
}

- (void)addDelegateForTask:(NSURLSessionTask *)task inSession:(NSURLSession *)session completion:(UploadCompletionHandler)completion {
    TransferSessionTaskDelegate *delegate = [[TransferSessionTaskDelegate alloc] initWithCompletionHandler:completion];
    [(TransferSessionDelegate *)session.delegate addDelegate:delegate forTask:task];
}

#pragma mark - session finishes

- (void)didFinishEventsForBackgroundURLSession:(NSURLSession *)session {
    if ([session.configuration.identifier isEqualToString:photoTransferSessionId]) {
        [self didFinishPhotoSessionEvents];
    } else if ([session.configuration.identifier isEqualToString:videoTransferSessionId]) {
        [self didFinishVideoSessionEvents];
    }
}

- (void)didFinishPhotoSessionEvents {
//    [[CameraUploadManager shared] uploadNextPhotoBatch];
    
    [NSOperationQueue.mainQueue addOperationWithBlock:^{
        if (self.photoSessionCompletion) {
            self.photoSessionCompletion();
        }
    }];
}

- (void)didFinishVideoSessionEvents {
    
    [NSOperationQueue.mainQueue addOperationWithBlock:^{
        if (self.videoSessionCompletion) {
            self.videoSessionCompletion();
        }
    }];
}

@end
