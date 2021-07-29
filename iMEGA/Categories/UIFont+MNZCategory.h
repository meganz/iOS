
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIFont (MNZCategory)

+ (nullable UIFont *)mnz_defaultFontForPureEmojiStringWithEmojis:(NSUInteger)emojiCount;
+ (UIFont *)mnz_preferredFontWithStyle:(UIFontTextStyle)style weight:(UIFontWeight)weight;

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

NS_ASSUME_NONNULL_END
