
#import "UIAlertAction+MNZCategory.h"

@implementation UIAlertAction (MNZCategory)

- (void)mnz_setTitleTextColor:(UIColor *)color {
    if ([[UIDevice currentDevice] systemVersionGreaterThanOrEqualVersion:@"8.3"]) {
        [self setValue:color forKey:@"titleTextColor"];
    }
}

@end
