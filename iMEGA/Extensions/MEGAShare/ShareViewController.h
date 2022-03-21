
#import "BrowserViewController.h"
#import "SendToViewController.h"

@interface ShareViewController : UIViewController <BrowserViewControllerDelegate, SendToViewControllerDelegate>

@property (getter=isChatDestination) BOOL chatDestination;

- (void)hideViewWithCompletion:(void (^)(void))completion;

@end
