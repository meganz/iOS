
#import "MEGABackgroundTaskOperation.h"

@interface MEGABackgroundTaskOperation ()

@property (nonatomic) UIBackgroundTaskIdentifier backgroundTaskId;

@end

@implementation MEGABackgroundTaskOperation

- (void)beginBackgroundTask {
    MEGALogDebug(@"%@ begin background task", self);
    self.backgroundTaskId = [UIApplication.sharedApplication beginBackgroundTaskWithName:NSStringFromClass([self class]) expirationHandler:^{
        MEGALogDebug(@"%@ background task expired", self);
        [self endBackgroundTaskIfNeeded];
    }];
    
    if (self.backgroundTaskId == UIBackgroundTaskInvalid) {
        MEGALogDebug(@"Running in the background is not possible for %@.", self);
    }
}

- (void)finishOperation {
    [super finishOperation];
    [self endBackgroundTaskIfNeeded];
}

- (void)endBackgroundTaskIfNeeded {
    if (self.backgroundTaskId != UIBackgroundTaskInvalid) {
        MEGALogDebug(@"%@ end background task", self);
        [UIApplication.sharedApplication endBackgroundTask:self.backgroundTaskId];
        self.backgroundTaskId = UIBackgroundTaskInvalid;
    }
}

@end
