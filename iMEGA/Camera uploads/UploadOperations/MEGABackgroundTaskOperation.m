
#import "MEGABackgroundTaskOperation.h"

@interface MEGABackgroundTaskOperation ()

@property (nonatomic) UIBackgroundTaskIdentifier backgroundTaskId;

@end

@implementation MEGABackgroundTaskOperation

- (void)beginBackgroundTaskWithExpirationHandler:(void (^)(void))handler {
    self.backgroundTaskId = [UIApplication.sharedApplication beginBackgroundTaskWithName:NSStringFromClass(self.class) expirationHandler:^{
        if (handler) {
            handler();
        }
        
        [self endBackgroundTaskIfNeeded];
    }];
}

- (void)finishOperation {
    [super finishOperation];
    
    [self endBackgroundTaskIfNeeded];
}

- (void)endBackgroundTaskIfNeeded {
    if (self.backgroundTaskId != UIBackgroundTaskInvalid) {
        [UIApplication.sharedApplication endBackgroundTask:self.backgroundTaskId];
        self.backgroundTaskId = UIBackgroundTaskInvalid;
    }
}

@end
