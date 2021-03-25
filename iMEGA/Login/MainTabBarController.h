#import <UIKit/UIKit.h>

#import "MEGASdkManager.h"

@class AudioPlayer;
@class MiniPlayerViewRouter;
@class Tab;

typedef NS_ENUM(NSInteger, MovementDirection) {
    MovementDirectionUp = 0,
    MovementDirectionDown
};

@interface MainTabBarController : UITabBarController <MEGAChatDelegate>

@property (nonatomic, strong) UIView * _Nullable bottomView;
@property (strong, nonatomic) NSLayoutConstraint *bottomViewBottomConstraint;
@property (nonatomic, strong) AudioPlayer * _Nullable player;
@property (nonatomic, strong) MiniPlayerViewRouter * _Nullable miniPlayerRouter;

- (void)openChatRoomNumber:(NSNumber *)chatNumber;
- (void)openChatRoomWithPublicLink:(NSString *)publicLink chatID:(uint64_t)chatNumber;

- (void)showAchievements;
- (void)showOfflineAndPresentFileWithHandle:(NSString * _Nullable )base64handle;
- (void)showRecents;
- (void)showUploadFile;
- (void)showScanDocument;
- (void)showStartConversation;
- (void)showAddContact;

- (void)setBadgeValueForChats;
- (void)shouldUpdateProgressViewLocation;
@end
