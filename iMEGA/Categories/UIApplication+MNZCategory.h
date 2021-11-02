
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIApplication (MNZCategory)

/* The view controller used to present other view controllers */
+ (UIViewController *)mnz_presentingViewController;

/* The visible view controller */
+ (UIViewController *)mnz_visibleViewController;

+ (nullable UIWindow * )mnz_keyWindow;

@end

NS_ASSUME_NONNULL_END
