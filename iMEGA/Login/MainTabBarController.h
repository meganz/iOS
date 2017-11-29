#import <UIKit/UIKit.h>

#import "MEGASdkManager.h"

static NSInteger const CLOUD = 0;
static NSInteger const PHOTOS = 1;
static NSInteger const CHAT = 2;
static NSInteger const SHARES = 3;
static NSInteger const MYACCOUNT = 4;

@interface MainTabBarController : UITabBarController <MEGAChatDelegate>

- (void)setBadgeValueForChats;

@end
