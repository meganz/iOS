#import "TransferSessionManager.h"
#import "TransferSessionDelegate.h"
#import "TransferSessionTaskDelegate.h"
#import "CameraUploadManager+Settings.h"
#import "CameraUploadCompletionManager.h"

static NSString * const PhotoCellularAllowedUploadSessionId = @"nz.mega.photoTransfer.cellularAllowed";
static NSString * const PhotoCellularDisallowedUploadSessionId = @"nz.mega.photoTransfer.cellularDisallowed";
static NSString * const VideoCellularAllowedUploadSessionId = @"nz.mega.videoTransfer.cellularAllowed";
static NSString * const VideoCellularDisallowedUploadSessionId = @"nz.mega.videoTransfer.cellularDisallowed";

@interface TransferSessionManager () <NSURLSessionDataDelegate>

@property (strong, nonatomic) NSURLSession *photoCellularAllowedUploadSession;
@property (strong, nonatomic) NSURLSession *photoCellularDisallowedUploadSession;
@property (strong, nonatomic) NSURLSession *videoCellularAllowedUploadSession;
@property (strong, nonatomic) NSURLSession *videoCellularDisallowedUploadSession;

@property (strong, nonatomic) dispatch_queue_t serialQueue;

@property (copy, nonatomic) void (^photoCellularAllowedUploadSessionCompletion)(void);
@property (copy, nonatomic) void (^photoCellularDisallowedUploadSessionCompletion)(void);
@property (copy, nonatomic) void (^videoCellularAllowedUploadSessionCompletion)(void);
@property (copy, nonatomic) void (^videoCellularDisallowedUploadSessionCompletion)(void);

@property (strong, nonatomic) NSString *userAgent;

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
        _userAgent = [NSString stringWithFormat:@"MEGAiOSCU/%@ (%@, %@)", [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"], UIDevice.currentDevice.model, UIDevice.currentDevice.systemVersion];
    }
    
    return self;
}

#pragma mark - session creation

- (NSURLSession *)photoCellularAllowedUploadSession {
    dispatch_sync(self.serialQueue, ^{
        if (self->_photoCellularAllowedUploadSession == nil) {
            self->_photoCellularAllowedUploadSession = [self createBackgroundSessionWithIdentifier:PhotoCellularAllowedUploadSessionId];
        }
    });
    
    return _photoCellularAllowedUploadSession;
}

- (NSURLSession *)photoCellularDisallowedUploadSession {
    dispatch_sync(self.serialQueue, ^{
        if (self->_photoCellularDisallowedUploadSession == nil) {
            self->_photoCellularDisallowedUploadSession = [self createBackgroundSessionWithIdentifier:PhotoCellularDisallowedUploadSessionId];
        }
    });
    
    return _photoCellularDisallowedUploadSession;
}

- (NSURLSession *)videoCellularAllowedUploadSession {
    dispatch_sync(self.serialQueue, ^{
        if (self->_videoCellularAllowedUploadSession == nil) {
            self->_videoCellularAllowedUploadSession = [self createBackgroundSessionWithIdentifier:VideoCellularAllowedUploadSessionId];
        }
    });
    
    return _videoCellularAllowedUploadSession;
}

- (NSURLSession *)videoCellularDisallowedUploadSession {
    dispatch_sync(self.serialQueue, ^{
        if (self->_videoCellularDisallowedUploadSession == nil) {
            self->_videoCellularDisallowedUploadSession = [self createBackgroundSessionWithIdentifier:VideoCellularDisallowedUploadSessionId];
        }
    });
    
    return _videoCellularDisallowedUploadSession;
}

- (NSURLSession *)createBackgroundSessionWithIdentifier:(NSString *)identifier {
    MEGALogDebug(@"[Camera Upload] create new background session with identifier %@", identifier);
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:identifier];
    configuration.discretionary = NO;
    configuration.shouldUseExtendedBackgroundIdleMode = YES;
    configuration.allowsCellularAccess = [identifier isEqualToString:PhotoCellularAllowedUploadSessionId] || [identifier isEqualToString:VideoCellularAllowedUploadSessionId];
    TransferSessionDelegate *delegate = [[TransferSessionDelegate alloc] initWithSessionManager:self];
    return [NSURLSession sessionWithConfiguration:configuration delegate:delegate delegateQueue:nil];
}

#pragma mark - invalidate sessions

- (void)invalidateAndCancelVideoSessions {
    [self invalidateAndCancelVideoCellularAllowedSession];
    [self invalidateAndCancelVideoCellularDisallowedSession];
}

- (void)invalidateAndCancelPhotoSessions {
    [self invalidateAndCancelPhotoCellularAllowedSession];
    [self invalidateAndCancelPhotoCellularDisallowedSession];
}

- (void)invalidateAndCancelPhotoCellularDisallowedSession {
    [_photoCellularDisallowedUploadSession invalidateAndCancel];
    _photoCellularDisallowedUploadSession = nil;
}

- (void)invalidateAndCancelPhotoCellularAllowedSession {
    [_photoCellularAllowedUploadSession invalidateAndCancel];
    _photoCellularAllowedUploadSession = nil;
}

- (void)invalidateAndCancelVideoCellularDisallowedSession {
    [_videoCellularDisallowedUploadSession invalidateAndCancel];
    _videoCellularDisallowedUploadSession = nil;
}

- (void)invalidateAndCancelVideoCellularAllowedSession {
    [_videoCellularAllowedUploadSession invalidateAndCancel];
    _videoCellularAllowedUploadSession = nil;
}

#pragma mark - sessions and tasks restoration

- (void)restorePhotoSessionsWithCompletion:(nullable RestoreSessionCompletionHandler)completion {
    [self restoreSessionsWithIdentifiers:@[PhotoCellularAllowedUploadSessionId,
                                           PhotoCellularDisallowedUploadSessionId]
                              completion:completion];
}

- (void)restoreVideoSessionsWithCompletion:(nullable RestoreSessionCompletionHandler)completion {
    [self restoreSessionsWithIdentifiers:@[VideoCellularAllowedUploadSessionId,
                                           VideoCellularDisallowedUploadSessionId]
                              completion:completion];
}

- (void)restoreAllSessionsWithCompletion:(RestoreSessionCompletionHandler)completion {
    [self restoreSessionsWithIdentifiers:@[PhotoCellularAllowedUploadSessionId,
                                           PhotoCellularDisallowedUploadSessionId,
                                           VideoCellularAllowedUploadSessionId,
                                           VideoCellularDisallowedUploadSessionId]
                              completion:completion];
}

- (void)restoreSessionsWithIdentifiers:(NSArray<NSString *> *)identifiers completion:(nullable RestoreSessionCompletionHandler)completion {
    __block NSMutableArray<NSURLSessionUploadTask *> *allUploadTasks = [NSMutableArray array];
    dispatch_group_t tasksRestoreGroup = dispatch_group_create();
    
    for (NSString *identifier in identifiers) {
        NSURLSession *session = [self createSessionIfNeededByIdentifier:identifier];
        if (session) {
            dispatch_group_enter(tasksRestoreGroup);
            
            [session getTasksWithCompletionHandler:^(NSArray<NSURLSessionDataTask *> * _Nonnull dataTasks, NSArray<NSURLSessionUploadTask *> * _Nonnull uploadTasks, NSArray<NSURLSessionDownloadTask *> * _Nonnull downloadTasks) {
                MEGALogDebug(@"[Camera Upload] session %@ restored tasks count %lu", session.configuration.identifier, (unsigned long)uploadTasks.count);
                [allUploadTasks addObjectsFromArray:uploadTasks];
                [self restoreDelegatesForTasks:uploadTasks inSession:session];
                
                dispatch_group_leave(tasksRestoreGroup);
            }];
        }
    }
    
    dispatch_group_notify(tasksRestoreGroup, dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        if (completion) {
            completion(allUploadTasks);
        }
    });
}

- (nullable NSURLSession *)createSessionIfNeededByIdentifier:(NSString *)identifier {
    NSURLSession *restoredSession;
    if ([identifier isEqualToString:PhotoCellularAllowedUploadSessionId]) {
        if (_photoCellularAllowedUploadSession == nil) {
            _photoCellularAllowedUploadSession = [self createBackgroundSessionWithIdentifier:identifier];
            restoredSession = _photoCellularAllowedUploadSession;
        }
    } else if ([identifier isEqualToString:PhotoCellularDisallowedUploadSessionId]) {
        if (_photoCellularDisallowedUploadSession == nil) {
            _photoCellularDisallowedUploadSession = [self createBackgroundSessionWithIdentifier:identifier];
            restoredSession = _photoCellularDisallowedUploadSession;
        }
    } else if ([identifier isEqualToString:VideoCellularAllowedUploadSessionId]) {
        if (_videoCellularAllowedUploadSession == nil) {
            _videoCellularAllowedUploadSession = [self createBackgroundSessionWithIdentifier:identifier];
            restoredSession = _videoCellularAllowedUploadSession;
        }
    } else if ([identifier isEqualToString:VideoCellularDisallowedUploadSessionId]) {
        if (_videoCellularDisallowedUploadSession == nil) {
            _videoCellularDisallowedUploadSession = [self createBackgroundSessionWithIdentifier:identifier];
            restoredSession = _videoCellularDisallowedUploadSession;
        }
    }
    
    return restoredSession;
}

- (void)restoreDelegatesForTasks:(NSArray<NSURLSessionTask *> *)tasks inSession:(NSURLSession *)session {
    for (NSURLSessionTask *task in tasks) {
        [self addDelegateForTask:task inSession:session completion:nil];
    }
}

#pragma mark - session completion handler

- (void)saveSessionCompletion:(void (^)(void))completion forIdentifier:(NSString *)identifier {
    if ([identifier isEqualToString:PhotoCellularAllowedUploadSessionId]) {
        self.photoCellularAllowedUploadSessionCompletion = completion;
    } else if ([identifier isEqualToString:PhotoCellularDisallowedUploadSessionId]) {
        self.photoCellularDisallowedUploadSessionCompletion = completion;
    } else if ([identifier isEqualToString:VideoCellularAllowedUploadSessionId]) {
        self.videoCellularAllowedUploadSessionCompletion = completion;
    } else if ([identifier isEqualToString:VideoCellularDisallowedUploadSessionId]) {
        self.videoCellularDisallowedUploadSessionCompletion = completion;
    }
}

- (void (^)(void))completionHandlerForIdentifier:(NSString *)identifier {
    if ([identifier isEqualToString:PhotoCellularAllowedUploadSessionId]) {
        return self.photoCellularAllowedUploadSessionCompletion;
    } else if ([identifier isEqualToString:PhotoCellularDisallowedUploadSessionId]) {
        return self.photoCellularDisallowedUploadSessionCompletion;
    } else if ([identifier isEqualToString:VideoCellularAllowedUploadSessionId]) {
        return self.videoCellularAllowedUploadSessionCompletion;
    } else if ([identifier isEqualToString:VideoCellularDisallowedUploadSessionId]) {
        return self.videoCellularDisallowedUploadSessionCompletion;
    } else {
        return nil;
    }
}

#pragma mark - task creation

- (NSURLSessionUploadTask *)photoUploadTaskWithURL:(NSURL *)requestURL fromFile:(NSURL *)fileURL completion:(UploadCompletionHandler)completion {
    NSURLSession *photoSession = CameraUploadManager.isCellularUploadAllowed ? self.photoCellularAllowedUploadSession : self.photoCellularDisallowedUploadSession;
    return [self backgroundUploadTaskInSession:photoSession withURL:requestURL fromFile:fileURL completion:completion];
}

- (NSURLSessionUploadTask *)videoUploadTaskWithURL:(NSURL *)requestURL fromFile:(NSURL *)fileURL completion:(UploadCompletionHandler)completion {
    NSURLSession *videoSession = (CameraUploadManager.isCellularUploadAllowed && CameraUploadManager.isCellularUploadForVideosAllowed) ? self.videoCellularAllowedUploadSession : self.videoCellularDisallowedUploadSession;
    return [self backgroundUploadTaskInSession:videoSession withURL:requestURL fromFile:fileURL completion:completion];
}

- (nullable NSURLSessionUploadTask *)backgroundUploadTaskInSession:(NSURLSession *)session withURL:(NSURL *)requestURL fromFile:(NSURL *)fileURL completion:(UploadCompletionHandler)completion {
    @try {
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:requestURL];
        request.HTTPMethod = @"POST";
        [request setValue:self.userAgent forHTTPHeaderField:@"User-Agent"];
        NSURLSessionUploadTask *task = [session uploadTaskWithRequest:request fromFile:fileURL];
        [self addDelegateForTask:task inSession:session completion:completion];
        return task;
    } @catch (NSException *exception) {
        return nil;
    }
}

- (void)addDelegateForTask:(NSURLSessionTask *)task inSession:(NSURLSession *)session completion:(UploadCompletionHandler)completion {
    TransferSessionTaskDelegate *delegate = [[TransferSessionTaskDelegate alloc] initWithCompletionHandler:completion];
    [(TransferSessionDelegate *)session.delegate addDelegate:delegate forTask:task];
}

#pragma mark - session finishes

- (void)finishEventsForBackgroundURLSession:(NSURLSession *)session {
    void (^sessionCompletion)(void) = [self completionHandlerForIdentifier:session.configuration.identifier];
    [NSOperationQueue.mainQueue addOperationWithBlock:^{
        if (sessionCompletion) {
            MEGALogDebug(@"[Camera Upload] [app lifecycle] call session completion handler for %@", session.configuration.identifier);
            sessionCompletion();
        }
    }];
}

@end
