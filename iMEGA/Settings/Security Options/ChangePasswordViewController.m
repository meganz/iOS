#import "ChangePasswordViewController.h"
#import "MEGASdkManager.h"
#import "MEGAReachabilityManager.h"
#import "SVProgressHUD.h"

@interface ChangePasswordViewController () <MEGARequestDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *currentPasswordImageView;
@property (weak, nonatomic) IBOutlet UITextField *currentPasswordTextField;
@property (weak, nonatomic) IBOutlet UIImageView *theNewPasswordImageView;
@property (weak, nonatomic) IBOutlet UITextField *theNewPasswordTextField;
@property (weak, nonatomic) IBOutlet UIImageView *confirmPasswordImageView;
@property (weak, nonatomic) IBOutlet UITextField *confirmPasswordTextField;

@property (weak, nonatomic) IBOutlet UIButton *changePasswordButton;

@property (weak, nonatomic) IBOutlet UIView *emailIsChangingView;
@property (weak, nonatomic) IBOutlet UILabel *emailIsChangingTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *emailIsChangingDescriptionLabel;

@end

@implementation ChangePasswordViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (self.changeType == ChangeTypePassword) {
        self.navigationItem.title = AMLocalizedString(@"changePasswordLabel", @"Section title where you can change your MEGA's password");
        
        self.currentPasswordTextField.placeholder = AMLocalizedString(@"currentPassword", @"Placeholder text to explain that the current password should be written on this text field.");
        self.theNewPasswordTextField.placeholder = AMLocalizedString(@"newPassword", @"Placeholder text to explain that the new password should be written on this text field.");
        self.confirmPasswordTextField.placeholder = AMLocalizedString(@"confirmPassword", @"Placeholder text to explain that the new password should be re-written on this text field.");
        
        [self.changePasswordButton setTitle:AMLocalizedString(@"changePasswordLabel", @"Section title where you can change your MEGA's password") forState:UIControlStateNormal];
        
        [self.currentPasswordTextField becomeFirstResponder];
    } else if (self.changeType == ChangeTypeEmail) {
        self.navigationItem.title = AMLocalizedString(@"changeEmail", @"The title of the alert dialog to change the email associated to an account.");
        
        self.currentPasswordImageView.image = [UIImage imageNamed:@"emailExisting"];
        self.currentPasswordTextField.text = [[MEGASdkManager sharedMEGASdk] myEmail];
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
        
        self.emailIsChangingTitleLabel.text = AMLocalizedString(@"awaitingEmailConfirmation", @"Title shown just after creating an account to remenber the user what to do to complete the account creation proccess");
        self.emailIsChangingDescriptionLabel.text = AMLocalizedString(@"emailIsChanging_description", @"Text shown just after tap to change an email account to remenber the user what to do to complete the change email proccess");
    }
    
    [self.changePasswordButton.layer setCornerRadius:4];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(emailHasChanged) name:@"emailHasChanged" object:nil];
}

#pragma mark - Private

- (BOOL)validatePasswordForm {
    if (_currentPasswordTextField.text.length == 0) {
        [SVProgressHUD showErrorWithStatus:AMLocalizedString(@"passwordInvalidFormat", @"Enter a valid password")];
        [_currentPasswordTextField becomeFirstResponder];
        return NO;
    }
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
    
    if ([_currentPasswordTextField.text isEqualToString:self.theNewPasswordTextField.text]) {
        [SVProgressHUD showErrorWithStatus:AMLocalizedString(@"oldAndNewPasswordMatch", @"The old and the new password can not match")];
        [self.theNewPasswordTextField setText:@""];
        [self.confirmPasswordTextField setText:@""];
        [self.theNewPasswordTextField becomeFirstResponder];
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
    
    NSString *emailRegex =
    @"(?:[a-z0-9!#$%\\&'*+/=?\\^_`{|}~-]+(?:\\.[a-z0-9!#$%\\&'*+/=?\\^_`{|}"
    @"~-]+)*|\"(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21\\x23-\\x5b\\x5d-\\"
    @"x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])*\")@(?:(?:[a-z0-9](?:[a-"
    @"z0-9-]*[a-z0-9])?\\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\\[(?:(?:25[0-5"
    @"]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-"
    @"9][0-9]?|[a-z0-9-]*[a-z0-9]:(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21"
    @"-\\x5a\\x53-\\x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])+)\\])";
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES[c] %@", emailRegex];
    BOOL validEmail = [emailTest evaluateWithObject:newEmail];
    
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

#pragma mark - IBAction

- (IBAction)changePasswordTouchUpIndise:(UIButton *)sender {
    if ([MEGAReachabilityManager isReachableHUDIfNot]) {
        if (self.changeType == ChangeTypePassword) {
            if ([self validatePasswordForm]) {
                self.changePasswordButton.enabled = NO;
                [[MEGASdkManager sharedMEGASdk] changePassword:self.currentPasswordTextField.text newPassword:self.theNewPasswordTextField.text delegate:self];
            }
        } else if (self.changeType == ChangeTypeEmail) {
            if ([self validateEmail]) {
                self.changePasswordButton.enabled = NO;
                [[MEGASdkManager sharedMEGASdk] changeEmail:self.confirmPasswordTextField.text delegate:self];
            } else {
                self.theNewPasswordImageView.image = [UIImage imageNamed:@"errorEmail"];
                self.confirmPasswordImageView.image = [UIImage imageNamed:@"errorEmailConfirm"];
            }
        }
    } else {
        self.changePasswordButton.enabled = YES;
    }
}

#pragma mark - UITextFieldDelegate

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    
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
        
        if (request.type == MEGARequestTypeChangePassword) {
            self.currentPasswordTextField.text = @"";
            self.theNewPasswordTextField.text = @"";
            self.confirmPasswordTextField.text = @"";
            [self.currentPasswordTextField becomeFirstResponder];
            [SVProgressHUD showErrorWithStatus:AMLocalizedString(@"passwordInvalidFormat", @"Enter a valid password")];
            return;
        } else if (request.type == MEGARequestTypeGetChangeEmailLink) {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:AMLocalizedString(@"emailAddressChangeAlreadyRequested", @"Error message shown when you try to change your account email to one that you already requested")
                                                                message:nil
                                                               delegate:nil
                                                      cancelButtonTitle:AMLocalizedString(@"ok", nil)
                                                      otherButtonTitles:nil];
            [alertView show];
            
            self.currentPasswordImageView.image = [UIImage imageNamed:@"emailExisting"];
            self.theNewPasswordImageView.image = [UIImage imageNamed:@"errorEmail"];
            self.confirmPasswordImageView.image = [UIImage imageNamed:@"errorEmailConfirm"];
            return;
        }
    }
    
    if ([request type] == MEGARequestTypeChangePassword) {
        [SVProgressHUD showSuccessWithStatus:AMLocalizedString(@"passwordChanged", @"The label showed when your password has been changed")];
        
        [self.navigationController popViewControllerAnimated:YES];
    } else if ([request type] == MEGARequestTypeGetChangeEmailLink) {
        self.view = self.emailIsChangingView;
    }
}

@end
