#import "ParkAccountViewController.h"

#import "SVProgressHUD.h"

#import "Helper.h"
#import "MEGASdkManager.h"

#import "ChangePasswordViewController.h"

@interface ParkAccountViewController () <UIAlertViewDelegate, MEGARequestDelegate>

@property (weak, nonatomic) IBOutlet UILabel *firstParagraphLabel;
@property (weak, nonatomic) IBOutlet UILabel *secondParagraphLabel;

@property (weak, nonatomic) IBOutlet UIButton *parkAccountButton;

@end

@implementation ParkAccountViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = AMLocalizedString(@"noMasterKey_title", @"The title of the screen to park an account.");
    
    self.firstParagraphLabel.text = AMLocalizedString(@"noMasterKey_firstParagraph", @"First paragraph of the screen to park an account");
    self.secondParagraphLabel.text = AMLocalizedString(@"noMasterKey_secondParagraph", @"Second paragraph of the screen to park an account");
    
    [self.parkAccountButton setTitle:AMLocalizedString(@"parkAccount", @"Headline for parking an account (basically restarting from scratch)") forState:UIControlStateNormal];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    if ([[UIDevice currentDevice] iPhoneDevice]) {
        return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown;
    }
    
    return UIInterfaceOrientationMaskAll;
}

#pragma mark - IBActions

- (IBAction)parkAccountTouchUpInside:(UIButton *)sender {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:AMLocalizedString(@"parkAccount", @"Headline for parking an account (basically restarting from scratch)") message:AMLocalizedString(@"recoveryLinkToParkYourAccount", @"Text of the dialog message to ask for the link to park the account") delegate:self cancelButtonTitle:AMLocalizedString(@"cancel", @"") otherButtonTitles:AMLocalizedString(@"ok", @""), nil];
    alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
    UITextField *textField = [alertView textFieldAtIndex:0];
    textField.placeholder = AMLocalizedString(@"emailPlaceholder", @"Hint text to suggest that the user has to write his email");
    [alertView show];
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
    if (alertView.tag == 0) {
        if (buttonIndex == 1) {
            UITextField *textField = [alertView textFieldAtIndex:0];
            NSString *email = [textField text];
            if ([Helper validateEmail:email]) {
                [[MEGASdkManager sharedMEGASdk] resetPasswordWithEmail:email hasMasterKey:NO delegate:self];
            } else {
                [SVProgressHUD showErrorWithStatus:AMLocalizedString(@"emailInvalidFormat", @"Message shown when the user writes an invalid format in the email field")];
            }
        }
    }
}

#pragma mark - MEGARequestDelegate

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    if (error.type) {
        return;
    }
    
    if (request.type == MEGARequestTypeGetRecoveryLink) {
        ChangePasswordViewController *changePasswordVC = [[UIStoryboard storyboardWithName:@"Settings" bundle:nil] instantiateViewControllerWithIdentifier:@"ChangePasswordViewControllerID"];
        changePasswordVC.emailIsChangingTitleLabel.text = AMLocalizedString(@"pleaseCheckYourEmail", nil);
        changePasswordVC.emailIsChangingDescriptionLabel.text = AMLocalizedString(@"ifYouCantAccessYourEmailAccount", @"Account closure, warning message to remind user to contact MEGA support after he confirms that he wants to cancel account.");
        self.view = changePasswordVC.emailIsChangingView;
    }
}

@end
