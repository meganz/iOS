
#import "CheckEmailAndFollowTheLinkViewController.h"

#import "SAMKeychain.h"
#import "SVProgressHUD.h"

#import "NSString+MNZCategory.h"

#import "MEGALoginRequestDelegate.h"
#import "MEGASendSignupLinkRequestDelegate.h"
#import "MEGAReachabilityManager.h"
#import "MEGASdkManager.h"


@interface CheckEmailAndFollowTheLinkViewController () <MEGAGlobalDelegate>

@property (weak, nonatomic) IBOutlet UITextField *emailTextField;
@property (weak, nonatomic) IBOutlet UIButton *resendButton;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UILabel *checkYourEmailLabel;
@property (weak, nonatomic) IBOutlet UILabel *misspelledLabel;

@property (nonatomic, copy) NSString *email;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *password;

@end

@implementation CheckEmailAndFollowTheLinkViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [_emailTextField setPlaceholder:AMLocalizedString(@"emailPlaceholder", nil)];
    
    _email = [SAMKeychain passwordForService:@"MEGA" account:@"email"];
    _name = [SAMKeychain passwordForService:@"MEGA" account:@"name"];
    _password = [SAMKeychain passwordForService:@"MEGA" account:@"password"];
    
    _emailTextField.text = self.email;
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    [self.view addGestureRecognizer:tap];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.checkYourEmailLabel.text = AMLocalizedString(@"accountNotConfirmed", @"Text shown just after creating an account to remenber the user what to do to complete the account creation proccess");
    self.misspelledLabel.text = AMLocalizedString(@"misspelledEmailAddress", @"A hint shown at the bottom of the Send Signup Link dialog to tell users they can edit the provided email.");
    [self.resendButton setTitle:AMLocalizedString(@"resend", @"A button to resend the email confirmation.") forState:UIControlStateNormal];
    [self.cancelButton setTitle:AMLocalizedString(@"cancel", nil) forState:UIControlStateNormal];
    [[MEGASdkManager sharedMEGASdk] addMEGAGlobalDelegate:self];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[MEGASdkManager sharedMEGASdk] removeMEGAGlobalDelegate:self];
}

#pragma mark - Private

-(void)dismissKeyboard {
    [self.emailTextField resignFirstResponder];
}

#pragma mark - IBActions

- (IBAction)cancelTouchUpInside:(UIButton *)sender {
    NSString *message = AMLocalizedString(@"areYouSureYouWantToAbortTheRegistration", @"Asking whether the user really wants to abort/stop the registration process or continue on.");
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:message preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"cancel", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
    }]];
    [alertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"ok", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [[MEGASdkManager sharedMEGASdk] logout];
        [SAMKeychain deletePasswordForService:@"MEGA" account:@"sessionId"];
        [SAMKeychain deletePasswordForService:@"MEGA" account:@"email"];
        [SAMKeychain deletePasswordForService:@"MEGA" account:@"name"];
        [SAMKeychain deletePasswordForService:@"MEGA" account:@"password"];
        [self dismissViewControllerAnimated:YES completion:nil];
    }]];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (IBAction)resendTouchUpInside:(UIButton *)sender {
    if ([MEGAReachabilityManager isReachableHUDIfNot]) {
        if ([self.emailTextField.text mnz_isValidEmail]) {
            [self.emailTextField resignFirstResponder];
            MEGASendSignupLinkRequestDelegate *sendSignupLinkRequestDelegate = [[MEGASendSignupLinkRequestDelegate alloc] init];
            [[MEGASdkManager sharedMEGASdk] sendSignupLinkWithEmail:self.emailTextField.text name:self.name password:self.password delegate:sendSignupLinkRequestDelegate];
        } else {
            [SVProgressHUD showErrorWithStatus:AMLocalizedString(@"emailInvalidFormat", @"Message shown when the user writes an invalid format in the email field")];
        }
    }
}


#pragma mark - UITextFieldDelegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    BOOL shoulBeCreateAccountButtonGray = NO;
    if (![self.emailTextField.text mnz_isValidEmail]) {
        shoulBeCreateAccountButtonGray = YES;
    } else {
        shoulBeCreateAccountButtonGray = NO;
    }
    
    shoulBeCreateAccountButtonGray ? [self.resendButton setBackgroundColor:[UIColor mnz_grayCCCCCC]] : [self.resendButton setBackgroundColor:[UIColor mnz_redFF4D52]];
    
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self.emailTextField resignFirstResponder];
    [self resendTouchUpInside:nil];
    
    return YES;
}

#pragma mark - MEGAGlobalDelegate

- (void)onAccountUpdate:(MEGASdk *)api {
    MEGALoginRequestDelegate *loginRequestDelegate = [[MEGALoginRequestDelegate alloc] init];
    loginRequestDelegate.confirmAccountInOtherClient = YES;
    [api loginWithEmail:self.email password:self.password delegate:loginRequestDelegate];
}

@end
