
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, PhotoUploadConcurrentCount) {
    PhotoUploadConcurrentCountInForeground = 6,
    PhotoUploadConcurrentCountInBackground = 3,
    PhotoUploadConcurrentCountInLowPowerMode = 2,
    PhotoUploadConcurrentCountInBatteryCharging = 7,
    PhotoUploadConcurrentCountInBatteryLevelBelow75 = 5,
    PhotoUploadConcurrentCountInBatteryLevelBelow55 = 3,
    PhotoUploadConcurrentCountInBatteryLevelBelow35 = 2,
    PhotoUploadConcurrentCountInBatteryLevelBelow20 = 1,
    PhotoUploadConcurrentCountInBatteryLevelBelow10 = 0,
    PhotoUploadConcurrentCountInThermalStateFair = 4,
    PhotoUploadConcurrentCountInThermalStateSerious = 1,
    PhotoUploadConcurrentCountInThermalStateCritical = 0,
};


typedef NS_ENUM(NSInteger, VideoUploadConcurrentCount) {
    VideoUploadConcurrentCountInForeground = 1,
    VideoUploadConcurrentCountInBackground = 1,
    VideoUploadConcurrentCountInLowPowerMode = 0,
    VideoUploadConcurrentCountInBatteryCharging = 1,
    VideoUploadConcurrentCountInBatteryLevelBelow75 = 1,
    VideoUploadConcurrentCountInBatteryLevelBelow55 = 1,
    VideoUploadConcurrentCountInBatteryLevelBelow35 = 1,
    VideoUploadConcurrentCountInBatteryLevelBelow20 = 0,
    VideoUploadConcurrentCountInBatteryLevelBelow10 = 0,
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
