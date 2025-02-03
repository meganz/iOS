#import <UIKit/UIKit.h>
#import "PasswordStrengthIndicatorView.h"
#import "PasswordView.h"

@interface ChangePasswordViewController : UIViewController

typedef NS_ENUM(NSUInteger, ChangeType) {
    ChangeTypePassword = 0,
    ChangeTypeEmail,
    ChangeTypeResetPassword,
    ChangeTypeParkAccount,
    ChangeTypePasswordFromLogout
};

@property (weak, nonatomic) IBOutlet PasswordView *theNewPasswordView;
@property (weak, nonatomic) IBOutlet PasswordStrengthIndicatorView *passwordStrengthIndicatorView;
@property (weak, nonatomic) IBOutlet UIView *passwordStrengthContainer;

@property (nonatomic) ChangeType changeType;

@property (strong, nonatomic) NSString *email;
@property (strong, nonatomic) NSString *masterKey;
@property (strong, nonatomic) NSString *link;

@property (getter=isTwoFactorAuthenticationEnabled) BOOL twoFactorAuthenticationEnabled;

@end
