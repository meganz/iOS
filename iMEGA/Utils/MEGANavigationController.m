
#import "MEGANavigationController.h"

#ifdef MNZ_SHARE_EXTENSION
#import "MEGAShare-Swift.h"
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

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    
    if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
#ifdef MNZ_SHARE_EXTENSION
        [ExtensionAppearanceManager forceNavigationBarUpdate:self.navigationBar traitCollection:self.traitCollection];
        [ExtensionAppearanceManager forceToolbarUpdate:self.toolbar traitCollection:self.traitCollection];
#else
        [AppearanceManager forceNavigationBarUpdate:self.navigationBar traitCollection:self.traitCollection];
        [AppearanceManager forceToolbarUpdate:self.toolbar traitCollection:self.traitCollection];
#endif
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
    UIBarButtonItem *cancelBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"cancel", nil) style:UIBarButtonItemStylePlain target:nil action:@selector(dismissNavigationController)];
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
    [self.navigationDelegate navigationController:navigationController willShowViewController:viewController];
}

- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animate {
    self.interactivePopGestureRecognizer.enabled = ([self respondsToSelector:@selector(interactivePopGestureRecognizer)] && self.viewControllers.count > 1);
}

@end
