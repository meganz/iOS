#import <UIKit/UIKit.h>

@interface ChangePasswordViewController : UIViewController

typedef NS_ENUM(NSUInteger, ChangeType) {
    ChangeTypePassword = 0,
    ChangeTypeEmail
};

@property (nonatomic) ChangeType changeType;

@property (weak, nonatomic) IBOutlet UIView *emailIsChangingView;
@property (weak, nonatomic) IBOutlet UILabel *emailIsChangingTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *emailIsChangingDescriptionLabel;

@end
