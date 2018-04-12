
#import "ChangePasswordViewController.h"

#import "MEGASdkManager.h"
#import "MEGAReachabilityManager.h"
#import "NSString+MNZCategory.h"
#import "SVProgressHUD.h"

#import "PasswordStrengthIndicatorView.h"
#import "PasswordView.h"

@interface ChangePasswordViewController () <MEGARequestDelegate, UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *currentPasswordImageView;
@property (weak, nonatomic) IBOutlet UITextField *currentPasswordTextField;
@property (weak, nonatomic) IBOutlet UIImageView *currentPasswordLineView;
@property (weak, nonatomic) IBOutlet UIImageView *theNewPasswordImageView;
@property (weak, nonatomic) IBOutlet UITextField *theNewPasswordTextField;
@property (weak, nonatomic) IBOutlet UIImageView *theNewPasswordLineView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *passwordStrengthIndicatorViewHeightLayoutConstraint;
@property (weak, nonatomic) IBOutlet PasswordStrengthIndicatorView *passwordStrengthIndicatorView;
@property (weak, nonatomic) IBOutlet UIImageView *confirmPasswordImageView;
@property (weak, nonatomic) IBOutlet UITextField *confirmPasswordTextField;
@property (weak, nonatomic) IBOutlet UIImageView *confirmPasswordLineView;

@property (weak, nonatomic) IBOutlet UIButton *changePasswordButton;

@property (strong, nonatomic) IBOutlet UIBarButtonItem *cancelBarButtonItem;

@property (weak, nonatomic) IBOutlet PasswordView *currentPasswordView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *currentPasswordViewHeightConstraint;

@property (weak, nonatomic) IBOutlet PasswordView *theNewPasswordView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *theNewPasswordViewHeightConstraint;

@property (weak, nonatomic) IBOutlet PasswordView *confirmPasswordView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *confirmPasswordViewHeightConstraint;

@end

@implementation ChangePasswordViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.passwordStrengthIndicatorViewHeightLayoutConstraint.constant = 0;
    
    if (self.changeType == ChangeTypePassword) {
        self.navigationItem.title = AMLocalizedString(@"changePasswordLabel", @"Section title where you can change your MEGA's password");
        
        [self configureTextFieldStyle:self.currentPasswordView.passwordTextField];
        self.currentPasswordView.passwordTextField.placeholder = AMLocalizedString(@"currentPassword", @"Placeholder text to explain that the current password should be written on this text field.");
        self.currentPasswordView.passwordTextField.tag = 3;
        self.currentPasswordView.leftImageView.image = [UIImage imageNamed:@"padlock"];
        self.currentPasswordView.leftImageView.tintColor = UIColor.mnz_gray777777;
        
        [self configureTextFieldStyle:self.theNewPasswordView.passwordTextField];
        self.theNewPasswordView.passwordTextField.placeholder = AMLocalizedString(@"newPassword", @"Placeholder text to explain that the new password should be written on this text field.");
        self.theNewPasswordView.passwordTextField.tag = 4;
        self.theNewPasswordView.leftImageView.image = [UIImage imageNamed:@"key"];
        self.theNewPasswordView.leftImageView.tintColor = UIColor.mnz_gray777777;

        [self configureTextFieldStyle:self.confirmPasswordView.passwordTextField];
        self.confirmPasswordView.passwordTextField.placeholder = AMLocalizedString(@"confirmPassword", @"Placeholder text to explain that the new password should be re-written on this text field.");
        self.confirmPasswordView.passwordTextField.tag = 5;
        self.confirmPasswordView.leftImageView.image = [UIImage imageNamed:@"keyDouble"];
        self.confirmPasswordView.leftImageView.tintColor = UIColor.mnz_gray777777;

        [self.changePasswordButton setTitle:AMLocalizedString(@"changePasswordLabel", @"Section title where you can change your MEGA's password") forState:UIControlStateNormal];
        
        [self.currentPasswordView.passwordTextField becomeFirstResponder];
    } else if (self.changeType == ChangeTypeEmail) {
        self.currentPasswordView.hidden = self.theNewPasswordView.hidden = self.confirmPasswordView.hidden = YES;
        
        self.currentPasswordTextField.hidden = self.currentPasswordImageView.hidden = self.currentPasswordLineView.hidden = self.theNewPasswordTextField.hidden = self.theNewPasswordImageView.hidden = self.theNewPasswordLineView.hidden = self.confirmPasswordTextField.hidden = self.confirmPasswordImageView.hidden = self.confirmPasswordLineView.hidden = NO;
        
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
        
        self.currentPasswordView.hidden = YES;
        self.currentPasswordTextField.hidden = self.currentPasswordImageView.hidden = NO;
        
        self.navigationItem.leftBarButtonItem = self.cancelBarButtonItem;
        
        self.navigationItem.title = (self.changeType == ChangeTypeResetPassword) ? AMLocalizedString(@"passwordReset", @"Headline of the password reset recovery procedure") : AMLocalizedString(@"parkAccount", @"Headline for parking an account (basically restarting from scratch)");
        
        self.currentPasswordImageView.image = [UIImage imageNamed:@"email"];
        self.currentPasswordTextField.text = self.email;
        self.currentPasswordTextField.secureTextEntry = NO;
        self.currentPasswordTextField.userInteractionEnabled = NO;
        
        [self configureTextFieldStyle:self.theNewPasswordView.passwordTextField];
        self.theNewPasswordView.passwordTextField.placeholder = AMLocalizedString(@"newPassword", @"Placeholder text to explain that the new password should be written on this text field.");
        self.theNewPasswordView.passwordTextField.tag = 4;
        self.theNewPasswordView.leftImageView.image = [UIImage imageNamed:@"key"];
        
        [self configureTextFieldStyle:self.confirmPasswordView.passwordTextField];
        self.confirmPasswordView.passwordTextField.placeholder = AMLocalizedString(@"confirmPassword", @"Placeholder text to explain that the new password should be re-written on this text field.");
        self.confirmPasswordView.passwordTextField.tag = 5;
        self.confirmPasswordView.leftImageView.image = [UIImage imageNamed:@"keyDouble"];

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

- (void)configureTextFieldStyle:(UITextField *)textField {
    textField.delegate = self;
    textField.textColor = UIColor.mnz_black333333;
    textField.font = [UIFont mnz_SFUIRegularWithSize:17];
}

- (void)showPasswordErrorView:(PasswordView *)passwordView constraint:(NSLayoutConstraint *)constraint message:(NSString *)message {
    constraint.constant = 83;
    passwordView.wrongPasswordView.hidden = NO;
    passwordView.leftImageView.tintColor = UIColor.mnz_redD90007;
    passwordView.wrongPasswordLabel.text = message;
}

- (void)hidePasswordErrorView:(PasswordView *)passwordView constraint:(NSLayoutConstraint *)constraint {
    if (!passwordView.wrongPasswordView.hidden) {
        constraint.constant = 44;
        passwordView.wrongPasswordView.hidden = YES;
        passwordView.leftImageView.tintColor = UIColor.mnz_gray777777;
    }
}

- (BOOL)validatePasswordForm {
    [self hidePasswordErrorView:self.theNewPasswordView constraint:self.theNewPasswordViewHeightConstraint];
    [self hidePasswordErrorView:self.currentPasswordView constraint:self.currentPasswordViewHeightConstraint];
    [self hidePasswordErrorView:self.confirmPasswordView constraint:self.confirmPasswordViewHeightConstraint];
    
    if (self.changeType == ChangeTypePassword) {
        if (self.currentPasswordView.passwordTextField.text.length == 0) {
            [self showPasswordErrorView:self.currentPasswordView constraint:self.currentPasswordViewHeightConstraint message:AMLocalizedString(@"passwordInvalidFormat", @"Enter a valid password")];
            [self.currentPasswordView.passwordTextField becomeFirstResponder];
            return NO;
        }
    }
    if (![self validatePassword:self.theNewPasswordView.passwordTextField.text]) {
        if (self.theNewPasswordView.passwordTextField.text.length == 0) {
            [self showPasswordErrorView:self.theNewPasswordView constraint:self.theNewPasswordViewHeightConstraint message:AMLocalizedString(@"passwordInvalidFormat", @"Enter a valid password")];
            [self.theNewPasswordView.passwordTextField becomeFirstResponder];
        } else {
            [self showPasswordErrorView:self.confirmPasswordView constraint:self.confirmPasswordViewHeightConstraint message:AMLocalizedString(@"passwordsDoNotMatch", @"Passwords do not match")];
            self.passwordStrengthIndicatorView.customView.hidden = YES;
            self.passwordStrengthIndicatorViewHeightLayoutConstraint.constant = 0;
            [self.confirmPasswordView.passwordTextField becomeFirstResponder];
        }
        return NO;
    }
    
    if (([[MEGASdkManager sharedMEGASdk] passwordStrength:self.theNewPasswordView.passwordTextField.text] == PasswordStrengthVeryWeak) && (self.changeType == ChangeTypePassword)) {
        [self showPasswordErrorView:self.theNewPasswordView constraint:self.theNewPasswordViewHeightConstraint message:AMLocalizedString(@"passwordInvalidFormat", @"Enter a valid password")];
        self.passwordStrengthIndicatorView.customView.hidden = YES;
        self.passwordStrengthIndicatorViewHeightLayoutConstraint.constant = 0;
        [self.theNewPasswordView.passwordTextField becomeFirstResponder];
        return NO;
    }
    
    if ([self.currentPasswordView.passwordTextField.text isEqualToString:self.theNewPasswordView.passwordTextField.text]) {
        [self showPasswordErrorView:self.theNewPasswordView constraint:self.theNewPasswordViewHeightConstraint message: AMLocalizedString(@"oldAndNewPasswordMatch", @"The old and the new password can not match")];
        [self.theNewPasswordView.passwordTextField becomeFirstResponder];
        return NO;
    }
    
    return YES;
}

- (BOOL)validatePassword:(NSString *)password {
    if (password.length == 0 || ![password isEqualToString:self.confirmPasswordView.passwordTextField.text]) {
        return NO;
    } else {
        return YES;
    }
}

- (BOOL)validateEmail {
    NSString *newEmail = self.theNewPasswordTextField.text;
    BOOL validEmail = newEmail.mnz_isValidEmail;
    
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
            if ([self.currentPasswordTextField.text isEqualToString:@""] || [self.confirmPasswordTextField.text isEqualToString:@""]) {
                isAnyTextFieldEmpty = YES;
            }
            break;
        }
            
        case 2: {
            if ([self.currentPasswordTextField.text isEqualToString:@""] || [self.theNewPasswordTextField.text isEqualToString:@""]) {
                isAnyTextFieldEmpty = YES;
            }
            break;
        }
            
        case 3: {
            if ([self.theNewPasswordView.passwordTextField.text isEqualToString:@""] || [self.confirmPasswordView.passwordTextField.text isEqualToString:@""]) {
                isAnyTextFieldEmpty = YES;
            }
            break;
        }
            
        case 4: {
            if ([self.currentPasswordView.passwordTextField.text isEqualToString:@""] || [self.confirmPasswordView.passwordTextField.text isEqualToString:@""]) {
                isAnyTextFieldEmpty = YES;
            }
            break;
        }
            
        case 5: {
            if ([self.currentPasswordView.passwordTextField.text isEqualToString:@""] || [self.theNewPasswordView.passwordTextField.text isEqualToString:@""]) {
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
                [[MEGASdkManager sharedMEGASdk] changePassword:self.currentPasswordView.passwordTextField.text newPassword:self.theNewPasswordView.passwordTextField.text delegate:self];
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
                [[MEGASdkManager sharedMEGASdk] confirmResetPasswordWithLink:self.link newPassword:self.theNewPasswordView.passwordTextField.text masterKey:self.masterKey delegate:self];
            }
        } else if (self.changeType == ChangeTypeParkAccount) {
            if ([self validatePasswordForm]) {
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"startNewAccount", @"Headline of the password reset recovery procedure")  message:AMLocalizedString(@"startingFreshAccount", @"Label text of a checkbox to ensure that the user is aware that the data of his current account will be lost when proceeding unless they remember their password or have their master encryption key (now renamed 'Recovery Key')") preferredStyle:UIAlertControllerStyleAlert];
                [alertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"cancel", nil) style:UIAlertActionStyleCancel handler:nil]];
                [alertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"ok", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    [[MEGASdkManager sharedMEGASdk] confirmResetPasswordWithLink:self.link newPassword:self.theNewPasswordView.passwordTextField.text masterKey:nil delegate:self];
                }]];
                [self presentViewController:alertController animated:YES completion:nil];
            }
        }
    } else {
        self.changePasswordButton.enabled = YES;
    }
}

#pragma mark - UITextFieldDelegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSString *text = [textField.text stringByReplacingCharactersInRange:range withString:string];
    BOOL shoulBeCreateAccountButtonGray = NO;
    if ([text isEqualToString:@""] || (([[MEGASdkManager sharedMEGASdk] passwordStrength:self.theNewPasswordView.passwordTextField.text] == PasswordStrengthVeryWeak) && self.changeType == ChangeTypePassword)) {
        shoulBeCreateAccountButtonGray = YES;
    } else {
        shoulBeCreateAccountButtonGray = [self isEmptyAnyTextFieldForTag:textField.tag];
    }
    
    shoulBeCreateAccountButtonGray ? [self.changePasswordButton setBackgroundColor:UIColor.mnz_grayCCCCCC] : [self.changePasswordButton setBackgroundColor:UIColor.mnz_redFF4C52];
    
    if (self.changeType == ChangeTypePassword || self.changeType == ChangeTypeResetPassword || self.changeType == ChangeTypeParkAccount) {
        if (textField.tag == 4) {
            if (text.length == 0) {
                self.passwordStrengthIndicatorView.customView.hidden = YES;
                self.passwordStrengthIndicatorViewHeightLayoutConstraint.constant = 0;
            } else {
                self.passwordStrengthIndicatorViewHeightLayoutConstraint.constant = 112.0f;
                self.passwordStrengthIndicatorView.customView.hidden = NO;
                
                [self.passwordStrengthIndicatorView updateViewWithPasswordStrength:[[MEGASdkManager sharedMEGASdk] passwordStrength:text]];
            }
            [self hidePasswordErrorView:self.theNewPasswordView constraint:self.theNewPasswordViewHeightConstraint];
            [self hidePasswordErrorView:self.confirmPasswordView constraint:self.confirmPasswordViewHeightConstraint];
        } else if (textField.tag == 3) {
            [self hidePasswordErrorView:self.currentPasswordView constraint:self.currentPasswordViewHeightConstraint];
        } else if (textField.tag == 5) {
            [self hidePasswordErrorView:self.theNewPasswordView constraint:self.theNewPasswordViewHeightConstraint];
            [self hidePasswordErrorView:self.confirmPasswordView constraint:self.confirmPasswordViewHeightConstraint];
        }
    }
    
    return YES;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField {
    if (self.changeType == ChangeTypePassword || self.changeType == ChangeTypeResetPassword || self.changeType == ChangeTypeParkAccount) {
        if (textField.tag == 4) {
            self.passwordStrengthIndicatorView.customView.hidden = YES;
            self.passwordStrengthIndicatorViewHeightLayoutConstraint.constant = 0;
            [self hidePasswordErrorView:self.theNewPasswordView constraint:self.theNewPasswordViewHeightConstraint];
            [self hidePasswordErrorView:self.confirmPasswordView constraint:self.confirmPasswordViewHeightConstraint];
        } else if (textField.tag == 3) {
            [self hidePasswordErrorView:self.currentPasswordView constraint:self.currentPasswordViewHeightConstraint];
        } else if (textField.tag == 5) {
            [self hidePasswordErrorView:self.theNewPasswordView constraint:self.theNewPasswordViewHeightConstraint];
            [self hidePasswordErrorView:self.confirmPasswordView constraint:self.confirmPasswordViewHeightConstraint];
        }
    }
    
    self.changePasswordButton.backgroundColor = UIColor.mnz_grayCCCCCC;
    
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    
    switch (textField.tag) {
        case 0:
            [self.theNewPasswordTextField becomeFirstResponder];
            break;
            
        case 1:
            [_confirmPasswordTextField becomeFirstResponder];
            break;
            
        case 2:
            [_confirmPasswordTextField resignFirstResponder];
            break;
            
        case 3:
            [self.theNewPasswordView.passwordTextField becomeFirstResponder];
            break;
            
        case 4:
            [self.confirmPasswordView.passwordTextField becomeFirstResponder];
            break;
            
        case 5:
            [self.confirmPasswordView.passwordTextField resignFirstResponder];
            break;
            
        default:
            break;
    }
    
    return YES;
}

#pragma mark - MEGARequestDelegate

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    if (error.type) {
        self.changePasswordButton.enabled = YES;
        
        switch (error.type) {
            case MEGAErrorTypeApiEArgs: {
                if (request.type == MEGARequestTypeChangePassword) {
                    [self showPasswordErrorView:self.currentPasswordView constraint:self.currentPasswordViewHeightConstraint message:AMLocalizedString(@"passwordInvalidFormat", @"Enter a valid password")];
                    [self.currentPasswordTextField becomeFirstResponder];
                }
                break;
            }
                
            case MEGAErrorTypeApiEExist: {
                if (request.type == MEGARequestTypeGetChangeEmailLink) {
                    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"emailAddressChangeAlreadyRequested", @"Error message shown when you try to change your account email to one that you already requested.")  message:nil preferredStyle:UIAlertControllerStyleAlert];
                    [alertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"ok", nil) style:UIAlertActionStyleCancel handler:nil]];
                    [self presentViewController:alertController animated:YES completion:nil];
                    
                    self.currentPasswordImageView.image = [UIImage imageNamed:@"emailExisting"];
                    self.theNewPasswordImageView.image = [UIImage imageNamed:@"errorEmail"];
                    self.confirmPasswordImageView.image = [UIImage imageNamed:@"errorEmailConfirm"];
                }
                break;
            }
                
            case MEGAErrorTypeApiEKey: {
                if (request.type == MEGARequestTypeConfirmRecoveryLink) {
                    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"invalidRecoveryKey", @"An alert title where the user provided the incorrect Recovery Key.")  message:nil preferredStyle:UIAlertControllerStyleAlert];
                    [alertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"ok", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"passwordReset", @"Headline of the password reset recovery procedure")  message:AMLocalizedString(@"pleaseEnterYourRecoveryKey", @"A message shown to explain that the user has to input (type or paste) their recovery key to continue with the reset password process.") preferredStyle:UIAlertControllerStyleAlert];
                        [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
                            textField.placeholder = AMLocalizedString(@"recoveryKey", @"Label for any 'Recovery Key' button, link, text, title, etc. Preserve uppercase - (String as short as possible). The Recovery Key is the new name for the account 'Master Key', and can unlock (recover) the account if the user forgets their password.");
                            [textField becomeFirstResponder];
                        }];
                        [alertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"cancel", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                                UITextField *textField = alertController.textFields.firstObject;
                                [textField resignFirstResponder];
                                [self dismissViewControllerAnimated:YES completion:nil];
                        }]];
                        [alertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"ok", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                            self.masterKey = alertController.textFields.firstObject.text;
                            [self.theNewPasswordTextField becomeFirstResponder];
                        }]];
                        [self presentViewController:alertController animated:YES completion:nil];
                    }]];
                    [self presentViewController:alertController animated:YES completion:nil];
                    
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
                [self dismissViewControllerAnimated:YES completion:nil];
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
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:nil preferredStyle:UIAlertControllerStyleAlert];
                [alertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"ok", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                    [self dismissViewControllerAnimated:YES completion:nil];
                }]];
                [self presentViewController:alertController animated:YES completion:nil];
            }
            
            break;
        }
            
        default:
            break;
    }
}

@end
