#import "UIApplication+MNZCategory.h"

#ifdef MNZ_SHARE_EXTENSION
#import "MEGAShare-Swift.h"
#else
#import "MEGA-Swift.h"
#endif

@implementation UIApplication (MNZCategory)

+ (UIViewController *)mnz_presentingViewController {
    UIViewController *rootViewController = UIApplication.mnz_keyWindow.rootViewController;
#ifndef MNZ_SHARE_EXTENSION
    if (rootViewController == nil) {
        // No connected scene (background launch) or no root yet: whatever the caller presents is lost.
        NSString *message = @"No presenting view controller: no key window in the connected scenes";
        MEGALogWarning(@"[App Lifecycle] %@", message);
        [CrashlyticsLogger logWithCategory:LogCategoryAppLifecycle
                                       msg:message
                                      file:@(__FILENAME__)
                                  function:@(__FUNCTION__)];
    }
#endif
    
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
    
    if (UIApplication.mainTabBarVisibleController) {
        return UIApplication.mainTabBarVisibleController;
    }
    
    return rootViewController;
}

+ (nullable UIWindow *)mnz_keyWindow {
    NSAssert([NSThread isMainThread], @"UIApplication+MNZCategory must be called from the main thread");
    NSSet <UIScene *> *connectedScenes = UIApplication.sharedApplication.connectedScenes;

    for (UIWindowScene *scene in connectedScenes) {
        for (UIWindow *window in scene.windows) {
            if (window.isKeyWindow) {
                return window;
            }
        }
    }
    return nil;
}

@end
