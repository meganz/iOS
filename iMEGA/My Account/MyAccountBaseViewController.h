
#import <UIKit/UIKit.h>

@interface MyAccountBaseViewController : UIViewController <MEGARequestDelegate>

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UIImageView *avatarImageView;
@property (weak, nonatomic) IBOutlet UIImageView *qrCodeImageView;

- (void)presentEditProfileAlertController;
- (void)setUserAvatar;

@end
