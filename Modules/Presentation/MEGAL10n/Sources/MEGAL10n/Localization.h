#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#define LocalizedString(key, developerComment)  [Localization localizedValueForKey:key comment:developerComment]

@interface Localization: NSObject

+ (NSString *)localizedValueForKey:(NSString *)key comment:(NSString *)comment;

@end

NS_ASSUME_NONNULL_END
