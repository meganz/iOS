
#import "UIScreen+MNZCategory.h"

@implementation UIScreen (MNZCategory)

- (CGFloat)mnz_screenWidth {
    return (UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation) ? [[UIScreen mainScreen] bounds].size.width : [[UIScreen mainScreen] bounds].size.height);
}

@end
