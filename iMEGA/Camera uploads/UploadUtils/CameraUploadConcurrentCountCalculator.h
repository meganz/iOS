#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, PhotoUploadConcurrentCount) {
    PhotoUploadConcurrentCountInBackground = 1,
    PhotoUploadConcurrentCountInLowPowerMode = 2,
    PhotoUploadConcurrentCountInMemoryWarning = 1,
    PhotoUploadConcurrentCountInBatteryCharging = 4,
    PhotoUploadConcurrentCountInBatteryLevel75OrAbove = 4,
    PhotoUploadConcurrentCountInBatteryLevelBelow75 = 4,
    PhotoUploadConcurrentCountInBatteryLevelBelow55 = 3,
    PhotoUploadConcurrentCountInBatteryLevelBelow40 = 2,
    PhotoUploadConcurrentCountInBatteryLevelBelow25 = 1,
    PhotoUploadConcurrentCountInBatteryLevelBelow15 = 0,
    PhotoUploadConcurrentCountInThermalStateFair = 3,
    PhotoUploadConcurrentCountInThermalStateSerious = 1,
    PhotoUploadConcurrentCountInThermalStateCritical = 0,
    PhotoUploadConcurrentCountInDefaultMaximum = 4 // maximum value of all
};

typedef NS_ENUM(NSInteger, VideoUploadConcurrentCount) {
    VideoUploadConcurrentCountInBackground = 1,
    VideoUploadConcurrentCountInLowPowerMode = 1,
    VideoUploadConcurrentCountInBatteryCharging = 1,
    VideoUploadConcurrentCountInBatteryLevel75OrAbove = 1,
    VideoUploadConcurrentCountInBatteryLevelBelow75 = 1,
    VideoUploadConcurrentCountInBatteryLevelBelow55 = 1,
    VideoUploadConcurrentCountInBatteryLevelBelow40 = 1,
    VideoUploadConcurrentCountInBatteryLevelBelow25 = 1,
    VideoUploadConcurrentCountInBatteryLevelBelow15 = 0,
    VideoUploadConcurrentCountInThermalStateFair = 1,
    VideoUploadConcurrentCountInThermalStateSerious = 0,
    VideoUploadConcurrentCountInThermalStateCritical = 0,
    VideoUploadConcurrentCountInDefaultMaximum = 1 // maximum value of all
};

typedef struct {
    PhotoUploadConcurrentCount photoConcurrentCount;
    VideoUploadConcurrentCount videoConcurrentCount;
} CameraUploadConcurrentCounts;

NS_INLINE CameraUploadConcurrentCounts MakeCounts(PhotoUploadConcurrentCount photoCount, VideoUploadConcurrentCount videoCount) {
    CameraUploadConcurrentCounts concurrentCounts;
    concurrentCounts.photoConcurrentCount = photoCount;
    concurrentCounts.videoConcurrentCount = videoCount;
    return concurrentCounts;
}

@interface CameraUploadConcurrentCountCalculator : NSObject

- (void)startCalculatingConcurrentCount;
- (void)stopCalculatingConcurrentCount;

- (PhotoUploadConcurrentCount)calculatePhotoUploadConcurrentCount;
- (VideoUploadConcurrentCount)calculateVideoUploadConcurrentCount;

- (CameraUploadConcurrentCounts)calculateCameraUploadConcurrentCountsByThermalState:(NSProcessInfoThermalState)thermalState applicationState:(UIApplicationState)applicationState batteryState:(UIDeviceBatteryState)batteryState batteryLevel:(float)batteryLevel isLowPowerModeEnabled:(BOOL)isLowPowerModeEnabled;

- (CameraUploadConcurrentCounts)calculateCameraUploadConcurrentCountsByApplicationState:(UIApplicationState)applicationState batteryState:(UIDeviceBatteryState)batteryState batteryLevel:(float)batteryLevel isLowPowerModeEnabled:(BOOL)isLowPowerModeEnabled;

@end

NS_ASSUME_NONNULL_END
