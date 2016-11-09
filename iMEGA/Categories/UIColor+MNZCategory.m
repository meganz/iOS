
#import "UIColor+MNZCategory.h"

@implementation UIColor (MNZCategory)

+ (UIColor *)mnz_black333333 {
    return [UIColor colorWithRed:51.0/255.0 green:51.0/255.0 blue:51.0/255.0 alpha:1.0];
}

+ (UIColor *)mnz_blue2BA6DE {
    return [UIColor colorWithRed:43.0/255.0 green:166.0/255.0 blue:222.0/255.0 alpha:1.0];
}

+ (UIColor *)mnz_green31B500 {
    return [UIColor colorWithRed:49.0/255.0 green:181.0/255.0 blue:0.0 alpha:1.0];
}

+ (UIColor *)mnz_gray666666 {
    return [UIColor colorWithRed:102.0/255.0 green:102.0/255.0 blue:102.0/255.0 alpha:1.0];
}

+ (UIColor *)mnz_gray777777 {
    return [UIColor colorWithRed:119.0/255.0 green:119.0/255.0 blue:119.0/255.0 alpha:1.0];
}

+ (UIColor *)mnz_gray8A8A8A {
    return [UIColor colorWithRed:138.0/255.0 green:138.0/255.0 blue:138.0/255.0 alpha:1.0];
}

+ (UIColor *)mnz_gray999999 {
    return [UIColor colorWithRed:153.0/255.0 green:153.0/255.0 blue:153.0/255.0 alpha:1.0];
}

+ (UIColor *)mnz_grayE3E3E3 {
    return [UIColor colorWithRed:227.0/255.0 green:227.0/255.0 blue:227.0/255.0 alpha:1.0];
}

+ (UIColor *)mnz_grayF5F5F5 {
    return [UIColor colorWithRed:245.0/255.0 green:245.0/255.0 blue:245.0/255.0 alpha:1.0];
}

+ (UIColor *)mnz_grayF7F7F7 {
    return [UIColor colorWithRed:247.0/255.0 green:247.0/255.0 blue:247.0/255.0 alpha:1.0];
}

+ (UIColor *)mnz_grayF9F9F9 {
    return [UIColor colorWithRed:249.0/255.0 green:249.0/255.0 blue:249.0/255.0 alpha:1.0];
}

+ (UIColor *)mnz_orangeFFA500 {
    return [UIColor colorWithRed:1.0 green:165.0/255.0 blue:0.0 alpha:1.0];
}

+ (UIColor *)mnz_redE13339 {
    return [UIColor colorWithRed:225.0/255.0 green:51.0/255.0 blue:57.0/255.0 alpha:1.0];
}

+ (UIColor *)mnz_redDC191F {
    return [UIColor colorWithRed:220.0/255.0 green:25.0/255.0 blue:31.0/255.0 alpha:1.0];
}

+ (UIColor *)mnz_redFF4C52 {
    return [UIColor colorWithRed:1.0 green:76.0/255.0 blue:82.0/255.0 alpha:1.0];
}

+ (UIColor *)mnz_redD90007 {
    return [UIColor colorWithRed:217.0/255.0 green:0.0 blue:7.0/255.0 alpha:1.0];
}

+ (UIColor *)mnz_pinkFF1A53 {
    return [UIColor colorWithRed:1.0 green:26.0/255.0 blue:83.0/255.0 alpha:1.0];
}

+ (UIColor *)colorFromHexString:(NSString *)hexString {
    unsigned rgbValue = 0;
    
    if([[hexString substringToIndex:1] isEqualToString:@"#"]) {
        hexString = [hexString substringFromIndex:1];
    }
    
    NSScanner *scanner = [NSScanner scannerWithString:hexString];
    if (![scanner scanHexInt:&rgbValue]) {
        return nil;
    }
    
    CGFloat r = (rgbValue & 0xFF0000) >> 16;
    CGFloat g = (rgbValue & 0xFF00) >> 8;
    CGFloat b = (rgbValue & 0xFF);
    
    return [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:1.0];
}

#pragma mark - MEGAChat colors

+ (UIColor *)mzn_vividGreen13E03C {
    return [UIColor colorWithRed:19.0f / 255.0f green:224.0f / 255.0f blue:60.0f / 255.0f alpha:1.0f];
}

+ (UIColor *)mzn_brownishGrey666666 {
    return [UIColor colorWithWhite:102.0f / 255.0f alpha:1.0f];
}

@end
