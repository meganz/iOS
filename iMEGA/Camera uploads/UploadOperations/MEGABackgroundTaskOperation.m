
#import "MEGABackgroundTaskOperation.h"

@interface MEGABackgroundTaskOperation ()

@property (nonatomic) UIBackgroundTaskIdentifier backgroundTaskId;
@property (copy, nonatomic) void (^backgroundTaskExpirationHandler)(void);

@end

@implementation MEGABackgroundTaskOperation

- (instancetype)initWithBackgroundTaskExpirationHandler:(void (^)(void))expirationHandler {
    self = [super init];
    if (self) {
        _backgroundTaskExpirationHandler = expirationHandler;
    }
    return self;
}

- (void)start {
    [super start];
    
    self.backgroundTaskId = [UIApplication.sharedApplication beginBackgroundTaskWithName:@"attributeUploadBackgroundTask" expirationHandler:^{
        MEGALogDebug(@"%@ background task expired.", NSStringFromClass(self.class));
        if (self.backgroundTaskExpirationHandler) {
            self.backgroundTaskExpirationHandler();
        }
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
