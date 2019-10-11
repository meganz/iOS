
#import <UIKit/UIKit.h>

typedef NS_ENUM (NSInteger, MEGAChatStatus);

@interface UIColor (MNZCategory)

#pragma mark - Objects

+ (UIColor *)mnz_mainBarsColorForTraitCollection:(UITraitCollection *)traitCollection;

+ (UIColor *)mnz_background;
+ (UIColor *)mnz_label;

+ (UIColor *)mnz_basicButtonForTraitCollection:(UITraitCollection *)traitCollection;
+ (UIColor *)mnz_basicButtonTextColorForTraitCollection:(UITraitCollection *)traitCollection;

#pragma mark - Black

+ (UIColor *)mnz_black262626;
+ (UIColor *)mnz_black333333;
+ (UIColor *)mnz_black151412_09;
+ (UIColor *)mnz_black000000_01;

#pragma mark - Blue

+ (UIColor *)mnz_blue007AFF;
+ (UIColor *)mnz_blue2BA6DE;
+ (UIColor *)mnz_chatBlueForTraitCollection:(UITraitCollection *)traitCollection;


#pragma mark - Gray

+ (UIColor *)mnz_primaryGrayForTraitCollection:(UITraitCollection *)traitCollection;
+ (UIColor *)mnz_secondaryGrayForTraitCollection:(UITraitCollection *)traitCollection;
+ (UIColor *)mnz_tertiaryGrayForTraitCollection:(UITraitCollection *)traitCollection;
+ (UIColor *)mnz_chatGrayForTraitCollection:(UITraitCollection *)traitCollection;

+ (UIColor *)mnz_gray666666;
+ (UIColor *)mnz_gray777777;
+ (UIColor *)mnz_gray999999;
+ (UIColor *)mnz_grayCCCCCC;
+ (UIColor *)mnz_grayE2EAEA;
+ (UIColor *)mnz_grayD8D8D8;
+ (UIColor *)mnz_grayE3E3E3;
+ (UIColor *)mnz_grayEEEEEE;
+ (UIColor *)mnz_grayFAFAFA;
+ (UIColor *)mnz_grayFCFCFC;
+ (UIColor *)mnz_grayF7F7F7;
+ (UIColor *)mnz_grayF9F9F9;

#pragma mark - Green

+ (UIColor *)mnz_green00897B;
+ (UIColor *)mnz_turquoiseForTraitCollection:(UITraitCollection *)traitCollection;

+ (UIColor *)mnz_green00BFA5;
+ (UIColor *)mnz_green13E03C;
+ (UIColor *)mnz_green31B500;
+ (UIColor *)mnz_green899B9C;

#pragma mark - Orange

+ (UIColor *)mnz_orangeFFA500;
+ (UIColor *)mnz_orangeFFD300;

#pragma mark - Red

+ (UIColor *)mnz_redMainForTraitCollection:(UITraitCollection *)traitCollection;

+ (UIColor *)mnz_redMain;
+ (UIColor *)mnz_redError;
+ (UIColor *)mnz_redProI;
+ (UIColor *)mnz_redProII;
+ (UIColor *)mnz_redProIII;

#pragma mark - White

+ (UIColor *)mnz_whiteFFFFFF_02;

#pragma mark - Utils

+ (UIColor *)colorFromHexString:(NSString *)hexString;
+ (UIColor *)mnz_colorForStatusChange:(MEGAChatStatus)onlineStatus;

@end
