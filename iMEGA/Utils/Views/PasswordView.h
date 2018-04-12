
#import <UIKit/UIKit.h>

@protocol PasswordViewDelegate <NSObject>

@optional

- (void)passwordViewBeginEditing;

@end

@interface PasswordView : UIView <UITextFieldDelegate>

@property (strong, nonatomic) UIView *customView;
@property (weak, nonatomic) IBOutlet UIImageView *leftImageView;
@property (weak, nonatomic) IBOutlet UIButton *rightImageView;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UIView *wrongPasswordView;
@property (weak, nonatomic) IBOutlet UILabel *wrongPasswordLabel;
@property (weak, nonatomic) IBOutlet UIImageView *wrongPasswordIcon;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *textFieldViewHeightConstraint;

@property (assign, nonatomic) IBOutlet id<PasswordViewDelegate> delegate;

@end
