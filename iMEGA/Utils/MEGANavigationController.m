
#import "MEGANavigationController.h"

@implementation MEGANavigationController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    __weak MEGANavigationController *weakSelf = self;
    
    if ([self respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        self.interactivePopGestureRecognizer.delegate = weakSelf;
        self.delegate = weakSelf;
    }
}

- (BOOL)shouldAutorotate {
    if ([self.topViewController respondsToSelector:@selector(shouldAutorotate)]) {
        return [self.topViewController shouldAutorotate];
    } else {
        return YES;
    }
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {    
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

- (void)addRightCancelButton {
    self.viewControllers.firstObject.navigationItem.rightBarButtonItem = [self cancelBarButtonItem];
}

- (void)addLeftDismissButtonWithText:(NSString *)text {
    self.viewControllers.firstObject.navigationItem.leftBarButtonItem = [self dismissBarButtonItemWithText:text];
}

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated {
    if ([self respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        self.interactivePopGestureRecognizer.enabled = NO;
    }
    [super pushViewController:viewController animated:animated];
}

#pragma mark - Private

- (UIBarButtonItem *)cancelBarButtonItem {
    UIBarButtonItem *cancelBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:AMLocalizedString(@"cancel", nil) style:UIBarButtonItemStylePlain target:nil action:@selector(dismissNavigationController)];
    return cancelBarButtonItem;
}

- (UIBarButtonItem *)dismissBarButtonItemWithText:(NSString *)text {
    UIBarButtonItem *cancelBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:text style:UIBarButtonItemStylePlain target:nil action:@selector(dismissNavigationController)];
    return cancelBarButtonItem;
}

- (void)dismissNavigationController {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UINavigationControllerDelegate

- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animate {
    self.interactivePopGestureRecognizer.enabled = ([self respondsToSelector:@selector(interactivePopGestureRecognizer)] && self.viewControllers.count > 1);
}

@end
