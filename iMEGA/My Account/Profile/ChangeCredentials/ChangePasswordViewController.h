#import <UIKit/UIKit.h>

@interface ChangePasswordViewController : UIViewController

typedef NS_ENUM(NSUInteger, ChangeType) {
    ChangeTypePassword = 0,
    ChangeTypeEmail,
    ChangeTypeResetPassword,
    ChangeTypeParkAccount,
    ChangeTypePasswordFromLogout
};

@property (nonatomic) ChangeType changeType;

@property (strong, nonatomic) NSString *email;
@property (strong, nonatomic) NSString *masterKey;
@property (strong, nonatomic) NSString *link;

@property (getter=isTwoFactorAuthenticationEnabled) BOOL twoFactorAuthenticationEnabled;

@end
