#import <UIKit/UIKit.h>
#import "MEGACallManager.h"

@interface AppDelegate : UIResponder 

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic, strong) MEGACallManager *megaCallManager;

- (void)showOnboardingWithCompletion:(void (^)(void))completion;

@end
