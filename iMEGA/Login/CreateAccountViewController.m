#import "CreateAccountViewController.h"

#import "Helper.h"
#import "MEGAReachabilityManager.h"
#import "SVProgressHUD.h"
#import "SVModalWebViewController.h"

@interface CreateAccountViewController () <UINavigationControllerDelegate, UITextFieldDelegate, MEGARequestDelegate>

@property (weak, nonatomic) IBOutlet UITextField *nameTextField;
@property (weak, nonatomic) IBOutlet UITextField *emailTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UITextField *retypePasswordTextField;

@property (weak, nonatomic) IBOutlet UIButton *termsCheckboxButton;
@property (weak, nonatomic) IBOutlet UIButton *termsOfServiceButton;

@property (weak, nonatomic) IBOutlet UIButton *createAccountButton;

@property (weak, nonatomic) IBOutlet UIView *accountCreatedView;
@property (weak, nonatomic) IBOutlet UILabel *accountCreatedTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *accountCreatedLabel;

@property (weak, nonatomic) IBOutlet UIButton *loginButton;

@end

@implementation CreateAccountViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.nameTextField setPlaceholder:AMLocalizedString(@"name", nil)];
    
    if (self.emailString == nil) {
        [_emailTextField setPlaceholder:AMLocalizedString(@"emailPlaceholder", nil)];
    } else {
        [_emailTextField setText:self.emailString];
    }
    
    [self.passwordTextField setPlaceholder:AMLocalizedString(@"passwordPlaceholder", @"Password")];
    [self.retypePasswordTextField setPlaceholder:AMLocalizedString(@"confirmPassword", nil)];
    
    [self.termsOfServiceButton setTitle:AMLocalizedString(@"termsOfServiceButton", @"I agree with the MEGA Terms of Service") forState:UIControlStateNormal];
    if ([[UIDevice currentDevice] iPhone4X] || [[UIDevice currentDevice] iPhone5X]) {
        self.termsOfServiceButton.titleLabel.font = [UIFont mnz_SFUILightWithSize:11.0f];
    }
    
    self.createAccountButton.layer.cornerRadius = 4.0f;
    self.createAccountButton.layer.masksToBounds = YES;
    self.createAccountButton.backgroundColor = [UIColor mnz_grayCCCCCC];
    [self.createAccountButton setTitle:AMLocalizedString(@"createAccount", @"Create Account") forState:UIControlStateNormal];
    
    [self.accountCreatedView.layer setMasksToBounds:YES];
    [self.accountCreatedTitleLabel setText:AMLocalizedString(@"awaitingEmailConfirmation", nil)];
    self.accountCreatedLabel.text = AMLocalizedString(@"accountNotConfirmed", @"Text shown just after creating an account to remenber the user what to do to complete the account creation proccess.");
    
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
    if (![self validateName:self.nameTextField.text]) {
        [SVProgressHUD showErrorWithStatus:AMLocalizedString(@"nameInvalidFormat", @"Enter a valid name")];
        [self.nameTextField becomeFirstResponder];
        return NO;
    } else if (![Helper validateEmail:self.emailTextField.text]) {
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
            if ([self.emailTextField.text isEqualToString:@""] || [self.passwordTextField.text isEqualToString:@""] || [self.retypePasswordTextField.text isEqualToString:@""]) {
                isAnyTextFieldEmpty = YES;
            }
            break;
        }
            
        case 1: {
            if ([self.nameTextField.text isEqualToString:@""] || [self.passwordTextField.text isEqualToString:@""] || [self.retypePasswordTextField.text isEqualToString:@""]) {
                isAnyTextFieldEmpty = YES;
            }
            break;
        }
            
        case 2: {
            if ([self.nameTextField.text isEqualToString:@""] || [self.emailTextField.text isEqualToString:@""] || [self.retypePasswordTextField.text isEqualToString:@""]) {
                isAnyTextFieldEmpty = YES;
            }
            break;
        }
            
        case 3: {
            if ([self.nameTextField.text isEqualToString:@""] || [self.emailTextField.text isEqualToString:@""] || [self.passwordTextField.text isEqualToString:@""]) {
                isAnyTextFieldEmpty = YES;
            }
            break;
        }
    }
    
    return isAnyTextFieldEmpty;
}

#pragma mark - UIResponder

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}

#pragma mark - IBActions

- (IBAction)termsCheckboxTouchUpInside:(id)sender {
    self.termsCheckboxButton.selected = !self.termsCheckboxButton.selected;
    
    [self.nameTextField resignFirstResponder];
    [self.emailTextField resignFirstResponder];
    [self.passwordTextField resignFirstResponder];
    [self.retypePasswordTextField resignFirstResponder];
}

- (IBAction)termOfServiceTouchUpInside:(UIButton *)sender {
    if ([MEGAReachabilityManager isReachableHUDIfNot]) {
        NSURL *URL = [NSURL URLWithString:@"https://mega.nz/ios_terms.html"];
        SVModalWebViewController *webViewController = [[SVModalWebViewController alloc] initWithURL:URL];
        [webViewController setBarsTintColor:[UIColor mnz_redD90007]];
        [self presentViewController:webViewController animated:YES completion:nil];
    }
}

- (IBAction)createAccountTouchUpInside:(id)sender {
    if ([self validateForm]) {
        if ([MEGAReachabilityManager isReachableHUDIfNot]) {
            [SVProgressHUD show];
            [[MEGASdkManager sharedMEGASdk] createAccountWithEmail:[self.emailTextField text] password:[self.passwordTextField text] firstname:[self.nameTextField text] lastname:NULL delegate:self];
            [self.createAccountButton setEnabled:NO];
        }
    }
}

#pragma mark - UITextFieldDelegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSString *text = [textField.text stringByReplacingCharactersInRange:range withString:string];
    BOOL shoulBeCreateAccountButtonGray = NO;
    if ([text isEqualToString:@""] || (![Helper validateEmail:self.emailTextField.text])) {
        shoulBeCreateAccountButtonGray = YES;
    } else {
        shoulBeCreateAccountButtonGray = [self isEmptyAnyTextFieldForTag:textField.tag];
    }
    
    shoulBeCreateAccountButtonGray ? [self.createAccountButton setBackgroundColor:[UIColor mnz_grayCCCCCC]] : [self.createAccountButton setBackgroundColor:[UIColor mnz_redFF4C52]];
    
    return YES;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField {
    self.createAccountButton.backgroundColor = [UIColor mnz_grayCCCCCC];
    
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    switch ([textField tag]) {
        case 0:
            [self.emailTextField becomeFirstResponder];
            break;
            
        case 1:
            [self.passwordTextField becomeFirstResponder];
            break;
            
        case 2:
            [self.retypePasswordTextField becomeFirstResponder];
            break;
            
        case 3:
            [self.retypePasswordTextField resignFirstResponder];
            break;
            
        default:
            break;
    }
    
    return YES;
}

#pragma mark - MEGARequestDelegate

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    if ([error type]) {
        switch ([error type]) {
                
            case MEGAErrorTypeApiEExist: {
                [SVProgressHUD showImage:[UIImage imageNamed:@"hudWarning"] status:AMLocalizedString(@"emailAlreadyRegistered", nil)];
                [self.emailTextField becomeFirstResponder];
                
                [self.createAccountButton setEnabled:YES];
                break;
            }
                
            default:
                break;
        }
        return;
    }
    
    switch ([request type]) {
        case MEGARequestTypeCreateAccount: {
            [SVProgressHUD dismiss];
            
            [self.nameTextField setEnabled:NO];
            [self.emailTextField setEnabled:NO];
            [self.passwordTextField setEnabled:NO];
            [self.retypePasswordTextField setEnabled:NO];
            [self.termsCheckboxButton setUserInteractionEnabled:NO];
            [self.createAccountButton setEnabled:NO];
            
            self.view = self.accountCreatedView;
        }
            
        default:
            break;
    }
}

@end
