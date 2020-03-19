
#import "UIColor+MNZCategory.h"

#import "MEGAChatSdk.h"

@implementation UIColor (MNZCategory)

#pragma mark - Objects

+ (UIColor *)mnz_mainBarsColorForTraitCollection:(UITraitCollection *)traitCollection {
    if (@available(iOS 13.0, *)) {
        switch (traitCollection.userInterfaceStyle) {
            case UIUserInterfaceStyleUnspecified:
            case UIUserInterfaceStyleLight: {
                if (traitCollection.accessibilityContrast == UIAccessibilityContrastHigh) {
                    return UIColor.whiteColor;
                } else {
                    return [UIColor colorWithRed:247.0/255.0 green:247.0/255.0 blue:247.0/255.0 alpha:1.0];
                }
            }
                
            case UIUserInterfaceStyleDark: {
                if (traitCollection.accessibilityContrast == UIAccessibilityContrastHigh) {
                    return UIColor.blackColor;
                } else {
                    return [UIColor colorWithRed:22.0/255.0 green:22.0/255.0 blue:22.0/255.0 alpha:1.0];
                }
            }
        }
    } else {
        return [UIColor colorWithRed:247.0/255.0 green:247.0/255.0 blue:247.0/255.0 alpha:1.0];
    }
}

+ (UIColor *)mnz_background {
    if (@available(iOS 13.0, *)) {
        return UIColor.systemBackgroundColor;
    } else {
        return UIColor.whiteColor;
    }
}

+ (UIColor *)mnz_accountViewsBackgroundColorForTraitCollection:(UITraitCollection *)traitCollection {
    if (@available(iOS 13.0, *)) {
        switch (traitCollection.userInterfaceStyle) {
            case UIUserInterfaceStyleUnspecified:
            case UIUserInterfaceStyleLight: {
                if (traitCollection.accessibilityContrast == UIAccessibilityContrastHigh) {
                    return [UIColor colorFromHexString:@"F4F5F6"];
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

+ (UIColor *)mnz_inputsBackgroundColorForTraitCollection:(UITraitCollection *)traitCollection {
    if (@available(iOS 13.0, *)) {
        switch (traitCollection.userInterfaceStyle) {
            case UIUserInterfaceStyleUnspecified:
            case UIUserInterfaceStyleLight: {
                return UIColor.whiteColor;
            }
                
            case UIUserInterfaceStyleDark: {
                if (traitCollection.accessibilityContrast == UIAccessibilityContrastHigh) {
                    return [UIColor colorFromHexString:@"2C2C2E"];
                } else {
                    return [UIColor colorFromHexString:@"1C1C1E"];
                }
            }
        }
    } else {
        return UIColor.whiteColor;
    }
}

+ (UIColor *)mnz_label {
    if (@available(iOS 13.0, *)) {
        return UIColor.labelColor;
    } else {
        return UIColor.darkTextColor;
    }
}

+ (UIColor *)mnz_basicButtonForTraitCollection:(UITraitCollection *)traitCollection {
    if (@available(iOS 13.0, *)) {
        switch (traitCollection.userInterfaceStyle) {
            case UIUserInterfaceStyleUnspecified:
            case UIUserInterfaceStyleLight: {
                return UIColor.whiteColor;
            }
                
            case UIUserInterfaceStyleDark: {
                if (traitCollection.accessibilityContrast == UIAccessibilityContrastHigh) {
                    return [UIColor colorFromHexString:@"535356"];
                } else {
                    return [UIColor colorFromHexString:@"363638"];
                }
            }
        }
    } else {
        return UIColor.whiteColor;
    }
}

+ (UIColor *)mnz_subtitlesColorForTraitCollection:(UITraitCollection *)traitCollection {
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

+ (UIColor *)mnz_separatorColorForTraitCollection:(UITraitCollection *)traitCollection {
    if (@available(iOS 13.0, *)) {
        switch (traitCollection.userInterfaceStyle) {
            case UIUserInterfaceStyleUnspecified:
            case UIUserInterfaceStyleLight: {
                if (traitCollection.accessibilityContrast == UIAccessibilityContrastHigh) {
                    return [UIColor colorWithRed:60.f/255.f green:60.f/255.f blue:67.f/255.f alpha:.45];
                } else {
                    return [UIColor colorWithRed:60.f/255.f green:60.f/255.f blue:67.f/255.f alpha:.29];
                }
            }
                
            case UIUserInterfaceStyleDark: {
                if (traitCollection.accessibilityContrast == UIAccessibilityContrastHigh) {
                    return [UIColor colorFromHexString:@"545458"];
                } else {
                    return [UIColor colorWithRed:84.f/255.f green:84.f/255.f blue:88.f/255.f alpha:.65];
                }
            }
        }
    } else {
        return [UIColor colorWithRed:60.f/255.f green:60.f/255.f blue:67.f/255.f alpha:.29];
    }
}

+ (UIColor *)mnz_settingsBackgroundForTraitCollection:(UITraitCollection *)traitCollection {
    if (@available(iOS 13.0, *)) {
        switch (traitCollection.userInterfaceStyle) {
            case UIUserInterfaceStyleUnspecified:
            case UIUserInterfaceStyleLight: {
                if (traitCollection.accessibilityContrast == UIAccessibilityContrastHigh) {
                    return [UIColor colorFromHexString:@"E6E6E6"];
                } else {
                    return UIColor.mnz_grayF7F7F7;
                }
            }
                
            case UIUserInterfaceStyleDark: {
                return [UIColor mnz_mainBarsColorForTraitCollection:traitCollection];
            }
        }
    } else {
        return UIColor.mnz_grayF7F7F7;
    }
}

+ (UIColor *)mnz_settingsDetailsBackgroundForTraitCollection:(UITraitCollection *)traitCollection {
    if (@available(iOS 13.0, *)) {
        switch (traitCollection.userInterfaceStyle) {
            case UIUserInterfaceStyleUnspecified:
            case UIUserInterfaceStyleLight: {
                return UIColor.mnz_background;
            }
                
            case UIUserInterfaceStyleDark: {
                return [UIColor mnz_chatGrayForTraitCollection:traitCollection];
            }
        }
    } else {
        return UIColor.mnz_background;
    }
}

+ (UIColor *)mnz_notificationSeenBackgroundForTraitCollection:(UITraitCollection *)traitCollection {
    if (@available(iOS 13.0, *)) {
        switch (traitCollection.userInterfaceStyle) {
            case UIUserInterfaceStyleUnspecified:
            case UIUserInterfaceStyleLight: {
                return UIColor.mnz_grayFAFAFA;
            }
                
            case UIUserInterfaceStyleDark: {
                return [UIColor colorFromHexString:@"1C1C1E"];
            }
        }
    } else {
        return UIColor.mnz_grayFAFAFA;
    }
}

+ (UIColor *)mnz_notificationUnseenBackgroundForTraitCollection:(UITraitCollection *)traitCollection {
    if (@available(iOS 13.0, *)) {
        switch (traitCollection.userInterfaceStyle) {
            case UIUserInterfaceStyleUnspecified:
            case UIUserInterfaceStyleLight: {
                return UIColor.whiteColor;
            }
                
            case UIUserInterfaceStyleDark: {
                return [UIColor colorFromHexString:@"2C2C2E"];
            }
        }
    } else {
        return UIColor.whiteColor;
    }
}

#pragma mark - Black

+ (UIColor *)mnz_black000000_01 {
    return [UIColor colorWithRed:0.0  green:0.0  blue:0.0 alpha:0.100];
}

#pragma mark - Blue

+ (UIColor *)mnz_chatBlueForTraitCollection:(UITraitCollection *)traitCollection {
    if (@available(iOS 13.0, *)) {
        switch (traitCollection.userInterfaceStyle) {
            case UIUserInterfaceStyleUnspecified:
            case UIUserInterfaceStyleLight: {
                if (traitCollection.accessibilityContrast == UIAccessibilityContrastHigh) {
                    return [UIColor colorFromHexString:@"007FB9"];
                } else {
                    return [UIColor colorFromHexString:@"009AE0"];
                }
            }
                
            case UIUserInterfaceStyleDark: {
                if (traitCollection.accessibilityContrast == UIAccessibilityContrastHigh) {
                    return [UIColor colorFromHexString:@"059DE2"];
                } else {
                    return [UIColor colorFromHexString:@"13B2FA"];
                }
            }
        }
    } else {
        return [UIColor colorFromHexString:@"009AE0"];
    }
}

+ (UIColor *)mnz_blue2BA6DE {
    return [UIColor colorWithRed:43.0/255.0 green:166.0/255.0 blue:222.0/255.0 alpha:1.0];
}

#pragma mark - Gray

+ (UIColor *)mnz_primaryGrayForTraitCollection:(UITraitCollection *)traitCollection {
    if (@available(iOS 13.0, *)) {
        switch (traitCollection.userInterfaceStyle) {
            case UIUserInterfaceStyleUnspecified:
            case UIUserInterfaceStyleLight: {
                if (traitCollection.accessibilityContrast == UIAccessibilityContrastHigh) {
                    return [UIColor colorFromHexString:@"3D3D3D"];
                } else {
                    return [UIColor colorFromHexString:@"515151"];
                }
            }
                
            case UIUserInterfaceStyleDark: {
                if (traitCollection.accessibilityContrast == UIAccessibilityContrastHigh) {
                    return [UIColor colorFromHexString:@"E5E5E5"];
                } else {
                    return [UIColor colorFromHexString:@"D1D1D1"];
                }
            }
        }
    } else {
        return [UIColor colorFromHexString:@"515151"];
    }
}

+ (UIColor *)mnz_secondaryGrayForTraitCollection:(UITraitCollection *)traitCollection {
    if (@available(iOS 13.0, *)) {
        switch (traitCollection.userInterfaceStyle) {
            case UIUserInterfaceStyleUnspecified:
            case UIUserInterfaceStyleLight: {
                if (traitCollection.accessibilityContrast == UIAccessibilityContrastHigh) {
                    return [UIColor colorFromHexString:@"676767"];
                } else {
                    return [UIColor colorFromHexString:@"848484"];
                }
            }
                
            case UIUserInterfaceStyleDark: {
                if (traitCollection.accessibilityContrast == UIAccessibilityContrastHigh) {
                    return [UIColor colorFromHexString:@"C9C9C9"];
                } else {
                    return [UIColor colorFromHexString:@"B5B5B5"];
                }
            }
        }
    } else {
        return [UIColor colorFromHexString:@"848484"];
    }
}

+ (UIColor *)mnz_tertiaryGrayForTraitCollection:(UITraitCollection *)traitCollection {
    if (@available(iOS 13.0, *)) {
        switch (traitCollection.userInterfaceStyle) {
            case UIUserInterfaceStyleUnspecified:
            case UIUserInterfaceStyleLight: {
                if (traitCollection.accessibilityContrast == UIAccessibilityContrastHigh) {
                    return [UIColor colorFromHexString:@"949494"];
                } else {
                    return [UIColor colorFromHexString:@"BBBBBB"];
                }
            }
                
            case UIUserInterfaceStyleDark: {
                if (traitCollection.accessibilityContrast == UIAccessibilityContrastHigh) {
                    return [UIColor colorFromHexString:@"F4F4F4"];
                } else {
                    return [UIColor colorFromHexString:@"E2E2E2"];
                }
            }
        }
    } else {
        return [UIColor colorFromHexString:@"BBBBBB"];
    }
}

+ (UIColor *)mnz_chatGrayForTraitCollection:(UITraitCollection *)traitCollection {
    if (@available(iOS 13.0, *)) {
        switch (traitCollection.userInterfaceStyle) {
            case UIUserInterfaceStyleUnspecified:
            case UIUserInterfaceStyleLight: {
                if (traitCollection.accessibilityContrast == UIAccessibilityContrastHigh) {
                    return [UIColor colorFromHexString:@"F2F2F2"];
                } else {
                    return [UIColor colorWithRed:238.0/255.0 green:238.0/255.0 blue:238.0/255.0 alpha:1.0]; //EEEEEE
                }
            }
                
            case UIUserInterfaceStyleDark: {
                if (traitCollection.accessibilityContrast == UIAccessibilityContrastHigh) {
                    return [UIColor colorFromHexString:@"3F3F42"];
                } else {
                    return [UIColor colorFromHexString:@"2C2C2E"];
                }
            }
        }
    } else {
        return [UIColor colorWithRed:238.0/255.0 green:238.0/255.0 blue:238.0/255.0 alpha:1.0]; //EEEEEE
    }
}

+ (UIColor *)mnz_grayFAFAFA {
    return [UIColor colorWithRed:250.0/255.0 green:250.0/255.0 blue:250.0/255.0 alpha:1.0];
}

+ (UIColor *)mnz_grayF7F7F7 {
    return [UIColor colorWithRed:247.0/255.0 green:247.0/255.0 blue:247.0/255.0 alpha:1.0];
}

#pragma mark - Green

+ (UIColor *)mnz_turquoiseForTraitCollection:(UITraitCollection *)traitCollection {
    if (@available(iOS 13.0, *)) {
        switch (traitCollection.userInterfaceStyle) {
            case UIUserInterfaceStyleUnspecified:
            case UIUserInterfaceStyleLight: {
                if (traitCollection.accessibilityContrast == UIAccessibilityContrastHigh) {
                    return [UIColor colorFromHexString:@"347467"];
                } else {
                    return [UIColor colorFromHexString:@"00A886"];
                }
            }
                
            case UIUserInterfaceStyleDark: {
                if (traitCollection.accessibilityContrast == UIAccessibilityContrastHigh) {
                    return [UIColor colorFromHexString:@"00E9B9"];
                } else {
                    return [UIColor colorFromHexString:@"00C29A"];
                }
            }
        }
    } else {
        return [UIColor colorFromHexString:@"00A886"];
    }
}

+ (UIColor *)mnz_green00897B {
    return [UIColor colorWithRed:0.0f green:0.54 blue:0.48 alpha:1.0f];
}

+ (UIColor *)mnz_green31B500 {
    return [UIColor colorWithRed:49.0/255.0 green:181.0/255.0 blue:0.0 alpha:1.0];
}

#pragma mark - Orange

+ (UIColor *)mnz_orangeFFA500 {
    return [UIColor colorWithRed:1.0 green:165.0/255.0 blue:0.0 alpha:1.0];
}

+ (UIColor *)mnz_orangeFFD300 {
    return [UIColor colorWithRed:1 green:0.83 blue:0 alpha:1];
}

#pragma mark - Red

+ (UIColor *)mnz_redMainForTraitCollection:(UITraitCollection *)traitCollection {
    if (@available(iOS 13.0, *)) {
        switch (traitCollection.userInterfaceStyle) {
            case UIUserInterfaceStyleUnspecified:
            case UIUserInterfaceStyleLight: {
                if (traitCollection.accessibilityContrast == UIAccessibilityContrastHigh) {
                    return [UIColor colorFromHexString:@"CE0A11"];
                } else {
                    return UIColor.mnz_redMain;
                }
            }
                
            case UIUserInterfaceStyleDark: {
                if (traitCollection.accessibilityContrast == UIAccessibilityContrastHigh) {
                    return [UIColor colorFromHexString:@"F95C61"];
                } else {
                    return [UIColor colorFromHexString:@"F7363D"];
                }
            }
        }
    } else {
        return UIColor.mnz_redMain;
    }
}

+ (UIColor *)mnz_redMain {
    return [UIColor mnz_redF30C14];
}

+ (UIColor *)mnz_redError {
    if (@available(iOS 13.0, *)) {
        return UIColor.systemRedColor;
    } else {
        return [UIColor colorFromHexString:@"FF3B30"];
    }
}

+ (UIColor *)mnz_redProI {
    return [UIColor mnz_redE13339];
}

+ (UIColor *)mnz_redProII {
    return [UIColor mnz_redDC191F];
}

+ (UIColor *)mnz_redProIII {
    return [UIColor mnz_redD90007];
}

+ (UIColor *)mnz_redF30C14 {
    return [UIColor colorWithRed:243.0f / 255.0f green:12.0f / 255.0f blue:20.0f / 255.0f alpha:1.0f];
}

+ (UIColor *)mnz_redD90007 {
    return [UIColor colorWithRed:217.0/255.0 green:0.0 blue:7.0/255.0 alpha:1.0];
}

+ (UIColor *)mnz_redE13339 {
    return [UIColor colorWithRed:225.0/255.0 green:51.0/255.0 blue:57.0/255.0 alpha:1.0];
}

+ (UIColor *)mnz_redDC191F {
    return [UIColor colorWithRed:220.0/255.0 green:25.0/255.0 blue:31.0/255.0 alpha:1.0];
}

#pragma mark - White

+ (UIColor *)mnz_whiteFFFFFF_02 {
    return [UIColor colorWithRed:1.0f green:1.0f blue:1.0f alpha:0.2];
}

#pragma mark - Utils

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
            colorForStatusChange = [self mnz_primaryGrayForTraitCollection:UIScreen.mainScreen.traitCollection];
            break;
            
        case MEGAChatStatusAway:
            colorForStatusChange = [self mnz_orangeFFA500];
            break;
            
        case MEGAChatStatusOnline:
            colorForStatusChange = UIColor.systemGreenColor;
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
