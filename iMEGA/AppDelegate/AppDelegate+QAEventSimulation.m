#import "AppDelegate.h"

#if DEBUG || QA_CONFIG

@import MEGASdk;
#import "MEGA-Swift.h"

@interface AppDelegate (QAEventSimulation) <QAQuotaEventSimulating>
@end

@implementation AppDelegate (QAEventSimulation)

- (void)qaSimulateStorageEvent:(MEGAEvent *)event {
    [(id<MEGAGlobalDelegate>)self onEvent:MEGASdk.shared event:event];
}

@end

#endif
