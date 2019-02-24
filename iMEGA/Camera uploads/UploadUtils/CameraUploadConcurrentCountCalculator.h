
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, PhotoUploadConcurrentCount) {
    PhotoUploadConcurrentCountInForeground = 9,
    PhotoUploadConcurrentCountInBackground = 4,
    PhotoUploadConcurrentCountInLowPowerMode = 2,
    PhotoUploadConcurrentCountInMemoryWarning = 2,
    PhotoUploadConcurrentCountInBatteryCharging = 10,
    PhotoUploadConcurrentCountInBatteryLevelBelow75 = 7,
    PhotoUploadConcurrentCountInBatteryLevelBelow55 = 5,
    PhotoUploadConcurrentCountInBatteryLevelBelow35 = 3,
    PhotoUploadConcurrentCountInBatteryLevelBelow20 = 1,
    PhotoUploadConcurrentCountInBatteryLevelBelow10 = 0,
    PhotoUploadConcurrentCountInThermalStateFair = 6,
    PhotoUploadConcurrentCountInThermalStateSerious = 1,
    PhotoUploadConcurrentCountInThermalStateCritical = 0,
};


typedef NS_ENUM(NSInteger, VideoUploadConcurrentCount) {
    VideoUploadConcurrentCountInForeground = 1,
    VideoUploadConcurrentCountInBackground = 1,
    VideoUploadConcurrentCountInLowPowerMode = 0,
    VideoUploadConcurrentCountInMemoryWarning = 0,
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
