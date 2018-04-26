
#import "ChangePasswordViewController.h"

#import "MEGASdkManager.h"
#import "MEGAReachabilityManager.h"
#import "NSString+MNZCategory.h"
#import "SVProgressHUD.h"

#import "PasswordStrengthIndicatorView.h"

@interface ChangePasswordViewController () <MEGARequestDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *currentPasswordImageView;
@property (weak, nonatomic) IBOutlet UITextField *currentPasswordTextField;
@property (weak, nonatomic) IBOutlet UIImageView *currentLineImageView;
@property (weak, nonatomic) IBOutlet UIImageView *theNewPasswordImageView;
@property (weak, nonatomic) IBOutlet UITextField *theNewPasswordTextField;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *passwordStrengthIndicatorViewHeightLayoutConstraint;
@property (weak, nonatomic) IBOutlet PasswordStrengthIndicatorView *passwordStrengthIndicatorView;
@property (weak, nonatomic) IBOutlet UIImageView *confirmPasswordImageView;
@property (weak, nonatomic) IBOutlet UITextField *confirmPasswordTextField;

@property (weak, nonatomic) IBOutlet UIButton *changePasswordButton;

@property (strong, nonatomic) IBOutlet UIBarButtonItem *cancelBarButtonItem;

@end

@implementation ChangePasswordViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.passwordStrengthIndicatorViewHeightLayoutConstraint.constant = 0;
    
    if (self.changeType == ChangeTypePassword) {
        self.navigationItem.title = AMLocalizedString(@"changePasswordLabel", @"Section title where you can change your MEGA's password");
        
        self.currentPasswordImageView.hidden = YES;
        self.currentPasswordTextField.hidden = YES;
        self.currentLineImageView.hidden = YES;
        self.theNewPasswordTextField.placeholder = AMLocalizedString(@"newPassword", @"Placeholder text to explain that the new password should be written on this text field.");
        self.confirmPasswordTextField.placeholder = AMLocalizedString(@"confirmPassword", @"Placeholder text to explain that the new password should be re-written on this text field.");
        
        [self.changePasswordButton setTitle:AMLocalizedString(@"changePasswordLabel", @"Section title where you can change your MEGA's password") forState:UIControlStateNormal];
        
        [self.theNewPasswordTextField becomeFirstResponder];
    } else if (self.changeType == ChangeTypeEmail) {
        self.navigationItem.title = AMLocalizedString(@"changeEmail", @"The title of the alert dialog to change the email associated to an account.");
        
        self.currentPasswordImageView.image = [UIImage imageNamed:@"emailExisting"];
        NSString *myEmail = [[MEGASdkManager sharedMEGASdk] myEmail];
        myEmail ? (self.currentPasswordTextField.text = myEmail) : (self.currentPasswordTextField.placeholder = AMLocalizedString(@"emailPlaceholder", @"Hint text to suggest that the user has to write his email"));
        self.currentPasswordTextField.secureTextEntry = NO;
        self.currentPasswordTextField.userInteractionEnabled = NO;
        
        self.theNewPasswordImageView.image = [UIImage imageNamed:@"email"];
        self.theNewPasswordTextField.placeholder = AMLocalizedString(@"newEmail", @"Placeholder text to explain that the new email should be written on this text field.");
        self.theNewPasswordTextField.secureTextEntry = NO;
        
        self.confirmPasswordImageView.image = [UIImage imageNamed:@"emailConfirm"];
        self.confirmPasswordTextField.placeholder = AMLocalizedString(@"confirmNewEmail", @"Placeholder text to explain that the new email should be re-written on this text field.");
        self.confirmPasswordTextField.secureTextEntry = NO;
        
        [self.changePasswordButton setTitle:AMLocalizedString(@"changeEmail", @"The title of the alert dialog to change the email associated to an account.") forState:UIControlStateNormal];
        
        [self.theNewPasswordTextField becomeFirstResponder];
        
        self.emailIsChangingTitleLabel.text = AMLocalizedString(@"awaitingEmailConfirmation", @"Title shown just after doing some action that requires confirming the action by an email");
        self.emailIsChangingDescriptionLabel.text = AMLocalizedString(@"emailIsChanging_description", @"Text shown just after tap to change an email account to remenber the user what to do to complete the change email proccess");
    } else if (self.changeType == ChangeTypeResetPassword || self.changeType == ChangeTypeParkAccount) {
        self.navigationItem.leftBarButtonItem = self.cancelBarButtonItem;
        
        self.navigationItem.title = (self.changeType == ChangeTypeResetPassword) ? AMLocalizedString(@"passwordReset", @"Headline of the password reset recovery procedure") : AMLocalizedString(@"parkAccount", @"Headline for parking an account (basically restarting from scratch)");
        
        self.currentPasswordImageView.image = [UIImage imageNamed:@"email"];
        self.currentPasswordTextField.text = self.email;
        self.currentPasswordTextField.secureTextEntry = NO;
        self.currentPasswordTextField.userInteractionEnabled = NO;
        
        self.theNewPasswordTextField.placeholder = AMLocalizedString(@"newPassword", @"Placeholder text to explain that the new password should be written on this text field.");
        self.confirmPasswordTextField.placeholder = AMLocalizedString(@"confirmPassword", @"Placeholder text to explain that the new password should be re-written on this text field.");
        
        NSString *buttonTitle = (self.changeType == ChangeTypeResetPassword) ? AMLocalizedString(@"changePasswordLabel", @"Section title where you can change your MEGA's password") : AMLocalizedString(@"startNewAccount", @"Caption of the button to proceed");
        [self.changePasswordButton setTitle:buttonTitle forState:UIControlStateNormal];
        
        [self.theNewPasswordTextField becomeFirstResponder];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(emailHasChanged) name:@"emailHasChanged" object:nil];
}

#pragma mark - Private

- (BOOL)validatePasswordForm {
    if (![self validatePassword:self.theNewPasswordTextField.text]) {
        if ([self.theNewPasswordTextField.text length] == 0) {
            [SVProgressHUD showErrorWithStatus:AMLocalizedString(@"passwordInvalidFormat", @"Enter a valid password")];
            [self.theNewPasswordTextField becomeFirstResponder];
        } else {
            [SVProgressHUD showErrorWithStatus:AMLocalizedString(@"passwordsDoNotMatch", @"Passwords do not match")];
            [self.theNewPasswordTextField setText:@""];
            [self.confirmPasswordTextField setText:@""];
            [self.theNewPasswordTextField becomeFirstResponder];
        }
        
        return NO;
    }
    
    if (([[MEGASdkManager sharedMEGASdk] passwordStrength:self.theNewPasswordTextField.text] == PasswordStrengthVeryWeak) && (self.changeType == ChangeTypePassword)) {
        [SVProgressHUD showImage:[UIImage imageNamed:@"hudWarning"] status:AMLocalizedString(@"pleaseStrengthenYourPassword", @"")];
        
        return NO;
    }
    
    return YES;
}

- (BOOL)validatePassword:(NSString *)password {
    if (password.length == 0 || ![password isEqualToString:_confirmPasswordTextField.text]) {
        return NO;
    } else {
        return YES;
    }
}

- (BOOL)validateEmail {
    NSString *newEmail = self.theNewPasswordTextField.text;
    BOOL validEmail = [newEmail mnz_isValidEmail];
    
    if (newEmail.length == 0 || !validEmail) {
        [SVProgressHUD showErrorWithStatus:AMLocalizedString(@"emailInvalidFormat", @"Message shown when the user writes an invalid format in the email field")];
        
        self.currentPasswordImageView.image = [UIImage imageNamed:@"emailExisting"];
        
        [self.theNewPasswordTextField becomeFirstResponder];
        return NO;
    } else if ([newEmail isEqualToString:self.currentPasswordTextField.text]) {
        [SVProgressHUD showErrorWithStatus:AMLocalizedString(@"oldAndNewEmailMatch", @"")];
        
        self.currentPasswordImageView.image = [UIImage imageNamed:@"errorEmailExisting"];
        
        [self.theNewPasswordTextField becomeFirstResponder];
        return NO;
    } else if (![newEmail isEqualToString:self.confirmPasswordTextField.text]) {
        [SVProgressHUD showErrorWithStatus:AMLocalizedString(@"emailsDoNotMatch", @"Error message shown when you have not written the same email")];
        
        self.currentPasswordImageView.image = [UIImage imageNamed:@"emailExisting"];
        
        [self.confirmPasswordTextField becomeFirstResponder];
        return NO;
    } else {
        return YES;
    }
}

- (void)emailHasChanged {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"emailHasChanged" object:nil];
    [self.navigationController popViewControllerAnimated:YES];
}

- (BOOL)isEmptyAnyTextFieldForTag:(NSInteger )tag {
    BOOL isAnyTextFieldEmpty = NO;
    switch (tag) {
        case 0: {
            if ([self.theNewPasswordTextField.text isEqualToString:@""] || [self.confirmPasswordTextField.text isEqualToString:@""]) {
                isAnyTextFieldEmpty = YES;
            }
            break;
        }
            
        case 1: {
            if ((self.changeType != ChangeTypePassword && [self.currentPasswordTextField.text isEqualToString:@""]) || [self.confirmPasswordTextField.text isEqualToString:@""]) {
                isAnyTextFieldEmpty = YES;
            }
            break;
        }
            
        case 2: {
            if ((self.changeType != ChangeTypePassword && [self.currentPasswordTextField.text isEqualToString:@""]) || [self.theNewPasswordTextField.text isEqualToString:@""]) {
                isAnyTextFieldEmpty = YES;
            }
            break;
        }
    }
    
    return isAnyTextFieldEmpty;
}

#pragma mark - IBActions

- (IBAction)cancelAction:(UIBarButtonItem *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)changePasswordTouchUpIndise:(UIButton *)sender {
    if ([MEGAReachabilityManager isReachableHUDIfNot]) {
        if (self.changeType == ChangeTypePassword) {
            if ([self validatePasswordForm]) {
                self.changePasswordButton.enabled = NO;
                [[MEGASdkManager sharedMEGASdk] changePassword:nil newPassword:self.theNewPasswordTextField.text delegate:self];
            } else {
                self.passwordStrengthIndicatorView.customView.hidden = YES;
                self.passwordStrengthIndicatorViewHeightLayoutConstraint.constant = 0;
            }
        } else if (self.changeType == ChangeTypeEmail) {
            if ([self validateEmail]) {
                self.changePasswordButton.enabled = NO;
                [[MEGASdkManager sharedMEGASdk] changeEmail:self.confirmPasswordTextField.text delegate:self];
            } else {
                self.theNewPasswordImageView.image = [UIImage imageNamed:@"errorEmail"];
                self.confirmPasswordImageView.image = [UIImage imageNamed:@"errorEmailConfirm"];
            }
        } else if (self.changeType == ChangeTypeResetPassword) {
            if ([self validatePasswordForm]) {
                [[MEGASdkManager sharedMEGASdk] confirmResetPasswordWithLink:self.link newPassword:self.theNewPasswordTextField.text masterKey:self.masterKey delegate:self];
            }
        } else if (self.changeType == ChangeTypeParkAccount) {
            if ([self validatePasswordForm]) {
                UIAlertView *startingFreshAccountAlertView = [[UIAlertView alloc] initWithTitle:AMLocalizedString(@"startNewAccount", @"Headline of the password reset recovery procedure") message:AMLocalizedString(@"startingFreshAccount", @"Label text of a checkbox to ensure that the user is aware that the data of his current account will be lost when proceeding unless they remember their password or have their master encryption key (now renamed 'Recovery Key')") delegate:self cancelButtonTitle:AMLocalizedString(@"cancel", nil) otherButtonTitles:AMLocalizedString(@"ok", nil), nil];
                startingFreshAccountAlertView.tag = 2;
                [startingFreshAccountAlertView show];
            }
        }
    } else {
        self.changePasswordButton.enabled = YES;
    }
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.tag == 0) { //invalidMasterKeyAlert
        UIAlertView *masterKeyAlertView = [[UIAlertView alloc] initWithTitle:AMLocalizedString(@"passwordReset", @"Headline of the password reset recovery procedure") message:AMLocalizedString(@"pleaseEnterYourRecoveryKey", @"A message shown to explain that the user has to input (type or paste) their recovery key to continue with the reset password process.") delegate:self cancelButtonTitle:AMLocalizedString(@"cancel", nil) otherButtonTitles:AMLocalizedString(@"ok", nil), nil];
        masterKeyAlertView.tag = 1;
        masterKeyAlertView.alertViewStyle = UIAlertViewStylePlainTextInput;
        UITextField *textField = [masterKeyAlertView textFieldAtIndex:0];
        textField.placeholder = AMLocalizedString(@"recoveryKey", @"Label for any 'Recovery Key' button, link, text, title, etc. Preserve uppercase - (String as short as possible). The Recovery Key is the new name for the account 'Master Key', and can unlock (recover) the account if the user forgets their password.");
        [masterKeyAlertView show];
        
        [textField becomeFirstResponder];
    } else if ([alertView tag] == 1) { //masterKeyAlertView
        if (buttonIndex == 1) {
            self.masterKey = [[alertView textFieldAtIndex:0] text];
            [self.theNewPasswordTextField becomeFirstResponder];
        } else {
            UITextField *textField = [alertView textFieldAtIndex:0];
            [textField resignFirstResponder];
            [self dismissViewControllerAnimated:YES completion:nil];
        }
    } else if (alertView.tag == 2) { //startingFreshAccountAlertView
        if (buttonIndex == 1) {
            [[MEGASdkManager sharedMEGASdk] confirmResetPasswordWithLink:self.link newPassword:self.theNewPasswordTextField.text masterKey:nil delegate:self];
        }
    }
}

#pragma mark - UITextFieldDelegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSString *text = [textField.text stringByReplacingCharactersInRange:range withString:string];
    BOOL shoulBeCreateAccountButtonGray = NO;
    if (([text isEqualToString:@""] || (([[MEGASdkManager sharedMEGASdk] passwordStrength:text] == PasswordStrengthVeryWeak))) && self.changeType == ChangeTypePassword) {
        shoulBeCreateAccountButtonGray = YES;
    } else {
        shoulBeCreateAccountButtonGray = [self isEmptyAnyTextFieldForTag:textField.tag];
    }
    
    shoulBeCreateAccountButtonGray ? [self.changePasswordButton setBackgroundColor:[UIColor mnz_grayCCCCCC]] : [self.changePasswordButton setBackgroundColor:[UIColor mnz_redFF4C52]];
    
    if (textField.tag == 1 && self.changeType == ChangeTypePassword) {
        if (text.length == 0) {
            self.passwordStrengthIndicatorView.customView.hidden = YES;
            self.passwordStrengthIndicatorViewHeightLayoutConstraint.constant = 0;
        } else {
            self.passwordStrengthIndicatorViewHeightLayoutConstraint.constant = 112.0f;
            self.passwordStrengthIndicatorView.customView.hidden = NO;
            
            [self.passwordStrengthIndicatorView updateViewWithPasswordStrength:[[MEGASdkManager sharedMEGASdk] passwordStrength:text]];
        }
    }
    
    return YES;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField {
    if (textField.tag == 1 && self.changeType == ChangeTypePassword) {
        self.passwordStrengthIndicatorView.customView.hidden = YES;
        self.passwordStrengthIndicatorViewHeightLayoutConstraint.constant = 0;
    }
    
    self.changePasswordButton.backgroundColor = [UIColor mnz_grayCCCCCC];
    
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    
    switch ([textField tag]) {
        case 0:
            [self.theNewPasswordTextField becomeFirstResponder];
            break;
            
        case 1:
            [_confirmPasswordTextField becomeFirstResponder];
            break;
            
        case 2:
            [_confirmPasswordTextField resignFirstResponder];
            break;
            
        default:
            break;
    }
    
    return YES;
}

#pragma mark - MEGARequestDelegate

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    if ([error type]) {
        [self.changePasswordButton setEnabled:YES];
        
        switch (error.type) {
            case MEGAErrorTypeApiEArgs: {
                if (request.type == MEGARequestTypeChangePassword) {
                    self.theNewPasswordTextField.text = self.confirmPasswordTextField.text = @"";
                    [self.theNewPasswordTextField becomeFirstResponder];
                    self.passwordStrengthIndicatorView.customView.hidden = YES;
                    self.passwordStrengthIndicatorViewHeightLayoutConstraint.constant = 0;
                    [SVProgressHUD showErrorWithStatus:AMLocalizedString(@"passwordInvalidFormat", @"Enter a valid password")];
                }
                break;
            }
                
            case MEGAErrorTypeApiEExist: {
                if (request.type == MEGARequestTypeGetChangeEmailLink) {
                    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:AMLocalizedString(@"emailAddressChangeAlreadyRequested", @"Error message shown when you try to change your account email to one that you already requested") message:nil delegate:nil cancelButtonTitle:AMLocalizedString(@"ok", nil) otherButtonTitles:nil];
                    [alertView show];
                    
                    self.currentPasswordImageView.image = [UIImage imageNamed:@"emailExisting"];
                    self.theNewPasswordImageView.image = [UIImage imageNamed:@"errorEmail"];
                    self.confirmPasswordImageView.image = [UIImage imageNamed:@"errorEmailConfirm"];
                }
                break;
            }
                
            case MEGAErrorTypeApiEKey: {
                if (request.type == MEGARequestTypeConfirmRecoveryLink) {
                    UIAlertView *invalidMasterKeyAlert = [[UIAlertView alloc] initWithTitle:AMLocalizedString(@"invalidRecoveryKey", @"An alert title where the user provided the incorrect Recovery Key.") message:nil delegate:self cancelButtonTitle:nil otherButtonTitles:AMLocalizedString(@"ok", nil), nil];
                    invalidMasterKeyAlert.tag = 0;
                    [invalidMasterKeyAlert show];
                    
                    self.theNewPasswordTextField.text = self.confirmPasswordTextField.text = @"";
                }
                break;
            }
                
            default:
                break;
        }
        return;
    }
    
    switch (request.type) {
        case MEGARequestTypeChangePassword: {
            [SVProgressHUD showSuccessWithStatus:AMLocalizedString(@"passwordChanged", @"The label showed when your password has been changed")];
            
            [self.navigationController popViewControllerAnimated:YES];
            break;
        }
            
        case MEGARequestTypeGetChangeEmailLink: {
            self.view = self.emailIsChangingView;
            break;
        }
            
        case MEGARequestTypeConfirmRecoveryLink: {
            if (self.changeType == ChangeTypePassword) {
                [SVProgressHUD showSuccessWithStatus:AMLocalizedString(@"passwordChanged", @"The label showed when your password has been changed")];
            } else {
                NSString *title;
                if (self.changeType == ChangeTypeResetPassword) {
                    if ([[MEGASdkManager sharedMEGASdk] isLoggedIn]) {
                        [[NSNotificationCenter defaultCenter] postNotificationName:@"passwordReset" object:nil];
                        title = AMLocalizedString(@"passwordChanged", @"The label showed when your password has been changed");
                    } else {
                        title = AMLocalizedString(@"yourPasswordHasBeenReset", nil);
                    }
                } else if (self.changeType == ChangeTypeParkAccount) {
                    title = AMLocalizedString(@"yourAccounHasBeenParked", nil);
                }
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title message:nil delegate:nil cancelButtonTitle:AMLocalizedString(@"ok", nil) otherButtonTitles:nil];
                [alertView show];
            }
            
            [self dismissViewControllerAnimated:YES completion:nil];
            break;
        }
            
        default:
            break;
    }
}

@end
