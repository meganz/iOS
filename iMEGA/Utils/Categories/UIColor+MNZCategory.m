#import "UIColor+MNZCategory.h"

#import "MEGAChatSdk.h"
#ifdef MNZ_SHARE_EXTENSION
#import "MEGAShare-Swift.h"
#else
#import "MEGA-Swift.h"
#endif

@implementation UIColor (MNZCategory)

#pragma mark - Background

+ (UIColor *)mnz_background {
    return UIColor.systemBackgroundColor;
}

#pragma mark - Text

+ (UIColor *)mnz_label {
    return UIColor.labelColor;
}

#pragma mark - Gray

+ (UIColor *)mnz_primaryGrayForTraitCollection:(UITraitCollection *)traitCollection {
    switch (traitCollection.userInterfaceStyle) {
        case UIUserInterfaceStyleUnspecified:
        case UIUserInterfaceStyleLight: {
            if (traitCollection.accessibilityContrast == UIAccessibilityContrastHigh) {
                return UIColor.mnz_gray3D3D3D;
            } else {
                return UIColor.mnz_gray515151;
            }
        }
            
        case UIUserInterfaceStyleDark: {
            if (traitCollection.accessibilityContrast == UIAccessibilityContrastHigh) {
                return UIColor.mnz_grayE5E5E5;
            } else {
                return UIColor.mnz_grayD1D1D1;
            }
        }
    }
}

+ (UIColor *)mnz_secondaryGrayForTraitCollection:(UITraitCollection *)traitCollection {
    switch (traitCollection.userInterfaceStyle) {
        case UIUserInterfaceStyleUnspecified:
        case UIUserInterfaceStyleLight: {
            if (traitCollection.accessibilityContrast == UIAccessibilityContrastHigh) {
                return UIColor.mnz_gray676767;
            } else {
                return UIColor.mnz_gray848484;
            }
        }
            
        case UIUserInterfaceStyleDark: {
            if (traitCollection.accessibilityContrast == UIAccessibilityContrastHigh) {
                return UIColor.mnz_grayC9C9C9;
            } else {
                return UIColor.mnz_grayB5B5B5;
            }
        }
    }
}

+ (UIColor *)mnz_tertiaryGrayForTraitCollection:(UITraitCollection *)traitCollection {
    switch (traitCollection.userInterfaceStyle) {
        case UIUserInterfaceStyleUnspecified:
        case UIUserInterfaceStyleLight: {
            if (traitCollection.accessibilityContrast == UIAccessibilityContrastHigh) {
                return UIColor.mnz_gray949494;
            } else {
                return UIColor.mnz_grayBBBBBB;
            }
        }
            
        case UIUserInterfaceStyleDark: {
            if (traitCollection.accessibilityContrast == UIAccessibilityContrastHigh) {
                return UIColor.mnz_grayF4F4F4;
            } else {
                return UIColor.mnz_grayE2E2E2;
            }
        }
    }
}

+ (UIColor *)mnz_grayF7F7F7 {
    return [UIColor colorWithRed:247.0/255.0 green:247.0/255.0 blue:247.0/255.0 alpha:1.0];
}

#pragma mark Gradients

+ (UIColor *)mnz_grayC2C2C2 {
    return [UIColor colorWithRed:194.0/255.0 green:194.0/255.0 blue:194.0/255.0 alpha:1.0];
}

+ (UIColor *)mnz_grayDBDBDB {
    return [UIColor colorWithRed:219.0/255.0 green:219.0/255.0 blue:219.0/255.0 alpha:1.0];
}

#pragma mark - Green

+ (UIColor *)mnz_turquoiseForTraitCollection:(UITraitCollection *)traitCollection {
    switch (traitCollection.userInterfaceStyle) {
        case UIUserInterfaceStyleUnspecified:
        case UIUserInterfaceStyleLight: {
            if (traitCollection.accessibilityContrast == UIAccessibilityContrastHigh) {
                return UIColor.mnz_green347467;
            } else {
                return UIColor.mnz_green00A886;
            }
        }
            
        case UIUserInterfaceStyleDark: {
            if (traitCollection.accessibilityContrast == UIAccessibilityContrastHigh) {
                return UIColor.mnz_green00E9B9;
            } else {
                return UIColor.mnz_green00C29A;
            }
        }
    }
}

#pragma mark - Red

+ (UIColor *)mnz_redForTraitCollection:(UITraitCollection *)traitCollection {
    switch (traitCollection.userInterfaceStyle) {
        case UIUserInterfaceStyleUnspecified:
        case UIUserInterfaceStyleLight: {
            if (traitCollection.accessibilityContrast == UIAccessibilityContrastHigh) {
                return UIColor.mnz_redCE0A11;
            } else {
                return UIColor.mnz_redF30C14;
            }
        }
            
        case UIUserInterfaceStyleDark: {
            if (traitCollection.accessibilityContrast == UIAccessibilityContrastHigh) {
                return UIColor.mnz_redF95C61;
            } else {
                return UIColor.mnz_redF7363D;
            }
        }
    }
}

+ (UIColor *)mnz_redError {
    return UIColor.systemRedColor;
}

#pragma mark - Utils

+ (UIColor *)mnz_fromHexString:(NSString *)hexString {
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

+ (UIColor *)mnz_colorForChatStatus:(MEGAChatStatus)onlineStatus {
    UIColor *colorForStatusChange;
    switch (onlineStatus) {
        case MEGAChatStatusOffline:
            colorForStatusChange = [self mnz_primaryGrayForTraitCollection:UIScreen.mainScreen.traitCollection];
            break;
            
        case MEGAChatStatusAway:
            colorForStatusChange = [self systemOrangeColor];
            break;
            
        case MEGAChatStatusOnline:
            colorForStatusChange = UIColor.systemGreenColor;
            break;
            
        case MEGAChatStatusBusy:
            colorForStatusChange = [self mnz_redForTraitCollection:UIScreen.mainScreen.traitCollection];
            break;
            
        default:
            colorForStatusChange = nil;
            break;
    }
    
    return colorForStatusChange;
}

@end
