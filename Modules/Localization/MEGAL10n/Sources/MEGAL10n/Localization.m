#import "Localization.h"

@implementation Localization

+ (NSString *)localizedValueForKey:(NSString *)key comment:(NSString *)comment {
    return [SWIFTPM_MODULE_BUNDLE localizedStringForKey:key value:key table:@"Localizable"];
}

@end
