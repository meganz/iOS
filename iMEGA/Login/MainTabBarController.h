#import <UIKit/UIKit.h>

#import "MEGASdkManager.h"

static NSInteger const CLOUD        = 0;
static NSInteger const PHOTOS       = 1;
static NSInteger const HOME         = 2;
static NSInteger const CHAT         = 3;
static NSInteger const SHARES       = 4;

@interface MainTabBarController : UITabBarController <MEGAChatDelegate>

- (void)openChatRoomNumber:(NSNumber *)chatNumber;
- (void)openChatRoomWithPublicLink:(NSString *)publicLink chatID:(uint64_t)chatNumber;

- (void)showAchievements;
- (void)showOffline;

- (void)setBadgeValueForChats;

@end
