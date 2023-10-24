#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN
typedef NS_ENUM (NSInteger, MEGAChatStatus);

@interface UIColor (MNZCategory)

#pragma mark - Background

+ (UIColor *)mnz_background;

#pragma mark - Text

+ (UIColor *)mnz_label;

#pragma mark - Gray

+ (UIColor *)mnz_primaryGrayForTraitCollection:(UITraitCollection *)traitCollection;
+ (UIColor *)mnz_secondaryGrayForTraitCollection:(UITraitCollection *)traitCollection;
+ (UIColor *)mnz_tertiaryGrayForTraitCollection:(UITraitCollection *)traitCollection;

+ (UIColor *)mnz_grayF7F7F7;

#pragma mark Gradients

+ (UIColor *)mnz_grayC2C2C2;
+ (UIColor *)mnz_grayDBDBDB;

#pragma mark - Green

+ (UIColor *)mnz_turquoiseForTraitCollection:(UITraitCollection *)traitCollection;

#pragma mark - Red

+ (UIColor *)mnz_redForTraitCollection:(UITraitCollection *)traitCollection;

+ (UIColor *)mnz_redError;

#pragma mark - Utils

+ (nullable UIColor *)mnz_fromHexString:(NSString *)hexString;
+ (nullable UIColor *)mnz_colorForChatStatus:(MEGAChatStatus)onlineStatus;

@end
NS_ASSUME_NONNULL_END
