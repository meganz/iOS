
#import "MEGANavigationController.h"

#import "Helper.h"

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
    /* iOS 9 may crash when calling supportedInterfaceOrientations on UIAlertController.class
     * When we'd stop supporting iOS 9, the following if-else statement can be safely removed
     * @see http://www.openradar.me/22385765
     */
    if (@available(iOS 10.0, *)) {} else {
        if (self.topViewController.presentedViewController && [self.topViewController.presentedViewController isKindOfClass:UIAlertController.class]) {
            if ([self.topViewController respondsToSelector:@selector(supportedInterfaceOrientations)]) {
                return [self.topViewController supportedInterfaceOrientations];
            } else {
                if (UIDevice.currentDevice.iPhone4X || UIDevice.currentDevice.iPhone5X) {
                    return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown;
                } else {
                    return UIInterfaceOrientationMaskAll;
                }
            }
        }
    }
    
    if (self.topViewController.presentedViewController) {
        if ([self.topViewController.presentedViewController respondsToSelector:@selector(supportedInterfaceOrientations)]) {
            return [self.topViewController.presentedViewController supportedInterfaceOrientations];
        }
    } else {
        if ([self.topViewController respondsToSelector:@selector(supportedInterfaceOrientations)]) {
            return [self.topViewController supportedInterfaceOrientations];
        }
    }
    
    if (UIDevice.currentDevice.iPhone4X || UIDevice.currentDevice.iPhone5X) {
        return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown;
    } else {
        return UIInterfaceOrientationMaskAll;
    }
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

#pragma mark - Public

- (void)addCancelButton {
    self.viewControllers.firstObject.navigationItem.rightBarButtonItem = [self cancelBarButtonItem];
}

#pragma mark - Private

- (UIBarButtonItem *)cancelBarButtonItem {
    UIBarButtonItem *cancelBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:AMLocalizedString(@"cancel", nil) style:UIBarButtonItemStylePlain target:nil action:@selector(dismissNavigationController)];
    return cancelBarButtonItem;
}

- (void)dismissNavigationController {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
