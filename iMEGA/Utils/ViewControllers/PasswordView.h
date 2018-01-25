
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

@property (assign, nonatomic) IBOutlet id<PasswordViewDelegate> delegate;

- (void)passwordTextFieldColor:(UIColor *)color;
- (void)hideKeyboard;

@end
