#import "MEGANavigationController.h"
@import MEGAL10nObjc;

#ifdef MNZ_SHARE_EXTENSION
#import "MEGAShare-Swift.h"
#else
#import "MEGA-Swift.h"
#endif

@implementation MEGANavigationController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.systemBackgroundColor;
    self.interactivePopGestureRecognizer.delegate = self;
    self.delegate = self;
    
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    
    if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
        [AppearanceManager forceNavigationBarUpdate:self.navigationBar];
        [AppearanceManager forceToolbarUpdate:self.toolbar];
    }
}

#pragma mark - Public

- (void)addRightCancelButton {
    self.viewControllers.firstObject.navigationItem.rightBarButtonItem = [self cancelBarButtonItem];
}

- (void)addLeftDismissButtonWithText:(NSString *)text {
    [self addLeftDismissBarButton:[self dismissBarButtonItemWithText:text]];
}

- (void)addLeftDismissBarButton:(UIBarButtonItem *)barButton {
    self.viewControllers.firstObject.navigationItem.leftBarButtonItem = barButton;
}

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated {
    if ([self respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        self.interactivePopGestureRecognizer.enabled = NO;
    }
    [super pushViewController:viewController animated:animated];
}
#pragma mark - Private

- (UIBarButtonItem *)cancelBarButtonItem {
    UIBarButtonItem *cancelBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:LocalizedString(@"cancel", @"") style:UIBarButtonItemStylePlain target:nil action:@selector(dismissNavigationController)];
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

- (void)navigationController:(UINavigationController *)navigationController
      willShowViewController:(UIViewController *)viewController
                    animated:(BOOL)animated {
    [self.navigationDelegate navigationController:navigationController
                           willShowViewController:viewController
                                         animated:animated];
}

- (void)navigationController:(UINavigationController *)navigationController
       didShowViewController:(UIViewController *)viewController
                    animated:(BOOL)animate {
    [self updateBackButtonMenu];
    self.interactivePopGestureRecognizer.enabled = ([self respondsToSelector:@selector(interactivePopGestureRecognizer)] && self.viewControllers.count > 1);
    if ([self.navigationController respondsToSelector:@selector(navigationController:didShowViewController:animated:)]) {
        [self.navigationDelegate navigationController:navigationController
                                didShowViewController:viewController
                                             animated:animate];
    }
}

@end
