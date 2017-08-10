#import "ForgotPasswordViewController.h"

#import "SVProgressHUD.h"

#import "NSString+MNZCategory.h"
#import "MEGASdkManager.h"

#import "ChangePasswordViewController.h"
#import "ParkAccountViewController.h"

@interface ForgotPasswordViewController () <UIAlertViewDelegate, MEGARequestDelegate>

@property (strong, nonatomic) IBOutlet UIBarButtonItem *cancelBarButtonItem;

@property (weak, nonatomic) IBOutlet UILabel *firstParagraphLabel;
@property (weak, nonatomic) IBOutlet UILabel *secondParagraphLabel;

@property (weak, nonatomic) IBOutlet UILabel *questionLabel;

@property (weak, nonatomic) IBOutlet UIButton *yesButton;
@property (weak, nonatomic) IBOutlet UIButton *noButton;

@end

@implementation ForgotPasswordViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.leftBarButtonItem = self.cancelBarButtonItem;
    
    self.navigationItem.title = AMLocalizedString(@"forgotPassword", @"An option to reset the password.");
    
    self.firstParagraphLabel.text = AMLocalizedString(@"forgotPassword_firstParagraph", @"First paragraph of the screen when the password has been forgotten");
    self.secondParagraphLabel.text = AMLocalizedString(@"forgotPassword_secondParagraph", @"Second paragraph of the screen when the password has been forgotten");
    
    self.questionLabel.text = AMLocalizedString(@"doYouHaveABackupOfYourRecoveryKey", @"A question asking if the user has made a copy of their master encryption key (now renamed 'Recovery Key')");
    
    [self.noButton setTitle:AMLocalizedString(@"no", nil) forState:UIControlStateNormal];
    [self.yesButton setTitle:AMLocalizedString(@"yes", nil) forState:UIControlStateNormal];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    if ([[UIDevice currentDevice] iPhoneDevice]) {
        return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown;
    }
    
    return UIInterfaceOrientationMaskAll;
}

#pragma mark - IBActions

- (IBAction)cancelAction:(UIBarButtonItem *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)yesButtonTouchUpInside:(UIButton *)sender {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:AMLocalizedString(@"great", @"Headline when the user chose YES")
                                                        message:AMLocalizedString(@"recoveryLinkToResetYourPassword", @"Text of the alert message to ask for the link to reset the pass with the MK")
                                                       delegate:self
                                              cancelButtonTitle:AMLocalizedString(@"cancel", @"")
                                              otherButtonTitles:AMLocalizedString(@"send", @""), nil];
    
    alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
    UITextField *textField = [alertView textFieldAtIndex:0];
    textField.placeholder = AMLocalizedString(@"emailPlaceholder", @"Hint text to suggest that the user has to write his email");
    [alertView show];
}

- (IBAction)noButtonTouchUpInside:(UIButton *)sender {
    ParkAccountViewController *parkAccountVC = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"ParkAccountViewControllerID"];
    [self.navigationController pushViewController:parkAccountVC animated:YES];
}

#pragma mark - UIAlertViewDelegate

- (BOOL)alertViewShouldEnableFirstOtherButton:(UIAlertView *)alertView {
    BOOL shouldEnable = YES;
    if (alertView.tag == 0) {
        UITextField *textField = [alertView textFieldAtIndex:0];
        NSString *text = [textField text];
        if (text.length == 0) {
            shouldEnable = NO;
        }
    }
    
    return shouldEnable;
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    switch ([alertView tag]) {
        case 0: {
            if (buttonIndex == 1) {
                UITextField *textField = [alertView textFieldAtIndex:0];
                NSString *email = [textField text];
                if ([email mnz_isValidEmail]) {
                    [[MEGASdkManager sharedMEGASdk] resetPasswordWithEmail:email hasMasterKey:YES delegate:self];
                } else {
                    [SVProgressHUD showErrorWithStatus:AMLocalizedString(@"emailInvalidFormat", @"Message shown when the user writes an invalid format in the email field")];
                }
            }
            break;
        }
            
        default:
            break;
    }
}

#pragma mark - MEGARequestDelegate

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    if (error.type) {
        return;
    }
    
    if (request.type == MEGARequestTypeGetRecoveryLink) {
        ChangePasswordViewController *changePasswordVC = [[UIStoryboard storyboardWithName:@"Settings" bundle:nil] instantiateViewControllerWithIdentifier:@"ChangePasswordViewControllerID"];
        changePasswordVC.emailIsChangingTitleLabel.text = AMLocalizedString(@"awaitingEmailConfirmation", @"Title shown just after doing some action that requires confirming the action by an email");
        changePasswordVC.emailIsChangingDescriptionLabel.text = AMLocalizedString(@"ifYouCantAccessYourEmailAccount", @"Account closure, warning message to remind user to contact MEGA support after he confirms that he wants to cancel account.");
        self.view = changePasswordVC.emailIsChangingView;
    }
}

@end
