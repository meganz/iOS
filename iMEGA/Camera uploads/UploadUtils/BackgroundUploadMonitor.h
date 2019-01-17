
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BackgroundUploadMonitor : NSObject

- (void)startBackgroundUploadIfPossible;
- (void)stopBackgroundUpload;

@end

NS_ASSUME_NONNULL_END
