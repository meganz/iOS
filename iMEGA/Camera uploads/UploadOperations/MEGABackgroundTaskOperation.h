#import "MEGAOperation.h"

NS_ASSUME_NONNULL_BEGIN

@class MEGABackgroundTaskOperation;

@protocol MEGABackgroundTaskExpireDelegate <NSObject>

- (void)backgroundTaskDidExpire;

@end

@interface MEGABackgroundTaskOperation : MEGAOperation <MEGABackgroundTaskExpireDelegate>

- (void)beginBackgroundTask;

@end

NS_ASSUME_NONNULL_END
