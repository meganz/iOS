#import <XCTest/XCTest.h>

#import "CameraUploadConcurrentCountCalculator.h"

@interface CameraUploadConcurrentCountCalculatorTests : XCTestCase

@property (strong, nonatomic) CameraUploadConcurrentCountCalculator *calculator;

@property (strong, nonatomic) NSArray<NSNumber *> *batteryChargingStates;
@property (strong, nonatomic) NSArray<NSNumber *> *sampleBatteryLevels;

@property (strong, nonatomic) NSArray<NSNumber *> *thermalStates;
@property (strong, nonatomic) NSArray<NSNumber *> *nonBackgroundApplicationStates;

@end

@implementation CameraUploadConcurrentCountCalculatorTests

- (void)setUp {
    [super setUp];
    
    self.calculator = CameraUploadConcurrentCountCalculator.alloc.init;
    
    self.batteryChargingStates = @[@(UIDeviceBatteryStateCharging), @(UIDeviceBatteryStateUnknown), @(UIDeviceBatteryStateFull)];
    self.sampleBatteryLevels = @[@(0.1), @(0.2), @(0.3), @(0.45), @(0.6), @(0.8), @(1)];
    
    self.thermalStates = @[@(NSProcessInfoThermalStateCritical), @(NSProcessInfoThermalStateSerious), @(NSProcessInfoThermalStateFair), @(NSProcessInfoThermalStateNominal)];
    self.nonBackgroundApplicationStates = @[@(UIApplicationStateActive), @(UIApplicationStateInactive)];
}

#pragma mark - Non-background state

- (void)testConcurrentCountsWith_NonBackground_BatteryUnplugged_LowPowerModeEnabled {
    for (NSNumber *appState in self.nonBackgroundApplicationStates) {
        for (NSNumber *batteryLevel in self.sampleBatteryLevels) {
            for (NSNumber *thermalState in self.thermalStates) {
                CameraUploadConcurrentCounts counts = [self.calculator calculateCameraUploadConcurrentCountsByThermalState:thermalState.integerValue applicationState:appState.integerValue batteryState:UIDeviceBatteryStateUnplugged batteryLevel:batteryLevel.floatValue isLowPowerModeEnabled:YES];
                
                switch (thermalState.integerValue) {
                    case NSProcessInfoThermalStateCritical: {
                        XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateCritical);
                        XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateCritical);
                        break;
                    }
                        
                    case NSProcessInfoThermalStateSerious: {
                        if (batteryLevel.floatValue < 0.15) {
                            XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBatteryLevelBelow15);
                            XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBatteryLevelBelow15);
                        } else if (batteryLevel.floatValue < 0.25) {
                            XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBatteryLevelBelow25);
                            XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateSerious);
                        } else {
                            XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateSerious);
                            XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateSerious);
                        }
                        break;
                    }
                        
                    case NSProcessInfoThermalStateFair:
                    case NSProcessInfoThermalStateNominal: {
                        if (batteryLevel.floatValue < 0.15) {
                            XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBatteryLevelBelow15);
                            XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBatteryLevelBelow15);
                        } else if (batteryLevel.floatValue < 0.25) {
                            XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBatteryLevelBelow25);
                            XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBatteryLevelBelow25);
                        } else {
                            XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInLowPowerMode);
                            XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInLowPowerMode);
                        }
                        break;
                    }
                }
            }
        }
    }
}

- (void)testConcurrentCountsWith_NonBackground_BatteryUnplugged_LowPowerModeDisabled {
    for (NSNumber *appState in self.nonBackgroundApplicationStates) {
        for (NSNumber *batteryLevel in self.sampleBatteryLevels) {
            for (NSNumber *thermalState in self.thermalStates) {
                CameraUploadConcurrentCounts counts = [self.calculator calculateCameraUploadConcurrentCountsByThermalState:thermalState.integerValue applicationState:appState.integerValue batteryState:UIDeviceBatteryStateUnplugged batteryLevel:batteryLevel.floatValue isLowPowerModeEnabled:NO];
                
                switch (thermalState.integerValue) {
                    case NSProcessInfoThermalStateCritical: {
                        XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateCritical);
                        XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateCritical);
                        break;
                    }
                        
                    case NSProcessInfoThermalStateSerious: {
                        if (batteryLevel.floatValue < 0.15) {
                            XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBatteryLevelBelow15);
                            XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBatteryLevelBelow15);
                        } else if (batteryLevel.floatValue < 0.25) {
                            XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBatteryLevelBelow25);
                            XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateSerious);
                        } else {
                            XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateSerious);
                            XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateSerious);
                        }
                        break;
                    }
                        
                    case NSProcessInfoThermalStateFair: {
                        if (batteryLevel.floatValue < 0.15) {
                            XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBatteryLevelBelow15);
                            XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBatteryLevelBelow15);
                        } else if (batteryLevel.floatValue < 0.25) {
                            XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBatteryLevelBelow25);
                            XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBatteryLevelBelow25);
                        } else if (batteryLevel.floatValue < 0.4) {
                            XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBatteryLevelBelow40);
                            XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBatteryLevelBelow40);
                        } else if (batteryLevel.floatValue < 0.55) {
                            XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBatteryLevelBelow55);
                            XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBatteryLevelBelow55);
                        } else {
                            XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateFair);
                            XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateFair);
                        }
                        break;
                    }
                        
                    case NSProcessInfoThermalStateNominal: {
                        if (batteryLevel.floatValue < 0.15) {
                            XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBatteryLevelBelow15);
                            XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBatteryLevelBelow15);
                        } else if (batteryLevel.floatValue < 0.25) {
                            XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBatteryLevelBelow25);
                            XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBatteryLevelBelow25);
                        } else if (batteryLevel.floatValue < 0.4) {
                            XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBatteryLevelBelow40);
                            XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBatteryLevelBelow40);
                        } else if (batteryLevel.floatValue < 0.55) {
                            XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBatteryLevelBelow55);
                            XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBatteryLevelBelow55);
                        } else if (batteryLevel.floatValue < 0.75) {
                            XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBatteryLevelBelow75);
                            XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBatteryLevelBelow75);
                        } else {
                            XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBatteryLevel75OrAbove);
                            XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBatteryLevel75OrAbove);
                        }
                        break;
                    }
                }
            }
        }
    }
}

- (void)testConcurrentCountsWith_NonBackground_BatteryCharging_LowPowerModeEnabled {
    for (NSNumber *appState in self.nonBackgroundApplicationStates) {
        for (NSNumber *batteryState in self.batteryChargingStates) {
            for (NSNumber *batteryLevel in self.sampleBatteryLevels) {
                for (NSNumber *thermalState in self.thermalStates) {
                    CameraUploadConcurrentCounts counts = [self.calculator calculateCameraUploadConcurrentCountsByThermalState:thermalState.integerValue applicationState:appState.integerValue batteryState:batteryState.integerValue batteryLevel:batteryLevel.floatValue isLowPowerModeEnabled:YES];
                    
                    switch (thermalState.integerValue) {
                        case NSProcessInfoThermalStateCritical: {
                            XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateCritical);
                            XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateCritical);
                            break;
                        }
                            
                        case NSProcessInfoThermalStateSerious: {
                            XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateSerious);
                            XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateSerious);
                            break;
                        }
                            
                        case NSProcessInfoThermalStateFair: {
                            XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateFair);
                            XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateFair);
                            break;
                        }
                            
                        case NSProcessInfoThermalStateNominal: {
                            XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBatteryCharging);
                            XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBatteryCharging);
                            break;
                        }
                    }
                }
            }
        }
    }
}

- (void)testConcurrentCountsWith_NonBackground_BatteryCharging_LowPowerModeDisabled {
    for (NSNumber *appState in self.nonBackgroundApplicationStates) {
        for (NSNumber *batteryState in self.batteryChargingStates) {
            for (NSNumber *batteryLevel in self.sampleBatteryLevels) {
                for (NSNumber *thermalState in self.thermalStates) {
                    CameraUploadConcurrentCounts counts = [self.calculator calculateCameraUploadConcurrentCountsByThermalState:thermalState.integerValue applicationState:appState.integerValue batteryState:batteryState.integerValue batteryLevel:batteryLevel.floatValue isLowPowerModeEnabled:NO];
                    
                    switch (thermalState.integerValue) {
                        case NSProcessInfoThermalStateCritical: {
                            XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateCritical);
                            XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateCritical);
                            break;
                        }
                            
                        case NSProcessInfoThermalStateSerious: {
                            XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateSerious);
                            XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateSerious);
                            break;
                        }
                            
                        case NSProcessInfoThermalStateFair: {
                            XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateFair);
                            XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateFair);
                            break;
                        }
                            
                        case NSProcessInfoThermalStateNominal: {
                            XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBatteryCharging);
                            XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBatteryCharging);
                            break;
                        }
                    }
                }
            }
        }
    }
}

#pragma mark - background state

- (void)testConcurrentCountsWith_Background_BatteryUnplugged_LowPowerModeEnabled {
    for (NSNumber *batteryLevel in self.sampleBatteryLevels) {
        for (NSNumber *thermalState in self.thermalStates) {
            CameraUploadConcurrentCounts counts = [self.calculator calculateCameraUploadConcurrentCountsByThermalState:thermalState.integerValue applicationState:UIApplicationStateBackground batteryState:UIDeviceBatteryStateUnplugged batteryLevel:batteryLevel.floatValue isLowPowerModeEnabled:YES];
            
            switch (thermalState.integerValue) {
                case NSProcessInfoThermalStateCritical:
                    XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateCritical);
                    XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateCritical);
                    break;
                    
                case NSProcessInfoThermalStateSerious: {
                    if (batteryLevel.floatValue < 0.15) {
                        XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBatteryLevelBelow15);
                        XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBatteryLevelBelow15);
                    } else if (batteryLevel.floatValue < 0.25) {
                        XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBatteryLevelBelow25);
                        XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateSerious);
                    } else {
                        XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateSerious);
                        XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateSerious);
                    }
                    break;
                }
                    
                case NSProcessInfoThermalStateFair:
                case NSProcessInfoThermalStateNominal: {
                    if (batteryLevel.floatValue < 0.15) {
                        XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBatteryLevelBelow15);
                        XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBatteryLevelBelow15);
                    } else if (batteryLevel.floatValue < 0.25) {
                        XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBatteryLevelBelow25);
                        XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBatteryLevelBelow25);
                    } else {
                        XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBackground);
                        XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBackground);
                    }
                    break;
                }
            }
        }
    }
}

- (void)testConcurrentCountsWith_Background_BatteryUnplugged_LowPowerModeDisabled {
    for (NSNumber *batteryLevel in self.sampleBatteryLevels) {
        for (NSNumber *thermalState in self.thermalStates) {
            CameraUploadConcurrentCounts counts = [self.calculator calculateCameraUploadConcurrentCountsByThermalState:thermalState.integerValue applicationState:UIApplicationStateBackground batteryState:UIDeviceBatteryStateUnplugged batteryLevel:batteryLevel.floatValue isLowPowerModeEnabled:NO];
            
            switch (thermalState.integerValue) {
                case NSProcessInfoThermalStateCritical:
                    XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateCritical);
                    XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateCritical);
                    break;
                    
                case NSProcessInfoThermalStateSerious: {
                    if (batteryLevel.floatValue < 0.15) {
                        XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBatteryLevelBelow15);
                        XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBatteryLevelBelow15);
                    } else if (batteryLevel.floatValue < 0.25) {
                        XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBatteryLevelBelow25);
                        XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateSerious);
                    } else {
                        XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateSerious);
                        XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateSerious);
                    }
                    break;
                }
                    
                case NSProcessInfoThermalStateFair:
                case NSProcessInfoThermalStateNominal: {
                    if (batteryLevel.floatValue < 0.15) {
                        XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBatteryLevelBelow15);
                        XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBatteryLevelBelow15);
                    } else if (batteryLevel.floatValue < 0.25) {
                        XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBatteryLevelBelow25);
                        XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBatteryLevelBelow25);
                    } else {
                        XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBackground);
                        XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBackground);
                    }
                    break;
                }
            }
        }
    }
}

- (void)testConcurrentCountsWith_Background_BatteryCharging_LowPowerModeEnabled {
    for (NSNumber *batteryState in self.batteryChargingStates) {
        for (NSNumber *batteryLevel in self.sampleBatteryLevels) {
            for (NSNumber *thermalState in self.thermalStates) {
                CameraUploadConcurrentCounts counts = [self.calculator calculateCameraUploadConcurrentCountsByThermalState:thermalState.integerValue applicationState:UIApplicationStateBackground batteryState:batteryState.integerValue batteryLevel:batteryLevel.floatValue isLowPowerModeEnabled:YES];
                
                switch (thermalState.integerValue) {
                    case NSProcessInfoThermalStateCritical: {
                        XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateCritical);
                        XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateCritical);
                        break;
                    }
                        
                    case NSProcessInfoThermalStateSerious: {
                        XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateSerious);
                        XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateSerious);
                        break;
                    }
                        
                    case NSProcessInfoThermalStateFair:
                    case NSProcessInfoThermalStateNominal: {
                        XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBackground);
                        XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBackground);
                        break;
                    }
                }
            }
        }
    }
}

- (void)testConcurrentCountsWith_Background_BatteryCharging_LowPowerModeDisabled {
    for (NSNumber *batteryState in self.batteryChargingStates) {
        for (NSNumber *batteryLevel in self.sampleBatteryLevels) {
            for (NSNumber *thermalState in self.thermalStates) {
                CameraUploadConcurrentCounts counts = [self.calculator calculateCameraUploadConcurrentCountsByThermalState:thermalState.integerValue applicationState:UIApplicationStateBackground batteryState:batteryState.integerValue batteryLevel:batteryLevel.floatValue isLowPowerModeEnabled:NO];
                
                switch (thermalState.integerValue) {
                    case NSProcessInfoThermalStateCritical: {
                        XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateCritical);
                        XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateCritical);
                        break;
                    }
                        
                    case NSProcessInfoThermalStateSerious: {
                        XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInThermalStateSerious);
                        XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInThermalStateSerious);
                        break;
                    }
                        
                    case NSProcessInfoThermalStateFair:
                    case NSProcessInfoThermalStateNominal: {
                        XCTAssertEqual(counts.photoConcurrentCount, PhotoUploadConcurrentCountInBackground);
                        XCTAssertEqual(counts.videoConcurrentCount, VideoUploadConcurrentCountInBackground);
                        break;
                    }
                }
            }
        }
    }
}

@end
