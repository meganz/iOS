#import "BackgroundUploadingTaskMonitor.h"
#import "CameraUploadRecordManager.h"

static const NSTimeInterval MonitorTimerInterval = 70;
static const NSUInteger MaximumBackgroundPendingTaskCount = 600;
static const NSTimeInterval MonitorTimerTolerance = 7;

@interface BackgroundUploadingTaskMonitor ()

@property (strong, nonatomic) dispatch_source_t monitorTimer;

@end

@implementation BackgroundUploadingTaskMonitor

#pragma mark - lifecycle

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setupMonitorTimer];
    }
    
    return self;
}

- (void)dealloc {
    // Calling dispatch_activate() on an active object has no effect.
    // Releasing the last reference count on an inactive object is undefined.
    // So we need to activate the dispatch object before release it.
    if (self.monitorTimer) {
        dispatch_activate(self.monitorTimer);
        dispatch_source_cancel(self.monitorTimer);
    }
}

#pragma mark - timer management

- (void)setupMonitorTimer {
    self.monitorTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_global_queue(QOS_CLASS_UTILITY, 0));
    if (self.monitorTimer == nil) {
        return;
    }
    
    dispatch_source_set_timer(self.monitorTimer, dispatch_walltime(NULL, (int64_t)(MonitorTimerInterval * NSEC_PER_SEC)), (uint64_t)(MonitorTimerInterval * NSEC_PER_SEC), (uint64_t)(MonitorTimerTolerance * NSEC_PER_SEC));
    
    __weak __typeof__(self) weakSelf = self;
    dispatch_source_set_event_handler(self.monitorTimer, ^{
        [weakSelf monitorTimerFired];
    });
}

- (void)startMonitoringBackgroundUploadingTasks {
    if (self.monitorTimer) {
        dispatch_activate(self.monitorTimer);
    }
}

- (void)stopMonitoringBackgroundUploadingTasks {
    if (self.monitorTimer) {
        // Calling dispatch_activate() on an active object has no effect.
        // This is to make sure the timer is active before we suspend it.
        dispatch_activate(self.monitorTimer);
        dispatch_suspend(self.monitorTimer);
    }
}

#pragma mark - timer handler

- (void)monitorTimerFired {
    NSError *error;
    NSUInteger uploadingTaskCount = [CameraUploadRecordManager.shared uploadingRecordsCountWithError:&error];
    if (error) {
        MEGALogError(@"[Camera Upload] error when to fetch uploading task count %@", error);
        return;
    }
    
    NSDictionary *info = @{MEGAHasUploadingTasksReachedMaximumCountUserInfoKey : @(uploadingTaskCount > MaximumBackgroundPendingTaskCount), MEGACurrentUploadingTasksCountUserInfoKey : @(uploadingTaskCount)};
    [NSNotificationCenter.defaultCenter postNotificationName:MEGACameraUploadUploadingTasksCountChangedNotification object:self userInfo:info];
    MEGALogDebug(@"[Camera Upload] monitoring timer fired with info %@", info);
}

@end
