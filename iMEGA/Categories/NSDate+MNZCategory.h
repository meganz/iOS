
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

@end

NS_ASSUME_NONNULL_END
