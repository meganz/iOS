
#import "BrowserViewController.h"
#import "SendToViewController.h"

@interface ShareViewController : UIViewController <BrowserViewControllerDelegate, SendToViewControllerDelegate>

- (void)dismissWithCompletionHandler:(void (^)(void))completion;

@end
