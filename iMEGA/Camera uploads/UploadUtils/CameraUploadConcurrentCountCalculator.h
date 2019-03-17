
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, PhotoUploadConcurrentCount) {
    PhotoUploadConcurrentCountInForeground = 4,
    PhotoUploadConcurrentCountInBackground = 1,
    PhotoUploadConcurrentCountInLowPowerMode = 2,
    PhotoUploadConcurrentCountInMemoryWarning = 1,
    PhotoUploadConcurrentCountInBatteryCharging = 4,
    PhotoUploadConcurrentCountInBatteryLevelBelow75 = 4,
    PhotoUploadConcurrentCountInBatteryLevelBelow55 = 3,
    PhotoUploadConcurrentCountInBatteryLevelBelow40 = 2,
    PhotoUploadConcurrentCountInBatteryLevelBelow25 = 1,
    PhotoUploadConcurrentCountInBatteryLevelBelow15 = 0,
    PhotoUploadConcurrentCountInThermalStateFair = 3,
    PhotoUploadConcurrentCountInThermalStateSerious = 1,
    PhotoUploadConcurrentCountInThermalStateCritical = 0,
};

typedef NS_ENUM(NSInteger, VideoUploadConcurrentCount) {
    VideoUploadConcurrentCountInForeground = 1,
    VideoUploadConcurrentCountInBackground = 1,
    VideoUploadConcurrentCountInLowPowerMode = 1,
    VideoUploadConcurrentCountInBatteryCharging = 1,
    VideoUploadConcurrentCountInBatteryLevelBelow75 = 1,
    VideoUploadConcurrentCountInBatteryLevelBelow55 = 1,
    VideoUploadConcurrentCountInBatteryLevelBelow40 = 1,
    VideoUploadConcurrentCountInBatteryLevelBelow25 = 1,
    VideoUploadConcurrentCountInBatteryLevelBelow15 = 0,
    VideoUploadConcurrentCountInThermalStateFair = 1,
    VideoUploadConcurrentCountInThermalStateSerious = 0,
    VideoUploadConcurrentCountInThermalStateCritical = 0,
};

@interface CameraUploadConcurrentCountCalculator : NSObject

- (void)startCalculatingConcurrentCount;
- (void)stopCalculatingConcurrentCount;

- (PhotoUploadConcurrentCount)calculatePhotoUploadConcurrentCount;
- (VideoUploadConcurrentCount)calculateVideoUploadConcurrentCount;

@end

NS_ASSUME_NONNULL_END
