
#import "UIColor+MNZCategory.h"

#import "MEGAChatSdk.h"

@implementation UIColor (MNZCategory)

#pragma mark - Black

+ (UIColor *)mnz_black262626 {
    return [UIColor colorWithRed:38.0/255.0 green:38.0/255.0 blue:38.0/255.0 alpha:1.0];
}

+ (UIColor *)mnz_black333333 {
    return [UIColor colorWithRed:51.0/255.0 green:51.0/255.0 blue:51.0/255.0 alpha:1.0];
}

+ (UIColor *)mnz_black333333_02 {
    return [UIColor colorWithRed:51.0/255.0 green:51.0/255.0 blue:51.0/255.0 alpha:0.2];
}

+ (UIColor *)mnz_black000000_01 {
    return [UIColor colorWithRed:0.0  green:0.0  blue:0.0 alpha:0.100];
}

#pragma mark - Blue

+ (UIColor *)mnz_blue007AFF {
    return [UIColor colorWithRed:0.0 green:122.0/255.0 blue:1.0 alpha:1.0];
}

+ (UIColor *)mnz_blue2BA6DE {
    return [UIColor colorWithRed:43.0/255.0 green:166.0/255.0 blue:222.0/255.0 alpha:1.0];
}

#pragma mark - Gray

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

+ (UIColor *)mnz_grayCCCCCC {
    return [UIColor colorWithRed:204.0/255.0 green:204.0/255.0 blue:204.0/255.0 alpha:1.0];
}

+ (UIColor *)mnz_grayE2EAEA {
    return [UIColor colorWithRed:0.89f green:0.92f blue:0.92f alpha:1.0];
}

+ (UIColor *)mnz_grayE3E3E3 {
    return [UIColor colorWithRed:227.0/255.0 green:227.0/255.0 blue:227.0/255.0 alpha:1.0];
}

+ (UIColor *)mnz_grayEEEEEE {
    return [UIColor colorWithRed:238.0/255.0 green:238.0/255.0 blue:238.0/255.0 alpha:1.0];
}

+ (UIColor *)mnz_grayF1F1F2 {
    return [UIColor colorWithRed:241.0/255.0 green:241.0/255.0 blue:242.0/255.0 alpha:1.0];
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

#pragma mark - Green

+ (UIColor *)mnz_green00BFA5 {
    return [UIColor colorWithRed:0.0f green:0.75 blue:0.65 alpha:1.0f];
}

+ (UIColor *)mnz_green13E03C {
    return [UIColor colorWithRed:19.0f / 255.0f green:224.0f / 255.0f blue:60.0f / 255.0f alpha:1.0f];
}

+ (UIColor *)mnz_green31B500 {
    return [UIColor colorWithRed:49.0/255.0 green:181.0/255.0 blue:0.0 alpha:1.0];
}

#pragma mark - Orange

+ (UIColor *)mnz_orangeFFA500 {
    return [UIColor colorWithRed:1.0 green:165.0/255.0 blue:0.0 alpha:1.0];
}

#pragma mark - Red

+ (UIColor *)mnz_redE13339 {
    return [UIColor colorWithRed:225.0/255.0 green:51.0/255.0 blue:57.0/255.0 alpha:1.0];
}

+ (UIColor *)mnz_redDC191F {
    return [UIColor colorWithRed:220.0/255.0 green:25.0/255.0 blue:31.0/255.0 alpha:1.0];
}

+ (UIColor *)mnz_redF0373A {
    return [UIColor colorWithRed:240.0/255.0 green:55.0/255.0 blue:58.0/255.0 alpha:1.0];
}

+ (UIColor *)mnz_redFF4C52 {
    return [UIColor colorWithRed:1.0 green:76.0/255.0 blue:82.0/255.0 alpha:1.0];
}

+ (UIColor *)mnz_redFF4D52 {
    return [UIColor colorWithRed:1.0 green:77.0/255.0 blue:82.0/255.0 alpha:1.0];
}

+ (UIColor *)mnz_redD90007 {
    return [UIColor colorWithRed:217.0/255.0 green:0.0 blue:7.0/255.0 alpha:1.0];
}

+ (UIColor *)mnz_redFF333A {
    return [UIColor colorWithRed:255.0f / 255.0f green:51.0f / 255.0f blue:58.0f / 255.0f alpha:1.0f];
}

#pragma mark - Pink

+ (UIColor *)mnz_pinkFF1A53 {
    return [UIColor colorWithRed:1.0 green:26.0/255.0 blue:83.0/255.0 alpha:1.0];
}

#pragma mark - White

+ (UIColor *)mnz_whiteFFFFFF_02 {
    return [UIColor colorWithRed:1.0f green:1.0f blue:1.0f alpha:0.2];
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

+ (UIColor *)mnz_colorForStatusChange:(MEGAChatStatus)onlineStatus {
    UIColor *colorForStatusChange;
    switch (onlineStatus) {
        case MEGAChatStatusOffline:
            colorForStatusChange = [self mnz_gray666666];
            break;
            
        case MEGAChatStatusAway:
            colorForStatusChange = [self mnz_orangeFFA500];
            break;
            
        case MEGAChatStatusOnline:
            colorForStatusChange = [self mnz_green13E03C];
            break;
            
        case MEGAChatStatusBusy:
            colorForStatusChange = [self colorFromHexString:@"EB4444"];
            break;
            
        default:
            colorForStatusChange = nil;
            break;
    }
    
    return colorForStatusChange;
}

@end
