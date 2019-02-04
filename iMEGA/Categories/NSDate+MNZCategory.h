
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSDate (MNZCategory)

- (NSString *)mnz_formattedDefaultNameForMedia;

- (NSString *)mnz_formattedHourAndMinutes;
- (NSString *)mnz_formattedDateMediumStyle;
- (NSString *)mnz_formattedMonthAndYear;

@end

NS_ASSUME_NONNULL_END
