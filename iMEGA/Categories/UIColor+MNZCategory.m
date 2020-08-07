
#import "UIColor+MNZCategory.h"

#import "MEGAChatSdk.h"
#ifdef MNZ_SHARE_EXTENSION
#import "MEGAShare-Swift.h"
#elif MNZ_PICKER_EXTENSION
#import "MEGAPicker-Swift.h"
#else
#import "MEGA-Swift.h"
#endif

@implementation UIColor (MNZCategory)

#pragma mark - Background

+ (UIColor *)mnz_mainBarsForTraitCollection:(UITraitCollection *)traitCollection {
    if (@available(iOS 13.0, *)) {
        switch (traitCollection.userInterfaceStyle) {
            case UIUserInterfaceStyleUnspecified:
            case UIUserInterfaceStyleLight: {
                if (traitCollection.accessibilityContrast == UIAccessibilityContrastHigh) {
                    return UIColor.whiteColor;
                } else {
                    return UIColor.mnz_grayF7F7F7;
                }
            }
                
            case UIUserInterfaceStyleDark: {
                if (traitCollection.accessibilityContrast == UIAccessibilityContrastHigh) {
                    return UIColor.blackColor;
                } else {
                    return UIColor.mnz_black161616;
                }
            }
        }
    } else {
        return UIColor.mnz_grayF7F7F7;
    }
}

+ (UIColor *)mnz_background {
    if (@available(iOS 13.0, *)) {
        return UIColor.systemBackgroundColor;
    } else {
        return UIColor.whiteColor;
    }
}

+ (UIColor *)mnz_secondaryBackgroundForTraitCollection:(UITraitCollection *)traitCollection {
    if (@available(iOS 13.0, *)) {
        switch (traitCollection.userInterfaceStyle) {
            case UIUserInterfaceStyleUnspecified:
            case UIUserInterfaceStyleLight: {
                if (traitCollection.accessibilityContrast == UIAccessibilityContrastHigh) {
                    return UIColor.mnz_grayE6E6E6;
                } else {
                    return UIColor.mnz_grayF7F7F7;
                }
            }
                
            case UIUserInterfaceStyleDark: {
                if (traitCollection.accessibilityContrast == UIAccessibilityContrastHigh) {
                    return UIColor.mnz_black2C2C2E;
                } else {
                    return UIColor.mnz_black1C1C1E;
                }
            }
        }
    } else {
        return UIColor.mnz_grayF7F7F7;
    }
}

#pragma mark Background grouped

+ (UIColor *)mnz_backgroundGroupedForTraitCollection:(UITraitCollection *)traitCollection {
    if (@available(iOS 13.0, *)) {
        switch (traitCollection.userInterfaceStyle) {
            case UIUserInterfaceStyleUnspecified:
            case UIUserInterfaceStyleLight: {
                if (traitCollection.accessibilityContrast == UIAccessibilityContrastHigh) {
                    return UIColor.mnz_grayE6E6E6;
                } else {
                    return UIColor.mnz_grayF7F7F7;
                }
            }
                
            case UIUserInterfaceStyleDark: {
                return UIColor.blackColor;
            }
        }
    } else {
        return UIColor.mnz_grayF7F7F7;
    }
}

#pragma mark Background miscellany

+ (UIColor *)mnz_notificationSeenBackgroundForTraitCollection:(UITraitCollection *)traitCollection {
    if (@available(iOS 13.0, *)) {
        switch (traitCollection.userInterfaceStyle) {
            case UIUserInterfaceStyleUnspecified:
            case UIUserInterfaceStyleLight: {
                if (traitCollection.accessibilityContrast == UIAccessibilityContrastHigh) {
                    return UIColor.mnz_grayF7F7F7;
                } else {
                    return UIColor.mnz_grayFAFAFA;
                }
            }
                
            case UIUserInterfaceStyleDark: {
                if (traitCollection.accessibilityContrast == UIAccessibilityContrastHigh) {
                    return UIColor.mnz_black2C2C2E;
                } else {
                    return UIColor.mnz_black1C1C1E;
                }
            }
        }
    } else {
        return UIColor.mnz_grayFAFAFA;
    }
}

#pragma mark - Objects

+ (UIColor *)mnz_basicButtonForTraitCollection:(UITraitCollection *)traitCollection {
    if (@available(iOS 13.0, *)) {
        switch (traitCollection.userInterfaceStyle) {
            case UIUserInterfaceStyleUnspecified:
            case UIUserInterfaceStyleLight: {
                return UIColor.whiteColor;
            }
                
            case UIUserInterfaceStyleDark: {
                if (traitCollection.accessibilityContrast == UIAccessibilityContrastHigh) {
                    return UIColor.mnz_gray535356;
                } else {
                    return UIColor.mnz_gray363638;
                }
            }
        }
    } else {
        return UIColor.whiteColor;
    }
}

+ (UIColor *)mnz_separatorForTraitCollection:(UITraitCollection *)traitCollection {
    if (@available(iOS 13.0, *)) {
        switch (traitCollection.userInterfaceStyle) {
            case UIUserInterfaceStyleUnspecified:
            case UIUserInterfaceStyleLight: {
                if (traitCollection.accessibilityContrast == UIAccessibilityContrastHigh) {
                    return [UIColor.mnz_gray3C3C43 colorWithAlphaComponent:0.5];
                } else {
                    return [UIColor.mnz_gray3C3C43 colorWithAlphaComponent:0.3];
                }
            }
                
            case UIUserInterfaceStyleDark: {
                if (traitCollection.accessibilityContrast == UIAccessibilityContrastHigh) {
                    return UIColor.mnz_gray545458;
                } else {
                    return [UIColor.mnz_gray545458 colorWithAlphaComponent:0.65];
                }
            }
        }
    } else {
        return [UIColor.mnz_gray3C3C43 colorWithAlphaComponent:0.3];
    }
}

+ (UIColor *)mnz_handlebarForTraitCollection:(UITraitCollection *)traitCollection {
    if (@available(iOS 13.0, *)) {
        switch (traitCollection.userInterfaceStyle) {
            case UIUserInterfaceStyleUnspecified:
            case UIUserInterfaceStyleLight: {
                if (traitCollection.accessibilityContrast == UIAccessibilityContrastHigh) {
                    return [UIColor.mnz_gray04040F colorWithAlphaComponent:0.4];
                } else {
                    return [UIColor.mnz_gray04040F colorWithAlphaComponent:0.15];
                }
            }
                
            case UIUserInterfaceStyleDark: {
                if (traitCollection.accessibilityContrast == UIAccessibilityContrastHigh) {
                    return [UIColor.mnz_grayEBEBF5 colorWithAlphaComponent:0.6];
                } else {
                    return [UIColor.mnz_grayEBEBF5 colorWithAlphaComponent:0.3];
                }
            }
        }
    } else {
        return [UIColor.mnz_gray04040F colorWithAlphaComponent:0.15];
    }
}

#pragma mark - Text

+ (UIColor *)mnz_label {
    if (@available(iOS 13.0, *)) {
        return UIColor.labelColor;
    } else {
        return UIColor.darkTextColor;
    }
}

+ (UIColor *)mnz_subtitlesForTraitCollection:(UITraitCollection *)traitCollection {
    if (@available(iOS 13.0, *)) {
        switch (traitCollection.userInterfaceStyle) {
            case UIUserInterfaceStyleUnspecified:
            case UIUserInterfaceStyleLight: {
                return [UIColor colorWithRed:0 green:0 blue:0 alpha:.8];
            }
                
            case UIUserInterfaceStyleDark: {
                return [UIColor colorWithWhite:1 alpha:.8];
            }
        }
    } else {
        return [UIColor colorWithRed:0 green:0 blue:0 alpha:.8];
    }
}

#pragma mark - Blue

+ (UIColor *)mnz_blueForTraitCollection:(UITraitCollection *)traitCollection {
    if (@available(iOS 13.0, *)) {
        switch (traitCollection.userInterfaceStyle) {
            case UIUserInterfaceStyleUnspecified:
            case UIUserInterfaceStyleLight: {
                if (traitCollection.accessibilityContrast == UIAccessibilityContrastHigh) {
                    return UIColor.mnz_blue0089C7;
                } else {
                    return UIColor.mnz_blue009AE0;
                }
            }
                
            case UIUserInterfaceStyleDark: {
                if (traitCollection.accessibilityContrast == UIAccessibilityContrastHigh) {
                    return UIColor.mnz_blue38C1FF;
                } else {
                    return UIColor.mnz_blue059DE2;
                }
            }
        }
    } else {
        return UIColor.mnz_blue009AE0;
    }
}

#pragma mark - Gray

+ (UIColor *)mnz_primaryGrayForTraitCollection:(UITraitCollection *)traitCollection {
    if (@available(iOS 13.0, *)) {
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
    } else {
        return UIColor.mnz_gray515151;
    }
}

+ (UIColor *)mnz_secondaryGrayForTraitCollection:(UITraitCollection *)traitCollection {
    if (@available(iOS 13.0, *)) {
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
    } else {
        return UIColor.mnz_gray848484;
    }
}

+ (UIColor *)mnz_tertiaryGrayForTraitCollection:(UITraitCollection *)traitCollection {
    if (@available(iOS 13.0, *)) {
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
    } else {
        return UIColor.mnz_grayBBBBBB;
    }
}

+ (UIColor *)mnz_grayFAFAFA {
    return [UIColor colorWithRed:250.0/255.0 green:250.0/255.0 blue:250.0/255.0 alpha:1.0];
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
    if (@available(iOS 13.0, *)) {
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
    } else {
        return UIColor.mnz_green00A886;
    }
}

#pragma mark - Red

+ (UIColor *)mnz_redForTraitCollection:(UITraitCollection *)traitCollection {
    if (@available(iOS 13.0, *)) {
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
    } else {
        return UIColor.mnz_redF30C14;
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
