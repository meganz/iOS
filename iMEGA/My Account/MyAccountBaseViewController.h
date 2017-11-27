
#import <UIKit/UIKit.h>

@interface MyAccountBaseViewController : UIViewController <MEGARequestDelegate>

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;

- (void)presentEditProfileAlertController;
- (void)setUserAvatar;

@end
