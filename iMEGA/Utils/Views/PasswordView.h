
#import <UIKit/UIKit.h>

@protocol PasswordViewDelegate <NSObject>

@optional

- (void)passwordViewBeginEditing;

@end

IB_DESIGNABLE
@interface PasswordView : UIView <UITextFieldDelegate>

@property (nonatomic) UIView *customView;
@property (nonatomic) IBInspectable UIImage *leftImage;
@property (nonatomic) IBInspectable NSString *topLabelTextKey;

@property (weak, nonatomic) IBOutlet UIImageView *leftImageView;
@property (weak, nonatomic) IBOutlet UILabel *topLabel;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UIButton *toggleSecureButton;

@property (assign, nonatomic) IBOutlet id<PasswordViewDelegate> delegate;

- (void)configureSecureTextEntry;
- (void)setErrorState:(BOOL)error;
- (void)setErrorState:(BOOL)error withText:(NSString *)text;

- (void)updateUI;

@end
