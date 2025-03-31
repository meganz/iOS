#import "LoginViewController.h"

#import "Helper.h"
#import "InputView.h"
#import "MEGALoginRequestDelegate.h"
#import "MEGAReachabilityManager.h"
#import "MEGA-Swift.h"
#import "NSURL+MNZCategory.h"
#import "NSString+MNZCategory.h"

#import "TwoFactorAuthenticationViewController.h"
#import "PasswordView.h"

@import MEGAL10nObjc;

typedef NS_ENUM(NSInteger, TextFieldTag) {
    EmailTextFieldTag = 0,
    PasswordTextFieldTag
};

@interface LoginViewController () <UIGestureRecognizerDelegate, UITextFieldDelegate, MEGARequestDelegate>

@property (weak, nonatomic) IBOutlet UIBarButtonItem *cancelBarButtonItem;

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

@property (weak, nonatomic) IBOutlet UIImageView *logoImageView;

@property (weak, nonatomic) IBOutlet InputView *emailInputView;
@property (weak, nonatomic) IBOutlet PasswordView *passwordView;

@property (weak, nonatomic) IBOutlet UIButton *loginButton;

@property (weak, nonatomic) IBOutlet UIButton *forgotPasswordButton;

@property (strong, nonatomic) UITapGestureRecognizer *tapGesture;
@property (weak, nonatomic) IBOutlet UILabel *createAccountLabel;

@end

@implementation LoginViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self updateAppearance];
    
    self.tapGesture = [UITapGestureRecognizer.alloc initWithTarget:self action:@selector(hideKeyboard)];
    self.tapGesture.cancelsTouchesInView = NO;
    self.tapGesture.delegate = self;
    [self.scrollView addGestureRecognizer:self.tapGesture];
    
    [self.createAccountLabel addGestureRecognizer:[UITapGestureRecognizer.alloc initWithTarget:self action:@selector(createAccountDidTap)]];
    
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(logoTappedFiveTimes:)];
    tapGestureRecognizer.numberOfTapsRequired = 5;
    UILongPressGestureRecognizer *longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(logoPressedFiveSeconds:)];
    longPressGestureRecognizer.minimumPressDuration = 5.0f;
    self.logoImageView.gestureRecognizers = @[tapGestureRecognizer, longPressGestureRecognizer];
    
    self.cancelBarButtonItem.title = LocalizedString(@"cancel", @"Button title to cancel something");
    
    self.emailInputView.inputTextField.returnKeyType = UIReturnKeyNext;
    self.emailInputView.inputTextField.delegate = self;
    self.emailInputView.inputTextField.tag = EmailTextFieldTag;
    self.emailInputView.inputTextField.keyboardType = UIKeyboardTypeEmailAddress;
    self.emailInputView.inputTextField.textContentType = UITextContentTypeUsername;
    
    self.passwordView.passwordTextField.delegate = self;
    self.passwordView.passwordTextField.tag = PasswordTextFieldTag;
    self.passwordView.passwordTextField.textContentType = UITextContentTypePassword;
    
    [self.loginButton setTitle:LocalizedString(@"login", @"Login") forState:UIControlStateNormal];

    [self.forgotPasswordButton setTitle:LocalizedString(@"forgotPassword", @"An option to reset the password.") forState:UIControlStateNormal];
    
    [self registerForKeyboardNotifications];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.navigationItem setTitle:LocalizedString(@"login", @"")];
    
    if (self.emailString) {
        self.emailInputView.inputTextField.text = self.emailString;
        self.emailString = nil;
        
        [self.passwordView.passwordTextField becomeFirstResponder];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    
    if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
        [AppearanceManager setupAppearance:self.traitCollection];
        
        [self updateAppearance];
    }
    
    if (self.traitCollection.preferredContentSizeCategory != previousTraitCollection.preferredContentSizeCategory) {
        [self setCreateAccountAttributedText];
    }
    
    [self updateLoginButtonTopConstraint];
}

#pragma mark - IBActions

- (IBAction)tapLogin:(id)sender {
    if ([MEGAChatSdk.shared initState] != MEGAChatInitWaitingNewSession) {
        MEGAChatInit chatInit = [MEGAChatSdk.shared initKarereWithSid:nil];
        if (chatInit != MEGAChatInitWaitingNewSession) {
            MEGALogError(@"Init Karere without sesion must return waiting for a new sesion");
            [MEGAChatSdk.shared logout];
        }
    }
    
    [self requestStopAudioPlayerSession];
    
    [self.emailInputView.inputTextField resignFirstResponder];
    [self.passwordView.passwordTextField resignFirstResponder];
    
    if ([self validateForm]) {
        if ([MEGAReachabilityManager isReachableHUDIfNot]) {
            MEGALoginRequestDelegate *loginRequestDelegate = [[MEGALoginRequestDelegate alloc] init];
            loginRequestDelegate.errorCompletion = ^(MEGAError *error) {
                if (error.type == MEGAErrorTypeApiEMFARequired) {
                    TwoFactorAuthenticationViewController *twoFactorAuthenticationVC = [[UIStoryboard storyboardWithName:@"TwoFactorAuthentication" bundle:nil] instantiateViewControllerWithIdentifier:@"TwoFactorAuthenticationViewControllerID"];
                    twoFactorAuthenticationVC.twoFAMode = TwoFactorAuthenticationLogin;
                    twoFactorAuthenticationVC.email = self.emailInputView.inputTextField.text;
                    twoFactorAuthenticationVC.password = self.passwordView.passwordTextField.text;
                    
                    [self.navigationController pushViewController:twoFactorAuthenticationVC animated:YES];
                }
            };
            [MEGASdk.shared loginWithEmail:self.emailInputView.inputTextField.text password:self.passwordView.passwordTextField.text delegate:loginRequestDelegate];
        }
    }
}

- (IBAction)forgotPasswordTouchUpInside:(UIButton *)sender {
    [[self recoveryPasswordURL:self.emailInputView.inputTextField.text] mnz_presentSafariViewController];
}

- (IBAction)cancel:(UIBarButtonItem *)sender {
    if (MEGALinkManager.linkURL &&
        MEGALinkManager.urlType == URLTypePublicChatLink) {
        [MEGALinkManager resetLinkAndURLType];
    }
    
    [self.view endEditing:YES];
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Private

- (void)logoTappedFiveTimes:(UITapGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateEnded) {
        [Helper enableOrDisableLog];
    }
}

- (void)logoPressedFiveSeconds:(UITapGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateBegan) {
        [Helper changeApiURL];
    }
}

- (BOOL)validateForm {
    BOOL valid = YES;
    if (![self validateEmail]) {
        [self.emailInputView.inputTextField becomeFirstResponder];
        
        valid = NO;
    }
    
    if (![self validatePassword]) {
        if (valid) {
            [self.passwordView.passwordTextField becomeFirstResponder];
        }
        
        valid = NO;
    }
    
    return valid;
}

- (BOOL)validateEmail {
    self.emailInputView.inputTextField.text = self.emailInputView.inputTextField.text.mnz_removeWhitespacesAndNewlinesFromBothEnds;
    BOOL validEmail = self.emailInputView.inputTextField.text.mnz_isValidEmail;
    if (validEmail) {
        [self.emailInputView setErrorState:NO withText:LocalizedString(@"emailPlaceholder", @"Hint text to suggest that the user has to write his email")];
    } else {
        [self.emailInputView setErrorState:YES withText:LocalizedString(@"emailInvalidFormat", @"Enter a valid email")];
    }
    
    return validEmail;
}

- (BOOL)validatePassword {
    BOOL validPassword = !self.passwordView.passwordTextField.text.mnz_isEmpty;
    
    if (validPassword) {
        [self.passwordView setErrorState:NO];
    } else {
        [self.passwordView setErrorState:YES withText:LocalizedString(@"passwordInvalidFormat", @"Enter a valid password")];
    }

    return validPassword;
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
    
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, keyboardSize.height, 0.0);
    self.scrollView.contentInset = contentInsets;
    self.scrollView.scrollIndicatorInsets = contentInsets;
    
    CGRect viewFrame = self.view.frame;
    viewFrame.size.height -= keyboardSize.height;
    CGRect activeTextFieldFrame = self.emailInputView.inputTextField.isFirstResponder ? self.emailInputView.frame : self.passwordView.frame;
    if (!CGRectContainsPoint(viewFrame, activeTextFieldFrame.origin)) {
        [self.scrollView scrollRectToVisible:activeTextFieldFrame animated:YES];
    }
}

- (void)keyboardWillBeHidden:(NSNotification *)aNotification {
    self.scrollView.contentInset = UIEdgeInsetsZero;
    self.scrollView.scrollIndicatorInsets = UIEdgeInsetsZero;
}

- (void)hideKeyboard {
    [self.view endEditing:YES];
}

- (void)updateAppearance {
    [AppearanceManager forceNavigationBarUpdate:self.navigationController.navigationBar];

    self.view.backgroundColor = [UIColor pageBackgroundColor];
    
    self.emailInputView.backgroundColor = [UIColor mnz_tertiaryBackground:self.traitCollection];
    [self.emailInputView updateAppearance];
    self.passwordView.backgroundColor = [UIColor mnz_tertiaryBackground:self.traitCollection];
    [self.passwordView updateAppearance];
    
    [self.forgotPasswordButton setTitleColor: [self forgotPasswordTintColor] forState:UIControlStateNormal];
    
    [self.loginButton mnz_setupPrimary];
        
    [self setCreateAccountAttributedText];
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if ((touch.view == self.passwordView.toggleSecureButton) && (gestureRecognizer == self.tapGesture)) {
        return NO;
    }
    
    return YES;
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    if (textField.tag == PasswordTextFieldTag) {
        self.passwordView.toggleSecureButton.hidden = NO;
    }
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    switch (textField.tag) {
        case EmailTextFieldTag:
            [self validateEmail];
            
            break;
            
        case PasswordTextFieldTag:
            self.passwordView.passwordTextField.secureTextEntry = YES;
            [self.passwordView configureSecureTextEntry];
            [self validatePassword];
            
            break;
            
        default:
            break;
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    switch (textField.tag) {
        case EmailTextFieldTag:
            [self.emailInputView setErrorState:NO withText:LocalizedString(@"emailPlaceholder", @"Hint text to suggest that the user has to write his email")];
            break;
            
        case PasswordTextFieldTag:
            [self.passwordView setErrorState:NO];
            break;
            
        default:
            break;
    }
    
    return YES;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField {
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    switch (textField.tag) {
        case EmailTextFieldTag:
            [self.passwordView.passwordTextField becomeFirstResponder];
            break;
            
        case PasswordTextFieldTag:
            [self.passwordView.passwordTextField resignFirstResponder];
            [self tapLogin:self.loginButton];            
            break;
            
        default:
            break;
    }
    
    return YES;
}

#pragma mark - Create Account
- (void)setCreateAccountAttributedText {
    NSString *newToMegaString = LocalizedString(@"account.login.newToMega", @"New to MEGA?");
    NSString *createAccountString = LocalizedString(@"createAccount", @"Create Account");
    
    UIFont *font = [UIFont mnz_preferredFontWithStyle:UIFontTextStyleCaption1 weight:UIFontWeightRegular];
    NSAttributedString *newToMegaAttributedString = [NSAttributedString.alloc
                                                     initWithString:newToMegaString
                                                     attributes:@{NSFontAttributeName : font,
                                                                  NSForegroundColorAttributeName:[self loginLabelrimaryTextColor]}];
    NSAttributedString *createAccountAttributedString = [NSAttributedString.alloc
                                                         initWithString:createAccountString
                                                         attributes:@{NSFontAttributeName : font,
                                                                      NSForegroundColorAttributeName:[self loginLabelLinkTextColor]}];
    
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] init];
    [attributedString appendAttributedString:newToMegaAttributedString];
    [attributedString appendAttributedString:[[NSAttributedString alloc] initWithString:@" "]];
    [attributedString appendAttributedString:createAccountAttributedString];
    [self.createAccountLabel setAttributedText:attributedString];
}

- (void)createAccountDidTap {
    [self dismissViewControllerAnimated:true completion:^{
        if ([UIApplication.mnz_visibleViewController isKindOfClass:OnboardingViewController.class]) {
            OnboardingViewController *onboardingVC = (OnboardingViewController *)[UIApplication mnz_visibleViewController];
            [onboardingVC presentCreateAccountViewController];
        }
    }];
}

@end
