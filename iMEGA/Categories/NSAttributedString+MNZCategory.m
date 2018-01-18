
#import "NSAttributedString+MNZCategory.h"

#import <CoreText/CoreText.h>

@implementation NSAttributedString (MNZCategory)

+ (NSAttributedString *)mnz_attributedStringFromMessage:(NSString *)message
                                                   font:(UIFont *)font
                                                  color:(UIColor *)color {
    static NSCache *cache;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cache = [NSCache new];
        cache.countLimit = 1000;
    });
    NSAttributedString *cachedAttributedString = [cache objectForKey:[NSString stringWithFormat:@"%lu%@", (unsigned long)message.hash, color.description]];
    if (cachedAttributedString) {
        return cachedAttributedString;
    }
    
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:message];
    id base = @{
        NSForegroundColorAttributeName:color,
        NSFontAttributeName:font,
        NSParagraphStyleAttributeName:NSParagraphStyle.defaultParagraphStyle
    };
    [attributedString addAttributes:base range:(NSRange){0, attributedString.length}];
    
    // Fonts:
    UIFont *boldFont = [self alternativeFontFor:font isBold:YES isItalic:NO];
    UIFont *italicFont = [self alternativeFontFor:font isBold:NO isItalic:YES];
    UIFont *boldItalicFont = [self alternativeFontFor:font isBold:YES isItalic:YES];
    UIFont *monospaceFont = [UIFont fontWithName:@"Menlo" size:font.pointSize];

    // Parsers:
    NSDictionary *preformattedParser = @{
        @"regex":@"(```\n?)([^`]+?)(\n?```)",
        @"replace":@[@"", @1, @""],
        @"attributes":@[@{ }, @{ NSFontAttributeName:monospaceFont }, @{ }]
    };
    
    NSDictionary *monospaceParser = @{
        @"regex":@"(`)([^`]+?)(`)",
        @"replace":@[@"", @1, @""],
        @"attributes":@[@{ }, @{ NSFontAttributeName:monospaceFont }, @{ }]
    };
    
    NSDictionary *boldItalicParser1 = @{
        @"regex":@"(?<=[^\\w\\d\\*\\_]|^)(\\*)(\\_)([^\\s]*?)(\\_)(\\*)(?=[^\\w\\d\\_\\*]|$)",
        @"replace":@[@"", @"", @2, @"", @""],
        @"attributes":@[@{ }, @{ }, @{ NSFontAttributeName:boldItalicFont }, @{ }, @{ }]
    };
    
    NSDictionary *boldItalicParser2 = @{
        @"regex":@"(?<=[^\\w\\d\\*\\_]|^)(\\_)(\\*)([^\\s][^\\*\\n]*?|[^\\*\\n]*?[^\\s])(\\*)(\\_)(?=[^\\w\\d\\*\\_]|$)",
        @"replace":@[@"", @"", @2, @"", @""],
        @"attributes":@[@{ }, @{ }, @{ NSFontAttributeName:boldItalicFont }, @{ }, @{ }]
    };
    
    NSDictionary *boldParser = @{
        @"regex":@"(?<=[^\\w\\d]|^)(\\*)([^\\s][^\\*\\n]*?|[^\\*\\n]*?[^\\s])(\\*)(?=[^\\w\\d]|$)",
        @"replace":@[@"", @1, @""],
        @"attributes":@[@{ }, @{ NSFontAttributeName:boldFont }, @{ }]
    };

    NSDictionary *italicParser = @{
        @"regex":@"(?<=[^\\w\\d]|^)(\\_)([^\\_\\n]*?)(\\_)(?=[^\\w\\d]|$)",
        @"replace":@[@"", @1, @""],
        @"attributes":@[@{ }, @{ NSFontAttributeName:italicFont }, @{ }]
    };

    [self applyParser:preformattedParser toString:attributedString atRange:(NSRange){0, attributedString.string.length}];
    [self applyParser:monospaceParser toString:attributedString atRange:(NSRange){0, attributedString.string.length}];

    // The enumeration has to be done separately for every parser, because the string may mutate during the enumeration
    [attributedString enumerateAttribute:NSFontAttributeName inRange:NSMakeRange(0, attributedString.length) options:0 usingBlock:^(id value, NSRange range, BOOL *stop) {
        if (value) {
            UIFont *currentFont = (UIFont *)value;
            if ([currentFont.fontName isEqualToString:font.fontName]) {
                [self applyParser:boldItalicParser1 toString:attributedString atRange:range];
            }
        }
    }];
    
    [attributedString enumerateAttribute:NSFontAttributeName inRange:NSMakeRange(0, attributedString.length) options:0 usingBlock:^(id value, NSRange range, BOOL *stop) {
        if (value) {
            UIFont *currentFont = (UIFont *)value;
            if ([currentFont.fontName isEqualToString:font.fontName]) {
                [self applyParser:boldItalicParser2 toString:attributedString atRange:range];
            }
        }
    }];
    
    [attributedString enumerateAttribute:NSFontAttributeName inRange:NSMakeRange(0, attributedString.length) options:0 usingBlock:^(id value, NSRange range, BOOL *stop) {
        if (value) {
            UIFont *currentFont = (UIFont *)value;
            if ([currentFont.fontName isEqualToString:font.fontName]) {
                [self applyParser:boldParser toString:attributedString atRange:range];
            }
        }
    }];
    
    [attributedString enumerateAttribute:NSFontAttributeName inRange:NSMakeRange(0, attributedString.length) options:0 usingBlock:^(id value, NSRange range, BOOL *stop) {
        if (value) {
            UIFont *currentFont = (UIFont *)value;
            if ([currentFont.fontName isEqualToString:font.fontName]) {
                [self applyParser:italicParser toString:attributedString atRange:range];
            }
        }
    }];
    
    [cache setObject:attributedString forKey:[NSString stringWithFormat:@"%lu%@", (unsigned long)message.hash, color.description]];
    return attributedString;
}

#pragma mark - Private

+ (UIFont *)alternativeFontFor:(UIFont *)font isBold:(BOOL)bold isItalic:(BOOL)italic {
    static NSMutableDictionary *fonts;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        fonts = [NSMutableDictionary new];
    });

    if (!bold && !italic) {
        return font;
    }
    
    CGFloat size = font.pointSize;
    CFStringRef name = (__bridge CFStringRef)font.fontName;
    NSString *fontCacheKey = [NSString stringWithFormat:@"%@-%@-%@-%@", name, bold ? @"bold" : @"normal", italic ? @"italic" : @"normal", @(size)];
    if (fonts[fontCacheKey]) {
        return fonts[fontCacheKey];
    }
    
    CTFontRef ctBase = CTFontCreateWithName(name, size, NULL);
    CTFontRef ctAlt;
    if (bold && italic) {
        ctAlt = CTFontCreateCopyWithSymbolicTraits(ctBase, 0, NULL, kCTFontBoldTrait | kCTFontItalicTrait, kCTFontBoldTrait | kCTFontItalicTrait);
    } else if (bold) {
        ctAlt = CTFontCreateCopyWithSymbolicTraits(ctBase, 0, NULL, kCTFontBoldTrait, kCTFontBoldTrait);
    } else {
        ctAlt = CTFontCreateCopyWithSymbolicTraits(ctBase, 0, NULL, kCTFontItalicTrait, kCTFontItalicTrait);
    }
    CFStringRef altName = CTFontCopyName(ctAlt, kCTFontPostScriptNameKey);
    UIFont *altFont = [UIFont fontWithName:(__bridge NSString *)altName size:size] ?: font;
    fonts[fontCacheKey] = altFont;
    
    if (ctBase) {
        CFRelease(ctBase);
    }
    if (ctAlt) {
        CFRelease(ctAlt);
    }
    if (name) {
        CFRelease(name);
    }
    
    return altFont;
}

+ (NSUInteger)applyParser:(NSDictionary *)parser toString:(NSMutableAttributedString *)attributedString atRange:(NSRange)range {
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:parser[@"regex"]
                                                                           options:NSRegularExpressionAnchorsMatchLines error:nil];
    NSString *text = [attributedString.string copy];
    
    __block int nudge = 0;
    __block NSUInteger matches = 0;
    [regex enumerateMatchesInString:text options:0
                              range:range
                         usingBlock:^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop) {
                             
                             matches++;
                             NSMutableArray *substrs = [NSMutableArray new];
                             NSMutableArray *replacements = [NSMutableArray new];
                             
                             // Make an array with capturing groups:
                             for (int i = 0; i < match.numberOfRanges - 1; i++) {
                                 NSRange nudged = [match rangeAtIndex:i + 1];
                                 nudged.location -= nudge;
                                 substrs[i] = [attributedString attributedSubstringFromRange:nudged].mutableCopy;
                             }
                             
                             // Make an initial array for the replacements:
                             for (int i = 0; i < match.numberOfRanges - 1; i++) {
                                 NSString *repstr = parser[@"replace"][i];
                                 replacements[i] = [repstr isKindOfClass:NSNumber.class]
                                 ? substrs[repstr.intValue]
                                 : [[NSMutableAttributedString alloc] initWithString:repstr];
                             }
                             
                             // Add attributes to the strings of the previous array:
                             for (int i = 0; i < match.numberOfRanges - 1; i++) {
                                 id attributes = parser[@"attributes"][i];
                                 if (![attributes count]) {
                                     continue;
                                 }
                                 NSMutableDictionary *attributesCopy = [attributes mutableCopy];
                                 for (NSString *attributeName in attributes) {
                                     // Fonts:
                                     if ([attributeName isEqualToString:NSFontAttributeName] &&
                                         [attributes[attributeName] isKindOfClass:NSNumber.class] &&
                                         [substrs[[attributes[attributeName] intValue]] isKindOfClass:NSAttributedString.class]) {
                                         NSString *fontString = [substrs[[attributes[attributeName] intValue]] string];
                                         NSArray *components = [fontString componentsSeparatedByString:@","];
                                         if (components.count == 2) {
                                             NSString *fontName = components[0];
                                             CGFloat size = [components[1] doubleValue];
                                             UIFont *font = [UIFont fontWithName:fontName size:size];
                                             if (font) {
                                                 attributesCopy[attributeName] = font;
                                             }
                                         }
                                     }
                                 }
                                 NSMutableAttributedString *repl = replacements[i];
                                 [repl addAttributes:attributesCopy range:(NSRange){0, repl.length}];
                             }
                             
                             // Replace the matchess with the new attributed strings:
                             for (int i = 0; i < match.numberOfRanges - 1; i++) {
                                 NSRange nudged = [match rangeAtIndex:i + 1];
                                 nudged.location -= nudge;
                                 nudge += [substrs[i] length] - [replacements[i] length];
                                 [attributedString replaceCharactersInRange:nudged
                                              withAttributedString:replacements[i]];
                             }
                         }];
    
    return matches;
}

@end
