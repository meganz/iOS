
#import "MEGABackgroundTaskOperation.h"

@interface MEGABackgroundTaskOperation ()

@property (nonatomic) UIBackgroundTaskIdentifier backgroundTaskId;
@property (copy, nonatomic) void (^expirationHandler)(void);

@end

@implementation MEGABackgroundTaskOperation

- (void)beginBackgroundTaskWithExpirationHandler:(void (^)(void))handler {
    self.expirationHandler = handler;
    self.backgroundTaskId = [UIApplication.sharedApplication beginBackgroundTaskWithName:NSStringFromClass(self.class) expirationHandler:^{
        MEGALogDebug(@"%@ background task expired", self);
        if (handler) {
            handler();
        }
        
        [self endBackgroundTaskIfNeeded];
    }];
}

- (void)start {
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(didReceiveApplicationDidBecomeActiveNotification) name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)didReceiveApplicationDidBecomeActiveNotification {
    [self endBackgroundTaskIfNeeded];
    
    if (self.isFinished || self.isCancelled) {
        return;
    }

    [self beginBackgroundTaskWithExpirationHandler:self.expirationHandler];
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
