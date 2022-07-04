
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT const NSInteger secondsInAMinute;
FOUNDATION_EXPORT const NSInteger secondsInAHour;
FOUNDATION_EXPORT const NSInteger secondsInADay;
FOUNDATION_EXPORT const NSInteger secondsInAWeek;
FOUNDATION_EXPORT const NSInteger secondsInAMonth_28;
FOUNDATION_EXPORT const NSInteger secondsInAMonth_29;
FOUNDATION_EXPORT const NSInteger secondsInAMonth_30;
FOUNDATION_EXPORT const NSInteger secondsInAMonth_31;
FOUNDATION_EXPORT const long long secondsInAYear;
FOUNDATION_EXPORT const long long secondsInAJulianYear;
FOUNDATION_EXPORT const long long secondsInAGregorianYear;

@interface NSDate (MNZCategory)

- (NSString *)mnz_formattedDefaultNameForMedia;

- (NSString *)mnz_formattedDateMediumTimeShortStyle;
- (NSString *)mnz_formattedHourAndMinutes;
- (NSString *)mnz_formattedDateMediumStyle;
- (NSString *)mnz_formattedMonthAndYear;
- (NSString *)mnz_formattedDateDayMonthYear;
- (NSString *)mnz_formattedAbbreviatedDayOfWeek;

- (BOOL)mnz_isInPastWeek;

- (NSString *)mnz_stringForLastMessageTs;

- (BOOL)isYesterday;

/// Convenience method that returns a formatted string representing the receiver's date formatted to a given date format
/// @param format NSString - String representing the desired date format
/// @return NSString representing the formatted date string
- (NSString *)formattedDateWithFormat:(NSString *)format;

/// Returns the number of days until the receiver's date. Returns 0 if the receiver is the same or earlier than now.
/// @return NSInteger representiation of days
- (NSInteger)daysUntil;

@end

NS_ASSUME_NONNULL_END
