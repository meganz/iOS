
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface UploadRecordsCollator : NSObject

- (void)collateUploadRecordsWithRunningTasks:(NSArray<NSURLSessionTask *> *)tasks;

@end

NS_ASSUME_NONNULL_END
