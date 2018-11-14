
#import <UIKit/UIKit.h>

@interface UIFont (MNZCategory)

+ (UIFont *)mnz_SFUIRegularItalicWithSize:(CGFloat)size;
+ (UIFont *)mnz_SFUIMediumWithSize:(CGFloat)size;
+ (UIFont *)mnz_SFUILightWithSize:(CGFloat)size;
+ (UIFont *)mnz_SFUIRegularWithSize:(CGFloat)size;
+ (UIFont *)mnz_SFUISemiBoldWithSize:(CGFloat)size;

+ (UIFont *)mnz_defaultFontForPureEmojiStringWithEmojis:(NSUInteger)emojiCount;



/**
 Returns a system font object that is the same size as the receiver but which has the specified weight instead.

 @param weight UIFontWeight
 @return a system font of the specified weight
 */
- (UIFont *)fontWithWeight:(UIFontWeight)weight;

/**
 @return Returns a font object that is the same as the receiver but which has bold style.
 */
- (UIFont *)bold;

/**
 @return Returns a font object that is the same as the receiver but which has italic style.
 */
- (UIFont *)italic;

@end
