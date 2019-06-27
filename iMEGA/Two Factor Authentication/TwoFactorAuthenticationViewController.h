
#import <UIKit/UIKit.h>

#import "TwoFactorAuthentication.h"

@interface TwoFactorAuthenticationViewController : UIViewController

@property (nonatomic) TwoFactorAuthentication twoFAMode;

@property (strong, nonatomic) IBOutlet NSString *email;
@property (strong, nonatomic) IBOutlet NSString *password;
@property (strong, nonatomic) IBOutlet NSString *newerPassword;

@end
