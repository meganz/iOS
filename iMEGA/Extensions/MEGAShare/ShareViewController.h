
#import "BrowserViewController.h"
#import "SendToViewController.h"

@interface ShareViewController : UIViewController <BrowserViewControllerDelegate, SendToViewControllerDelegate>

- (void)hideViewWithCompletion:(void (^)(void))completion;

@end
