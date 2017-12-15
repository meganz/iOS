
#import "UIApplication+MNZCategory.h"

@implementation UIApplication (MNZCategory)

+ (UIViewController *)mnz_visibleViewController {
    UIViewController *rootViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
    
    while (rootViewController.presentedViewController) {
        rootViewController = rootViewController.presentedViewController;
    }
    
    return rootViewController;
}

@end
