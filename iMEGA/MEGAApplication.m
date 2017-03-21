
#import "MEGAApplication.h"

@implementation MEGAApplication

- (void)sendEvent:(UIEvent *)event {
    if (event.type == UIEventTypeTouches && event.allTouches.anyObject.phase == UITouchPhaseEnded) {
        id<MEGAApplicationDelegate> delegate = (id<MEGAApplicationDelegate>)self.delegate;
        [delegate application:self willSendTouchEvent:event];
    }
    [super sendEvent:event];
}

@end
