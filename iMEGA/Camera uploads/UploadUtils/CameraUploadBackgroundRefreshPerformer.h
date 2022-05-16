
#import <Foundation/Foundation.h>
@import BackgroundTasks;

NS_ASSUME_NONNULL_BEGIN

@interface CameraUploadBackgroundRefreshPerformer : NSObject

- (void)performBackgroundRefreshWithTask:(BGAppRefreshTask *)task;

@end

NS_ASSUME_NONNULL_END
