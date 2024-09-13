#import <UIKit/UIKit.h>
#import "MEGAChatSdk.h"

@class AudioPlayer;
@class MiniPlayerViewRouter;
@class Tab;
@class PSAViewModel;
@class MainTabBarCallsViewModel;
@class MainTabBarAdsViewModel;

typedef NS_ENUM(NSInteger, MovementDirection) {
    MovementDirectionUp = 0,
    MovementDirectionDown
};

NS_ASSUME_NONNULL_BEGIN

@interface MainTabBarController : UITabBarController <MEGAChatDelegate>

@property (nonatomic, strong, nullable) UIView *bottomView;
@property (nonatomic, strong, nullable) NSLayoutConstraint *bottomViewBottomConstraint;
@property (nonatomic, strong, nullable) AudioPlayer *player;
@property (nonatomic, strong, nullable) MiniPlayerViewRouter *miniPlayerRouter;
@property (nonatomic, strong, nullable) UIImageView *phoneBadgeImageView;
@property (nonatomic, assign) NSInteger unreadMessages;
@property (strong, nonatomic) NSMutableArray<UIViewController *> *defaultViewControllers;
@property (nonatomic, strong) MainTabBarCallsViewModel *mainTabBarViewModel;
@property (nonatomic, strong) MainTabBarAdsViewModel *mainTabBarAdsViewModel;
@property (nonatomic, strong, nullable) PSAViewModel *psaViewModel;

- (void)openChatRoomNumber:(nullable NSNumber *)chatNumber;

- (void)showAchievements;
- (void)showFavouritesNodeWithHandle:(nullable NSString *)base64handle;
- (void)showOfflineAndPresentFileWithHandle:(nullable NSString *)base64handle;
- (void)showRecents;
- (void)showUploadFile;
- (void)showScanDocument;
- (void)showAddContact;

- (void)shouldUpdateProgressViewLocation;
- (void)setBadgeValue:(nullable NSString *)badgeValue tabPosition:(NSInteger)tabPosition;
@end

NS_ASSUME_NONNULL_END
