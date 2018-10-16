
#import "TransferSessionManager.h"
#import "TransferSessionDelegate.h"

NSString * const photoTransferSessionId = @"nz.mega.photoTransfer";
NSString * const videoTransferSessionId = @"nz.mega.videoTransfer";

@interface TransferSessionManager ()

@property (strong, nonatomic) TransferSessionDelegate *sessionDelegate;
@property (strong, nonatomic) dispatch_queue_t serialQueue;

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
        _serialQueue = dispatch_queue_create("nz.mega.sessionManager.serialQueue", DISPATCH_QUEUE_SERIAL);
        _sessionDelegate = [[TransferSessionDelegate alloc] initWithManager:self];
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
    }
}

- (NSURLSession *)createBackgroundSessionWithIdentifier:(NSString *)identifier {
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:identifier];
    configuration.discretionary = YES;
    configuration.sessionSendsLaunchEvents = YES;
    return [NSURLSession sessionWithConfiguration:configuration delegate:self.sessionDelegate delegateQueue:nil];
}

#pragma mark - complete session

- (void)didFinishEventsForBackgroundURLSession:(NSURLSession *)session {
    
}

@end
