#import <UIKit/UIKit.h>

@interface ChangePasswordViewController : UIViewController

typedef NS_ENUM(NSUInteger, ChangeType) {
    ChangeTypePassword = 0,
    ChangeTypeEmail,
    ChangeTypeResetPassword
};

@property (nonatomic) ChangeType changeType;

@property (strong, nonatomic) NSString *email;
@property (strong, nonatomic) NSString *masterKey;
@property (strong, nonatomic) NSString *link;

@property (weak, nonatomic) IBOutlet UIView *emailIsChangingView;
@property (weak, nonatomic) IBOutlet UILabel *emailIsChangingTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *emailIsChangingDescriptionLabel;

@end
