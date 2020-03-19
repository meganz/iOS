
#import <UIKit/UIKit.h>

typedef NS_ENUM (NSInteger, MEGAChatStatus);

@interface UIColor (MNZCategory)

#pragma mark - Objects

+ (UIColor *)mnz_mainBarsColorForTraitCollection:(UITraitCollection *)traitCollection;

+ (UIColor *)mnz_background;

+ (UIColor *)mnz_accountViewsBackgroundColorForTraitCollection:(UITraitCollection *)traitCollection;
+ (UIColor *)mnz_inputsBackgroundColorForTraitCollection:(UITraitCollection *)traitCollection;

+ (UIColor *)mnz_label;

+ (UIColor *)mnz_basicButtonForTraitCollection:(UITraitCollection *)traitCollection;

+ (UIColor *)mnz_subtitlesColorForTraitCollection:(UITraitCollection *)traitCollection;

+ (UIColor *)mnz_separatorColorForTraitCollection:(UITraitCollection *)traitCollection;

+ (UIColor *)mnz_settingsBackgroundForTraitCollection:(UITraitCollection *)traitCollection;
+ (UIColor *)mnz_settingsDetailsBackgroundForTraitCollection:(UITraitCollection *)traitCollection;

+ (UIColor *)mnz_notificationSeenBackgroundForTraitCollection:(UITraitCollection *)traitCollection;
+ (UIColor *)mnz_notificationUnseenBackgroundForTraitCollection:(UITraitCollection *)traitCollection;

#pragma mark - Black

+ (UIColor *)mnz_black000000_01;

#pragma mark - Blue

+ (UIColor *)mnz_chatBlueForTraitCollection:(UITraitCollection *)traitCollection;

+ (UIColor *)mnz_blue2BA6DE;

#pragma mark - Gray

+ (UIColor *)mnz_primaryGrayForTraitCollection:(UITraitCollection *)traitCollection;
+ (UIColor *)mnz_secondaryGrayForTraitCollection:(UITraitCollection *)traitCollection;
+ (UIColor *)mnz_tertiaryGrayForTraitCollection:(UITraitCollection *)traitCollection;

+ (UIColor *)mnz_chatGrayForTraitCollection:(UITraitCollection *)traitCollection;

+ (UIColor *)mnz_grayFAFAFA;
+ (UIColor *)mnz_grayF7F7F7;

#pragma mark - Green

+ (UIColor *)mnz_turquoiseForTraitCollection:(UITraitCollection *)traitCollection;

// This is used for the Contacts label in notifications and will stay the same for light and dark
+ (UIColor *)mnz_green00897B;
+ (UIColor *)mnz_green31B500;

#pragma mark - Orange

// This is used for the Incoming & Outgoing label in notifications and will stay the same for light and dark
+ (UIColor *)mnz_orangeFFA500;
// This is used for the Incoming & Outgoing label in notifications and will stay the same for light and dark
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
