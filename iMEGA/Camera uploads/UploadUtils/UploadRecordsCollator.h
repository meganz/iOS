#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface UploadRecordsCollator : NSObject

- (void)collateNonUploadingRecords;

- (void)collatePhotoUploadingRecordsByUploadTasks:(NSArray<NSURLSessionTask *> *)tasks;
- (void)collateVideoUploadingRecordsByUploadTasks:(NSArray<NSURLSessionTask *> *)tasks;
- (void)collateAllUploadingRecordsByUploadTasks:(NSArray<NSURLSessionTask *> *)tasks;

@end

NS_ASSUME_NONNULL_END
