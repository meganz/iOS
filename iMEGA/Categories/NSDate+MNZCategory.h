
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

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
