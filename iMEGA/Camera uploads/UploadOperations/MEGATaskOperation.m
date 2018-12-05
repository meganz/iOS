
#import "MEGATaskOperation.h"

@interface MEGATaskOperation ()

@property (nonatomic) UIBackgroundTaskIdentifier backgroundTaskId;

@end

@implementation MEGATaskOperation

- (void)start {
    [super start];
    
    self.backgroundTaskId = [UIApplication.sharedApplication beginBackgroundTaskWithName:@"attributeUploadBackgroundTask" expirationHandler:^{
        MEGALogDebug(@"%@ background task expired.", NSStringFromClass(self.class));
        [self finishOperation];
    }];
}

- (void)finishOperation {
    [super finishOperation];
    
    if (self.backgroundTaskId != UIBackgroundTaskInvalid) {
        [UIApplication.sharedApplication endBackgroundTask:self.backgroundTaskId];
        self.backgroundTaskId = UIBackgroundTaskInvalid;
    }
}

@end
