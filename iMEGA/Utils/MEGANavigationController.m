#import "Helper.h"

#import "MWPhotoBrowser.h"

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
        if ([self.topViewController isKindOfClass:[MWPhotoBrowser class]]) {
            if ([self.topViewController respondsToSelector:@selector(supportedInterfaceOrientations)]) {
                return [self.topViewController supportedInterfaceOrientations];
            }
        }
        
        return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown;
    }
    
    if([self.topViewController respondsToSelector:@selector(supportedInterfaceOrientations)]) {
        return [self.topViewController supportedInterfaceOrientations];
    }
    
    return UIInterfaceOrientationMaskAll;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

@end
