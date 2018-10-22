
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
    self.passwordTextField.delegate = self;
}

- (IBAction)tapToggleSecureTextEntry:(id)sender {
    self.passwordTextField.secureTextEntry = !self.passwordTextField.secureTextEntry;
    [self configureToggleSecureButton];
    //This code fix the position of the text field cursor not locating properly when toggle secure text entry
    NSString *tmpString = self.passwordTextField.text;
    self.passwordTextField.text = @" ";
    self.passwordTextField.text = tmpString;
}

- (void)configureToggleSecureButton {
    if (self.passwordTextField.secureTextEntry) {
        [self.toggleSecureButton setImage:[UIImage imageNamed:@"showHidePassword"] forState:UIControlStateNormal];
    } else {
        [self.toggleSecureButton setImage:[UIImage imageNamed:@"showHidePassword_active"] forState:UIControlStateNormal];
    }
}

#pragma mark - Public

- (void)configureSecureTextEntry {
    [self configureToggleSecureButton];
    self.toggleSecureButton.hidden = YES;
}

- (void)setErrorState:(BOOL)error {
    NSString *text = error ? AMLocalizedString(@"passwordWrong", @"Wrong password") : AMLocalizedString(@"passwordPlaceholder", @"Hint text to suggest that the user has to write his password");
    [self setErrorState:error withText:text];
}

- (void)setErrorState:(BOOL)error withText:(NSString *)text {
    self.topLabel.text = text;
    if (error) {
        self.topLabel.textColor = UIColor.mnz_redError;
        self.passwordTextField.textColor = UIColor.mnz_redError;
    } else {
        self.topLabel.textColor = UIColor.mnz_gray999999;
        self.passwordTextField.textColor = UIColor.blackColor;
    }
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    self.toggleSecureButton.hidden = NO;
    [self.delegate passwordViewBeginEditing];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    self.passwordTextField.secureTextEntry = YES;
    self.toggleSecureButton.hidden = YES;
}

@end
