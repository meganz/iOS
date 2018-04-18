
#import "CreateAccountViewController.h"

#import "SAMKeychain.h"
#import "SVProgressHUD.h"

#import "Helper.h"
#import "MEGACreateAccountRequestDelegate.h"
#import "MEGAReachabilityManager.h"
#import "NSString+MNZCategory.h"

#import "CheckEmailAndFollowTheLinkViewController.h"
#import "PasswordStrengthIndicatorView.h"
#import "PasswordView.h"

@interface CreateAccountViewController () <UINavigationControllerDelegate, UITextFieldDelegate, MEGARequestDelegate>

@property (weak, nonatomic) IBOutlet UIBarButtonItem *cancelBarButtonItem;

@property (weak, nonatomic) IBOutlet UITextField *nameTextField;
@property (weak, nonatomic) IBOutlet UITextField *lastNameTextField;
@property (weak, nonatomic) IBOutlet UIImageView *nameIconImageView;
@property (weak, nonatomic) IBOutlet UITextField *emailTextField;
@property (weak, nonatomic) IBOutlet UIImageView *emailIconImageView;
@property (weak, nonatomic) IBOutlet PasswordView *passwordView;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *passwordStrengthIndicatorViewHeightLayoutConstraint;
@property (weak, nonatomic) IBOutlet PasswordStrengthIndicatorView *passwordStrengthIndicatorView;

@property (weak, nonatomic) IBOutlet PasswordView *retypePasswordView;

@property (weak, nonatomic) IBOutlet UIButton *termsCheckboxButton;
@property (weak, nonatomic) IBOutlet UIButton *termsOfServiceButton;

@property (weak, nonatomic) IBOutlet UIButton *createAccountButton;

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UITextField *activeTextField;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *passwordViewHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *retypePasswordViewHeightConstraint;

@end

@implementation CreateAccountViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.passwordStrengthIndicatorViewHeightLayoutConstraint.constant = 0;
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard)];
    tapGesture.cancelsTouchesInView = NO;
    [self.scrollView addGestureRecognizer:tapGesture];
    
    self.cancelBarButtonItem.title = AMLocalizedString(@"cancel", @"Button title to cancel something");
    
    self.nameTextField.placeholder = AMLocalizedString(@"firstName", @"Hint text for the first name (Placeholder)");
    self.lastNameTextField.placeholder = AMLocalizedString(@"lastName", @"Hint text for the last name (Placeholder)");
    
    if (self.emailString == nil) {
        [_emailTextField setPlaceholder:AMLocalizedString(@"emailPlaceholder", nil)];
    } else {
        [_emailTextField setText:self.emailString];
    }
    
    [self configureTextFieldStyle:self.passwordView.passwordTextField];
    self.passwordView.passwordTextField.tag = 3;

    [self configureTextFieldStyle:self.retypePasswordView.passwordTextField];
    [self.retypePasswordView.passwordTextField setPlaceholder:AMLocalizedString(@"confirmPassword", nil)];
    self.retypePasswordView.passwordTextField.tag = 4;
    self.retypePasswordView.leftImageView.image = [UIImage imageNamed:@"keyDouble"];
    self.retypePasswordView.leftImageView.tintColor = UIColor.mnz_gray777777;
    
    [self setTermsOfServiceAttributedTitle];
    
    self.createAccountButton.backgroundColor = UIColor.mnz_grayEEEEEE;
    [self.createAccountButton setTitle:AMLocalizedString(@"createAccount", @"Create Account") forState:UIControlStateNormal];
    
    [self registerForKeyboardNotifications];
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

- (IBAction)cancel:(UIBarButtonItem *)sender {
    [self hideKeyboard];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (BOOL)validateForm {
    if (![self validateName:self.nameTextField.text] || ![self validateName:self.lastNameTextField.text]) {
        [SVProgressHUD showErrorWithStatus:AMLocalizedString(@"invalidFirstNameAndLastName", @"")];
        self.nameIconImageView.tintColor = UIColor.mnz_redD90007;
        if (![self validateName:self.nameTextField.text]) {
            [self.nameTextField becomeFirstResponder];
        } else {
            [self.lastNameTextField becomeFirstResponder];
        }
        
        return NO;
    }
    
    if (!self.emailTextField.text.mnz_isValidEmail) {
        [SVProgressHUD showErrorWithStatus:AMLocalizedString(@"emailInvalidFormat", @"Enter a valid email")];
        self.emailIconImageView.image = [UIImage imageNamed:@"errorEmail"];
        [self.emailTextField becomeFirstResponder];
        
        return NO;
    }
    
    if (![self validatePassword]) {
        if ([self.passwordView.passwordTextField.text length] == 0) {
            [self showPasswordErrorView:self.passwordView constraint:self.passwordViewHeightConstraint message:AMLocalizedString(@"passwordInvalidFormat", @"Enter a valid password")];
            [self.passwordView.passwordTextField becomeFirstResponder];
        } else {
            [self showPasswordErrorView:self.retypePasswordView constraint:self.retypePasswordViewHeightConstraint message: AMLocalizedString(@"passwordsDoNotMatch", @"Passwords do not match")];
            [self.retypePasswordView.passwordTextField becomeFirstResponder];
        }
        
        return NO;
    }
    
    if ([[MEGASdkManager sharedMEGASdk] passwordStrength:self.passwordView.passwordTextField.text] == PasswordStrengthVeryWeak) {
        [SVProgressHUD showImage:[UIImage imageNamed:@"hudWarning"] status:AMLocalizedString(@"pleaseStrengthenYourPassword", @"")];
        
        return NO;
    }
    
    if (!self.termsCheckboxButton.isSelected) {
        [SVProgressHUD showImage:[UIImage imageNamed:@"hudWarning"] status:AMLocalizedString(@"termsCheckboxUnselected", @"Error text shown when you don't have selected the checkbox to agree with the Terms of Service")];
        
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
    if (self.passwordView.passwordTextField.text.length == 0 || self.retypePasswordView.passwordTextField.text.length == 0 || ![self.passwordView.passwordTextField.text isEqualToString:self.retypePasswordView.passwordTextField.text]) {
        return NO;
    } else {
        return YES;
    }
}

- (BOOL)isEmptyAnyTextFieldForTag:(NSInteger )tag {
    BOOL isAnyTextFieldEmpty = NO;
    switch (tag) {
        case 0: {
            if ([self.lastNameTextField.text isEqualToString:@""] || [self.emailTextField.text isEqualToString:@""] || [self.passwordView.passwordTextField.text isEqualToString:@""] || [self.retypePasswordView.passwordTextField.text isEqualToString:@""]) {
                isAnyTextFieldEmpty = YES;
            }
            break;
        }
            
        case 1: {
            if ([self.nameTextField.text isEqualToString:@""] || [self.lastNameTextField.text isEqualToString:@""] || [self.emailTextField.text isEqualToString:@""] || [self.passwordView.passwordTextField.text isEqualToString:@""] || [self.retypePasswordView.passwordTextField.text isEqualToString:@""]) {
                isAnyTextFieldEmpty = YES;
            }
            break;
        }
            
        case 2: {
            if ([self.nameTextField.text isEqualToString:@""] || [self.lastNameTextField.text isEqualToString:@""] || [self.passwordView.passwordTextField.text isEqualToString:@""] || [self.retypePasswordView.passwordTextField.text isEqualToString:@""]) {
                isAnyTextFieldEmpty = YES;
            }
            break;
        }
            
        case 3: {
            if ([self.nameTextField.text isEqualToString:@""] || [self.lastNameTextField.text isEqualToString:@""] || [self.emailTextField.text isEqualToString:@""] || [self.retypePasswordView.passwordTextField.text isEqualToString:@""]) {
                isAnyTextFieldEmpty = YES;
            }
            break;
        }
            
        case 4: {
            if ([self.nameTextField.text isEqualToString:@""] || [self.lastNameTextField.text isEqualToString:@""] || [self.emailTextField.text isEqualToString:@""] || [self.passwordView.passwordTextField.text isEqualToString:@""]) {
                isAnyTextFieldEmpty = YES;
            }
            break;
        }
    }
    
    return isAnyTextFieldEmpty;
}

- (void)hideKeyboard {
    [self.view endEditing:YES];
}

- (void)registerForKeyboardNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardDidShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:nil];
    
}

- (void)keyboardWasShown:(NSNotification*)aNotification {
    NSDictionary *info = aNotification.userInfo;
    CGSize keyboardSize = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;

    CGFloat bottomSpaceToLineSeparator = 14.0f;
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, keyboardSize.height + (bottomSpaceToLineSeparator * 2), 0.0);
    self.scrollView.contentInset = contentInsets;
    self.scrollView.scrollIndicatorInsets = contentInsets;

    CGRect viewFrame = self.view.frame;
    viewFrame.size.height -= keyboardSize.height;
    if (!CGRectContainsPoint(viewFrame, self.activeTextField.frame.origin)) {
        [self.scrollView scrollRectToVisible:self.activeTextField.frame animated:YES];
    }
}

- (void)keyboardWillBeHidden:(NSNotification *)aNotification {
    self.scrollView.contentInset = UIEdgeInsetsZero;
    self.scrollView.scrollIndicatorInsets = UIEdgeInsetsZero;
}

- (void)setTermsOfServiceAttributedTitle {
    NSString *agreeWithTheMEGATermsOfService = AMLocalizedString(@"agreeWithTheMEGATermsOfService", @"");
    NSString *termsOfServiceString = [agreeWithTheMEGATermsOfService mnz_stringBetweenString:@"<a href='terms'>" andString:@"</a>"];
    agreeWithTheMEGATermsOfService = [agreeWithTheMEGATermsOfService mnz_removeWebclientFormatters];
    
    NSMutableAttributedString *termsOfServiceMutableAttributedString = [[NSMutableAttributedString alloc] initWithString:agreeWithTheMEGATermsOfService attributes:@{NSFontAttributeName:[UIFont mnz_SFUIRegularWithSize:12.0f], NSForegroundColorAttributeName:UIColor.mnz_gray666666}];
    [termsOfServiceMutableAttributedString setAttributes:@{NSFontAttributeName:[UIFont mnz_SFUISemiBoldWithSize:12.0f], NSForegroundColorAttributeName:UIColor.mnz_gray666666} range:[agreeWithTheMEGATermsOfService rangeOfString:@"MEGA"]];
    if (termsOfServiceString) {
        [termsOfServiceMutableAttributedString setAttributes:@{NSFontAttributeName:[UIFont mnz_SFUISemiBoldWithSize:12.0f], NSForegroundColorAttributeName:UIColor.mnz_gray666666} range:[agreeWithTheMEGATermsOfService rangeOfString:termsOfServiceString]];
    }
    
    [self.termsOfServiceButton setAttributedTitle:termsOfServiceMutableAttributedString forState:UIControlStateNormal];
}

#pragma mark - IBActions

- (IBAction)termsCheckboxTouchUpInside:(id)sender {
    self.termsCheckboxButton.selected = !self.termsCheckboxButton.selected;
    
    BOOL shoulBeCreateAccountButtonGray = NO;
    if ((!self.emailTextField.text.mnz_isValidEmail) || ([[MEGASdkManager sharedMEGASdk] passwordStrength:self.passwordView.passwordTextField.text] == PasswordStrengthVeryWeak) || !self.termsCheckboxButton.selected) {
        shoulBeCreateAccountButtonGray = YES;
    } else {
        shoulBeCreateAccountButtonGray = [self isEmptyAnyTextFieldForTag:self.retypePasswordView.passwordTextField.tag];
    }
    self.createAccountButton.backgroundColor = shoulBeCreateAccountButtonGray ? UIColor.mnz_grayEEEEEE : UIColor.mnz_redFF4D52;
    
    [self hideKeyboard];
}

- (IBAction)termOfServiceTouchUpInside:(UIButton *)sender {
    [Helper presentSafariViewControllerWithURL:[NSURL URLWithString:@"https://mega.nz/ios_terms.html"]];
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
                    self.emailIconImageView.tintColor = UIColor.mnz_redD90007;
                    [self.emailTextField becomeFirstResponder];
                    self.createAccountButton.enabled = YES;
                }
            }];
            createAccountRequestDelegate.resumeCreateAccount = NO;
            [[MEGASdkManager sharedMEGASdk] createAccountWithEmail:self.emailTextField.text password:self.passwordView.passwordTextField.text firstname:self.nameTextField.text lastname:self.lastNameTextField.text delegate:createAccountRequestDelegate];
            self.createAccountButton.enabled = NO;
        }
    }
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    self.activeTextField = textField;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    self.activeTextField = nil;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSString *text = [textField.text stringByReplacingCharactersInRange:range withString:string];
    BOOL shoulBeCreateAccountButtonGray = NO;
    if ([text isEqualToString:@""] || (!self.emailTextField.text.mnz_isValidEmail) || ([[MEGASdkManager sharedMEGASdk] passwordStrength:self.passwordView.passwordTextField.text] == PasswordStrengthVeryWeak) || !self.termsCheckboxButton.isSelected) {
        shoulBeCreateAccountButtonGray = YES;
    } else {
        shoulBeCreateAccountButtonGray = [self isEmptyAnyTextFieldForTag:textField.tag];
    }
    
    self.createAccountButton.backgroundColor = shoulBeCreateAccountButtonGray ? UIColor.mnz_grayEEEEEE : UIColor.mnz_redFF4D52;
    
    if (textField.tag == 0 || textField.tag == 1) {
        self.nameIconImageView.tintColor = UIColor.mnz_gray777777;
    } else if (textField.tag == 2) {
        self.emailIconImageView.image = [UIImage imageNamed:@"email"];
    } else if (textField.tag == 3) {
        if (text.length == 0) {
            self.passwordStrengthIndicatorView.customView.hidden = YES;
            self.passwordStrengthIndicatorViewHeightLayoutConstraint.constant = 0;
        } else {
            self.passwordStrengthIndicatorViewHeightLayoutConstraint.constant = 112.0f;
            self.passwordStrengthIndicatorView.customView.hidden = NO;
            
            [self.scrollView scrollRectToVisible:self.passwordStrengthIndicatorView.frame animated:YES];
            
            [self.passwordStrengthIndicatorView updateViewWithPasswordStrength:[[MEGASdkManager sharedMEGASdk] passwordStrength:text]];
        }
        [self hidePasswordErrorView:self.passwordView constraint:self.passwordViewHeightConstraint];
        [self hidePasswordErrorView:self.retypePasswordView constraint:self.retypePasswordViewHeightConstraint];
    } else if (textField.tag == 4) {
        [self hidePasswordErrorView:self.passwordView constraint:self.passwordViewHeightConstraint];
        [self hidePasswordErrorView:self.retypePasswordView constraint:self.retypePasswordViewHeightConstraint];
    }
    
    return YES;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField {
    
    if (textField.tag == 0 || textField.tag == 1) {
        self.nameIconImageView.tintColor = UIColor.mnz_gray777777;
    } else if (textField.tag == 2) {
        self.emailIconImageView.tintColor = UIColor.mnz_gray777777;
    } else if (textField.tag == 3) {
        self.passwordStrengthIndicatorView.customView.hidden = YES;
        self.passwordStrengthIndicatorViewHeightLayoutConstraint.constant = 0;
        [self hidePasswordErrorView:self.passwordView constraint:self.passwordViewHeightConstraint];
        [self hidePasswordErrorView:self.retypePasswordView constraint:self.retypePasswordViewHeightConstraint];
    } else if (textField.tag == 4) {
        [self hidePasswordErrorView:self.passwordView constraint:self.passwordViewHeightConstraint];
        [self hidePasswordErrorView:self.retypePasswordView constraint:self.retypePasswordViewHeightConstraint];
    }
    
    self.createAccountButton.backgroundColor = UIColor.mnz_grayEEEEEE;
    
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
            [self.passwordView.passwordTextField becomeFirstResponder];
            break;
            
        case 3:
            [self.retypePasswordView.passwordTextField becomeFirstResponder];
            break;
            
        case 4:
            [self.retypePasswordView.passwordTextField resignFirstResponder];
            break;
            
        default:
            break;
    }
    
    return YES;
}

@end
