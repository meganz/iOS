#import <UIKit/UIKit.h>

#import "MEGASdkManager.h"

@class AudioPlayer;
@class MiniPlayerViewRouter;
@class Tab;

typedef NS_ENUM(NSInteger, MovementDirection) {
    MovementDirectionUp = 0,
    MovementDirectionDown
};

NS_ASSUME_NONNULL_BEGIN

@interface MainTabBarController : UITabBarController <MEGAChatDelegate, MEGAChatCallDelegate>

@property (nonatomic, strong, nullable) UIView *bottomView;
@property (nonatomic, strong, nullable) UIView *snackBarContainerView;
@property (nonatomic, strong, nullable) NSLayoutConstraint *bottomViewBottomConstraint;
@property (nonatomic, strong, nullable) NSLayoutConstraint *snackBarViewBottomConstraint;
@property (nonatomic, strong, nullable) AudioPlayer *player;
@property (nonatomic, strong, nullable) MiniPlayerViewRouter *miniPlayerRouter;

- (void)openChatRoomNumber:(nullable NSNumber *)chatNumber;

- (void)showAchievements;
- (void)showFavouritesNodeWithHandle:(nullable NSString *)base64handle;
- (void)showOfflineAndPresentFileWithHandle:(nullable NSString *)base64handle;
- (void)showRecents;
- (void)showUploadFile;
- (void)showScanDocument;
- (void)showAddContact;

- (void)setBadgeValueForChats;
- (void)shouldUpdateProgressViewLocation;
@end

NS_ASSUME_NONNULL_END
