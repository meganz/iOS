
#import "BrowserViewController.h"
#import "SendToViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface ShareViewController : UIViewController <BrowserViewControllerDelegate, SendToViewControllerDelegate>

@property (getter=isChatDestination) BOOL chatDestination;
@property (nonatomic, strong, nullable) UINavigationController *loginRequiredNC;

- (void)hideViewWithCompletion:(void (^)(void))completion;

@end

NS_ASSUME_NONNULL_END
