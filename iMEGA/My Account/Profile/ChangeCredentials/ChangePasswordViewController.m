#import "ChangePasswordViewController.h"

#import "MEGA-Swift.h"
#import "MEGAReachabilityManager.h"
#import "NSString+MNZCategory.h"
#import "SVProgressHUD.h"
#import "UIApplication+MNZCategory.h"
#import "UITextField+MNZCategory.h"

#import "AwaitingEmailConfirmationView.h"
#import "Helper.h"
#import "InputView.h"
#import "TwoFactorAuthenticationViewController.h"
@import MEGAAppSDKRepo;
@import MEGAL10nObjc;

typedef NS_ENUM(NSUInteger, TextFieldTag) {
    CurrentEmailTextFieldTag = 0,
    NewEmailTextFieldTag,
    CurrentPasswordTextFieldTag,
    NewPasswordTextFieldTag,
    ConfirmPasswordTextFieldTag
};

@interface ChangePasswordViewController () <UITextFieldDelegate, UIGestureRecognizerDelegate, MEGARequestDelegate, MEGAGlobalDelegate, UIAdaptivePresentationControllerDelegate>

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

@property (weak, nonatomic) IBOutlet InputView *currentEmailInputView;
@property (weak, nonatomic) IBOutlet InputView *theNewEmailInputView;

@property (weak, nonatomic) IBOutlet PasswordView *currentPasswordView;
@property (weak, nonatomic) IBOutlet PasswordView *confirmPasswordView;

@property (weak, nonatomic) InputView *activeInputView;
@property (weak, nonatomic) PasswordView *activePasswordView;

@property (strong, nonatomic) UIBarButtonItem *confirmButton;

@property (strong, nonatomic) UITapGestureRecognizer *tapGesture;

@end

@implementation ChangePasswordViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.confirmButton = [[UIBarButtonItem alloc] initWithTitle:LocalizedString(@"save", @"save password or email associated to an account.") style:UIBarButtonItemStylePlain target:self action:@selector(confirmButtonTouchUpInside:)];
    self.navigationItem.rightBarButtonItem = self.confirmButton;
    
    switch (self.changeType) {
        case ChangeTypePassword:
        case ChangeTypePasswordFromLogout:
            self.navigationItem.title = LocalizedString(@"changePasswordLabel", @"Section title where you can change your MEGA's password");
            
            self.theNewPasswordView.passwordTextField.returnKeyType = UIReturnKeyNext;
            self.theNewPasswordView.passwordTextField.delegate = self;
            self.theNewPasswordView.passwordTextField.tag = NewPasswordTextFieldTag;
            
            self.confirmPasswordView.passwordTextField.delegate = self;
            self.confirmPasswordView.passwordTextField.tag = ConfirmPasswordTextFieldTag;
            self.theNewPasswordView.passwordTextField.textContentType = UITextContentTypePassword;
            self.confirmPasswordView.passwordTextField.textContentType = UITextContentTypeNewPassword;
            [self.theNewPasswordView.passwordTextField becomeFirstResponder];
            
            break;
            
        case ChangeTypeEmail: {
            self.navigationItem.title = LocalizedString(@"Change Email", @"The title of the alert dialog to change the email associated to an account.");
            self.theNewPasswordView.hidden = self.confirmPasswordView.hidden = YES;
            self.currentEmailInputView.hidden = self.theNewEmailInputView.hidden = NO;
            
            self.currentEmailInputView.inputTextField.text = MEGASdk.currentUserEmail;
            self.currentEmailInputView.inputTextField.userInteractionEnabled = NO;
            
            self.theNewEmailInputView.inputTextField.returnKeyType = UIReturnKeyNext;
            self.theNewEmailInputView.inputTextField.delegate = self;
            self.theNewEmailInputView.inputTextField.tag = NewEmailTextFieldTag;
            self.theNewEmailInputView.inputTextField.keyboardType = UIKeyboardTypeEmailAddress;
            self.theNewEmailInputView.inputTextField.textContentType = UITextContentTypeUsername;
            
            [self.theNewEmailInputView.inputTextField becomeFirstResponder];
            
            break;
        }
            
        case ChangeTypeResetPassword:
        case ChangeTypeParkAccount:
            self.navigationItem.title = (self.changeType == ChangeTypeResetPassword) ? LocalizedString(@"passwordReset", @"Headline of the password reset recovery procedure") : LocalizedString(@"parkAccount", @"Headline for parking an account (basically restarting from scratch)");
            self.currentEmailInputView.hidden = NO;
            
            self.currentEmailInputView.inputTextField.text = self.email;
            self.currentEmailInputView.inputTextField.userInteractionEnabled = NO;
            self.currentEmailInputView.inputTextField.textContentType = UITextContentTypeUsername;
            
            self.theNewPasswordView.passwordTextField.returnKeyType = UIReturnKeyNext;
            self.theNewPasswordView.passwordTextField.delegate = self;
            self.theNewPasswordView.passwordTextField.tag = NewPasswordTextFieldTag;
            
            self.confirmPasswordView.passwordTextField.delegate = self;
            self.confirmPasswordView.passwordTextField.tag = ConfirmPasswordTextFieldTag;
            self.theNewPasswordView.passwordTextField.textContentType = UITextContentTypeNewPassword;
            self.confirmPasswordView.passwordTextField.textContentType = UITextContentTypePassword;

            [self.theNewPasswordView.passwordTextField becomeFirstResponder];
            
            break;
    }
    
    if (self.changeType == ChangeTypePassword || self.changeType == ChangeTypeResetPassword || self.changeType == ChangeTypeParkAccount) {
        [self setupPasswordTextFieldTarget];
    }
    
    self.tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard)];
    self.tapGesture.cancelsTouchesInView = NO;
    self.tapGesture.delegate = self;
    [self.view addGestureRecognizer:self.tapGesture];
    
    [self registerForKeyboardNotifications];
    
    [self setupColors];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.navigationController.presentationController.delegate = self;
    
    [MEGASdk.shared addMEGAGlobalDelegate:self];
    [[MEGAReachabilityManager sharedManager] retryPendingConnections];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(emailHasChanged) name:MEGAEmailHasChangedNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [MEGASdk.shared removeMEGAGlobalDelegate:self];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

#pragma mark - Private

- (void)setupColors {
    self.view.backgroundColor = [UIColor pageBackgroundColor];
    
    switch (self.changeType) {
        case ChangeTypePassword:
        case ChangeTypePasswordFromLogout:
            self.theNewPasswordView.backgroundColor = self.confirmPasswordView.backgroundColor = [UIColor mnz_tertiaryBackground:self.traitCollection];
            [self.theNewPasswordView updateAppearance];
            [self.confirmPasswordView updateAppearance];
            break;
            
        case ChangeTypeEmail:
            self.currentEmailInputView.backgroundColor = self.theNewEmailInputView.backgroundColor = [UIColor mnz_tertiaryBackground:self.traitCollection];
            [self.currentEmailInputView updateAppearance];
            [self.theNewEmailInputView updateAppearance];
            break;
            
        case ChangeTypeResetPassword:
        case ChangeTypeParkAccount:
            self.currentEmailInputView.backgroundColor = self.theNewPasswordView.backgroundColor = self.confirmPasswordView.backgroundColor = [UIColor mnz_tertiaryBackground:self.traitCollection];
            [self.currentEmailInputView updateAppearance];
            [self.theNewPasswordView updateAppearance];
            [self.confirmPasswordView updateAppearance];
            break;
    }
}

- (BOOL)validateForm {
    BOOL valid = YES;
    switch (self.changeType) {
        case ChangeTypePassword:
        case ChangeTypeResetPassword:
        case ChangeTypeParkAccount:
        case ChangeTypePasswordFromLogout:
            if (![self validateNewPassword]) {
                [self.theNewPasswordView.passwordTextField becomeFirstResponder];
                
                valid = NO;
            }
            
            if (![self validateConfirmPassword]) {
                if (valid) {
                    [self.confirmPasswordView.passwordTextField becomeFirstResponder];
                }
                
                valid = NO;
            }
            
            break;
            
        case ChangeTypeEmail:
            if (![self validateEmail]) {
                [self.theNewEmailInputView.inputTextField becomeFirstResponder];
                
                valid = NO;
            }
            
            break;
    }
    
    return valid;
}

- (BOOL)validateNewPassword {
    if (self.theNewPasswordView.passwordTextField.text.mnz_isEmpty) {
        [self.theNewPasswordView setErrorState:YES withText:LocalizedString(@"passwordInvalidFormat", @"Message shown when the user enters a wrong password")];
        return NO;
    } else if ([MEGASdk.shared checkPassword:self.theNewPasswordView.passwordTextField.text]) {
        [self.theNewPasswordView setErrorState:YES withText:LocalizedString(@"account.changePassword.error.currentPassword", @"Account, Change Password view. Error shown when you type your current password.")];
        return NO;
    } else if ([MEGASdk.shared passwordStrength:self.theNewPasswordView.passwordTextField.text] == PasswordStrengthVeryWeak) {
        [self.theNewPasswordView setErrorState:YES withText:LocalizedString(@"pleaseStrengthenYourPassword", @"")];
        return NO;
    } else {
        [self.theNewPasswordView setErrorState:NO withText:LocalizedString(@"passwordPlaceholder", @"Hint text to suggest that the user has to write his password")];
        return YES;
    }
}

- (BOOL)validateConfirmPassword {
    if ([self.confirmPasswordView.passwordTextField.text isEqualToString:self.theNewPasswordView.passwordTextField.text]) {
        [self.confirmPasswordView setErrorState:NO withText:LocalizedString(@"confirmPassword", @"Hint text where the user have to re-write the new password to confirm it")];
        return YES;
    } else {
        [self.confirmPasswordView setErrorState:YES withText:LocalizedString(@"passwordsDoNotMatch", @"Error text shown when you have not written the same password")];
        return NO;
    }
}

- (BOOL)validateEmail {
    self.theNewEmailInputView.inputTextField.text = self.theNewEmailInputView.inputTextField.text.mnz_removeWhitespacesAndNewlinesFromBothEnds;
    if (!self.theNewEmailInputView.inputTextField.text.mnz_isValidEmail) {
        [self.theNewEmailInputView setErrorState:YES withText:LocalizedString(@"emailInvalidFormat", @"Message shown when the user writes an invalid format in the email field")];
        return NO;
    } else if ([self.theNewEmailInputView.inputTextField.text isEqualToString:self.currentEmailInputView.inputTextField.text]) {
        [self.theNewEmailInputView setErrorState:YES withText:LocalizedString(@"oldAndNewEmailMatch", @"Error message shown when the users tryes to change his/her email and writes the current one as the new one.")];
        return NO;
    } else {
        [self.theNewEmailInputView setErrorState:NO withText:LocalizedString(@"newEmail", @"Placeholder text to explain that the new email should be written on this text field.")];
        return YES;
    }
}

- (void)emailHasChanged {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MEGAEmailHasChangedNotification object:nil];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)processStarted {
    [self.currentEmailInputView.inputTextField resignFirstResponder];
    [self.theNewEmailInputView.inputTextField resignFirstResponder];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"processStarted" object:nil];
    
    AwaitingEmailConfirmationView *awaitingEmailConfirmationView = [[[NSBundle mainBundle] loadNibNamed:@"AwaitingEmailConfirmationView" owner:self options: nil] firstObject];
    awaitingEmailConfirmationView.titleLabel.text = LocalizedString(@"awaitingEmailConfirmation", @"Title shown just after doing some action that requires confirming the action by an email");
    awaitingEmailConfirmationView.descriptionLabel.text = LocalizedString(@"emailIsChanging_description", @"Text shown just after tap to change an email account to remenber the user what to do to complete the change email proccess");
    awaitingEmailConfirmationView.frame = self.view.bounds;
    self.view = awaitingEmailConfirmationView;
    
    self.confirmButton.enabled = NO;
}

- (void)hideKeyboard {
    [self.view endEditing:YES];
}

- (void)registerForKeyboardNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWasShown:) name:UIKeyboardDidShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillBeHidden:) name:UIKeyboardWillHideNotification object:nil];
    
}

- (void)keyboardWasShown:(NSNotification*)aNotification {
    NSDictionary *info = aNotification.userInfo;
    CGSize keyboardSize = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
    
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, keyboardSize.height, 0.0);
    self.scrollView.contentInset = contentInsets;
    self.scrollView.scrollIndicatorInsets = contentInsets;
    
    CGRect viewFrame = self.view.frame;
    viewFrame.size.height -= keyboardSize.height;
    CGRect activeTextFieldFrame = self.activeInputView ? self.activeInputView.frame : self.activePasswordView.frame;
    if (!CGRectContainsPoint(viewFrame, activeTextFieldFrame.origin)) {
        [self.scrollView scrollRectToVisible:activeTextFieldFrame animated:YES];
    }
}

- (void)keyboardWillBeHidden:(NSNotification *)aNotification {
    self.scrollView.contentInset = UIEdgeInsetsZero;
    self.scrollView.scrollIndicatorInsets = UIEdgeInsetsZero;
}

- (void)alertTextFieldDidChange:(UITextField *)textField {
    UIAlertController *alertController = (UIAlertController *)UIApplication.mnz_visibleViewController;
    if ([alertController isKindOfClass:UIAlertController.class]) {
        UIAlertAction *rightButtonAction = alertController.actions.lastObject;
        rightButtonAction.enabled = !textField.text.mnz_isEmpty;
    }
}

#pragma mark - IBActions

- (IBAction)cancelAction:(UIBarButtonItem *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)confirmButtonTouchUpInside:(UIButton *)sender {
    if ([MEGAReachabilityManager isReachableHUDIfNot]) {
        if ([self validateForm]) {
            switch (self.changeType) {
                case ChangeTypePassword:
                case ChangeTypePasswordFromLogout:
                    if (self.isTwoFactorAuthenticationEnabled) {
                        TwoFactorAuthenticationViewController *twoFactorAuthenticationVC = [[UIStoryboard storyboardWithName:@"TwoFactorAuthentication" bundle:nil] instantiateViewControllerWithIdentifier:@"TwoFactorAuthenticationViewControllerID"];
                        twoFactorAuthenticationVC.twoFAMode = self.changeType == ChangeTypePassword ? TwoFactorAuthenticationChangePassword : TwoFactorAuthenticationChangePasswordFromLogout;
                        twoFactorAuthenticationVC.newerPassword = self.theNewPasswordView.passwordTextField.text;
                        
                        [self.navigationController pushViewController:twoFactorAuthenticationVC animated:YES];
                    } else {
                        [MEGASdk.shared changePassword:nil newPassword:self.theNewPasswordView.passwordTextField.text delegate:self];
                    }
                    
                    break;
                    
                case ChangeTypeEmail:
                    if (self.isTwoFactorAuthenticationEnabled) {
                        TwoFactorAuthenticationViewController *twoFactorAuthenticationVC = [[UIStoryboard storyboardWithName:@"TwoFactorAuthentication" bundle:nil] instantiateViewControllerWithIdentifier:@"TwoFactorAuthenticationViewControllerID"];
                        twoFactorAuthenticationVC.twoFAMode = TwoFactorAuthenticationChangeEmail;
                        twoFactorAuthenticationVC.email = self.theNewEmailInputView.inputTextField.text;
                        
                        [self.navigationController pushViewController:twoFactorAuthenticationVC animated:YES];
                        
                        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(processStarted) name:@"processStarted" object:nil];
                    } else {
                        [MEGASdk.shared changeEmail:self.theNewEmailInputView.inputTextField.text delegate:self];
                    }
                    
                    break;
                    
                case ChangeTypeResetPassword:
                    [MEGASdk.shared confirmResetPasswordWithLink:self.link newPassword:self.theNewPasswordView.passwordTextField.text masterKey:self.masterKey delegate:self];
                    
                    break;
                    
                case ChangeTypeParkAccount: {
                    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:LocalizedString(@"startNewAccount", @"Headline of the password reset recovery procedure")  message:LocalizedString(@"startingFreshAccount", @"Label text of a checkbox to ensure that the user is aware that the data of his current account will be lost when proceeding unless they remember their password or have their master encryption key (now renamed 'Recovery Key')") preferredStyle:UIAlertControllerStyleAlert];
                    [alertController addAction:[UIAlertAction actionWithTitle:LocalizedString(@"cancel", @"") style:UIAlertActionStyleCancel handler:nil]];
                    [alertController addAction:[UIAlertAction actionWithTitle:LocalizedString(@"ok", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                        [MEGASdk.shared confirmResetPasswordWithLink:self.link newPassword:self.theNewPasswordView.passwordTextField.text masterKey:nil delegate:self];
                    }]];
                    [self presentViewController:alertController animated:YES completion:nil];
                    
                    break;
                }
            }

        }
    }
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    switch (textField.tag) {
        case NewEmailTextFieldTag:
            self.activeInputView = self.theNewEmailInputView;
            break;
            
        case CurrentPasswordTextFieldTag:
            self.activePasswordView = self.currentPasswordView;
            self.currentPasswordView.toggleSecureButton.hidden = NO;
            break;
            
        case NewPasswordTextFieldTag:
            self.activePasswordView = self.theNewPasswordView;
            self.theNewPasswordView.toggleSecureButton.hidden = NO;
            break;
            
        case ConfirmPasswordTextFieldTag:
            self.activePasswordView = self.confirmPasswordView;
            self.confirmPasswordView.toggleSecureButton.hidden = NO;
            break;
            
        default:
            break;
    }
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    self.activeInputView = nil;
    self.activePasswordView = nil;
    
    switch (textField.tag) {
        case NewEmailTextFieldTag:
            [self validateEmail];
            break;
            
        case NewPasswordTextFieldTag:
            self.theNewPasswordView.passwordTextField.secureTextEntry = YES;
            [self.theNewPasswordView configureSecureTextEntry];
            [self validateNewPassword];
            break;
            
        case ConfirmPasswordTextFieldTag:
            self.confirmPasswordView.passwordTextField.secureTextEntry = YES;
            [self.confirmPasswordView configureSecureTextEntry];
            [self validateNewPassword];
            [self validateConfirmPassword];
            break;
            
        default:
            break;
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    switch (textField.tag) {
        case NewEmailTextFieldTag:
            [self.theNewEmailInputView setErrorState:NO withText:LocalizedString(@"newEmail", @"Placeholder text to explain that the new email should be written on this text field.")];
            
            break;
            
        case NewPasswordTextFieldTag:
            [self.theNewPasswordView setErrorState:NO withText:LocalizedString(@"passwordPlaceholder", @"Hint text to suggest that the user has to write his password")];
            break;
            
        case ConfirmPasswordTextFieldTag:
            [self.confirmPasswordView setErrorState:NO withText:LocalizedString(@"confirmPassword", @"Hint text where the user have to re-write the new password to confirm it")];
            break;
            
        default:
            break;
    }
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    switch (textField.tag) {
        case CurrentEmailTextFieldTag:
            [self.theNewEmailInputView.inputTextField becomeFirstResponder];
            break;
            
        case NewEmailTextFieldTag:
            [self.theNewEmailInputView.inputTextField becomeFirstResponder];
            break;
            
        case CurrentPasswordTextFieldTag:
            [self.theNewPasswordView.passwordTextField becomeFirstResponder];
            break;
            
        case NewPasswordTextFieldTag:
            [self.confirmPasswordView.passwordTextField becomeFirstResponder];
            break;
            
        case ConfirmPasswordTextFieldTag:
            [self.confirmPasswordView.passwordTextField resignFirstResponder];
            break;
            
        default:
            break;
    }
    
    return YES;
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if ((touch.view == self.currentPasswordView.toggleSecureButton || touch.view == self.theNewPasswordView.toggleSecureButton || touch.view == self.confirmPasswordView.toggleSecureButton) && (gestureRecognizer == self.tapGesture)) {
        return NO;
    }
    return YES;
}

#pragma mark - UIAdaptivePresentationControllerDelegate

- (BOOL)presentationControllerShouldDismiss:(UIPresentationController *)presentationController {
    switch (self.changeType) {
        case ChangeTypePassword:
            return self.theNewPasswordView.passwordTextField.text.length == 0;
            
        case ChangeTypeEmail:
            return self.theNewEmailInputView.inputTextField.text.length == 0;

        default:
            return YES;
    }
}

- (void)presentationControllerDidAttemptToDismiss:(UIPresentationController *)presentationController {
    UIBarButtonItem *barButton = self.navigationItem.leftBarButtonItem;
    if (barButton == nil) {
        return;
    }
    
    UIAlertController *confirmDismissAlert = [UIAlertController.alloc discardChangesFromBarButton:barButton withConfirmAction:^{
        [self dismissViewControllerAnimated:YES completion:nil];
    }];
    [self presentViewController:confirmDismissAlert animated:YES completion:nil];
}

#pragma mark - MEGAGlobalDelegate

- (void)onUsersUpdate:(MEGASdk *)api userList:(MEGAUserList *)userList {
    NSInteger count = userList.size;
    for (NSInteger i = 0 ; i < count; i++) {
        MEGAUser *user = [userList userAtIndex:i];
        if (user.handle == MEGASdk.currentUserHandle.unsignedLongLongValue && user.changes == MEGAUserChangeTypeEmail) {
            NSString *emailChangedString = [LocalizedString(@"congratulationsNewEmailAddress", @"The [X] will be replaced with the e-mail address.") stringByReplacingOccurrencesOfString:@"[X]" withString:user.email];
            [SVProgressHUD showSuccessWithStatus:emailChangedString];
            [self dismissViewControllerAnimated:YES completion:nil];
        }
    }
}

#pragma mark - MEGARequestDelegate

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    if (error.type) {
        
        switch (error.type) {
            case MEGAErrorTypeApiEArgs: {
                if (request.type == MEGARequestTypeChangePassword) {
                    [self.theNewPasswordView setErrorState:YES withText:LocalizedString(@"passwordInvalidFormat", @"Message shown when the user enters a wrong password")];
                    [self.theNewPasswordView.passwordTextField becomeFirstResponder];
                }
                break;
            }
                
            case MEGAErrorTypeApiEExist: {
                if (request.type == MEGARequestTypeGetChangeEmailLink) {
                    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:LocalizedString(@"emailAddressChangeAlreadyRequested", @"Error message shown when you try to change your account email to one that you already requested.")  message:nil preferredStyle:UIAlertControllerStyleAlert];
                    [alertController addAction:[UIAlertAction actionWithTitle:LocalizedString(@"ok", @"") style:UIAlertActionStyleCancel handler:nil]];
                    [self presentViewController:alertController animated:YES completion:nil];
                }
                break;
            }
                
            case MEGAErrorTypeApiEKey: {
                if (request.type == MEGARequestTypeConfirmRecoveryLink) {
                    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:LocalizedString(@"invalidRecoveryKey", @"An alert title where the user provided the incorrect Recovery Key.")  message:nil preferredStyle:UIAlertControllerStyleAlert];
                    [alertController addAction:[UIAlertAction actionWithTitle:LocalizedString(@"ok", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:LocalizedString(@"passwordReset", @"Headline of the password reset recovery procedure")  message:LocalizedString(@"pleaseEnterYourRecoveryKey", @"A message shown to explain that the user has to input (type or paste) their recovery key to continue with the reset password process.") preferredStyle:UIAlertControllerStyleAlert];
                        [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
                            textField.placeholder = LocalizedString(@"recoveryKey", @"Label for any 'Recovery Key' button, link, text, title, etc. Preserve uppercase - (String as short as possible). The Recovery Key is the new name for the account 'Master Key', and can unlock (recover) the account if the user forgets their password.");
                            [textField becomeFirstResponder];
                            [textField addTarget:self action:@selector(alertTextFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
                            textField.shouldReturnCompletion = ^BOOL(UITextField *textField) {
                                return !textField.text.mnz_isEmpty;
                            };
                        }];
                        [alertController addAction:[UIAlertAction actionWithTitle:LocalizedString(@"cancel", @"") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                                UITextField *textField = alertController.textFields.firstObject;
                                [textField resignFirstResponder];
                                [self dismissViewControllerAnimated:YES completion:nil];
                        }]];
                        [alertController addAction:[UIAlertAction actionWithTitle:LocalizedString(@"ok", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                            self.masterKey = alertController.textFields.firstObject.text;
                            [self.theNewEmailInputView.inputTextField becomeFirstResponder];
                        }]];
                        [self presentViewController:alertController animated:YES completion:nil];
                    }]];
                    [self presentViewController:alertController animated:YES completion:nil];
                    
                    self.theNewEmailInputView.inputTextField.text = @"";
                }
                break;
            }
                
            case MEGAErrorTypeApiEAccess:
                if (request.type == MEGARequestTypeGetChangeEmailLink) {
                    [self.theNewEmailInputView setErrorState:YES withText:LocalizedString(@"emailAlreadyInUse", @"Error shown when the user tries to change his mail to one that is already used")];
                    [self.theNewEmailInputView.inputTextField becomeFirstResponder];
                }
                break;
                
            default:
                break;
        }
        return;
    }
    
    switch (request.type) {
        case MEGARequestTypeChangePassword: {
            [SVProgressHUD showSuccessWithStatus:LocalizedString(@"passwordChanged", @"The label showed when your password has been changed")];
            
            if (self.changeType == ChangeTypePassword) {
                [self.navigationController dismissViewControllerAnimated:YES completion:nil];
            } else if (self.changeType == ChangeTypePasswordFromLogout) {
                [MEGASdk.shared logout];
            }
            
            break;
        }
            
        case MEGARequestTypeGetChangeEmailLink: {
            [self processStarted];
            break;
        }
            
        case MEGARequestTypeConfirmRecoveryLink: {
            if (self.changeType == ChangeTypePassword) {
                [SVProgressHUD showSuccessWithStatus:LocalizedString(@"passwordChanged", @"The label showed when your password has been changed")];
                [self dismissViewControllerAnimated:YES completion:nil];
            } else {
                [self.view endEditing:YES];
                
                NSString *title;
                void (^completion)(void);
                if (self.changeType == ChangeTypeResetPassword) {
                    if ([MEGASdk.shared isLoggedIn]) {
                        [[NSNotificationCenter defaultCenter] postNotificationName:@"passwordReset" object:nil];
                        title = LocalizedString(@"passwordChanged", @"The label showed when your password has been changed");
                        
                        completion = ^{
                            if (self.link) {
                                [self.navigationController dismissViewControllerAnimated:YES completion:nil];
                            } else {
                                [self.navigationController popToViewController:self.navigationController.viewControllers[2] animated:YES];
                            }
                        };
                    } else {
                        title = LocalizedString(@"yourPasswordHasBeenReset", @"");
                        
                        completion = ^{
                            [self.navigationController dismissViewControllerAnimated:YES completion:nil];
                        };
                    }
                } else if (self.changeType == ChangeTypeParkAccount) {
                    title = LocalizedString(@"yourAccounHasBeenParked", @"");
                    
                    completion = ^{
                        [self.navigationController dismissViewControllerAnimated:YES completion:nil];
                    };
                }
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:nil preferredStyle:UIAlertControllerStyleAlert];
                [alertController addAction:[UIAlertAction actionWithTitle:LocalizedString(@"ok", @"") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                    completion();
                }]];
                
                [UIApplication.mnz_presentingViewController presentViewController:alertController animated:YES completion:nil];
            }
            
            break;
        }
            
        default:
            break;
    }
}

@end
