
#import "NSDate+MNZCategory.h"

@implementation NSDate (MNZCategory)

- (NSString *)mnz_formattedDefaultNameForMedia {
    static NSDateFormatter *defaultNameForMediaDateFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        defaultNameForMediaDateFormatter = NSDateFormatter.alloc.init;
        defaultNameForMediaDateFormatter.dateFormat = @"yyyy'-'MM'-'dd' 'HH'.'mm'.'ss";
        defaultNameForMediaDateFormatter.locale = [NSLocale.alloc initWithLocaleIdentifier:@"en_US_POSIX"];
    });
    
    return [defaultNameForMediaDateFormatter stringFromDate:self];
}

- (NSString *)mnz_formattedHourAndMinutes {
    static NSDateFormatter *hourAndMinutesDateFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        hourAndMinutesDateFormatter = NSDateFormatter.alloc.init;
        hourAndMinutesDateFormatter.dateFormat = @"HH:mm";
        hourAndMinutesDateFormatter.locale = NSLocale.autoupdatingCurrentLocale;
    });
    
    return [hourAndMinutesDateFormatter stringFromDate:self];
}

- (NSString *)mnz_formattedMonthAndYear {
    static NSDateFormatter *monthAndYearDateFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        monthAndYearDateFormatter = NSDateFormatter.alloc.init;
        monthAndYearDateFormatter.dateFormat = @"LLLL yyyy";
        monthAndYearDateFormatter.locale = NSLocale.autoupdatingCurrentLocale;
    });
    
    return [monthAndYearDateFormatter stringFromDate:self];
}

@end
