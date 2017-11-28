#import <UIKit/UIKit.h>

#import "MEGASdkManager.h"

@interface MainTabBarController : UITabBarController <MEGAChatDelegate>

- (void)setBadgeValueForChats;
- (NSInteger)tabPositionForTag:(NSInteger)tag;

@end
