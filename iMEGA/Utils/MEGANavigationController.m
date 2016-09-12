#import "Helper.h"

#import "MEGANavigationController.h"

@implementation MEGANavigationController

#pragma mark - Lifecycle

- (BOOL)shouldAutorotate {
    if ([self.topViewController respondsToSelector:@selector(shouldAutorotate)]) {
        return [self.topViewController shouldAutorotate];
    } else {
        return YES;
    }
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    if ([[UIDevice currentDevice] iPhone4X] || [[UIDevice currentDevice] iPhone5X]) {
        return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown;
    }
    
    if([self.topViewController respondsToSelector:@selector(supportedInterfaceOrientations)]) {
        return [self.topViewController supportedInterfaceOrientations];
    }
    
    return UIInterfaceOrientationMaskAll;
}

@end
