
#import <XCTest/XCTest.h>
#import "CameraUploadConcurrentCountCalculator.h"

@interface CameraUploadConcurrentCountCalculationTestsForiOSBelow11 : XCTestCase

@property (strong, nonatomic) CameraUploadConcurrentCountCalculator *calculator;
@property (strong, nonatomic) NSArray<NSNumber *> *nonBackgroundStates;
@property (strong, nonatomic) NSArray<NSNumber *> *batteryNonUnpluggedStates;

@end

@implementation CameraUploadConcurrentCountCalculationTestsForiOSBelow11

- (void)setUp {
    [super setUp];
    self.calculator = [[CameraUploadConcurrentCountCalculator alloc] init];
    self.nonBackgroundStates = @[@(UIApplicationStateActive), @(UIApplicationStateInactive)];
    self.batteryNonUnpluggedStates = @[@(UIDeviceBatteryStateCharging), @(UIDeviceBatteryStateUnknown), @(UIDeviceBatteryStateFull)];
}

#pragma mark - Non-background state

- (void)testConcurrentCountsWith_NonBackground_BatteryUnplugged_LowPowerModeEnabled {
    for (NSNumber *appState in self.nonBackgroundStates) {
        CameraUploadConcurrentCounts counts = [self.calculator calculateCameraUploadConcurrentCountsByApplicationState:appState.integerValue batteryState:UIDeviceBatteryStateUnplugged batteryLevel:.1 isLowPowerModeEnabled:YES];
        XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBatteryLevelBelow15);
        XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBatteryLevelBelow15);
        
        counts = [self.calculator calculateCameraUploadConcurrentCountsByApplicationState:appState.integerValue batteryState:UIDeviceBatteryStateUnplugged batteryLevel:.2 isLowPowerModeEnabled:YES];
        XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBatteryLevelBelow25);
        XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBatteryLevelBelow25);
        
        counts = [self.calculator calculateCameraUploadConcurrentCountsByApplicationState:appState.integerValue batteryState:UIDeviceBatteryStateUnplugged batteryLevel:.3 isLowPowerModeEnabled:YES];
        XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInLowPowerMode);
        XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInLowPowerMode);
        
        counts = [self.calculator calculateCameraUploadConcurrentCountsByApplicationState:appState.integerValue batteryState:UIDeviceBatteryStateUnplugged batteryLevel:.45 isLowPowerModeEnabled:YES];
        XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInLowPowerMode);
        XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInLowPowerMode);
        
        counts = [self.calculator calculateCameraUploadConcurrentCountsByApplicationState:appState.integerValue batteryState:UIDeviceBatteryStateUnplugged batteryLevel:.6 isLowPowerModeEnabled:YES];
        XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInLowPowerMode);
        XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInLowPowerMode);
        
        counts = [self.calculator calculateCameraUploadConcurrentCountsByApplicationState:appState.integerValue batteryState:UIDeviceBatteryStateUnplugged batteryLevel:.8 isLowPowerModeEnabled:YES];
        XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInLowPowerMode);
        XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInLowPowerMode);
        
        counts = [self.calculator calculateCameraUploadConcurrentCountsByApplicationState:appState.integerValue batteryState:UIDeviceBatteryStateUnplugged batteryLevel:1 isLowPowerModeEnabled:YES];
        XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInLowPowerMode);
        XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInLowPowerMode);
    }
}

- (void)testConcurrentCountsWith_NonBackground_BatteryUnplugged_LowPowerModeNotEnabled {
    for (NSNumber *appState in self.nonBackgroundStates) {
        CameraUploadConcurrentCounts counts = [self.calculator calculateCameraUploadConcurrentCountsByApplicationState:appState.integerValue batteryState:UIDeviceBatteryStateUnplugged batteryLevel:.1 isLowPowerModeEnabled:NO];
        XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBatteryLevelBelow15);
        XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBatteryLevelBelow15);
        
        counts = [self.calculator calculateCameraUploadConcurrentCountsByApplicationState:appState.integerValue batteryState:UIDeviceBatteryStateUnplugged batteryLevel:.2 isLowPowerModeEnabled:NO];
        XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBatteryLevelBelow25);
        XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBatteryLevelBelow25);
        
        counts = [self.calculator calculateCameraUploadConcurrentCountsByApplicationState:appState.integerValue batteryState:UIDeviceBatteryStateUnplugged batteryLevel:.3 isLowPowerModeEnabled:NO];
        XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBatteryLevelBelow40);
        XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBatteryLevelBelow40);
        
        counts = [self.calculator calculateCameraUploadConcurrentCountsByApplicationState:appState.integerValue batteryState:UIDeviceBatteryStateUnplugged batteryLevel:.45 isLowPowerModeEnabled:NO];
        XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBatteryLevelBelow55);
        XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBatteryLevelBelow55);
        
        counts = [self.calculator calculateCameraUploadConcurrentCountsByApplicationState:appState.integerValue batteryState:UIDeviceBatteryStateUnplugged batteryLevel:.6 isLowPowerModeEnabled:NO];
        XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBatteryLevelBelow75);
        XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBatteryLevelBelow75);
        
        counts = [self.calculator calculateCameraUploadConcurrentCountsByApplicationState:appState.integerValue batteryState:UIDeviceBatteryStateUnplugged batteryLevel:.8 isLowPowerModeEnabled:NO];
        XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBatteryLevel75OrAbove);
        XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBatteryLevel75OrAbove);
        
        counts = [self.calculator calculateCameraUploadConcurrentCountsByApplicationState:appState.integerValue batteryState:UIDeviceBatteryStateUnplugged batteryLevel:1 isLowPowerModeEnabled:NO];
        XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBatteryLevel75OrAbove);
        XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBatteryLevel75OrAbove);
    }
}

- (void)testConcurrentCountsWith_NonBackground_BatteryNonUnplugged_LowPowerModeEnabled {
    for (NSNumber *appState in self.nonBackgroundStates) {
        for (NSNumber *batteryState in self.batteryNonUnpluggedStates) {
            CameraUploadConcurrentCounts counts = [self.calculator calculateCameraUploadConcurrentCountsByApplicationState:appState.integerValue batteryState:batteryState.integerValue batteryLevel:.1 isLowPowerModeEnabled:YES];
            XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBatteryCharging);
            XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBatteryCharging);
            
            counts = [self.calculator calculateCameraUploadConcurrentCountsByApplicationState:appState.integerValue batteryState:batteryState.integerValue batteryLevel:.2 isLowPowerModeEnabled:YES];
            XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBatteryCharging);
            XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBatteryCharging);
            
            counts = [self.calculator calculateCameraUploadConcurrentCountsByApplicationState:appState.integerValue batteryState:batteryState.integerValue batteryLevel:.3 isLowPowerModeEnabled:YES];
            XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBatteryCharging);
            XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBatteryCharging);
            
            counts = [self.calculator calculateCameraUploadConcurrentCountsByApplicationState:appState.integerValue batteryState:batteryState.integerValue batteryLevel:.45 isLowPowerModeEnabled:YES];
            XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBatteryCharging);
            XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBatteryCharging);
            
            counts = [self.calculator calculateCameraUploadConcurrentCountsByApplicationState:appState.integerValue batteryState:batteryState.integerValue batteryLevel:.6 isLowPowerModeEnabled:YES];
            XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBatteryCharging);
            XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBatteryCharging);
            
            counts = [self.calculator calculateCameraUploadConcurrentCountsByApplicationState:appState.integerValue batteryState:batteryState.integerValue batteryLevel:.8 isLowPowerModeEnabled:YES];
            XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBatteryCharging);
            XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBatteryCharging);
            
            counts = [self.calculator calculateCameraUploadConcurrentCountsByApplicationState:appState.integerValue batteryState:batteryState.integerValue batteryLevel:1 isLowPowerModeEnabled:YES];
            XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBatteryCharging);
            XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBatteryCharging);
        }
    }
}

- (void)testConcurrentCountsWith_NonBackground_BatteryNonUnplugged_LowPowerModeNotEnabled {
    for (NSNumber *appState in self.nonBackgroundStates) {
        for (NSNumber *batteryState in self.batteryNonUnpluggedStates) {
            CameraUploadConcurrentCounts counts = [self.calculator calculateCameraUploadConcurrentCountsByApplicationState:appState.integerValue batteryState:batteryState.integerValue batteryLevel:.1 isLowPowerModeEnabled:NO];
            XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBatteryCharging);
            XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBatteryCharging);
            
            counts = [self.calculator calculateCameraUploadConcurrentCountsByApplicationState:appState.integerValue batteryState:batteryState.integerValue batteryLevel:.2 isLowPowerModeEnabled:NO];
            XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBatteryCharging);
            XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBatteryCharging);
            
            counts = [self.calculator calculateCameraUploadConcurrentCountsByApplicationState:appState.integerValue batteryState:batteryState.integerValue batteryLevel:.3 isLowPowerModeEnabled:NO];
            XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBatteryCharging);
            XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBatteryCharging);
            
            counts = [self.calculator calculateCameraUploadConcurrentCountsByApplicationState:appState.integerValue batteryState:batteryState.integerValue batteryLevel:.45 isLowPowerModeEnabled:NO];
            XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBatteryCharging);
            XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBatteryCharging);
            
            counts = [self.calculator calculateCameraUploadConcurrentCountsByApplicationState:appState.integerValue batteryState:batteryState.integerValue batteryLevel:.6 isLowPowerModeEnabled:NO];
            XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBatteryCharging);
            XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBatteryCharging);
            
            counts = [self.calculator calculateCameraUploadConcurrentCountsByApplicationState:appState.integerValue batteryState:batteryState.integerValue batteryLevel:.8 isLowPowerModeEnabled:NO];
            XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBatteryCharging);
            XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBatteryCharging);
            
            counts = [self.calculator calculateCameraUploadConcurrentCountsByApplicationState:appState.integerValue batteryState:batteryState.integerValue batteryLevel:1 isLowPowerModeEnabled:NO];
            XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBatteryCharging);
            XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBatteryCharging);
        }
    }
}

#pragma mark - background state

- (void)testConcurrentCountsWith_Background_BatteryUnplugged_LowPowerModeEnabled {
    CameraUploadConcurrentCounts counts = [self.calculator calculateCameraUploadConcurrentCountsByApplicationState:UIApplicationStateBackground batteryState:UIDeviceBatteryStateUnplugged batteryLevel:.1 isLowPowerModeEnabled:YES];
    XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBatteryLevelBelow15);
    XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBatteryLevelBelow15);
    
    counts = [self.calculator calculateCameraUploadConcurrentCountsByApplicationState:UIApplicationStateBackground batteryState:UIDeviceBatteryStateUnplugged batteryLevel:.2 isLowPowerModeEnabled:YES];
    XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBatteryLevelBelow25);
    XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBatteryLevelBelow25);
    
    counts = [self.calculator calculateCameraUploadConcurrentCountsByApplicationState:UIApplicationStateBackground batteryState:UIDeviceBatteryStateUnplugged batteryLevel:.3 isLowPowerModeEnabled:YES];
    XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBackground);
    XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBackground);
    
    counts = [self.calculator calculateCameraUploadConcurrentCountsByApplicationState:UIApplicationStateBackground batteryState:UIDeviceBatteryStateUnplugged batteryLevel:.45 isLowPowerModeEnabled:YES];
    XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBackground);
    XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBackground);
    
    counts = [self.calculator calculateCameraUploadConcurrentCountsByApplicationState:UIApplicationStateBackground batteryState:UIDeviceBatteryStateUnplugged batteryLevel:.6 isLowPowerModeEnabled:YES];
    XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBackground);
    XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBackground);
    
    counts = [self.calculator calculateCameraUploadConcurrentCountsByApplicationState:UIApplicationStateBackground batteryState:UIDeviceBatteryStateUnplugged batteryLevel:.8 isLowPowerModeEnabled:YES];
    XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBackground);
    XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBackground);
    
    counts = [self.calculator calculateCameraUploadConcurrentCountsByApplicationState:UIApplicationStateBackground batteryState:UIDeviceBatteryStateUnplugged batteryLevel:1 isLowPowerModeEnabled:YES];
    XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBackground);
    XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBackground);
}

- (void)testConcurrentCountsWith_Background_BatteryUnplugged_LowPowerModeNotEnabled {
    CameraUploadConcurrentCounts counts = [self.calculator calculateCameraUploadConcurrentCountsByApplicationState:UIApplicationStateBackground batteryState:UIDeviceBatteryStateUnplugged batteryLevel:.1 isLowPowerModeEnabled:NO];
    XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBatteryLevelBelow15);
    XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBatteryLevelBelow15);
    
    counts = [self.calculator calculateCameraUploadConcurrentCountsByApplicationState:UIApplicationStateBackground batteryState:UIDeviceBatteryStateUnplugged batteryLevel:.2 isLowPowerModeEnabled:NO];
    XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBatteryLevelBelow25);
    XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBatteryLevelBelow25);
    
    counts = [self.calculator calculateCameraUploadConcurrentCountsByApplicationState:UIApplicationStateBackground batteryState:UIDeviceBatteryStateUnplugged batteryLevel:.3 isLowPowerModeEnabled:NO];
    XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBackground);
    XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBackground);
    
    counts = [self.calculator calculateCameraUploadConcurrentCountsByApplicationState:UIApplicationStateBackground batteryState:UIDeviceBatteryStateUnplugged batteryLevel:.45 isLowPowerModeEnabled:NO];
    XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBackground);
    XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBackground);
    
    counts = [self.calculator calculateCameraUploadConcurrentCountsByApplicationState:UIApplicationStateBackground batteryState:UIDeviceBatteryStateUnplugged batteryLevel:.6 isLowPowerModeEnabled:NO];
    XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBackground);
    XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBackground);
    
    counts = [self.calculator calculateCameraUploadConcurrentCountsByApplicationState:UIApplicationStateBackground batteryState:UIDeviceBatteryStateUnplugged batteryLevel:.8 isLowPowerModeEnabled:NO];
    XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBackground);
    XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBackground);
    
    counts = [self.calculator calculateCameraUploadConcurrentCountsByApplicationState:UIApplicationStateBackground batteryState:UIDeviceBatteryStateUnplugged batteryLevel:1 isLowPowerModeEnabled:NO];
    XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBackground);
    XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBackground);
}

- (void)testConcurrentCountsWith_Background_BatteryNonUnplugged_LowPowerModeEnabled {
    for (NSNumber *batteryState in self.batteryNonUnpluggedStates) {
        CameraUploadConcurrentCounts counts = [self.calculator calculateCameraUploadConcurrentCountsByApplicationState:UIApplicationStateBackground batteryState:batteryState.integerValue batteryLevel:.1 isLowPowerModeEnabled:YES];
        XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBackground);
        XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBackground);
        
        counts = [self.calculator calculateCameraUploadConcurrentCountsByApplicationState:UIApplicationStateBackground batteryState:batteryState.integerValue batteryLevel:.2 isLowPowerModeEnabled:YES];
        XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBackground);
        XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBackground);
        
        counts = [self.calculator calculateCameraUploadConcurrentCountsByApplicationState:UIApplicationStateBackground batteryState:batteryState.integerValue batteryLevel:.3 isLowPowerModeEnabled:YES];
        XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBackground);
        XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBackground);
        
        counts = [self.calculator calculateCameraUploadConcurrentCountsByApplicationState:UIApplicationStateBackground batteryState:batteryState.integerValue batteryLevel:.45 isLowPowerModeEnabled:YES];
        XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBackground);
        XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBackground);
        
        counts = [self.calculator calculateCameraUploadConcurrentCountsByApplicationState:UIApplicationStateBackground batteryState:batteryState.integerValue batteryLevel:.6 isLowPowerModeEnabled:YES];
        XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBackground);
        XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBackground);
        
        counts = [self.calculator calculateCameraUploadConcurrentCountsByApplicationState:UIApplicationStateBackground batteryState:batteryState.integerValue batteryLevel:.8 isLowPowerModeEnabled:YES];
        XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBackground);
        XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBackground);
        
        counts = [self.calculator calculateCameraUploadConcurrentCountsByApplicationState:UIApplicationStateBackground batteryState:batteryState.integerValue batteryLevel:1 isLowPowerModeEnabled:YES];
        XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBackground);
        XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBackground);
    }
}

- (void)testConcurrentCountsWith_Background_BatteryNonUnplugged_LowPowerModeNotEnabled {
    for (NSNumber *batteryState in self.batteryNonUnpluggedStates) {
        CameraUploadConcurrentCounts counts = [self.calculator calculateCameraUploadConcurrentCountsByApplicationState:UIApplicationStateBackground batteryState:batteryState.integerValue batteryLevel:.1 isLowPowerModeEnabled:NO];
        XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBackground);
        XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBackground);
        
        counts = [self.calculator calculateCameraUploadConcurrentCountsByApplicationState:UIApplicationStateBackground batteryState:batteryState.integerValue batteryLevel:.2 isLowPowerModeEnabled:NO];
        XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBackground);
        XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBackground);
        
        counts = [self.calculator calculateCameraUploadConcurrentCountsByApplicationState:UIApplicationStateBackground batteryState:batteryState.integerValue batteryLevel:.3 isLowPowerModeEnabled:NO];
        XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBackground);
        XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBackground);
        
        counts = [self.calculator calculateCameraUploadConcurrentCountsByApplicationState:UIApplicationStateBackground batteryState:batteryState.integerValue batteryLevel:.45 isLowPowerModeEnabled:NO];
        XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBackground);
        XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBackground);
        
        counts = [self.calculator calculateCameraUploadConcurrentCountsByApplicationState:UIApplicationStateBackground batteryState:batteryState.integerValue batteryLevel:.6 isLowPowerModeEnabled:NO];
        XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBackground);
        XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBackground);
        
        counts = [self.calculator calculateCameraUploadConcurrentCountsByApplicationState:UIApplicationStateBackground batteryState:batteryState.integerValue batteryLevel:.8 isLowPowerModeEnabled:NO];
        XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBackground);
        XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBackground);
        
        counts = [self.calculator calculateCameraUploadConcurrentCountsByApplicationState:UIApplicationStateBackground batteryState:batteryState.integerValue batteryLevel:1 isLowPowerModeEnabled:NO];
        XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBackground);
        XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBackground);
    }
}

@end
