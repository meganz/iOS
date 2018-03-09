#import "ForgotPasswordViewController.h"

#import "SVProgressHUD.h"

#import "NSString+MNZCategory.h"
#import "MEGAReachabilityManager.h"
#import "MEGASdkManager.h"

#import "ChangePasswordViewController.h"
#import "ParkAccountViewController.h"

@interface ForgotPasswordViewController () <MEGARequestDelegate>

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

#pragma mark - Private

- (void)emailAlertTextFieldDidChange:(UITextField *)sender {
    UIAlertController *emailAlertController = (UIAlertController *)self.presentedViewController;
    if (emailAlertController) {
        UITextField *textField = emailAlertController.textFields.firstObject;
        UIAlertAction *rightButtonAction = emailAlertController.actions.lastObject;
        rightButtonAction.enabled = !textField.text.mnz_isEmpty;
    }
}

#pragma mark - IBActions

- (IBAction)cancelAction:(UIBarButtonItem *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)yesButtonTouchUpInside:(UIButton *)sender {
    UIAlertController *emailAlertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"great", @"Headline when the user chose YES") message:AMLocalizedString(@"recoveryLinkToResetYourPassword", @"Text of the alert message to ask for the link to reset the pass with the MK") preferredStyle:UIAlertControllerStyleAlert];
    
    [emailAlertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = AMLocalizedString(@"emailPlaceholder", @"Hint text to suggest that the user has to write his email");
        [textField addTarget:self action:@selector(emailAlertTextFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    }];
    
    [emailAlertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"cancel", @"Button title to cancel something") style:UIAlertActionStyleCancel handler:nil]];
    
    UIAlertAction *sendAlertAction = [UIAlertAction actionWithTitle:AMLocalizedString(@"send", @"Label for any 'Send' button, link, text, title, etc. - (String as short as possible).") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        if ([MEGAReachabilityManager isReachableHUDIfNot]) {
            UITextField *textField = emailAlertController.textFields.firstObject;
            NSString *email = textField.text;
            if (email.mnz_isValidEmail) {
                [[MEGASdkManager sharedMEGASdk] resetPasswordWithEmail:email hasMasterKey:YES delegate:self];
            } else {
                [SVProgressHUD showErrorWithStatus:AMLocalizedString(@"emailInvalidFormat", @"Message shown when the user writes an invalid format in the email field")];
            }
        }
    }];
    sendAlertAction.enabled = NO;
    [emailAlertController addAction:sendAlertAction];
    
    [self presentViewController:emailAlertController animated:YES completion:nil];
}

- (IBAction)noButtonTouchUpInside:(UIButton *)sender {
    ParkAccountViewController *parkAccountVC = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"ParkAccountViewControllerID"];
    [self.navigationController pushViewController:parkAccountVC animated:YES];
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
