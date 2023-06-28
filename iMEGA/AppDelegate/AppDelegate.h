#import <UIKit/UIKit.h>
#import "MEGACallManager.h"
#import "MEGAProviderDelegate.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, MEGANotificationType) {
    MEGANotificationTypeShareFolder = 1,
    MEGANotificationTypeChatMessage = 2,
    MEGANotificationTypeContactRequest = 3
};

@class MainTabBarController;

@interface AppDelegate : UIResponder 

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic, strong, nullable) MEGACallManager *megaCallManager;
@property (nonatomic, readonly, nullable) MEGAProviderDelegate *megaProviderDelegate;
@property (strong, nonatomic, nullable) UIWindow *blockingWindow;
@property (nonatomic, weak, readonly) MainTabBarController *mainTBC;
@property (nonatomic) NSNumber *openChatLater;

- (void)showMainTabBar;
- (void)performCall;
- (void)showOnboardingWithCompletion:(nullable void (^)(void))completion;
- (void)presentAccountExpiredAlertIfNeeded;

@end

NS_ASSUME_NONNULL_END
