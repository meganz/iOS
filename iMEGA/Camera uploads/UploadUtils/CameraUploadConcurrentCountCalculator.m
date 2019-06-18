
#import "CameraUploadConcurrentCountCalculator.h"
#import "MEGAConstants.h"

typedef struct {
    PhotoUploadConcurrentCount photoConcurrentCount;
    VideoUploadConcurrentCount videoConcurrentCount;
} CameraUploadConcurrentCounts;

static CameraUploadConcurrentCounts MakeCounts(PhotoUploadConcurrentCount photoCount, VideoUploadConcurrentCount videoCount) {
    CameraUploadConcurrentCounts concurrentCounts;
    concurrentCounts.photoConcurrentCount = photoCount;
    concurrentCounts.videoConcurrentCount = videoCount;
    return concurrentCounts;
}

@interface CameraUploadConcurrentCountCalculator ()

@property (nonatomic) CameraUploadConcurrentCounts currentConcurrentCounts;

@end

@implementation CameraUploadConcurrentCountCalculator

#pragma mark - notifications to monitor

- (void)startCalculatingConcurrentCount {
    [NSNotificationCenter.defaultCenter removeObserver:self];
    
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(applicationStatesChangedNotification:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(applicationStatesChangedNotification:) name:UIApplicationDidBecomeActiveNotification object:nil];
    
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(applicationStatesChangedNotification:) name:UIDeviceBatteryStateDidChangeNotification object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(applicationStatesChangedNotification:) name:UIDeviceBatteryLevelDidChangeNotification object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(applicationStatesChangedNotification:) name:NSProcessInfoPowerStateDidChangeNotification object:nil];
    
    if (@available(iOS 11.0, *)) {
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(applicationStatesChangedNotification:) name:NSProcessInfoThermalStateDidChangeNotification object:nil];
    }
}

- (void)stopCalculatingConcurrentCount {
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (void)applicationStatesChangedNotification:(NSNotification *)notification {
    MEGALogDebug(@"[Camera Upload] concurrent calculator received %@", notification.name);
    CameraUploadConcurrentCounts concurrentCounts = [self calculateCameraUploadConcurrentCounts];
    if (concurrentCounts.photoConcurrentCount != self.currentConcurrentCounts.photoConcurrentCount) {
        [NSNotificationCenter.defaultCenter postNotificationName:MEGACameraUploadPhotoConcurrentCountChangedNotification object:self userInfo:@{MEGAPhotoConcurrentCountUserInfoKey : @(concurrentCounts.photoConcurrentCount)}];
    }
    
    if (concurrentCounts.videoConcurrentCount != self.currentConcurrentCounts.videoConcurrentCount) {
        [NSNotificationCenter.defaultCenter postNotificationName:MEGACameraUploadVideoConcurrentCountChangedNotification object:self userInfo:@{MEGAVideoConcurrentCountUserInfoKey : @(concurrentCounts.videoConcurrentCount)}];
    }
    
    self.currentConcurrentCounts = concurrentCounts;
}

#pragma mark - concurrent count calculation

- (PhotoUploadConcurrentCount)calculatePhotoUploadConcurrentCount {
    self.currentConcurrentCounts = [self calculateCameraUploadConcurrentCounts];
    return self.currentConcurrentCounts.photoConcurrentCount;
}

- (VideoUploadConcurrentCount)calculateVideoUploadConcurrentCount {
    self.currentConcurrentCounts = [self calculateCameraUploadConcurrentCounts];
    return self.currentConcurrentCounts.videoConcurrentCount;
}

- (CameraUploadConcurrentCounts)calculateCameraUploadConcurrentCounts {
    if (NSThread.isMainThread) {
        return [self calculateCameraUploadConcurrentCountsInMainThread];
    } else {
        __block CameraUploadConcurrentCounts counts;
        dispatch_sync(dispatch_get_main_queue(), ^{
            counts = [self calculateCameraUploadConcurrentCountsInMainThread];
        });
        return counts;
    }
}

- (CameraUploadConcurrentCounts)calculateCameraUploadConcurrentCountsInMainThread {
    CameraUploadConcurrentCounts countsByAppState = [self concurrentCountsByApplicationState];
    CameraUploadConcurrentCounts countsByPower = [self concurrentCountsByPowerState];
    CameraUploadConcurrentCounts concurrentCounts = MakeCounts(MIN(countsByAppState.photoConcurrentCount, countsByPower.photoConcurrentCount), MIN(countsByAppState.videoConcurrentCount, countsByPower.videoConcurrentCount));
    if (@available(iOS 11.0, *)) {
        CameraUploadConcurrentCounts countsByThermal = [self concurrentCountsByThermalState];
        concurrentCounts = MakeCounts(MIN(concurrentCounts.photoConcurrentCount, countsByThermal.photoConcurrentCount), MIN(concurrentCounts.videoConcurrentCount, countsByThermal.videoConcurrentCount));
    }
    
    return concurrentCounts;
}

- (CameraUploadConcurrentCounts)concurrentCountsByApplicationState {
    if (UIApplication.sharedApplication.applicationState == UIApplicationStateBackground) {
        return MakeCounts(PhotoUploadConcurrentCountInBackground, VideoUploadConcurrentCountInBackground);
    } else {
        return MakeCounts(PhotoUploadConcurrentCountDefaultMaximum, VideoUploadConcurrentCountDefaultMaximum);
    }
}

- (CameraUploadConcurrentCounts)concurrentCountsByPowerState {
    if (UIDevice.currentDevice.batteryState == UIDeviceBatteryStateUnplugged) {
        float batteryLevel = UIDevice.currentDevice.batteryLevel;
        if (batteryLevel < 0.15) {
            return MakeCounts(PhotoUploadConcurrentCountInBatteryLevelBelow15, VideoUploadConcurrentCountInBatteryLevelBelow15);
        } else if (batteryLevel < 0.25) {
            return MakeCounts(PhotoUploadConcurrentCountInBatteryLevelBelow25, VideoUploadConcurrentCountInBatteryLevelBelow25);
        } else if (NSProcessInfo.processInfo.isLowPowerModeEnabled) {
            return MakeCounts(PhotoUploadConcurrentCountInLowPowerMode, VideoUploadConcurrentCountInLowPowerMode);
        } else if (batteryLevel < 0.4) {
            return MakeCounts(PhotoUploadConcurrentCountInBatteryLevelBelow40, VideoUploadConcurrentCountInBatteryLevelBelow40);
        } else if (batteryLevel < 0.55) {
            return MakeCounts(PhotoUploadConcurrentCountInBatteryLevelBelow55, VideoUploadConcurrentCountInBatteryLevelBelow55);
        } else if (batteryLevel < 0.75) {
            return MakeCounts(PhotoUploadConcurrentCountInBatteryLevelBelow75, VideoUploadConcurrentCountInBatteryLevelBelow75);
        } else {
            return MakeCounts(PhotoUploadConcurrentCountInForeground, VideoUploadConcurrentCountInForeground);
        }
    } else {
        return MakeCounts(PhotoUploadConcurrentCountInBatteryCharging, VideoUploadConcurrentCountInBatteryCharging);
    }
}

- (CameraUploadConcurrentCounts)concurrentCountsByThermalState API_AVAILABLE(ios(11.0)) {
    switch (NSProcessInfo.processInfo.thermalState) {
        case NSProcessInfoThermalStateCritical:
            return MakeCounts(PhotoUploadConcurrentCountInThermalStateCritical, VideoUploadConcurrentCountInThermalStateCritical);
            break;
        case NSProcessInfoThermalStateSerious:
            return MakeCounts(PhotoUploadConcurrentCountInThermalStateSerious, VideoUploadConcurrentCountInThermalStateSerious);
            break;
        case NSProcessInfoThermalStateFair:
            return MakeCounts(PhotoUploadConcurrentCountInThermalStateFair, VideoUploadConcurrentCountInThermalStateFair);
            break;
        case NSProcessInfoThermalStateNominal:
            return MakeCounts(PhotoUploadConcurrentCountDefaultMaximum, VideoUploadConcurrentCountDefaultMaximum);
            break;
    }
}

@end
