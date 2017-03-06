
#import "UIFont+MNZCategory.h"

@implementation UIFont (MNZCategory)

+ (UIFont *)mnz_SFUILightWithSize:(CGFloat)size {
    NSParameterAssert(size >= 0.0f);
    
    UIFont *font;
    if (size >= 20.0f) {
        font = [UIFont fontWithName:@"SFUIDisplay-Light" size:size];
    } else {
        font = [UIFont fontWithName:@"SFUIText-Light" size:size];
    }
    
    return font;
}

+ (UIFont *)mnz_SFUIRegularWithSize:(CGFloat)size {
    NSParameterAssert(size >= 0.0f);
    
    UIFont *font;
    if (size >= 20.0f) {
        font = [UIFont fontWithName:@"SFUIDisplay-Regular" size:size];
    } else {
        font = [UIFont fontWithName:@"SFUIText-Regular" size:size];
    }
    
    return font;
}

@end
