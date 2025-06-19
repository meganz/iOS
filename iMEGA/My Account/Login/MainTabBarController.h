#import <UIKit/UIKit.h>
#import "MEGAChatSdk.h"

@class AudioPlayer, Tab, PSAViewModel, MainTabBarCallsViewModel, MainTabBarAdsViewModel, BottomOverlayManager;

typedef NS_ENUM(NSInteger, MovementDirection) {
    MovementDirectionUp = 0,
    MovementDirectionDown
};

NS_ASSUME_NONNULL_BEGIN

@interface MainTabBarController : UITabBarController <MEGAChatDelegate>

/**
 The container view sitting just above the tab bar, containing the`bottomOverlayStack`.
 */
@property (nonatomic, strong, nullable) UIView *bottomOverlayContainer;

/**
 A vertical stack view inside the `bottomOverlayContainer`. It arranges any bottom overlays (e.g., `PSA Banner`, `mini-player`, etc...)
 in a vertical layout.
 */
@property (nonatomic, strong, nullable) UIStackView *bottomOverlayStack;
@property (nonatomic, strong, nullable) NSLayoutConstraint *bottomContainerBottomConstraint;
@property (nonatomic, strong, nullable) BottomOverlayManager *bottomOverlayManager;
@property (nonatomic, strong, nullable) UIView *safeAreaCoverView;

@property (nonatomic, strong, nullable) AudioPlayer *player;
@property (nonatomic, strong, nullable) UIImageView *phoneBadgeImageView;
@property (nonatomic, assign) NSInteger unreadMessages;
@property (nonatomic, strong) MainTabBarCallsViewModel *mainTabBarViewModel;
@property (nonatomic, strong) MainTabBarAdsViewModel *mainTabBarAdsViewModel;
@property (nonatomic, strong, nullable) PSAViewModel *psaViewModel;

- (void)openChatRoomNumber:(nullable NSNumber *)chatNumber;

- (void)showAchievements;
- (void)showFavouritesNodeWithHandle:(nullable NSString *)base64handle;
- (void)showOfflineAndPresentFileWithHandle:(nullable NSString *)base64handle;
- (void)showRecents;
- (void)showAddContact;

- (void)shouldUpdateProgressViewLocation;
- (void)setBadgeValue:(nullable NSString *)badgeValue tabPosition:(NSInteger)tabPosition;
@end

NS_ASSUME_NONNULL_END
