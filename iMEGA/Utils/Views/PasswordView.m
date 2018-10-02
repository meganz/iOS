
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
    [self configureRightImage];
    //This code fix the position of the text field cursor not locating properly when toggle secure text entry
    NSString *tmpString = self.passwordTextField.text;
    self.passwordTextField.text = @" ";
    self.passwordTextField.text = tmpString;
}

- (void)configureRightImage {
    if (self.passwordTextField.secureTextEntry) {
        [self.rightImageView setImage:[UIImage imageNamed:@"showHidePassword"] forState:UIControlStateNormal];
    } else {
        [self.rightImageView setImage:[UIImage imageNamed:@"showHidePassword_active"] forState:UIControlStateNormal];
    }
}

#pragma mark - Public

- (void)configureSecureTextEntry {
    [self configureRightImage];
    self.rightImageView.hidden = YES;
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    self.rightImageView.hidden = NO;
    [self.delegate passwordViewBeginEditing];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    self.passwordTextField.secureTextEntry = YES;
    self.rightImageView.hidden = YES;
}

@end
