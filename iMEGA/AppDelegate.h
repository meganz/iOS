#import <UIKit/UIKit.h>
#import "MEGACallManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface AppDelegate : UIResponder 

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic, strong, nullable) MEGACallManager *megaCallManager;
@property (strong, nonatomic, nullable) UIWindow *blockingWindow;

- (void)showOnboardingWithCompletion:(nullable void (^)(void))completion;

@end

NS_ASSUME_NONNULL_END
