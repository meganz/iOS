
#import "UIFont+MNZCategory.h"

@implementation UIFont (MNZCategory)

+ (UIFont *)mnz_SFUIRegularItalicWithSize:(CGFloat)size {
    NSParameterAssert(size >= 0.0f);
    
    return [UIFont fontWithName:@"SFUIText-Italic" size:size];
}

+ (UIFont *)mnz_SFUIMediumWithSize:(CGFloat)size {
    NSParameterAssert(size >= 0.0f);
    
    UIFont *font;
    if (size >= 20.0f) {
        font = [UIFont fontWithName:@"SFUIDisplay-Medium" size:size];
    } else {
        font = [UIFont fontWithName:@"SFUIText-Medium" size:size];
    }
    
    return font;
}

+ (UIFont *)mnz_SFUILightWithSize:(CGFloat)size {
    NSParameterAssert(size >= 0.0f);
    
    UIFont *font;
    if (size >= 20.0f) {
        font = [UIFont fontWithName:@"SFUIDisplay-Light" size:size];
    } else {
        font = [UIFont fontWithName:@"SFUIText-Light" size:size];
    }
    
    return font;
}

+ (UIFont *)mnz_SFUIRegularWithSize:(CGFloat)size {
    NSParameterAssert(size >= 0.0f);
    
    UIFont *font;
    if (size >= 20.0f) {
        font = [UIFont fontWithName:@"SFUIDisplay-Regular" size:size];
    } else {
        font = [UIFont fontWithName:@"SFUIText-Regular" size:size];
    }
    
    return font;
}

+ (UIFont *)mnz_SFUISemiBoldWithSize:(CGFloat)size {
    NSParameterAssert(size >= 0.0f);
    
    UIFont *font;
    if (size >= 20.0f) {
        font = [UIFont fontWithName:@"SFUIDisplay-Semibold" size:size];
    } else {
        font = [UIFont fontWithName:@"SFUIText-Semibold" size:size];
    }
    
    return font;
}

+ (UIFont *)mnz_defaultFontForPureEmojiStringWithEmojis:(NSUInteger)emojiCount {
    CGFloat size = 15.0f;
    
    if (emojiCount == 1) {
        size = 45.0f;
    } else if (emojiCount == 2) {
        size = 35.0f;
    } else if (emojiCount == 3) {
        size = 25.0f;
    }
    
    return [UIFont mnz_SFUIRegularWithSize:size];
}

@end
