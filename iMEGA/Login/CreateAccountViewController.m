
#import "CreateAccountViewController.h"

#import <SafariServices/SafariServices.h>

#import "SAMKeychain.h"
#import "SVProgressHUD.h"

#import "MEGACreateAccountRequestDelegate.h"
#import "MEGAReachabilityManager.h"
#import "NSString+MNZCategory.h"

#import "CheckEmailAndFollowTheLinkViewController.h"

@interface CreateAccountViewController () <UINavigationControllerDelegate, UITextFieldDelegate, MEGARequestDelegate>

@property (weak, nonatomic) IBOutlet UITextField *nameTextField;
@property (weak, nonatomic) IBOutlet UITextField *lastNameTextField;
@property (weak, nonatomic) IBOutlet UITextField *emailTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *passwordStrengthIndicatorViewHeightLayoutConstraint;
@property (weak, nonatomic) IBOutlet UIView *passwordStrengthIndicatorView;
@property (weak, nonatomic) IBOutlet UIImageView *passwordStrengthIndicatorImageView;
@property (weak, nonatomic) IBOutlet UILabel *passwordStrengthIndicatorLabel;
@property (weak, nonatomic) IBOutlet UILabel *passwordStrengthIndicatorDescriptionLabel;

@property (weak, nonatomic) IBOutlet UITextField *retypePasswordTextField;

@property (weak, nonatomic) IBOutlet UIButton *termsCheckboxButton;
@property (weak, nonatomic) IBOutlet UIButton *termsOfServiceButton;

@property (weak, nonatomic) IBOutlet UIButton *createAccountButton;

@property (weak, nonatomic) IBOutlet UIButton *loginButton;

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

@end

@implementation CreateAccountViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.passwordStrengthIndicatorViewHeightLayoutConstraint.constant = 0;
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard)];
    tapGesture.cancelsTouchesInView = NO;
    [self.scrollView addGestureRecognizer:tapGesture];
    
    self.nameTextField.placeholder = AMLocalizedString(@"firstName", @"Hint text for the first name (Placeholder)");
    self.lastNameTextField.placeholder = AMLocalizedString(@"lastName", @"Hint text for the last name (Placeholder)");
    
    if (self.emailString == nil) {
        [_emailTextField setPlaceholder:AMLocalizedString(@"emailPlaceholder", nil)];
    } else {
        [_emailTextField setText:self.emailString];
    }
    
    [self.passwordTextField setPlaceholder:AMLocalizedString(@"passwordPlaceholder", @"Password")];
    [self.retypePasswordTextField setPlaceholder:AMLocalizedString(@"confirmPassword", nil)];
    
    [self.termsOfServiceButton setTitle:AMLocalizedString(@"termsOfServiceButton", @"I agree with the MEGA Terms of Service") forState:UIControlStateNormal];
    if ([[UIDevice currentDevice] iPhone4X] || [[UIDevice currentDevice] iPhone5X]) {
        self.termsOfServiceButton.titleLabel.font = [UIFont mnz_SFUIRegularWithSize:11.0f];
    }
    
    self.createAccountButton.backgroundColor = [UIColor mnz_grayCCCCCC];
    [self.createAccountButton setTitle:AMLocalizedString(@"createAccount", @"Create Account") forState:UIControlStateNormal];
    
    [self.loginButton setTitle:AMLocalizedString(@"login", nil) forState:UIControlStateNormal];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.navigationController.navigationBar.topItem setTitle:AMLocalizedString(@"createAccount", @"Create Account")];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    if ([[UIDevice currentDevice] iPhoneDevice]) {
        return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown;
    }
    
    return UIInterfaceOrientationMaskAll;
}

#pragma mark - Private

- (BOOL)validateForm {
    if (![self validateName:self.nameTextField.text] || ![self validateName:self.lastNameTextField.text]) {
        [SVProgressHUD showErrorWithStatus:AMLocalizedString(@"invalidFirstNameAndLastName", @"")];
        if (![self validateName:self.nameTextField.text]) {
            [self.nameTextField becomeFirstResponder];
        } else {
            [self.lastNameTextField becomeFirstResponder];
        }
        
        return NO;
    } else if (![self.emailTextField.text mnz_isValidEmail]) {
        [SVProgressHUD showErrorWithStatus:AMLocalizedString(@"emailInvalidFormat", @"Enter a valid email")];
        [self.emailTextField becomeFirstResponder];
        return NO;
    } else if (![self validatePassword]) {
        if ([self.passwordTextField.text length] == 0) {
            [SVProgressHUD showErrorWithStatus:AMLocalizedString(@"passwordInvalidFormat", @"Enter a valid password")];
            [self.passwordTextField becomeFirstResponder];
        } else {
            [SVProgressHUD showErrorWithStatus:AMLocalizedString(@"passwordsDoNotMatch", @"Passwords do not match")];
            [self.retypePasswordTextField becomeFirstResponder];
        }
        return NO;
    } else if (![self.termsCheckboxButton isSelected]) {
        [SVProgressHUD showImage:[UIImage imageNamed:@"hudWarning"] status:AMLocalizedString(@"termsCheckboxUnselected", nil)];
        return NO;
    } else if ([[MEGASdkManager sharedMEGASdk] passwordStrength:self.passwordTextField.text] == PasswordStrengthVeryWeak) {
        [SVProgressHUD showImage:[UIImage imageNamed:@"hudWarning"] status:AMLocalizedString(@"yourPasswordIsTooWeakToProceed", @"")];
        return NO;
    }
    
    return YES;
}

- (BOOL)validateName:(NSString *)name {
    if (name.length == 0) {
        return NO;
    } else {
        return YES;
    }
}

- (BOOL)validatePassword {
    if (self.passwordTextField.text.length == 0 || self.retypePasswordTextField.text.length == 0 || ![self.passwordTextField.text isEqualToString:self.retypePasswordTextField.text]) {
        return NO;
    } else {
        return YES;
    }
}

- (BOOL)isEmptyAnyTextFieldForTag:(NSInteger )tag {
    BOOL isAnyTextFieldEmpty = NO;
    switch (tag) {
        case 0: {
            if ([self.lastNameTextField.text isEqualToString:@""] || [self.emailTextField.text isEqualToString:@""] || [self.passwordTextField.text isEqualToString:@""] || [self.retypePasswordTextField.text isEqualToString:@""]) {
                isAnyTextFieldEmpty = YES;
            }
            break;
        }
            
        case 1: {
            if ([self.nameTextField.text isEqualToString:@""] || [self.lastNameTextField.text isEqualToString:@""] || [self.emailTextField.text isEqualToString:@""] || [self.passwordTextField.text isEqualToString:@""] || [self.retypePasswordTextField.text isEqualToString:@""]) {
                isAnyTextFieldEmpty = YES;
            }
            break;
        }
            
        case 2: {
            if ([self.nameTextField.text isEqualToString:@""] || [self.lastNameTextField.text isEqualToString:@""] || [self.passwordTextField.text isEqualToString:@""] || [self.retypePasswordTextField.text isEqualToString:@""]) {
                isAnyTextFieldEmpty = YES;
            }
            break;
        }
            
        case 3: {
            if ([self.nameTextField.text isEqualToString:@""] || [self.lastNameTextField.text isEqualToString:@""] || [self.emailTextField.text isEqualToString:@""] || [self.retypePasswordTextField.text isEqualToString:@""]) {
                isAnyTextFieldEmpty = YES;
            }
            break;
        }
            
        case 4: {
            if ([self.nameTextField.text isEqualToString:@""] || [self.lastNameTextField.text isEqualToString:@""] || [self.emailTextField.text isEqualToString:@""] || [self.passwordTextField.text isEqualToString:@""]) {
                isAnyTextFieldEmpty = YES;
            }
            break;
        }
    }
    
    return isAnyTextFieldEmpty;
}

- (void)updatePasswordStrengthIndicatorViewWith:(PasswordStrength)passwordStrength {
    switch (passwordStrength) {
        case PasswordStrengthVeryWeak:
            self.passwordStrengthIndicatorImageView.image = [UIImage imageNamed:@"indicatorVeryWeak"];
            self.passwordStrengthIndicatorLabel.text = AMLocalizedString(@"veryWeak", @"Label displayed during checking the strength of the password introduced. Represents Very Weak security");
            self.passwordStrengthIndicatorLabel.textColor = [UIColor mnz_redF0373A];
            self.passwordStrengthIndicatorDescriptionLabel.text = AMLocalizedString(@"passwordVeryWeakOrWeak", @"");
            break;
            
        case PasswordStrengthWeak:
            self.passwordStrengthIndicatorImageView.image = [UIImage imageNamed:@"indicatorWeak"];
            self.passwordStrengthIndicatorLabel.text = AMLocalizedString(@"weak", @"");
            self.passwordStrengthIndicatorLabel.textColor = [UIColor colorWithRed:1.0 green:165.0/255.0 blue:0 alpha:1.0];
            self.passwordStrengthIndicatorDescriptionLabel.text = AMLocalizedString(@"passwordVeryWeakOrWeak", @"");
            break;
            
        case PasswordStrengthMedium:
            self.passwordStrengthIndicatorImageView.image = [UIImage imageNamed:@"indicatorMedium"];
            self.passwordStrengthIndicatorLabel.text = AMLocalizedString(@"medium", @"Label displayed during checking the strength of the password introduced. Represents Medium security");
            self.passwordStrengthIndicatorLabel.textColor = [UIColor mnz_green31B500];
            self.passwordStrengthIndicatorDescriptionLabel.text = AMLocalizedString(@"passwordMedium", @"");
            break;
            
        case PasswordStrengthGood:
            self.passwordStrengthIndicatorImageView.image = [UIImage imageNamed:@"indicatorGood"];
            self.passwordStrengthIndicatorLabel.text = AMLocalizedString(@"good", @"");
            self.passwordStrengthIndicatorLabel.textColor = [UIColor colorWithRed:18.0/255.0 green:210.0/255.0 blue:56.0/255.0 alpha:1.0];
            self.passwordStrengthIndicatorDescriptionLabel.text = AMLocalizedString(@"passwordGood", @"");
            break;
            
        case PasswordStrengthStrong:
            self.passwordStrengthIndicatorImageView.image = [UIImage imageNamed:@"indicatorStrong"];
            self.passwordStrengthIndicatorLabel.text = AMLocalizedString(@"strong", @"Label displayed during checking the strength of the password introduced. Represents Strong security");
            self.passwordStrengthIndicatorLabel.textColor = [UIColor mnz_blue2BA6DE];
            self.passwordStrengthIndicatorDescriptionLabel.text = AMLocalizedString(@"passwordStrong", @"");
            break;
    }
}

- (void)hideKeyboard {
    [self.nameTextField resignFirstResponder];
    [self.lastNameTextField resignFirstResponder];
    [self.emailTextField resignFirstResponder];
    [self.passwordTextField resignFirstResponder];
    [self.retypePasswordTextField resignFirstResponder];
}

#pragma mark - IBActions

- (IBAction)termsCheckboxTouchUpInside:(id)sender {
    self.termsCheckboxButton.selected = !self.termsCheckboxButton.selected;
    
    [self hideKeyboard];
}

- (IBAction)termOfServiceTouchUpInside:(UIButton *)sender {
    if ([MEGAReachabilityManager isReachableHUDIfNot]) {
        NSURL *URL = [NSURL URLWithString:@"https://mega.nz/ios_terms.html"];
        UIViewController *webViewController = [[SFSafariViewController alloc] initWithURL:URL];
        ((SFSafariViewController *)webViewController).modalPresentationStyle = UIModalPresentationOverFullScreen;
        if (@available(iOS 10.0, *)) {
            ((SFSafariViewController *)webViewController).preferredControlTintColor = [UIColor mnz_redD90007];
        } else {
            webViewController.view.tintColor = [UIColor mnz_redD90007];
        }
        [self presentViewController:webViewController animated:YES completion:nil];
    }
}

- (IBAction)createAccountTouchUpInside:(id)sender {
    if ([self validateForm]) {
        if ([MEGAReachabilityManager isReachableHUDIfNot]) {
            [SVProgressHUD show];
            
            MEGACreateAccountRequestDelegate *createAccountRequestDelegate = [[MEGACreateAccountRequestDelegate alloc] initWithCompletion:^(MEGAError *error) {
                [SVProgressHUD dismiss];
                if (error.type == MEGAErrorTypeApiOk) {
                    CheckEmailAndFollowTheLinkViewController *checkEmailAndFollowTheLinkVC = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"CheckEmailAndFollowTheLinkViewControllerID"];
                    [self presentViewController:checkEmailAndFollowTheLinkVC animated:YES completion:^{
                        [self.navigationController popViewControllerAnimated:YES];
                    }];
                } else {
                    [self.emailTextField becomeFirstResponder];
                    [self.createAccountButton setEnabled:YES];
                }
            }];
            createAccountRequestDelegate.resumeCreateAccount = NO;
            [[MEGASdkManager sharedMEGASdk] createAccountWithEmail:self.emailTextField.text password:self.passwordTextField.text firstname:self.nameTextField.text lastname:self.lastNameTextField.text delegate:createAccountRequestDelegate];
            [self.createAccountButton setEnabled:NO];
        }
    }
}

#pragma mark - UITextFieldDelegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSString *text = [textField.text stringByReplacingCharactersInRange:range withString:string];
    BOOL shoulBeCreateAccountButtonGray = NO;
    if ([text isEqualToString:@""] || (![self.emailTextField.text mnz_isValidEmail])) {
        shoulBeCreateAccountButtonGray = YES;
    } else {
        shoulBeCreateAccountButtonGray = [self isEmptyAnyTextFieldForTag:textField.tag];
    }
    
    shoulBeCreateAccountButtonGray ? [self.createAccountButton setBackgroundColor:[UIColor mnz_grayCCCCCC]] : [self.createAccountButton setBackgroundColor:[UIColor mnz_redFF4D52]];
    
    if (textField.tag == 3) {
        if (text.length == 0) {
            self.passwordStrengthIndicatorView.hidden = YES;
            self.passwordStrengthIndicatorViewHeightLayoutConstraint.constant = 0;
        } else {
            self.passwordStrengthIndicatorViewHeightLayoutConstraint.constant = 112.0f;
            self.passwordStrengthIndicatorView.hidden = NO;
            
            [self updatePasswordStrengthIndicatorViewWith:[[MEGASdkManager sharedMEGASdk] passwordStrength:text]];
        }
    }
    
    return YES;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField {
    if (textField.tag == 3) {
        self.passwordStrengthIndicatorView.hidden = YES;
        self.passwordStrengthIndicatorViewHeightLayoutConstraint.constant = 0;
    }
    
    self.createAccountButton.backgroundColor = [UIColor mnz_grayCCCCCC];
    
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    switch ([textField tag]) {
        case 0:
            [self.lastNameTextField becomeFirstResponder];
            break;
            
        case 1:
            [self.emailTextField becomeFirstResponder];
            break;
            
        case 2:
            [self.passwordTextField becomeFirstResponder];
            break;
            
        case 3:
            [self.retypePasswordTextField becomeFirstResponder];
            break;
            
        case 4:
            [self.retypePasswordTextField resignFirstResponder];
            break;
            
        default:
            break;
    }
    
    return YES;
}

@end
