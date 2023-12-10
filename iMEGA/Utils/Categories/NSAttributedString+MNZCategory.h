#import <Foundation/Foundation.h>

@interface NSAttributedString (MNZCategory)

+ (NSAttributedString *)mnz_attributedStringFromMessage:(NSString *)message
                                                   font:(UIFont *)font
                                                  color:(UIColor *)color;

+ (NSAttributedString *)mnz_attributedStringFromImage:(UIImage *)sourceImage fontCapHeight:(CGFloat)capHeight;

@end
