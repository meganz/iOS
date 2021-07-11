
#import "UIFont+MNZCategory.h"

@implementation UIFont (MNZCategory)

+ (UIFont *)mnz_defaultFontForPureEmojiStringWithEmojis:(NSUInteger)emojiCount {
    CGFloat size = 15.0f;
    
    if (emojiCount == 1) {
        size = 45.0f;
    } else if (emojiCount == 2) {
        size = 35.0f;
    } else if (emojiCount == 3) {
        size = 25.0f;
    }
    return [UIFont fontWithName:@"Apple color emoji" size:size];
}

- (UIFont *)bold {
    return [UIFont fontWithDescriptor:[self.fontDescriptor fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitBold] size:0];
}

- (UIFont *)italic {
    return [UIFont fontWithDescriptor:[self.fontDescriptor fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitItalic] size:0];
}

- (UIFont *)fontWithWeight:(UIFontWeight)weight {
    return [UIFont systemFontOfSize:self.pointSize weight:weight];
}

+ (UIFont *)mnz_preferredFontWithStyle:(UIFontTextStyle)style weight:(UIFontWeight)weight {
    UIFont *font = [UIFont preferredFontForTextStyle:style];
    return [UIFont systemFontOfSize:font.pointSize weight:weight];
}

@end
