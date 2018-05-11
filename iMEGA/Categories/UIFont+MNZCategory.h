
#import <UIKit/UIKit.h>

@interface UIFont (MNZCategory)

+ (UIFont *)mnz_SFUIRegularItalicWithSize:(CGFloat)size;
+ (UIFont *)mnz_SFUIMediumWithSize:(CGFloat)size;
+ (UIFont *)mnz_SFUILightWithSize:(CGFloat)size;
+ (UIFont *)mnz_SFUIRegularWithSize:(CGFloat)size;
+ (UIFont *)mnz_SFUISemiBoldWithSize:(CGFloat)size;

+ (UIFont *)mnz_defaultFontForPureEmojiStringWithEmojis:(NSUInteger)emojiCount;

@end
