#import "ParkAccountViewController.h"

#import "SVProgressHUD.h"

#import "NSString+MNZCategory.h"
#import "MEGAReachabilityManager.h"
#import "MEGASdkManager.h"

#import "ChangePasswordViewController.h"

@interface ParkAccountViewController () <MEGARequestDelegate>

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

- (IBAction)parkAccountTouchUpInside:(UIButton *)sender {
    UIAlertController *emailAlertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"parkAccount", @"Headline for parking an account (basically restarting from scratch)") message:AMLocalizedString(@"recoveryLinkToParkYourAccount", @"Text of the dialog message to ask for the link to park the account") preferredStyle:UIAlertControllerStyleAlert];
    
    [emailAlertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = AMLocalizedString(@"emailPlaceholder", @"Hint text to suggest that the user has to write his email");
        [textField addTarget:self action:@selector(emailAlertTextFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    }];
    
    [emailAlertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"cancel", @"Button title to cancel something") style:UIAlertActionStyleCancel handler:nil]];
    
    UIAlertAction *okAlertAction = [UIAlertAction actionWithTitle:AMLocalizedString(@"ok", @"Button title to accept something") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        if ([MEGAReachabilityManager isReachableHUDIfNot]) {
            UITextField *textField = emailAlertController.textFields.firstObject;
            NSString *email = textField.text;
            if (email.mnz_isValidEmail) {
                [[MEGASdkManager sharedMEGASdk] resetPasswordWithEmail:email hasMasterKey:NO delegate:self];
            } else {
                [SVProgressHUD showErrorWithStatus:AMLocalizedString(@"emailInvalidFormat", @"Message shown when the user writes an invalid format in the email field")];
            }
        }
    }];
    okAlertAction.enabled = NO;
    [emailAlertController addAction:okAlertAction];
    
    [self presentViewController:emailAlertController animated:YES completion:nil];
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
