
#import "BackgroundUploadingTaskMonitor.h"
#import "CameraUploadRecordManager.h"

static const NSTimeInterval MonitorTimerInterval = 70;
static const NSUInteger MaximumBackgroundPendingTaskCount = 600;
static const NSTimeInterval MonitorTimerTolerance = 7;

@interface BackgroundUploadingTaskMonitor ()

@property (strong, nonatomic) dispatch_source_t monitorTimer;

@end

@implementation BackgroundUploadingTaskMonitor

- (void)startMonitoringBackgroundUploadingTasks {
    if (self.monitorTimer) {
        dispatch_source_cancel(self.monitorTimer);
    }
    
    self.monitorTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_global_queue(QOS_CLASS_UTILITY, 0));
    dispatch_source_set_timer(self.monitorTimer, dispatch_walltime(NULL, (int64_t)(MonitorTimerInterval * NSEC_PER_SEC)), (uint64_t)(MonitorTimerInterval * NSEC_PER_SEC), (uint64_t)(MonitorTimerTolerance * NSEC_PER_SEC));
    
    __weak __typeof__(self) weakSelf = self;
    dispatch_source_set_event_handler(self.monitorTimer, ^{
        [weakSelf monitorTimerFired];
    });
    
    dispatch_resume(self.monitorTimer);
}

- (void)stopMonitoringBackgroundUploadingTasks {
    if (self.monitorTimer) {
        dispatch_source_cancel(self.monitorTimer);
    }
}

- (void)monitorTimerFired {
    NSError *error;
    NSUInteger uploadingTaskCount = [CameraUploadRecordManager.shared uploadingRecordsCountWithError:&error];
    if (error) {
        MEGALogError(@"[Camera Upload] error when to fetch uploading task count %@", error);
        return;
    }
    
    NSDictionary *info = @{MEGAHasUploadingTasksReachedMaximumCountUserInfoKey : @(uploadingTaskCount > MaximumBackgroundPendingTaskCount), MEGACurrentUploadingTasksCountUserInfoKey : @(uploadingTaskCount)};
    [NSNotificationCenter.defaultCenter postNotificationName:MEGACameraUploadUploadingTasksCountChangedNotification object:self userInfo:info];
}

@end
