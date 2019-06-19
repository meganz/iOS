
#import <XCTest/XCTest.h>
#import "CameraUploadConcurrentCountCalculator.h"

API_AVAILABLE(ios(11.0))
@interface CameraUploadConcurrentCountCalculationTestsForiOS11OrAbove : XCTestCase

@property (strong, nonatomic) CameraUploadConcurrentCountCalculator *calculator;
@property (strong, nonatomic) NSArray<NSNumber *> *nonBackgroundStates;
@property (strong, nonatomic) NSArray<NSNumber *> *batteryNonUnpluggedStates;
@property (strong, nonatomic) NSArray<NSNumber *> *thermalStates;

@end

@implementation CameraUploadConcurrentCountCalculationTestsForiOS11OrAbove

- (void)setUp {
    [super setUp];
    self.calculator = [[CameraUploadConcurrentCountCalculator alloc] init];
    self.nonBackgroundStates = @[@(UIApplicationStateActive), @(UIApplicationStateInactive)];
    self.batteryNonUnpluggedStates = @[@(UIDeviceBatteryStateCharging), @(UIDeviceBatteryStateUnknown), @(UIDeviceBatteryStateFull)];
    self.thermalStates = @[@(NSProcessInfoThermalStateCritical), @(NSProcessInfoThermalStateSerious), @(NSProcessInfoThermalStateFair), @(NSProcessInfoThermalStateNominal)];
}

#pragma mark - Non-background state

- (void)testConcurrentCountsWith_NonBackground_BatteryUnplugged_LowPowerModeEnabled {
    for (NSNumber *appState in self.nonBackgroundStates) {
        for (NSNumber *thermalState in self.thermalStates) {
            CameraUploadConcurrentCounts counts = [self.calculator calculateCameraUploadConcurrentCountsByThermalState:thermalState.integerValue applicationState:appState.integerValue batteryState:UIDeviceBatteryStateUnplugged batteryLevel:.1 isLowPowerModeEnabled:YES];
            switch (thermalState.integerValue) {
                case NSProcessInfoThermalStateCritical:
                    XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateCritical);
                    XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateCritical);
                    break;
                case NSProcessInfoThermalStateSerious:
                    XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBatteryLevelBelow15);
                    XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBatteryLevelBelow15);
                    break;
                case NSProcessInfoThermalStateFair:
                    XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBatteryLevelBelow15);
                    XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBatteryLevelBelow15);
                    break;
                case NSProcessInfoThermalStateNominal:
                    XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBatteryLevelBelow15);
                    XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBatteryLevelBelow15);
                    break;
            }
            
            counts = [self.calculator calculateCameraUploadConcurrentCountsByThermalState:thermalState.integerValue applicationState:appState.integerValue batteryState:UIDeviceBatteryStateUnplugged batteryLevel:.2 isLowPowerModeEnabled:YES];
            switch (thermalState.integerValue) {
                case NSProcessInfoThermalStateCritical:
                    XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateCritical);
                    XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateCritical);
                    break;
                case NSProcessInfoThermalStateSerious:
                    XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBatteryLevelBelow25);
                    XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateSerious);
                    break;
                case NSProcessInfoThermalStateFair:
                    XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBatteryLevelBelow25);
                    XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBatteryLevelBelow25);
                    break;
                case NSProcessInfoThermalStateNominal:
                    XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBatteryLevelBelow25);
                    XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBatteryLevelBelow25);
                    break;
            }
            
            counts = [self.calculator calculateCameraUploadConcurrentCountsByThermalState:thermalState.integerValue applicationState:appState.integerValue batteryState:UIDeviceBatteryStateUnplugged batteryLevel:.3 isLowPowerModeEnabled:YES];
            switch (thermalState.integerValue) {
                case NSProcessInfoThermalStateCritical:
                    XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateCritical);
                    XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateCritical);
                    break;
                case NSProcessInfoThermalStateSerious:
                    XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateSerious);
                    XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateSerious);
                    break;
                case NSProcessInfoThermalStateFair:
                    XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInLowPowerMode);
                    XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInLowPowerMode);
                    break;
                case NSProcessInfoThermalStateNominal:
                    XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInLowPowerMode);
                    XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInLowPowerMode);
                    break;
            }
            
            counts = [self.calculator calculateCameraUploadConcurrentCountsByThermalState:thermalState.integerValue applicationState:appState.integerValue batteryState:UIDeviceBatteryStateUnplugged batteryLevel:.45 isLowPowerModeEnabled:YES];
            switch (thermalState.integerValue) {
                case NSProcessInfoThermalStateCritical:
                    XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateCritical);
                    XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateCritical);
                    break;
                case NSProcessInfoThermalStateSerious:
                    XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateSerious);
                    XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateSerious);
                    break;
                case NSProcessInfoThermalStateFair:
                    XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInLowPowerMode);
                    XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInLowPowerMode);
                    break;
                case NSProcessInfoThermalStateNominal:
                    XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInLowPowerMode);
                    XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInLowPowerMode);
                    break;
            }
            
            counts = [self.calculator calculateCameraUploadConcurrentCountsByThermalState:thermalState.integerValue applicationState:appState.integerValue batteryState:UIDeviceBatteryStateUnplugged batteryLevel:.6 isLowPowerModeEnabled:YES];
            switch (thermalState.integerValue) {
                case NSProcessInfoThermalStateCritical:
                    XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateCritical);
                    XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateCritical);
                    break;
                case NSProcessInfoThermalStateSerious:
                    XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateSerious);
                    XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateSerious);
                    break;
                case NSProcessInfoThermalStateFair:
                    XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInLowPowerMode);
                    XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInLowPowerMode);
                    break;
                case NSProcessInfoThermalStateNominal:
                    XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInLowPowerMode);
                    XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInLowPowerMode);
                    break;
            }
            
            counts = [self.calculator calculateCameraUploadConcurrentCountsByThermalState:thermalState.integerValue applicationState:appState.integerValue batteryState:UIDeviceBatteryStateUnplugged batteryLevel:.8 isLowPowerModeEnabled:YES];
            switch (thermalState.integerValue) {
                case NSProcessInfoThermalStateCritical:
                    XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateCritical);
                    XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateCritical);
                    break;
                case NSProcessInfoThermalStateSerious:
                    XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateSerious);
                    XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateSerious);
                    break;
                case NSProcessInfoThermalStateFair:
                    XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInLowPowerMode);
                    XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInLowPowerMode);
                    break;
                case NSProcessInfoThermalStateNominal:
                    XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInLowPowerMode);
                    XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInLowPowerMode);
                    break;
            }
            
            counts = [self.calculator calculateCameraUploadConcurrentCountsByThermalState:thermalState.integerValue applicationState:appState.integerValue batteryState:UIDeviceBatteryStateUnplugged batteryLevel:1 isLowPowerModeEnabled:YES];
            switch (thermalState.integerValue) {
                case NSProcessInfoThermalStateCritical:
                    XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateCritical);
                    XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateCritical);
                    break;
                case NSProcessInfoThermalStateSerious:
                    XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateSerious);
                    XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateSerious);
                    break;
                case NSProcessInfoThermalStateFair:
                    XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInLowPowerMode);
                    XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInLowPowerMode);
                    break;
                case NSProcessInfoThermalStateNominal:
                    XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInLowPowerMode);
                    XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInLowPowerMode);
                    break;
            }
        }
    }
}

- (void)testConcurrentCountsWith_NonBackground_BatteryUnplugged_LowPowerModeNotEnabled {
    for (NSNumber *appState in self.nonBackgroundStates) {
        for (NSNumber *thermalState in self.thermalStates) {
            CameraUploadConcurrentCounts counts = [self.calculator calculateCameraUploadConcurrentCountsByThermalState:thermalState.integerValue applicationState:appState.integerValue batteryState:UIDeviceBatteryStateUnplugged batteryLevel:.1 isLowPowerModeEnabled:NO];
            switch (thermalState.integerValue) {
                case NSProcessInfoThermalStateCritical:
                    XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateCritical);
                    XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateCritical);
                    break;
                case NSProcessInfoThermalStateSerious:
                    XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBatteryLevelBelow15);
                    XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBatteryLevelBelow15);
                    break;
                case NSProcessInfoThermalStateFair:
                    XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBatteryLevelBelow15);
                    XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBatteryLevelBelow15);
                    break;
                case NSProcessInfoThermalStateNominal:
                    XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBatteryLevelBelow15);
                    XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBatteryLevelBelow15);
                    break;
            }
            
            counts = [self.calculator calculateCameraUploadConcurrentCountsByThermalState:thermalState.integerValue applicationState:appState.integerValue batteryState:UIDeviceBatteryStateUnplugged batteryLevel:.2 isLowPowerModeEnabled:NO];
            switch (thermalState.integerValue) {
                case NSProcessInfoThermalStateCritical:
                    XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateCritical);
                    XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateCritical);
                    break;
                case NSProcessInfoThermalStateSerious:
                    XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBatteryLevelBelow25);
                    XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateSerious);
                    break;
                case NSProcessInfoThermalStateFair:
                    XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBatteryLevelBelow25);
                    XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBatteryLevelBelow25);
                    break;
                case NSProcessInfoThermalStateNominal:
                    XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBatteryLevelBelow25);
                    XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBatteryLevelBelow25);
                    break;
            }
            
            counts = [self.calculator calculateCameraUploadConcurrentCountsByThermalState:thermalState.integerValue applicationState:appState.integerValue batteryState:UIDeviceBatteryStateUnplugged batteryLevel:.3 isLowPowerModeEnabled:NO];
            switch (thermalState.integerValue) {
                case NSProcessInfoThermalStateCritical:
                    XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateCritical);
                    XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateCritical);
                    break;
                case NSProcessInfoThermalStateSerious:
                    XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateSerious);
                    XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateSerious);
                    break;
                case NSProcessInfoThermalStateFair:
                    XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBatteryLevelBelow40);
                    XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBatteryLevelBelow40);
                    break;
                case NSProcessInfoThermalStateNominal:
                    XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBatteryLevelBelow40);
                    XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBatteryLevelBelow40);
                    break;
            }
            
            counts = [self.calculator calculateCameraUploadConcurrentCountsByThermalState:thermalState.integerValue applicationState:appState.integerValue batteryState:UIDeviceBatteryStateUnplugged batteryLevel:.45 isLowPowerModeEnabled:NO];
            switch (thermalState.integerValue) {
                case NSProcessInfoThermalStateCritical:
                    XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateCritical);
                    XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateCritical);
                    break;
                case NSProcessInfoThermalStateSerious:
                    XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateSerious);
                    XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateSerious);
                    break;
                case NSProcessInfoThermalStateFair:
                    XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBatteryLevelBelow55);
                    XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBatteryLevelBelow55);
                    break;
                case NSProcessInfoThermalStateNominal:
                    XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBatteryLevelBelow55);
                    XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBatteryLevelBelow55);
                    break;
            }
            
            counts = [self.calculator calculateCameraUploadConcurrentCountsByThermalState:thermalState.integerValue applicationState:appState.integerValue batteryState:UIDeviceBatteryStateUnplugged batteryLevel:.6 isLowPowerModeEnabled:NO];
            switch (thermalState.integerValue) {
                case NSProcessInfoThermalStateCritical:
                    XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateCritical);
                    XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateCritical);
                    break;
                case NSProcessInfoThermalStateSerious:
                    XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateSerious);
                    XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateSerious);
                    break;
                case NSProcessInfoThermalStateFair:
                    XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateFair);
                    XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateFair);
                    break;
                case NSProcessInfoThermalStateNominal:
                    XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBatteryLevelBelow75);
                    XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBatteryLevelBelow75);
                    break;
            }
            
            counts = [self.calculator calculateCameraUploadConcurrentCountsByThermalState:thermalState.integerValue applicationState:appState.integerValue batteryState:UIDeviceBatteryStateUnplugged batteryLevel:.8 isLowPowerModeEnabled:NO];
            switch (thermalState.integerValue) {
                case NSProcessInfoThermalStateCritical:
                    XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateCritical);
                    XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateCritical);
                    break;
                case NSProcessInfoThermalStateSerious:
                    XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateSerious);
                    XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateSerious);
                    break;
                case NSProcessInfoThermalStateFair:
                    XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateFair);
                    XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateFair);
                    break;
                case NSProcessInfoThermalStateNominal:
                    XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBatteryLevel75OrAbove);
                    XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBatteryLevel75OrAbove);
                    break;
            }
            
            counts = [self.calculator calculateCameraUploadConcurrentCountsByThermalState:thermalState.integerValue applicationState:appState.integerValue batteryState:UIDeviceBatteryStateUnplugged batteryLevel:1 isLowPowerModeEnabled:NO];
            switch (thermalState.integerValue) {
                case NSProcessInfoThermalStateCritical:
                    XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateCritical);
                    XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateCritical);
                    break;
                case NSProcessInfoThermalStateSerious:
                    XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateSerious);
                    XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateSerious);
                    break;
                case NSProcessInfoThermalStateFair:
                    XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateFair);
                    XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateFair);
                    break;
                case NSProcessInfoThermalStateNominal:
                    XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBatteryLevel75OrAbove);
                    XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBatteryLevel75OrAbove);
                    break;
            }
        }
    }
}

- (void)testConcurrentCountsWith_NonBackground_BatteryNonUnplugged_LowPowerModeEnabled {
    for (NSNumber *appState in self.nonBackgroundStates) {
        for (NSNumber *thermalState in self.thermalStates) {
            for (NSNumber *batteryState in self.batteryNonUnpluggedStates) {
                CameraUploadConcurrentCounts counts = [self.calculator calculateCameraUploadConcurrentCountsByThermalState:thermalState.integerValue applicationState:appState.integerValue batteryState:batteryState.integerValue batteryLevel:.1 isLowPowerModeEnabled:YES];
                switch (thermalState.integerValue) {
                    case NSProcessInfoThermalStateCritical:
                        XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateCritical);
                        XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateCritical);
                        break;
                    case NSProcessInfoThermalStateSerious:
                        XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateSerious);
                        XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateSerious);
                        break;
                    case NSProcessInfoThermalStateFair:
                        XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateFair);
                        XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateFair);
                        break;
                    case NSProcessInfoThermalStateNominal:
                        XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBatteryCharging);
                        XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBatteryCharging);
                        break;
                }
                
                counts = [self.calculator calculateCameraUploadConcurrentCountsByThermalState:thermalState.integerValue applicationState:appState.integerValue batteryState:batteryState.integerValue batteryLevel:.2 isLowPowerModeEnabled:YES];
                switch (thermalState.integerValue) {
                    case NSProcessInfoThermalStateCritical:
                        XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateCritical);
                        XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateCritical);
                        break;
                    case NSProcessInfoThermalStateSerious:
                        XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateSerious);
                        XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateSerious);
                        break;
                    case NSProcessInfoThermalStateFair:
                        XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateFair);
                        XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateFair);
                        break;
                    case NSProcessInfoThermalStateNominal:
                        XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBatteryCharging);
                        XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBatteryCharging);
                        break;
                }
                
                counts = [self.calculator calculateCameraUploadConcurrentCountsByThermalState:thermalState.integerValue applicationState:appState.integerValue batteryState:batteryState.integerValue batteryLevel:.3 isLowPowerModeEnabled:YES];
                switch (thermalState.integerValue) {
                    case NSProcessInfoThermalStateCritical:
                        XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateCritical);
                        XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateCritical);
                        break;
                    case NSProcessInfoThermalStateSerious:
                        XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateSerious);
                        XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateSerious);
                        break;
                    case NSProcessInfoThermalStateFair:
                        XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateFair);
                        XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateFair);
                        break;
                    case NSProcessInfoThermalStateNominal:
                        XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBatteryCharging);
                        XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBatteryCharging);
                        break;
                }
                
                counts = [self.calculator calculateCameraUploadConcurrentCountsByThermalState:thermalState.integerValue applicationState:appState.integerValue batteryState:batteryState.integerValue batteryLevel:.45 isLowPowerModeEnabled:YES];
                switch (thermalState.integerValue) {
                    case NSProcessInfoThermalStateCritical:
                        XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateCritical);
                        XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateCritical);
                        break;
                    case NSProcessInfoThermalStateSerious:
                        XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateSerious);
                        XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateSerious);
                        break;
                    case NSProcessInfoThermalStateFair:
                        XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateFair);
                        XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateFair);
                        break;
                    case NSProcessInfoThermalStateNominal:
                        XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBatteryCharging);
                        XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBatteryCharging);
                        break;
                }
                
                counts = [self.calculator calculateCameraUploadConcurrentCountsByThermalState:thermalState.integerValue applicationState:appState.integerValue batteryState:batteryState.integerValue batteryLevel:.6 isLowPowerModeEnabled:YES];
                switch (thermalState.integerValue) {
                    case NSProcessInfoThermalStateCritical:
                        XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateCritical);
                        XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateCritical);
                        break;
                    case NSProcessInfoThermalStateSerious:
                        XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateSerious);
                        XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateSerious);
                        break;
                    case NSProcessInfoThermalStateFair:
                        XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateFair);
                        XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateFair);
                        break;
                    case NSProcessInfoThermalStateNominal:
                        XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBatteryCharging);
                        XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBatteryCharging);
                        break;
                }
                
                counts = [self.calculator calculateCameraUploadConcurrentCountsByThermalState:thermalState.integerValue applicationState:appState.integerValue batteryState:batteryState.integerValue batteryLevel:.8 isLowPowerModeEnabled:YES];
                switch (thermalState.integerValue) {
                    case NSProcessInfoThermalStateCritical:
                        XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateCritical);
                        XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateCritical);
                        break;
                    case NSProcessInfoThermalStateSerious:
                        XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateSerious);
                        XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateSerious);
                        break;
                    case NSProcessInfoThermalStateFair:
                        XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateFair);
                        XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateFair);
                        break;
                    case NSProcessInfoThermalStateNominal:
                        XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBatteryCharging);
                        XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBatteryCharging);
                        break;
                }
                
                counts = [self.calculator calculateCameraUploadConcurrentCountsByThermalState:thermalState.integerValue applicationState:appState.integerValue batteryState:batteryState.integerValue batteryLevel:1 isLowPowerModeEnabled:YES];
                switch (thermalState.integerValue) {
                    case NSProcessInfoThermalStateCritical:
                        XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateCritical);
                        XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateCritical);
                        break;
                    case NSProcessInfoThermalStateSerious:
                        XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateSerious);
                        XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateSerious);
                        break;
                    case NSProcessInfoThermalStateFair:
                        XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateFair);
                        XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateFair);
                        break;
                    case NSProcessInfoThermalStateNominal:
                        XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBatteryCharging);
                        XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBatteryCharging);
                        break;
                }
            }
        }
    }
}

- (void)testConcurrentCountsWith_NonBackground_BatteryNonUnplugged_LowPowerModeNotEnabled {
    for (NSNumber *appState in self.nonBackgroundStates) {
        for (NSNumber *thermalState in self.thermalStates) {
            for (NSNumber *batteryState in self.batteryNonUnpluggedStates) {
                CameraUploadConcurrentCounts counts = [self.calculator calculateCameraUploadConcurrentCountsByThermalState:thermalState.integerValue applicationState:appState.integerValue batteryState:batteryState.integerValue batteryLevel:.1 isLowPowerModeEnabled:NO];
                switch (thermalState.integerValue) {
                    case NSProcessInfoThermalStateCritical:
                        XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateCritical);
                        XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateCritical);
                        break;
                    case NSProcessInfoThermalStateSerious:
                        XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateSerious);
                        XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateSerious);
                        break;
                    case NSProcessInfoThermalStateFair:
                        XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateFair);
                        XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateFair);
                        break;
                    case NSProcessInfoThermalStateNominal:
                        XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBatteryCharging);
                        XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBatteryCharging);
                        break;
                }
                
                counts = [self.calculator calculateCameraUploadConcurrentCountsByThermalState:thermalState.integerValue applicationState:appState.integerValue batteryState:batteryState.integerValue batteryLevel:.2 isLowPowerModeEnabled:NO];
                switch (thermalState.integerValue) {
                    case NSProcessInfoThermalStateCritical:
                        XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateCritical);
                        XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateCritical);
                        break;
                    case NSProcessInfoThermalStateSerious:
                        XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateSerious);
                        XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateSerious);
                        break;
                    case NSProcessInfoThermalStateFair:
                        XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateFair);
                        XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateFair);
                        break;
                    case NSProcessInfoThermalStateNominal:
                        XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBatteryCharging);
                        XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBatteryCharging);
                        break;
                }
                
                counts = [self.calculator calculateCameraUploadConcurrentCountsByThermalState:thermalState.integerValue applicationState:appState.integerValue batteryState:batteryState.integerValue batteryLevel:.3 isLowPowerModeEnabled:NO];
                switch (thermalState.integerValue) {
                    case NSProcessInfoThermalStateCritical:
                        XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateCritical);
                        XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateCritical);
                        break;
                    case NSProcessInfoThermalStateSerious:
                        XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateSerious);
                        XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateSerious);
                        break;
                    case NSProcessInfoThermalStateFair:
                        XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateFair);
                        XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateFair);
                        break;
                    case NSProcessInfoThermalStateNominal:
                        XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBatteryCharging);
                        XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBatteryCharging);
                        break;
                }
                
                counts = [self.calculator calculateCameraUploadConcurrentCountsByThermalState:thermalState.integerValue applicationState:appState.integerValue batteryState:batteryState.integerValue batteryLevel:.45 isLowPowerModeEnabled:NO];
                switch (thermalState.integerValue) {
                    case NSProcessInfoThermalStateCritical:
                        XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateCritical);
                        XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateCritical);
                        break;
                    case NSProcessInfoThermalStateSerious:
                        XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateSerious);
                        XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateSerious);
                        break;
                    case NSProcessInfoThermalStateFair:
                        XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateFair);
                        XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateFair);
                        break;
                    case NSProcessInfoThermalStateNominal:
                        XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBatteryCharging);
                        XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBatteryCharging);
                        break;
                }
                
                counts = [self.calculator calculateCameraUploadConcurrentCountsByThermalState:thermalState.integerValue applicationState:appState.integerValue batteryState:batteryState.integerValue batteryLevel:.6 isLowPowerModeEnabled:NO];
                switch (thermalState.integerValue) {
                    case NSProcessInfoThermalStateCritical:
                        XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateCritical);
                        XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateCritical);
                        break;
                    case NSProcessInfoThermalStateSerious:
                        XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateSerious);
                        XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateSerious);
                        break;
                    case NSProcessInfoThermalStateFair:
                        XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateFair);
                        XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateFair);
                        break;
                    case NSProcessInfoThermalStateNominal:
                        XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBatteryCharging);
                        XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBatteryCharging);
                        break;
                }
                
                counts = [self.calculator calculateCameraUploadConcurrentCountsByThermalState:thermalState.integerValue applicationState:appState.integerValue batteryState:batteryState.integerValue batteryLevel:.8 isLowPowerModeEnabled:NO];
                switch (thermalState.integerValue) {
                    case NSProcessInfoThermalStateCritical:
                        XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateCritical);
                        XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateCritical);
                        break;
                    case NSProcessInfoThermalStateSerious:
                        XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateSerious);
                        XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateSerious);
                        break;
                    case NSProcessInfoThermalStateFair:
                        XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateFair);
                        XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateFair);
                        break;
                    case NSProcessInfoThermalStateNominal:
                        XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBatteryCharging);
                        XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBatteryCharging);
                        break;
                }
                
                counts = [self.calculator calculateCameraUploadConcurrentCountsByThermalState:thermalState.integerValue applicationState:appState.integerValue batteryState:batteryState.integerValue batteryLevel:1 isLowPowerModeEnabled:NO];
                switch (thermalState.integerValue) {
                    case NSProcessInfoThermalStateCritical:
                        XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateCritical);
                        XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateCritical);
                        break;
                    case NSProcessInfoThermalStateSerious:
                        XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateSerious);
                        XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateSerious);
                        break;
                    case NSProcessInfoThermalStateFair:
                        XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateFair);
                        XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateFair);
                        break;
                    case NSProcessInfoThermalStateNominal:
                        XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBatteryCharging);
                        XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBatteryCharging);
                        break;
                }
            }
        }
    }
}

#pragma mark - background state

- (void)testConcurrentCountsWith_Background_BatteryUnplugged_LowPowerModeEnabled {
    for (NSNumber *thermalState in self.thermalStates) {
        CameraUploadConcurrentCounts counts = [self.calculator calculateCameraUploadConcurrentCountsByThermalState:thermalState.integerValue applicationState:UIApplicationStateBackground batteryState:UIDeviceBatteryStateUnplugged batteryLevel:.1 isLowPowerModeEnabled:YES];
        switch (thermalState.integerValue) {
            case NSProcessInfoThermalStateCritical:
                XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateCritical);
                XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateCritical);
                break;
            case NSProcessInfoThermalStateSerious:
                XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBatteryLevelBelow15);
                XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBatteryLevelBelow15);
                break;
            case NSProcessInfoThermalStateFair:
                XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBatteryLevelBelow15);
                XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBatteryLevelBelow15);
                break;
            case NSProcessInfoThermalStateNominal:
                XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBatteryLevelBelow15);
                XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBatteryLevelBelow15);
                break;
        }
        
        counts = [self.calculator calculateCameraUploadConcurrentCountsByThermalState:thermalState.integerValue applicationState:UIApplicationStateBackground batteryState:UIDeviceBatteryStateUnplugged batteryLevel:.2 isLowPowerModeEnabled:YES];
        switch (thermalState.integerValue) {
            case NSProcessInfoThermalStateCritical:
                XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateCritical);
                XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateCritical);
                break;
            case NSProcessInfoThermalStateSerious:
                XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBatteryLevelBelow25);
                XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateSerious);
                break;
            case NSProcessInfoThermalStateFair:
                XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBatteryLevelBelow25);
                XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBatteryLevelBelow25);
                break;
            case NSProcessInfoThermalStateNominal:
                XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBatteryLevelBelow25);
                XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBatteryLevelBelow25);
                break;
        }
        
        counts = [self.calculator calculateCameraUploadConcurrentCountsByThermalState:thermalState.integerValue applicationState:UIApplicationStateBackground batteryState:UIDeviceBatteryStateUnplugged batteryLevel:.3 isLowPowerModeEnabled:YES];
        switch (thermalState.integerValue) {
            case NSProcessInfoThermalStateCritical:
                XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateCritical);
                XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateCritical);
                break;
            case NSProcessInfoThermalStateSerious:
                XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateSerious);
                XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateSerious);
                break;
            case NSProcessInfoThermalStateFair:
                XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBackground);
                XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBackground);
                break;
            case NSProcessInfoThermalStateNominal:
                XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBackground);
                XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBackground);
                break;
        }
        
        counts = [self.calculator calculateCameraUploadConcurrentCountsByThermalState:thermalState.integerValue applicationState:UIApplicationStateBackground batteryState:UIDeviceBatteryStateUnplugged batteryLevel:.45 isLowPowerModeEnabled:YES];
        switch (thermalState.integerValue) {
            case NSProcessInfoThermalStateCritical:
                XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateCritical);
                XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateCritical);
                break;
            case NSProcessInfoThermalStateSerious:
                XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateSerious);
                XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateSerious);
                break;
            case NSProcessInfoThermalStateFair:
                XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBackground);
                XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBackground);
                break;
            case NSProcessInfoThermalStateNominal:
                XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBackground);
                XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBackground);
                break;
        }
        
        counts = [self.calculator calculateCameraUploadConcurrentCountsByThermalState:thermalState.integerValue applicationState:UIApplicationStateBackground batteryState:UIDeviceBatteryStateUnplugged batteryLevel:.6 isLowPowerModeEnabled:YES];
        switch (thermalState.integerValue) {
            case NSProcessInfoThermalStateCritical:
                XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateCritical);
                XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateCritical);
                break;
            case NSProcessInfoThermalStateSerious:
                XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateSerious);
                XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateSerious);
                break;
            case NSProcessInfoThermalStateFair:
                XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBackground);
                XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBackground);
                break;
            case NSProcessInfoThermalStateNominal:
                XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBackground);
                XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBackground);
                break;
        }
        
        counts = [self.calculator calculateCameraUploadConcurrentCountsByThermalState:thermalState.integerValue applicationState:UIApplicationStateBackground batteryState:UIDeviceBatteryStateUnplugged batteryLevel:.8 isLowPowerModeEnabled:YES];
        switch (thermalState.integerValue) {
            case NSProcessInfoThermalStateCritical:
                XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateCritical);
                XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateCritical);
                break;
            case NSProcessInfoThermalStateSerious:
                XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateSerious);
                XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateSerious);
                break;
            case NSProcessInfoThermalStateFair:
                XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBackground);
                XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBackground);
                break;
            case NSProcessInfoThermalStateNominal:
                XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBackground);
                XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBackground);
                break;
        }
        
        counts = [self.calculator calculateCameraUploadConcurrentCountsByThermalState:thermalState.integerValue applicationState:UIApplicationStateBackground batteryState:UIDeviceBatteryStateUnplugged batteryLevel:1 isLowPowerModeEnabled:YES];
        switch (thermalState.integerValue) {
            case NSProcessInfoThermalStateCritical:
                XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateCritical);
                XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateCritical);
                break;
            case NSProcessInfoThermalStateSerious:
                XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateSerious);
                XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateSerious);
                break;
            case NSProcessInfoThermalStateFair:
                XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBackground);
                XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBackground);
                break;
            case NSProcessInfoThermalStateNominal:
                XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBackground);
                XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBackground);
                break;
        }
    }
}

- (void)testConcurrentCountsWith_Background_BatteryUnplugged_LowPowerModeNotEnabled {
    for (NSNumber *thermalState in self.thermalStates) {
        CameraUploadConcurrentCounts counts = [self.calculator calculateCameraUploadConcurrentCountsByThermalState:thermalState.integerValue applicationState:UIApplicationStateBackground batteryState:UIDeviceBatteryStateUnplugged batteryLevel:.1 isLowPowerModeEnabled:NO];
        switch (thermalState.integerValue) {
            case NSProcessInfoThermalStateCritical:
                XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateCritical);
                XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateCritical);
                break;
            case NSProcessInfoThermalStateSerious:
                XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBatteryLevelBelow15);
                XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBatteryLevelBelow15);
                break;
            case NSProcessInfoThermalStateFair:
                XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBatteryLevelBelow15);
                XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBatteryLevelBelow15);
                break;
            case NSProcessInfoThermalStateNominal:
                XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBatteryLevelBelow15);
                XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBatteryLevelBelow15);
                break;
        }
        
        counts = [self.calculator calculateCameraUploadConcurrentCountsByThermalState:thermalState.integerValue applicationState:UIApplicationStateBackground batteryState:UIDeviceBatteryStateUnplugged batteryLevel:.2 isLowPowerModeEnabled:NO];
        switch (thermalState.integerValue) {
            case NSProcessInfoThermalStateCritical:
                XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateCritical);
                XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateCritical);
                break;
            case NSProcessInfoThermalStateSerious:
                XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBatteryLevelBelow25);
                XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateSerious);
                break;
            case NSProcessInfoThermalStateFair:
                XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBatteryLevelBelow25);
                XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBatteryLevelBelow25);
                break;
            case NSProcessInfoThermalStateNominal:
                XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBatteryLevelBelow25);
                XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBatteryLevelBelow25);
                break;
        }
        
        counts = [self.calculator calculateCameraUploadConcurrentCountsByThermalState:thermalState.integerValue applicationState:UIApplicationStateBackground batteryState:UIDeviceBatteryStateUnplugged batteryLevel:.3 isLowPowerModeEnabled:NO];
        switch (thermalState.integerValue) {
            case NSProcessInfoThermalStateCritical:
                XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateCritical);
                XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateCritical);
                break;
            case NSProcessInfoThermalStateSerious:
                XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateSerious);
                XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateSerious);
                break;
            case NSProcessInfoThermalStateFair:
                XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBackground);
                XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBackground);
                break;
            case NSProcessInfoThermalStateNominal:
                XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBackground);
                XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBackground);
                break;
        }
        
        counts = [self.calculator calculateCameraUploadConcurrentCountsByThermalState:thermalState.integerValue applicationState:UIApplicationStateBackground batteryState:UIDeviceBatteryStateUnplugged batteryLevel:.45 isLowPowerModeEnabled:NO];
        switch (thermalState.integerValue) {
            case NSProcessInfoThermalStateCritical:
                XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateCritical);
                XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateCritical);
                break;
            case NSProcessInfoThermalStateSerious:
                XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateSerious);
                XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateSerious);
                break;
            case NSProcessInfoThermalStateFair:
                XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBackground);
                XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBackground);
                break;
            case NSProcessInfoThermalStateNominal:
                XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBackground);
                XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBackground);
                break;
        }
        
        counts = [self.calculator calculateCameraUploadConcurrentCountsByThermalState:thermalState.integerValue applicationState:UIApplicationStateBackground batteryState:UIDeviceBatteryStateUnplugged batteryLevel:.6 isLowPowerModeEnabled:NO];
        switch (thermalState.integerValue) {
            case NSProcessInfoThermalStateCritical:
                XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateCritical);
                XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateCritical);
                break;
            case NSProcessInfoThermalStateSerious:
                XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateSerious);
                XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateSerious);
                break;
            case NSProcessInfoThermalStateFair:
                XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBackground);
                XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBackground);
                break;
            case NSProcessInfoThermalStateNominal:
                XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBackground);
                XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBackground);
                break;
        }
        
        counts = [self.calculator calculateCameraUploadConcurrentCountsByThermalState:thermalState.integerValue applicationState:UIApplicationStateBackground batteryState:UIDeviceBatteryStateUnplugged batteryLevel:.8 isLowPowerModeEnabled:NO];
        switch (thermalState.integerValue) {
            case NSProcessInfoThermalStateCritical:
                XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateCritical);
                XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateCritical);
                break;
            case NSProcessInfoThermalStateSerious:
                XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateSerious);
                XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateSerious);
                break;
            case NSProcessInfoThermalStateFair:
                XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBackground);
                XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBackground);
                break;
            case NSProcessInfoThermalStateNominal:
                XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBackground);
                XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBackground);
                break;
        }
        
        counts = [self.calculator calculateCameraUploadConcurrentCountsByThermalState:thermalState.integerValue applicationState:UIApplicationStateBackground batteryState:UIDeviceBatteryStateUnplugged batteryLevel:1 isLowPowerModeEnabled:NO];
        switch (thermalState.integerValue) {
            case NSProcessInfoThermalStateCritical:
                XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateCritical);
                XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateCritical);
                break;
            case NSProcessInfoThermalStateSerious:
                XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateSerious);
                XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateSerious);
                break;
            case NSProcessInfoThermalStateFair:
                XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBackground);
                XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBackground);
                break;
            case NSProcessInfoThermalStateNominal:
                XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBackground);
                XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBackground);
                break;
        }
    }
    
}

- (void)testConcurrentCountsWith_Background_BatteryNonUnplugged_LowPowerModeEnabled {
    for (NSNumber *thermalState in self.thermalStates) {
        for (NSNumber *batteryState in self.batteryNonUnpluggedStates) {
            CameraUploadConcurrentCounts counts = [self.calculator calculateCameraUploadConcurrentCountsByThermalState:thermalState.integerValue applicationState:UIApplicationStateBackground batteryState:batteryState.integerValue batteryLevel:.1 isLowPowerModeEnabled:YES];
            switch (thermalState.integerValue) {
                case NSProcessInfoThermalStateCritical:
                    XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateCritical);
                    XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateCritical);
                    break;
                case NSProcessInfoThermalStateSerious:
                    XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateSerious);
                    XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateSerious);
                    break;
                case NSProcessInfoThermalStateFair:
                    XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBackground);
                    XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBackground);
                    break;
                case NSProcessInfoThermalStateNominal:
                    XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBackground);
                    XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBackground);
                    break;
            }
            
            counts = [self.calculator calculateCameraUploadConcurrentCountsByThermalState:thermalState.integerValue applicationState:UIApplicationStateBackground batteryState:batteryState.integerValue batteryLevel:.2 isLowPowerModeEnabled:YES];
            switch (thermalState.integerValue) {
                case NSProcessInfoThermalStateCritical:
                    XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateCritical);
                    XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateCritical);
                    break;
                case NSProcessInfoThermalStateSerious:
                    XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateSerious);
                    XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateSerious);
                    break;
                case NSProcessInfoThermalStateFair:
                    XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBackground);
                    XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBackground);
                    break;
                case NSProcessInfoThermalStateNominal:
                    XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBackground);
                    XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBackground);
                    break;
            }
            
            counts = [self.calculator calculateCameraUploadConcurrentCountsByThermalState:thermalState.integerValue applicationState:UIApplicationStateBackground batteryState:batteryState.integerValue batteryLevel:.3 isLowPowerModeEnabled:YES];
            switch (thermalState.integerValue) {
                case NSProcessInfoThermalStateCritical:
                    XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateCritical);
                    XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateCritical);
                    break;
                case NSProcessInfoThermalStateSerious:
                    XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateSerious);
                    XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateSerious);
                    break;
                case NSProcessInfoThermalStateFair:
                    XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBackground);
                    XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBackground);
                    break;
                case NSProcessInfoThermalStateNominal:
                    XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBackground);
                    XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBackground);
                    break;
            }
            
            counts = [self.calculator calculateCameraUploadConcurrentCountsByThermalState:thermalState.integerValue applicationState:UIApplicationStateBackground batteryState:batteryState.integerValue batteryLevel:.45 isLowPowerModeEnabled:YES];
            switch (thermalState.integerValue) {
                case NSProcessInfoThermalStateCritical:
                    XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateCritical);
                    XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateCritical);
                    break;
                case NSProcessInfoThermalStateSerious:
                    XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateSerious);
                    XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateSerious);
                    break;
                case NSProcessInfoThermalStateFair:
                    XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBackground);
                    XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBackground);
                    break;
                case NSProcessInfoThermalStateNominal:
                    XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBackground);
                    XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBackground);
                    break;
            }
            
            counts = [self.calculator calculateCameraUploadConcurrentCountsByThermalState:thermalState.integerValue applicationState:UIApplicationStateBackground batteryState:batteryState.integerValue batteryLevel:.6 isLowPowerModeEnabled:YES];
            switch (thermalState.integerValue) {
                case NSProcessInfoThermalStateCritical:
                    XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateCritical);
                    XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateCritical);
                    break;
                case NSProcessInfoThermalStateSerious:
                    XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateSerious);
                    XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateSerious);
                    break;
                case NSProcessInfoThermalStateFair:
                    XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBackground);
                    XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBackground);
                    break;
                case NSProcessInfoThermalStateNominal:
                    XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBackground);
                    XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBackground);
                    break;
            }
            
            counts = [self.calculator calculateCameraUploadConcurrentCountsByThermalState:thermalState.integerValue applicationState:UIApplicationStateBackground batteryState:batteryState.integerValue batteryLevel:.8 isLowPowerModeEnabled:YES];
            switch (thermalState.integerValue) {
                case NSProcessInfoThermalStateCritical:
                    XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateCritical);
                    XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateCritical);
                    break;
                case NSProcessInfoThermalStateSerious:
                    XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateSerious);
                    XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateSerious);
                    break;
                case NSProcessInfoThermalStateFair:
                    XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBackground);
                    XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBackground);
                    break;
                case NSProcessInfoThermalStateNominal:
                    XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBackground);
                    XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBackground);
                    break;
            }
            
            counts = [self.calculator calculateCameraUploadConcurrentCountsByThermalState:thermalState.integerValue applicationState:UIApplicationStateBackground batteryState:batteryState.integerValue batteryLevel:1 isLowPowerModeEnabled:YES];
            switch (thermalState.integerValue) {
                case NSProcessInfoThermalStateCritical:
                    XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateCritical);
                    XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateCritical);
                    break;
                case NSProcessInfoThermalStateSerious:
                    XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateSerious);
                    XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateSerious);
                    break;
                case NSProcessInfoThermalStateFair:
                    XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBackground);
                    XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBackground);
                    break;
                case NSProcessInfoThermalStateNominal:
                    XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBackground);
                    XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBackground);
                    break;
            }
        }
    }
}

- (void)testConcurrentCountsWith_Background_BatteryNonUnplugged_LowPowerModeNotEnabled {
    for (NSNumber *thermalState in self.thermalStates) {
        for (NSNumber *batteryState in self.batteryNonUnpluggedStates) {
            CameraUploadConcurrentCounts counts = [self.calculator calculateCameraUploadConcurrentCountsByThermalState:thermalState.integerValue applicationState:UIApplicationStateBackground batteryState:batteryState.integerValue batteryLevel:.1 isLowPowerModeEnabled:NO];
            switch (thermalState.integerValue) {
                case NSProcessInfoThermalStateCritical:
                    XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateCritical);
                    XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateCritical);
                    break;
                case NSProcessInfoThermalStateSerious:
                    XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateSerious);
                    XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateSerious);
                    break;
                case NSProcessInfoThermalStateFair:
                    XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBackground);
                    XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBackground);
                    break;
                case NSProcessInfoThermalStateNominal:
                    XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBackground);
                    XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBackground);
                    break;
            }
            
            counts = [self.calculator calculateCameraUploadConcurrentCountsByThermalState:thermalState.integerValue applicationState:UIApplicationStateBackground batteryState:batteryState.integerValue batteryLevel:.2 isLowPowerModeEnabled:NO];
            switch (thermalState.integerValue) {
                case NSProcessInfoThermalStateCritical:
                    XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateCritical);
                    XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateCritical);
                    break;
                case NSProcessInfoThermalStateSerious:
                    XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateSerious);
                    XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateSerious);
                    break;
                case NSProcessInfoThermalStateFair:
                    XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBackground);
                    XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBackground);
                    break;
                case NSProcessInfoThermalStateNominal:
                    XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBackground);
                    XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBackground);
                    break;
            }
            
            counts = [self.calculator calculateCameraUploadConcurrentCountsByThermalState:thermalState.integerValue applicationState:UIApplicationStateBackground batteryState:batteryState.integerValue batteryLevel:.3 isLowPowerModeEnabled:NO];
            switch (thermalState.integerValue) {
                case NSProcessInfoThermalStateCritical:
                    XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateCritical);
                    XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateCritical);
                    break;
                case NSProcessInfoThermalStateSerious:
                    XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateSerious);
                    XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateSerious);
                    break;
                case NSProcessInfoThermalStateFair:
                    XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBackground);
                    XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBackground);
                    break;
                case NSProcessInfoThermalStateNominal:
                    XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBackground);
                    XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBackground);
                    break;
            }
            
            counts = [self.calculator calculateCameraUploadConcurrentCountsByThermalState:thermalState.integerValue applicationState:UIApplicationStateBackground batteryState:batteryState.integerValue batteryLevel:.45 isLowPowerModeEnabled:NO];
            switch (thermalState.integerValue) {
                case NSProcessInfoThermalStateCritical:
                    XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateCritical);
                    XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateCritical);
                    break;
                case NSProcessInfoThermalStateSerious:
                    XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateSerious);
                    XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateSerious);
                    break;
                case NSProcessInfoThermalStateFair:
                    XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBackground);
                    XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBackground);
                    break;
                case NSProcessInfoThermalStateNominal:
                    XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBackground);
                    XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBackground);
                    break;
            }
            
            counts = [self.calculator calculateCameraUploadConcurrentCountsByThermalState:thermalState.integerValue applicationState:UIApplicationStateBackground batteryState:batteryState.integerValue batteryLevel:.6 isLowPowerModeEnabled:NO];
            switch (thermalState.integerValue) {
                case NSProcessInfoThermalStateCritical:
                    XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateCritical);
                    XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateCritical);
                    break;
                case NSProcessInfoThermalStateSerious:
                    XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateSerious);
                    XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateSerious);
                    break;
                case NSProcessInfoThermalStateFair:
                    XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBackground);
                    XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBackground);
                    break;
                case NSProcessInfoThermalStateNominal:
                    XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBackground);
                    XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBackground);
                    break;
            }
            
            counts = [self.calculator calculateCameraUploadConcurrentCountsByThermalState:thermalState.integerValue applicationState:UIApplicationStateBackground batteryState:batteryState.integerValue batteryLevel:.8 isLowPowerModeEnabled:NO];
            switch (thermalState.integerValue) {
                case NSProcessInfoThermalStateCritical:
                    XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateCritical);
                    XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateCritical);
                    break;
                case NSProcessInfoThermalStateSerious:
                    XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateSerious);
                    XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateSerious);
                    break;
                case NSProcessInfoThermalStateFair:
                    XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBackground);
                    XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBackground);
                    break;
                case NSProcessInfoThermalStateNominal:
                    XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBackground);
                    XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBackground);
                    break;
            }
            
            counts = [self.calculator calculateCameraUploadConcurrentCountsByThermalState:thermalState.integerValue applicationState:UIApplicationStateBackground batteryState:batteryState.integerValue batteryLevel:1 isLowPowerModeEnabled:NO];
            switch (thermalState.integerValue) {
                case NSProcessInfoThermalStateCritical:
                    XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateCritical);
                    XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateCritical);
                    break;
                case NSProcessInfoThermalStateSerious:
                    XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateSerious);
                    XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateSerious);
                    break;
                case NSProcessInfoThermalStateFair:
                    XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBackground);
                    XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBackground);
                    break;
                case NSProcessInfoThermalStateNominal:
                    XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBackground);
                    XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBackground);
                    break;
            }
        }
    }
}

@end
