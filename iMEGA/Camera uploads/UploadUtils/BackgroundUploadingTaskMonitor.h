#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BackgroundUploadingTaskMonitor : NSObject

- (void)startMonitoringBackgroundUploadingTasks;
- (void)stopMonitoringBackgroundUploadingTasks;

@end

NS_ASSUME_NONNULL_END
