
#import "CameraUploadConcurrentCountCalculator.h"
#import "MEGAConstants.h"

typedef struct {
    PhotoUploadConcurrentCount photoConcurrentCount;
    VideoUploadConcurrentCount videoConcurrentCount;
} CameraUploadConcurrentCount;

static CameraUploadConcurrentCount MakeCount(PhotoUploadConcurrentCount photoCount, VideoUploadConcurrentCount videoCount) {
    CameraUploadConcurrentCount concurrentCount;
    concurrentCount.photoConcurrentCount = photoCount;
    concurrentCount.videoConcurrentCount = videoCount;
    return concurrentCount;
}

@interface CameraUploadConcurrentCountCalculator ()

@property (nonatomic) CameraUploadConcurrentCount currentConcurrentCount;

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
    MEGALogDebug(@"[Camera Upload] concurrent calculator received %@", notification);
    CameraUploadConcurrentCount concurrentCount = [self calculateCameraUploadConcurrentCount];
    if (concurrentCount.photoConcurrentCount != self.currentConcurrentCount.photoConcurrentCount) {
        [NSNotificationCenter.defaultCenter postNotificationName:MEGACameraUploadPhotoConcurrentCountChangedNotificationName object:self userInfo:@{MEGAPhotoConcurrentCountUserInfoKey : @(concurrentCount.photoConcurrentCount)}];
    }
    
    if (concurrentCount.videoConcurrentCount != self.currentConcurrentCount.videoConcurrentCount) {
        [NSNotificationCenter.defaultCenter postNotificationName:MEGACameraUploadVideoConcurrentCountChangedNotificationName object:self userInfo:@{MEGAVideoConcurrentCountUserInfoKey : @(concurrentCount.videoConcurrentCount)}];
    }
    
    self.currentConcurrentCount = concurrentCount;
}

#pragma mark - concurrent count calculation

- (PhotoUploadConcurrentCount)calculatePhotoUploadConcurrentCount {
    self.currentConcurrentCount = [self calculateCameraUploadConcurrentCount];
    return self.currentConcurrentCount.photoConcurrentCount;
}

- (VideoUploadConcurrentCount)calculateVideoUploadConcurrentCount {
    self.currentConcurrentCount = [self calculateCameraUploadConcurrentCount];
    return self.currentConcurrentCount.videoConcurrentCount;
}

- (CameraUploadConcurrentCount)calculateCameraUploadConcurrentCount {
    if (@available(iOS 11.0, *)) {
        if (NSProcessInfo.processInfo.thermalState == NSProcessInfoThermalStateCritical) {
            return MakeCount(PhotoUploadConcurrentCountInThermalStateCritical, VideoUploadConcurrentCountInThermalStateCritical);
        }
    }
    
    UIDeviceBatteryState batteryState = UIDevice.currentDevice.batteryState;
    if (batteryState == UIDeviceBatteryStateUnplugged) {
        float batteryLevel = UIDevice.currentDevice.batteryLevel;
        if (batteryLevel < 0.1) {
            return MakeCount(PhotoUploadConcurrentCountInBatteryLevelBelow10, VideoUploadConcurrentCountInBatteryLevelBelow10);
        }
        
        if (batteryLevel < 0.2) {
            return MakeCount(PhotoUploadConcurrentCountInBatteryLevelBelow20, VideoUploadConcurrentCountInBatteryLevelBelow20);
        }
        
        if (@available(iOS 11.0, *)) {
            if (NSProcessInfo.processInfo.thermalState == NSProcessInfoThermalStateSerious) {
                return MakeCount(PhotoUploadConcurrentCountInThermalStateSerious, VideoUploadConcurrentCountInThermalStateSerious);
            }
        }
        
        if (NSProcessInfo.processInfo.isLowPowerModeEnabled) {
            return MakeCount(PhotoUploadConcurrentCountInLowPowerMode, VideoUploadConcurrentCountInLowPowerMode);
        }
        
        if (batteryLevel < 0.35) {
            return MakeCount(PhotoUploadConcurrentCountInBatteryLevelBelow35, VideoUploadConcurrentCountInBatteryLevelBelow35);
        }
        
        if (batteryLevel < 0.55) {
            return MakeCount(PhotoUploadConcurrentCountInBatteryLevelBelow55, VideoUploadConcurrentCountInBatteryLevelBelow55);
        }
        
        if (@available(iOS 11.0, *)) {
            if (NSProcessInfo.processInfo.thermalState == NSProcessInfoThermalStateFair) {
                return MakeCount(PhotoUploadConcurrentCountInThermalStateFair, VideoUploadConcurrentCountInThermalStateFair);
            }
        }
        
        if (batteryLevel < 0.75) {
            return MakeCount(PhotoUploadConcurrentCountInBatteryLevelBelow75, VideoUploadConcurrentCountInBatteryLevelBelow75);
        }
        
        if (UIApplication.sharedApplication.applicationState == UIApplicationStateBackground) {
            return MakeCount(PhotoUploadConcurrentCountInBackground, VideoUploadConcurrentCountInBackground);
        } else {
            return MakeCount(PhotoUploadConcurrentCountInForeground, VideoUploadConcurrentCountInForeground);
        }
    } else {
        if (@available(iOS 11.0, *)) {
            NSProcessInfoThermalState thermalState = NSProcessInfo.processInfo.thermalState;
            if (thermalState == NSProcessInfoThermalStateSerious) {
                return MakeCount(PhotoUploadConcurrentCountInThermalStateSerious, VideoUploadConcurrentCountInThermalStateSerious);
            } else if (thermalState == NSProcessInfoThermalStateFair) {
                return MakeCount(PhotoUploadConcurrentCountInThermalStateFair, VideoUploadConcurrentCountInThermalStateFair);
            }
        }
        
        if (UIApplication.sharedApplication.applicationState == UIApplicationStateBackground) {
            return MakeCount(PhotoUploadConcurrentCountInBackground, VideoUploadConcurrentCountInBackground);
        } else {
            return MakeCount(PhotoUploadConcurrentCountInBatteryCharging, VideoUploadConcurrentCountInBatteryCharging);
        }
    }
}

@end
