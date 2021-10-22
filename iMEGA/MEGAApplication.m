
#import "MEGAApplication.h"

#if DEBUG
#import "FLEXManager.h"
#endif

@implementation MEGAApplication

- (void)sendEvent:(UIEvent *)event {
    if (event.type == UIEventTypeTouches && event.allTouches.anyObject.phase == UITouchPhaseEnded) {
        id<MEGAApplicationDelegate> delegate = (id<MEGAApplicationDelegate>)self.delegate;
        [delegate application:self willSendTouchEvent:event];
    }

    
#if DEBUG
    if (event.allTouches.count == 4) {
        [[FLEXManager sharedManager] showExplorer];
    }
#endif

    [super sendEvent:event];
}

@end
