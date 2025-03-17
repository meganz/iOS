#import "ConfirmAccountViewController.h"

#import "SAMKeychain.h"
#import "SVProgressHUD.h"

#import "Helper.h"
#import "MEGALinkManager.h"
#import "MEGALoginRequestDelegate.h"
#import "MEGAReachabilityManager.h"
#import "MEGA-Swift.h"
#import "NSString+MNZCategory.h"
#import "UIApplication+MNZCategory.h"

#import "InputView.h"
#import "PasswordView.h"

@import MEGAL10nObjc;

@interface ConfirmAccountViewController () <UITextFieldDelegate, MEGARequestDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *logoImageView;
@property (weak, nonatomic) IBOutlet UILabel *confirmTextLabel;
@property (weak, nonatomic) IBOutlet InputView *emailInputView;
@property (weak, nonatomic) IBOutlet PasswordView *passwordView;
@property (weak, nonatomic) IBOutlet UIButton *confirmAccountButton;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

@end

@implementation ConfirmAccountViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self updateAppearance];
    
    switch (self.urlType) {
        case URLTypeConfirmationLink:
            self.confirmTextLabel.text = LocalizedString(@"confirmText", @"Text shown on the confirm account view to remind the user what to do");
            [self.confirmAccountButton setTitle:LocalizedString(@"Confirm account", @"Label for any ‘Confirm account’ button, link, text, title, etc. - (String as short as possible).") forState:UIControlStateNormal];
            
            break;
        
        case URLTypeChangeEmailLink:
            self.confirmTextLabel.text = LocalizedString(@"verifyYourEmailAddress_description", @"Text shown on the confirm email view to remind the user what to do");
            [self.confirmAccountButton setTitle:LocalizedString(@"confirmEmail", @"Button text for the user to confirm their change of email address.") forState:UIControlStateNormal];
            
            break;
        
        case URLTypeCancelAccountLink: {
            NSString* message = LocalizedString(@"enterYourPasswordToConfirmThatYouWanToClose", @"Account closure, message shown when you click on the link in the email to confirm the closure of your account");

            MEGAAccountDetails *accountDetails = [MEGASdk.shared mnz_accountDetails];
            if (accountDetails &&
                 accountDetails.type != MEGAAccountTypeFree &&
                 (accountDetails.subscriptionMethodId == MEGAPaymentMethodECP ||
                  accountDetails.subscriptionMethodId == MEGAPaymentMethodStripe2)) {
                message = LocalizedString(@"account.delete.subscription.webClient", @"Account closure, message shown when you click on the link in the email to confirm the closure of your account");
            }
            
            self.confirmTextLabel.text = message;
            [self.confirmAccountButton setTitle:LocalizedString(@"cancelYourAccount", @"Account closure, password check dialog when user click on closure email.") forState:UIControlStateNormal];
            
            [self showSubscriptionDialogIfNeeded];
            break;
        }

        default:
            break;
    }
    
    [self.cancelButton setTitle:LocalizedString(@"cancel", @"") forState:UIControlStateNormal];
    
    self.emailInputView.inputTextField.text = self.emailString;
    self.emailInputView.inputTextField.enabled = NO;
    self.emailInputView.inputTextField.keyboardType = UIKeyboardTypeEmailAddress;
    self.emailInputView.inputTextField.textContentType = UITextContentTypeUsername;
    
    self.passwordView.passwordTextField.delegate = self;
    self.passwordView.passwordTextField.textContentType = UITextContentTypePassword;
    
    [self registerForKeyboardNotifications];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    
    if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
        [AppearanceManager setupAppearance:self.traitCollection];
        [AppearanceManager forceNavigationBarUpdate:self.navigationController.navigationBar traitCollection:self.traitCollection];
        
        [self updateAppearance];
    }
}

#pragma mark - IBActions

- (IBAction)confirmTouchUpInside:(UIButton *)sender {
    if ([MEGAReachabilityManager isReachableHUDIfNot]) {
        if ([self validateForm]) {
            [SVProgressHUD show];
            [self lockUI:YES];
            switch (self.urlType) {
                case URLTypeConfirmationLink:
                    [MEGASdk.shared confirmAccountWithLink:self.confirmationLinkString password:self.passwordView.passwordTextField.text delegate:self];
                    
                    break;
                    
                case URLTypeChangeEmailLink:
                    [MEGASdk.shared confirmChangeEmailWithLink:self.confirmationLinkString password:self.passwordView.passwordTextField.text delegate:self];
                    
                    break;
                    
                case URLTypeCancelAccountLink:
                    [MEGASdk.shared confirmCancelAccountWithLink:self.confirmationLinkString password:self.passwordView.passwordTextField.text delegate:self];
                    
                    break;
                    
                default:
                    break;
            }
        }
    }
}

- (IBAction)cancelTouchUpInside:(UIButton *)sender {
    [self.passwordView.passwordTextField resignFirstResponder];

    if (self.urlType == URLTypeConfirmationLink) {
        NSString *message = LocalizedString(@"areYouSureYouWantToAbortTheRegistration", @"Asking whether the user really wants to abort/stop the registration process or continue on.");
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:message preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:LocalizedString(@"cancel", @"") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            [MEGALinkManager resetLinkAndURLType];
        }]];
        [alertController addAction:[UIAlertAction actionWithTitle:LocalizedString(@"ok", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [MEGALinkManager resetLinkAndURLType];
            
            if ([SAMKeychain passwordForService:@"MEGA" account:@"sessionId"]) {
                [MEGASdk.shared logout];
                [Helper clearEphemeralSession];
            }
            
            [self dismissViewControllerAnimated:YES completion:nil];
        }]];
        [self presentViewController:alertController animated:YES completion:nil];
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

#pragma mark - Private

- (BOOL)validateForm {
    BOOL validPassword = !self.passwordView.passwordTextField.text.mnz_isEmpty;
    
    if (validPassword) {
        [self.passwordView setErrorState:NO];
    } else {
        [self.passwordView setErrorState:YES withText:LocalizedString(@"passwordInvalidFormat", @"Enter a valid password")];
    }
    
    return validPassword;
}

- (void)lockUI:(BOOL)boolValue {
    self.passwordView.passwordTextField.enabled = !boolValue;
    self.cancelButton.enabled = !boolValue;
}

- (void)updateAppearance {
    self.view.backgroundColor = [UIColor pageBackgroundColor];
    
    self.emailInputView.backgroundColor = [UIColor mnz_tertiaryBackground:self.traitCollection];
    [self.emailInputView updateAppearance];
    
    self.passwordView.backgroundColor = [UIColor mnz_tertiaryBackground:self.traitCollection];
    [self.passwordView updateAppearance];
    
    if (self.urlType == URLTypeCancelAccountLink) {
        [self.confirmAccountButton mnz_setupDelete];
    } else {
        [self.confirmAccountButton mnz_setupPrimary];
    }
    
    [self.cancelButton mnz_setupCancel];
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
    CGRect activeTextFieldFrame = self.passwordView.passwordTextField.frame;
    if (!CGRectContainsPoint(viewFrame, activeTextFieldFrame.origin)) {
        [self.scrollView scrollRectToVisible:activeTextFieldFrame animated:YES];
    }
}

- (void)keyboardWillBeHidden:(NSNotification *)aNotification {
    self.scrollView.contentInset = UIEdgeInsetsZero;
    self.scrollView.scrollIndicatorInsets = UIEdgeInsetsZero;
}

#pragma mark - UIResponder

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    self.passwordView.toggleSecureButton.hidden = NO;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    [self validateForm];
    self.passwordView.passwordTextField.secureTextEntry = YES;
    [self.passwordView configureSecureTextEntry];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    [self.passwordView setErrorState:NO];
    
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self.passwordView.passwordTextField resignFirstResponder];
    [self confirmTouchUpInside:self.confirmAccountButton];
    return YES;
}

#pragma mark - MEGARequestDelegate

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    if ([error type]) {
        [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeNone];
        [SVProgressHUD dismiss];
        
        [self lockUI:NO];
        
        switch ([error type]) {
            case MEGAErrorTypeApiEKey:
            case MEGAErrorTypeApiENoent: { //MEGARequestTypeConfirmAccount, MEGARequestTypeConfirmChangeEmailLink, MEGARequestTypeConfirmCancelLink
                [self.passwordView setErrorState:YES];
                [self.passwordView.passwordTextField becomeFirstResponder];
                break;
            }
                
            case MEGAErrorTypeApiEAccess: {
                UIAlertController *alreadyLoggedInAlertController = [UIAlertController alertControllerWithTitle:LocalizedString(@"error", @"") message:LocalizedString(@"This link is not related to this account. Please log in with the correct account.", @"Error message shown when opening a link with an account that not corresponds to the link") preferredStyle:UIAlertControllerStyleAlert];
                [alreadyLoggedInAlertController addAction:[UIAlertAction actionWithTitle:LocalizedString(@"ok", @"Button title to accept something") style:UIAlertActionStyleDestructive handler:nil]];
                
                [self presentViewController:alreadyLoggedInAlertController animated:YES completion:nil];
                break;
            }
                
            case MEGAErrorTypeApiEExist: {
                [self.emailInputView setErrorState:YES withText:LocalizedString(@"emailAlreadyInUse", @"Error shown when the user tries to change his mail to one that is already used")];
                break;
            }
                
            case MEGAErrorTypeApiESid:
                break;
                
            default:
                [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"%@ (%ld)", LocalizedString(error.name, @""), (long)error.type]];
                break;
        }
        
        return;
    }
    
    switch ([request type]) {
        case MEGARequestTypeConfirmAccount: {
            MEGAChatInit chatInit = [MEGAChatSdk.shared initKarereWithSid:nil];
            if (chatInit != MEGAChatInitWaitingNewSession) {
                MEGALogError(@"Init Karere without sesion must return waiting for a new sesion");
                [MEGAChatSdk.shared logout];
            }

            if ([api isLoggedIn] <= 1) {
                MEGALoginRequestDelegate *loginRequestDelegate = [[MEGALoginRequestDelegate alloc] init];
                [api loginWithEmail:self.emailInputView.inputTextField.text password:self.passwordView.passwordTextField.text delegate:loginRequestDelegate];

                [Helper clearEphemeralSession];
            }
            break;
        }
            
        case MEGARequestTypeLogout: {
            [Helper logout];
            [MEGASdk.shared confirmAccountWithLink:self.confirmationLinkString password:self.passwordView.passwordTextField.text delegate:self];
            break;
        }
            
        case MEGARequestTypeConfirmChangeEmailLink: {
            [SVProgressHUD dismiss];
            [self.passwordView.passwordTextField resignFirstResponder];
            [[NSNotificationCenter defaultCenter] postNotificationName:MEGAEmailHasChangedNotification object:nil];
            [self dismissViewControllerAnimated:YES completion:^{
                NSString *alertMessage = [LocalizedString(@"congratulationsNewEmailAddress", @"The [X] will be replaced with the e-mail address.") stringByReplacingOccurrencesOfString:@"[X]" withString:request.email];
                UIAlertController *newEmailAddressAlertController = [UIAlertController alertControllerWithTitle:LocalizedString(@"newEmail", @"Hint text to suggest that the user have to write the new email on it") message:alertMessage preferredStyle:UIAlertControllerStyleAlert];
                
                [newEmailAddressAlertController addAction:[UIAlertAction actionWithTitle:LocalizedString(@"ok", @"Button title to accept something") style:UIAlertActionStyleDefault handler:nil]];
                
                [UIApplication.mnz_presentingViewController presentViewController:newEmailAddressAlertController animated:YES completion:nil];
            }];
            break;
        }
            
        default:
            break;
    }
}

@end
