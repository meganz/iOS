#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN
typedef NS_ENUM (NSInteger, MEGAChatStatus);

@interface UIColor (MNZCategory)

#pragma mark - Utils

+ (nullable UIColor *)mnz_colorForChatStatus:(MEGAChatStatus)onlineStatus;

@end
NS_ASSUME_NONNULL_END
