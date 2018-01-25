
#import "PasswordView.h"

@implementation PasswordView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self customInit];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if(self) {
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
    //TODO:set eye image color to red if not secure text entry
}

#pragma mark - Public

- (void)passwordTextFieldColor:(UIColor *)color {
    [self.passwordTextField setTextColor:color];
}

- (void)hideKeyboard {
    [self.passwordTextField resignFirstResponder];
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    [self.delegate passwordViewBeginEditing];
}

@end
