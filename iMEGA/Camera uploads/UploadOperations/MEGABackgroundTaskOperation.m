
#import "MEGABackgroundTaskOperation.h"

@interface MEGABackgroundTaskOperation ()

@property (nonatomic) UIBackgroundTaskIdentifier backgroundTaskId;
@property (weak, nonatomic) id<MEGABackgroundTaskOperationDelegate> delegate;

@end

@implementation MEGABackgroundTaskOperation

- (instancetype)init {
    self = [super init];
    if (self) {
        _delegate = self;
    }
    return self;
}

- (void)beginBackgroundTask {
    self.backgroundTaskId = [UIApplication.sharedApplication beginBackgroundTaskWithName:NSStringFromClass([self class]) expirationHandler:^{
        MEGALogDebug(@"%@ background task expired", self);
        [self.delegate backgroundTaskDidExpire];
    }];
}

- (void)start {
    [self beginBackgroundTask];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(didReceiveApplicationDidBecomeActiveNotification) name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)didReceiveApplicationDidBecomeActiveNotification {
    [self endBackgroundTaskIfNeeded];
    
    if (self.isFinished || self.isCancelled) {
        return;
    }

    [self beginBackgroundTask];
}

- (void)finishOperation {
    [super finishOperation];
    [NSNotificationCenter.defaultCenter removeObserver:self];
    [self endBackgroundTaskIfNeeded];
}

- (void)endBackgroundTaskIfNeeded {
    if (self.backgroundTaskId != UIBackgroundTaskInvalid) {
        [UIApplication.sharedApplication endBackgroundTask:self.backgroundTaskId];
        self.backgroundTaskId = UIBackgroundTaskInvalid;
    }
}

#pragma mark - MEGABackgroundTaskOperationDelegate

- (void)backgroundTaskDidExpire {
    [self endBackgroundTaskIfNeeded];
}

@end
