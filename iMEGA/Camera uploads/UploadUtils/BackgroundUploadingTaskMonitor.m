
#import "BackgroundUploadingTaskMonitor.h"
#import "CameraUploadRecordManager.h"
#import "MEGAConstants.h"

static const NSTimeInterval MonitorTimerInterval = 100;
static const NSUInteger MaximumBackgroundPendingTaskCount = 700;
static const NSTimeInterval MonitorTimerTolerance = 10;

@interface BackgroundUploadingTaskMonitor ()

@property (strong, nonatomic) NSTimer *monitorTimer;

@end

@implementation BackgroundUploadingTaskMonitor

- (void)startMonitoringBackgroundUploadingTasks {
    if (self.monitorTimer.isValid) {
        return;
    }
    
    [NSOperationQueue.mainQueue addOperationWithBlock:^{
        self.monitorTimer = [NSTimer scheduledTimerWithTimeInterval:MonitorTimerInterval target:self selector:@selector(fireMonitorTimer:) userInfo:nil repeats:YES];
        self.monitorTimer.tolerance = MonitorTimerTolerance;
    }];
}

- (void)stopMonitoringBackgroundUploadingTasks {
    if (self.monitorTimer.isValid) {
        [NSOperationQueue.mainQueue addOperationWithBlock:^{
            [self.monitorTimer invalidate];
            self.monitorTimer = nil;
        }];
    }
}

- (void)fireMonitorTimer:(NSTimer *)timer {
    NSError *error;
    NSUInteger uploadingTaskCount = [CameraUploadRecordManager.shared uploadingUploadRecordsCountWithError:&error];
    if (error) {
        MEGALogError(@"[Camera Upload] error when to fetch uploading task count %@", error);
        return;
    }
    
    [NSNotificationCenter.defaultCenter postNotificationName:MEGACameraUploadUploadingTasksCountChangedNotificationName object:self userInfo:@{MEGAHasUploadingTasksReachedMaximumCountUserInfoKey : @(uploadingTaskCount > MaximumBackgroundPendingTaskCount)}];
}

@end
