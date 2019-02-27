
#import "BackgroundUploadingTaskMonitor.h"
#import "CameraUploadRecordManager.h"
#import "MEGAConstants.h"

static const NSTimeInterval MonitorTimerInterval = 60;
static const NSUInteger MaximumBackgroundPendingTaskCount = 650;
static const NSTimeInterval MonitorTimerTolerance = 6;

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
    
    NSDictionary *info = @{MEGAHasUploadingTasksReachedMaximumCountUserInfoKey : @(uploadingTaskCount > MaximumBackgroundPendingTaskCount), MEGACurrentUploadingTasksCountUserInfoKey : @(uploadingTaskCount)};
    [NSNotificationCenter.defaultCenter postNotificationName:MEGACameraUploadUploadingTasksCountChangedNotificationName object:self userInfo:info];
}

@end
