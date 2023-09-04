#import "MEGABackgroundTaskOperation.h"

@interface MEGABackgroundTaskOperation ()

@property (nonatomic) UIBackgroundTaskIdentifier backgroundTaskId;
@property (weak, nonatomic) id<MEGABackgroundTaskExpireDelegate> expireDelegate;

@end

@implementation MEGABackgroundTaskOperation

- (instancetype)init {
    self = [super init];
    if (self) {
        _expireDelegate = self;
    }
    return self;
}

- (void)beginBackgroundTask {
    MEGALogDebug(@"%@ begin background task", self);
    self.backgroundTaskId = [UIApplication.sharedApplication beginBackgroundTaskWithName:NSStringFromClass([self class]) expirationHandler:^{
        MEGALogDebug(@"%@ background task expired", self);
        [self.expireDelegate backgroundTaskDidExpire];
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

#pragma mark - background task expire delegate

- (void)backgroundTaskDidExpire { }

@end
