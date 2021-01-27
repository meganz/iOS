#import <UIKit/UIKit.h>

#import "MEGASdkManager.h"

@class Tab;

@interface MainTabBarController : UITabBarController <MEGAChatDelegate>

- (void)openChatRoomNumber:(NSNumber *)chatNumber;
- (void)openChatRoomWithPublicLink:(NSString *)publicLink chatID:(uint64_t)chatNumber;

- (void)showAchievements;
- (void)showOffline;
- (void)showUploadFile;
- (void)showScanDocument;
- (void)showStartConversation;
- (void)showAddContact;

- (void)setBadgeValueForChats;

@end
