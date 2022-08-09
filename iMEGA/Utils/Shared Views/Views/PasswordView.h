
#import <UIKit/UIKit.h>

@protocol PasswordViewDelegate <NSObject>

@optional

- (void)passwordViewBeginEditing;

@end

IB_DESIGNABLE
@interface PasswordView : UIView <UITextFieldDelegate>

@property (nonatomic) UIView *customView;
@property (nonatomic) IBOutlet UIView *topSeparatorView;
@property (nonatomic) IBInspectable UIImage *leftImage;
@property (nonatomic) IBInspectable NSString *topLabelTextKey;

@property (weak, nonatomic) IBOutlet UIImageView *leftImageView;
@property (weak, nonatomic) IBOutlet UILabel *topLabel;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UIButton *toggleSecureButton;
@property (nonatomic) IBOutlet UIView *bottomSeparatorView;

@property (weak, nonatomic) IBOutlet id<PasswordViewDelegate> delegate;

@property (nonatomic, getter=isUsingDefaultBackgroundColor) BOOL usingDefaultBackgroundColor;

- (void)configureSecureTextEntry;
- (void)setErrorState:(BOOL)error;
- (void)setErrorState:(BOOL)error withText:(NSString *)text;

- (void)updateAppearance;

@end
