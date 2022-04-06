
#import "NSDate+MNZCategory.h"

@import DateToolsObjc;

const NSInteger secondsInAMinute = 60;
const NSInteger secondsInAHour = 60 * 60;
const NSInteger secondsInADay = 3600 * 24;
const NSInteger secondsInAWeek = 86400 * 7;
const NSInteger secondsInAMonth_28 = 86400 * 28;
const NSInteger secondsInAMonth_29 = 86400 * 29;
const NSInteger secondsInAMonth_30 = 86400 * 30;
const NSInteger secondsInAMonth_31 = 86400 * 31;
const long long secondsInAYear = 86400 * 365;
const long long secondsInAGregorianYear = 86400 * 365.2425;
const long long secondsInAJulianYear = 86400 * 365.25;

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

- (NSString *)mnz_formattedDateMediumTimeShortStyle {
    static NSDateFormatter *defaultNameForMediaDateFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        defaultNameForMediaDateFormatter = NSDateFormatter.alloc.init;
        defaultNameForMediaDateFormatter.dateStyle = NSDateFormatterMediumStyle;
        defaultNameForMediaDateFormatter.timeStyle = NSDateFormatterShortStyle;
        defaultNameForMediaDateFormatter.locale = NSLocale.autoupdatingCurrentLocale;
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

- (NSString *)mnz_formattedDateMediumStyle {
    static NSDateFormatter *dateMediumStyleDateFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dateMediumStyleDateFormatter = NSDateFormatter.alloc.init;
        dateMediumStyleDateFormatter.dateStyle = NSDateFormatterMediumStyle;
        dateMediumStyleDateFormatter.timeStyle = NSDateFormatterNoStyle;
        dateMediumStyleDateFormatter.locale = NSLocale.autoupdatingCurrentLocale;
    });
    
    return [dateMediumStyleDateFormatter stringFromDate:self];
}

- (NSString *)mnz_formattedDateDayMonthYear {
    static NSDateFormatter *dayMonthYearDateFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dayMonthYearDateFormatter = NSDateFormatter.alloc.init;
        [dayMonthYearDateFormatter setLocalizedDateFormatFromTemplate:@"ddyyMM"];
        dayMonthYearDateFormatter.locale = NSLocale.autoupdatingCurrentLocale;
    });
    
    return [dayMonthYearDateFormatter stringFromDate:self];
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

- (NSString *)mnz_formattedAbbreviatedDayOfWeek {
    static NSDateFormatter *monthAndYearDateFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        monthAndYearDateFormatter = NSDateFormatter.alloc.init;
        monthAndYearDateFormatter.dateFormat = @"EEE";
        monthAndYearDateFormatter.locale = NSLocale.autoupdatingCurrentLocale;
    });
    
    return [monthAndYearDateFormatter stringFromDate:self];
}

- (BOOL)mnz_isInPastWeek{
    NSDate *oneWeekAgo = [NSCalendar.currentCalendar dateByAddingUnit:NSCalendarUnitDay value:-7 toDate:NSDate.date options:0];

    return [self compare:oneWeekAgo] == NSOrderedDescending;
}

- (NSString *)mnz_stringForLastMessageTs {
    if (self.isToday) {
        return self.mnz_formattedHourAndMinutes;
    } else if (self.mnz_isInPastWeek) {
        return self.mnz_formattedAbbreviatedDayOfWeek;
    } else {
        return self.mnz_formattedDateDayMonthYear;
    }
}

@end
