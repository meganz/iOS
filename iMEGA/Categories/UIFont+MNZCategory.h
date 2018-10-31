
#import <UIKit/UIKit.h>

@interface UIFont (MNZCategory)

+ (UIFont *)mnz_SFUIRegularItalicWithSize:(CGFloat)size;
+ (UIFont *)mnz_SFUIMediumWithSize:(CGFloat)size;
+ (UIFont *)mnz_SFUILightWithSize:(CGFloat)size;
+ (UIFont *)mnz_SFUIRegularWithSize:(CGFloat)size;
+ (UIFont *)mnz_SFUISemiBoldWithSize:(CGFloat)size;

+ (UIFont *)mnz_defaultFontForPureEmojiStringWithEmojis:(NSUInteger)emojiCount;


/**
 Returns a matching font by the given text style and weight

 @param style UIFontTextStyle type
 @param weight UIFontWeight type
 @return a new font matching the given style and weight
 */
+ (UIFont *)preferredFontForTextStyle:(UIFontTextStyle)style weight:(UIFontWeight)weight;

/**
 @return a bold font based on the current font
 */
- (UIFont *)bold;

/**
 @return an italic font based on the current font
 */
- (UIFont *)italic;

@end
