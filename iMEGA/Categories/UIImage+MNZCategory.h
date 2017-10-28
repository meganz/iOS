
#import <UIKit/UIKit.h>

@interface UIImage (MNZCategory)

+ (UIImage *)mnz_navigationBarShadow;
+ (UIImage *)mnz_navigationBarBackground;
+ (UIImage *)mnz_convertBitmapRGBA8ToUIImage:(unsigned char *)buffer
                               withWidth:(NSInteger)width
                              withHeight:(NSInteger)height;

@end
