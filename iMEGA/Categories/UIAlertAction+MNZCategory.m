
#import "UIAlertAction+MNZCategory.h"

@implementation UIAlertAction (MNZCategory)

- (void)mnz_setTitleTextColor:(UIColor *)color {
    [self setValue:color forKey:@"titleTextColor"];
}

@end
