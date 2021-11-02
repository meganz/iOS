
#import "UIApplication+MNZCategory.h"

@implementation UIApplication (MNZCategory)

+ (UIViewController *)mnz_presentingViewController {
    UIViewController *rootViewController = UIApplication.mnz_keyWindow.rootViewController;
    
    while (rootViewController.presentedViewController) {
        rootViewController = rootViewController.presentedViewController;
    }
    
    return rootViewController;
}

+ (UIViewController *)mnz_visibleViewController {
    UIViewController *rootViewController = UIApplication.mnz_presentingViewController;
    
    if ([rootViewController isKindOfClass:[UINavigationController class]]) {
        UINavigationController *navigationController = (UINavigationController *)rootViewController;
        UIViewController *lastViewController = [[navigationController viewControllers] lastObject];
        
        return lastViewController;
    }
    
    if ([rootViewController isKindOfClass:[UITabBarController class]]) {
        UITabBarController *tabBarController = (UITabBarController *)rootViewController;
        UIViewController *selectedViewController = tabBarController.selectedViewController;
        
        if ([selectedViewController isKindOfClass:[UINavigationController class]]) {
            UINavigationController *navigationController = (UINavigationController *)selectedViewController;
            UIViewController *lastViewController = [[navigationController viewControllers] lastObject];
            
            return lastViewController;
        }
        
        return selectedViewController;
    }
    
    return rootViewController;
}

+ (UIWindow *)mnz_keyWindow {
    UIWindow *keyWindow;
    NSArray *windows = UIApplication.sharedApplication.windows;
    for (UIWindow *window in windows) {
        if (window.isKeyWindow) {
            keyWindow = window;
            break;
        }
    }
    return keyWindow;
}

@end
