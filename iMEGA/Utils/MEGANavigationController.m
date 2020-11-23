
#import "MEGANavigationController.h"

#ifdef MNZ_SHARE_EXTENSION
#import "MEGAShare-Swift.h"
#elif MNZ_PICKER_EXTENSION
#import "MEGAPicker-Swift.h"
#else
#import "MEGA-Swift.h"
#endif

@implementation MEGANavigationController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.mnz_background;
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

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    
    if (@available(iOS 13.0, *)) {
        if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
            #ifdef MNZ_SHARE_EXTENSION
            [ExtensionAppearanceManager forceNavigationBarUpdate:self.navigationBar traitCollection:self.traitCollection];
            [ExtensionAppearanceManager forceToolbarUpdate:self.toolbar traitCollection:self.traitCollection];
            #elif MNZ_PICKER_EXTENSION
            
            #else
            [AppearanceManager forceNavigationBarUpdate:self.navigationBar traitCollection:self.traitCollection];
            [AppearanceManager forceToolbarUpdate:self.toolbar traitCollection:self.traitCollection];
            #endif
        }
    }
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
