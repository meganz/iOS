
#import <UIKit/UIKit.h>

typedef NS_ENUM (NSInteger, MEGAChatStatus);

@interface UIColor (MNZCategory)

#pragma mark - Black

+ (UIColor *)mnz_black333333;
+ (UIColor *)mnz_black333333_02;
+ (UIColor *)mnz_black000000_01;

#pragma mark - Blue

+ (UIColor *)mnz_blue2BA6DE;

#pragma mark - Gray

+ (UIColor *)mnz_gray666666;
+ (UIColor *)mnz_gray777777;
+ (UIColor *)mnz_gray8A8A8A;
+ (UIColor *)mnz_gray999999;
+ (UIColor *)mnz_grayE3E3E3;
+ (UIColor *)mnz_grayF5F5F5;
+ (UIColor *)mnz_grayCCCCCC;
+ (UIColor *)mnz_grayF7F7F7;
+ (UIColor *)mnz_grayF9F9F9;

#pragma mark - Green

+ (UIColor *)mnz_green31B500;
+ (UIColor *)mnz_green13E03C;

#pragma mark - Orange

+ (UIColor *)mnz_orangeFFA500;

#pragma mark - Red

+ (UIColor *)mnz_redE13339;
+ (UIColor *)mnz_redDC191F;
+ (UIColor *)mnz_redFF4C52;
+ (UIColor *)mnz_redFF4D52;
+ (UIColor *)mnz_redD90007;
+ (UIColor *)mnz_redFF333A;

#pragma mark - Pink

+ (UIColor *)mnz_pinkFF1A53;

+ (UIColor *)colorFromHexString:(NSString *)hexString;

+ (UIColor *)mnz_colorForStatusChange:(MEGAChatStatus)onlineStatus;

@end
