
#import "PasswordView.h"

@implementation PasswordView

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self customInit];
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self customInit];
    }
    
    return self;
}

- (void)customInit {
    self.customView = [[[NSBundle mainBundle] loadNibNamed:@"PasswordView" owner:self options:nil] firstObject];
    [self addSubview:self.customView];
    self.customView.frame = self.bounds;
    self.textFieldViewHeightConstraint.constant = self.bounds.size.height;
    self.passwordTextField.delegate = self;
    self.passwordTextField.placeholder = AMLocalizedString(@"passwordPlaceholder", @"Hint text to suggest that the user has to write his password");
    self.wrongPasswordLabel.text = AMLocalizedString(@"passwordWrong", @"Wrong password");
}

- (IBAction)tapToggleSecureTextEntry:(id)sender {
    self.passwordTextField.secureTextEntry = !self.passwordTextField.secureTextEntry;
    if (self.passwordTextField.secureTextEntry) {
        [self.rightImageView setImage:[UIImage imageNamed:@"showHidePassword"] forState:UIControlStateNormal];
    } else {
        [self.rightImageView setImage:[UIImage imageNamed:@"showHidePassword_active"] forState:UIControlStateNormal];
    }
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    [self.delegate passwordViewBeginEditing];
}

@end
