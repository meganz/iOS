
#import "MEGABackgroundTaskOperation.h"

@interface MEGABackgroundTaskOperation ()

@property (nonatomic) UIBackgroundTaskIdentifier backgroundTaskId;

@end

@implementation MEGABackgroundTaskOperation

- (void)beginBackgroundTask {
    self.backgroundTaskId = [UIApplication.sharedApplication beginBackgroundTaskWithName:NSStringFromClass([self class]) expirationHandler:^{
        MEGALogDebug(@"%@ background task expired", self);
        [self.backgroundTaskdelegate backgroundTaskDidExpired];
        [self endBackgroundTaskIfNeeded];
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

@end
