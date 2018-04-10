#import "ConfirmAccountViewController.h"

#import "SAMKeychain.h"
#import "SVProgressHUD.h"

#import "Helper.h"
#import "MEGALoginRequestDelegate.h"
#import "MEGAReachabilityManager.h"
#import "PasswordView.h"

@interface ConfirmAccountViewController () <UITextFieldDelegate, MEGARequestDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *logoImageView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *logoTopLayoutConstraint;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *confirmTextTopLayoutConstraint;
@property (weak, nonatomic) IBOutlet UILabel *confirmTextLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *confirmTextBottomLayoutConstraint;

@property (weak, nonatomic) IBOutlet UITextField *emailTextField;
@property (weak, nonatomic) IBOutlet PasswordView *passwordView;

@property (weak, nonatomic) IBOutlet UIButton *confirmAccountButton;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *confirmAccountButtonTopLayoutConstraint;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *passwordViewHeightConstraint;

@end

@implementation ConfirmAccountViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if ([[UIDevice currentDevice] iPhone4X]) {
        self.logoTopLayoutConstraint.constant = 24.f;
        self.confirmTextTopLayoutConstraint.constant = 24.f;
        self.confirmTextBottomLayoutConstraint.constant = 55.f;
        self.confirmAccountButtonTopLayoutConstraint.constant = 70.f;
    } else if ([[UIDevice currentDevice] iPhone5X]) {
        self.logoTopLayoutConstraint.constant = 24.f;
    }
    
    if (self.confirmType == ConfirmTypeAccount) {
        self.confirmTextLabel.text = AMLocalizedString(@"confirmText", @"Text shown on the confirm account view to remind the user what to do");
        [self.confirmAccountButton setTitle:AMLocalizedString(@"confirmAccountButton", @"Button title that triggers the confirm account action") forState:UIControlStateNormal];
    } else if (self.confirmType == ConfirmTypeEmail) {
        self.confirmTextLabel.text = AMLocalizedString(@"verifyYourEmailAddress_description", @"Text shown on the confirm email view to remind the user what to do");
        [self.confirmAccountButton setTitle:AMLocalizedString(@"confirmEmail", @"Button text for the user to confirm their change of email address.") forState:UIControlStateNormal];
    } else if (self.confirmType == ConfirmTypeCancelAccount) {
        self.confirmTextLabel.text = AMLocalizedString(@"enterYourPasswordToConfirmThatYouWanToClose", @"Account closure, message shown when you click on the link in the email to confirm the closure of your account");
        [self.confirmAccountButton setTitle:AMLocalizedString(@"closeAccount", @"Account closure, password check dialog when user click on closure email.") forState:UIControlStateNormal];
    }
    
    [self.cancelButton setTitle:AMLocalizedString(@"cancel", nil) forState:UIControlStateNormal];
    
    [self.emailTextField setPlaceholder:AMLocalizedString(@"emailPlaceholder", @"Email")];
    self.passwordView.passwordTextField.delegate = self;
    self.passwordView.passwordTextField.textColor = UIColor.mnz_black333333;
    self.passwordView.passwordTextField.font = [UIFont mnz_SFUIRegularWithSize:17];
    
    [self.emailTextField setText:_emailString];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    if ([[UIDevice currentDevice] iPhoneDevice]) {
        return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown;
    }
    
    return UIInterfaceOrientationMaskAll;
}

#pragma mark - IBActions

- (IBAction)confirmTouchUpInside:(id)sender {
    if ([MEGAReachabilityManager isReachableHUDIfNot]) {
        if ([self validateForm]) {
            [SVProgressHUD show];
            [self lockUI:YES];
            if (self.confirmType == ConfirmTypeAccount) {
                [[MEGASdkManager sharedMEGASdk] confirmAccountWithLink:self.confirmationLinkString password:self.passwordView.passwordTextField.text delegate:self];
            } else if (self.confirmType == ConfirmTypeEmail) {
                [[MEGASdkManager sharedMEGASdk] confirmChangeEmailWithLink:self.confirmationLinkString password:self.passwordView.passwordTextField.text delegate:self];
            } else if (self.confirmType == ConfirmTypeCancelAccount) {
                [[MEGASdkManager sharedMEGASdk] confirmCancelAccountWithLink:self.confirmationLinkString password:self.passwordView.passwordTextField.text delegate:self];
            }
        }
    }
}

- (IBAction)cancelTouchUpInside:(UIButton *)sender {
    [self.passwordView.passwordTextField resignFirstResponder];

    if (self.confirmType == ConfirmTypeAccount) {
        NSString *message = AMLocalizedString(@"areYouSureYouWantToAbortTheRegistration", @"Asking whether the user really wants to abort/stop the registration process or continue on.");
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:message preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"cancel", nil) style:UIAlertActionStyleCancel handler:nil]];
        [alertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"ok", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [[MEGASdkManager sharedMEGASdk] logout];
            [SAMKeychain deletePasswordForService:@"MEGA" account:@"sessionId"];
            [SAMKeychain deletePasswordForService:@"MEGA" account:@"email"];
            [SAMKeychain deletePasswordForService:@"MEGA" account:@"name"];
            [SAMKeychain deletePasswordForService:@"MEGA" account:@"base64pwkey"];
            [self dismissViewControllerAnimated:YES completion:nil];
        }]];
        [self presentViewController:alertController animated:YES completion:nil];
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

#pragma mark - Private

- (BOOL)validateForm {
    if (self.passwordView.passwordTextField.text.length == 0) {
        [SVProgressHUD showErrorWithStatus:AMLocalizedString(@"passwordInvalidFormat", @"Enter a valid password")];
        [self.passwordView.passwordTextField becomeFirstResponder];
        return NO;
    }
    return YES;
}

- (void)lockUI:(BOOL)boolValue {
    self.passwordView.passwordTextField.enabled = !boolValue;
    self.confirmAccountButton.enabled = !boolValue;
    self.cancelButton.enabled = !boolValue;
}

#pragma mark - UIResponder

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self.passwordView.passwordTextField resignFirstResponder];
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    if (!self.passwordView.wrongPasswordView.hidden) {
        self.passwordViewHeightConstraint.constant = 44;
        self.passwordView.wrongPasswordView.hidden = YES;
    }
}

#pragma mark - MEGARequestDelegate

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    if ([error type]) {
        switch ([error type]) {
            case MEGAErrorTypeApiENoent: { //MEGARequestTypeConfirmAccount, MEGARequestTypeConfirmChangeEmailLink, MEGARequestTypeConfirmCancelLink
                [self lockUI:NO];
                self.passwordViewHeightConstraint.constant = 83;
                self.passwordView.wrongPasswordView.hidden = NO;
                break;
            }
                
            case MEGAErrorTypeApiEAccess: {
                [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeNone];
                [SVProgressHUD dismiss];
                
                UIAlertController *alreadyLoggedInAlertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"alreadyLoggedInAlertTitle", @"Warning title shown when you try to confirm an account but you are logged in with another one") message:AMLocalizedString(@"alreadyLoggedInAlertMessage", @"Warning message shown when you try to confirm an account but you are logged in with another one") preferredStyle:UIAlertControllerStyleAlert];
                
                [alreadyLoggedInAlertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"cancel", @"Button title to cancel something") style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
                    [self lockUI:NO];
                }]];
                
                [alreadyLoggedInAlertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"ok", @"Button title to accept something") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                    if ([MEGAReachabilityManager isReachableHUDIfNot]) {
                        [self lockUI:YES];
                        [SVProgressHUD show];
                        [[MEGASdkManager sharedMEGASdk] logoutWithDelegate:self];
                    }
                }]];
                
                [self presentViewController:alreadyLoggedInAlertController animated:YES completion:nil];
                break;
            }

            default:
                [self lockUI:NO];
                [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"%@ (%ld)", error.name, (long)error.type]];
                break;
        }
        
        return;
    }
    
    switch ([request type]) {
            
        case MEGARequestTypeConfirmAccount: {
            if ([MEGASdkManager sharedMEGAChatSdk] == nil) {
                [MEGASdkManager createSharedMEGAChatSdk];
            }
            
            MEGAChatInit chatInit = [[MEGASdkManager sharedMEGAChatSdk] initKarereWithSid:nil];
            if (chatInit != MEGAChatInitWaitingNewSession) {
                MEGALogError(@"Init Karere without sesion must return waiting for a new sesion");
                [[MEGASdkManager sharedMEGAChatSdk] logout];
            }
            
            if (![api isLoggedIn] || [api isLoggedIn] <= 1) {
                MEGALoginRequestDelegate *loginRequestDelegate = [[MEGALoginRequestDelegate alloc] init];
                [api loginWithEmail:[self.emailTextField text] password:[self.passwordView.passwordTextField text] delegate:loginRequestDelegate];

                [SAMKeychain deletePasswordForService:@"MEGA" account:@"sessionId"];
                [SAMKeychain deletePasswordForService:@"MEGA" account:@"email"];
                [SAMKeychain deletePasswordForService:@"MEGA" account:@"name"];
                [SAMKeychain deletePasswordForService:@"MEGA" account:@"base64pwkey"];
            }
            break;
        }
            
        case MEGARequestTypeLogout: {
            [Helper logoutFromConfirmAccount];
            [[MEGASdkManager sharedMEGASdk] confirmAccountWithLink:self.confirmationLinkString password:self.passwordView.passwordTextField.text delegate:self];
            break;
        }
            
        case MEGARequestTypeConfirmChangeEmailLink: {
            [SVProgressHUD dismiss];
            [self.passwordView.passwordTextField resignFirstResponder];
            [self dismissViewControllerAnimated:YES completion:nil];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"emailHasChanged" object:nil];
            
            NSString *alertMessage = [AMLocalizedString(@"congratulationsNewEmailAddress", @"The [X] will be replaced with the e-mail address.") stringByReplacingOccurrencesOfString:@"[X]" withString:request.email];
            UIAlertController *newEmailAddressAlertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"newEmail", @"Hint text to suggest that the user have to write the new email on it") message:alertMessage preferredStyle:UIAlertControllerStyleAlert];
            
            [newEmailAddressAlertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"ok", @"Button title to accept something") style:UIAlertActionStyleDefault handler:nil]];
            
            [self presentViewController:newEmailAddressAlertController animated:YES completion:nil];
            break;
        }
            
        default:
            break;
    }
}

@end
