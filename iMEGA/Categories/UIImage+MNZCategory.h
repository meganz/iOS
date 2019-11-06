
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, MEGAChatMessageEndCallReason);

@interface UIImage (MNZCategory)

+ (UIImage *)mnz_convertBitmapRGBA8ToUIImage:(unsigned char *)buffer
                               withWidth:(NSInteger)width
                              withHeight:(NSInteger)height;

+ (UIImage *)mnz_imageForUserHandle:(uint64_t)userHandle size:(CGSize)size delegate:(id<MEGARequestDelegate>)delegate;
+ (UIImage *)mnz_imageForUserHandle:(uint64_t)userHandle name:(NSString *)name size:(CGSize)size delegate:(id<MEGARequestDelegate>)delegate;
+ (UIImage *)imageWithColor:(UIColor *)color andBounds:(CGRect)imgBounds;

+ (UIImage *)mnz_qrImageFromString:(NSString *)qrString withSize:(CGSize)size color:(UIColor *)color;

+ (UIImage *)mnz_imageByEndCallReason:(MEGAChatMessageEndCallReason)endCallReason userHandle:(uint64_t)userHandle;

+ (UIImage *)mnz_imageNamed:(NSString *)name scaledToSize:(CGSize)newSize;

@end
