#import "LoginViewController.h"

#import "SAMKeychain.h"
#import "SVProgressHUD.h"

#import "Helper.h"
#import "MEGANavigationController.h"
#import "MEGAReachabilityManager.h"

#import "CreateAccountViewController.h"
#import "LaunchViewController.h"

@interface LoginViewController () <UITextFieldDelegate, MEGARequestDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *logoImageView;

@property (weak, nonatomic) IBOutlet UITextField *emailTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;

@property (weak, nonatomic) IBOutlet UIButton *loginButton;

@property (weak, nonatomic) IBOutlet UIButton *createAccountButton;
@property (weak, nonatomic) IBOutlet UIButton *forgotPasswordButton;

@end

@implementation LoginViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(logoTappedFiveTimes:)];
    tapGestureRecognizer.numberOfTapsRequired = 5;
    self.logoImageView.gestureRecognizers = @[tapGestureRecognizer];
    
    self.loginButton.layer.cornerRadius = 4.0f;
    self.loginButton.layer.masksToBounds = YES;
    
    [self.emailTextField setPlaceholder:AMLocalizedString(@"emailPlaceholder", @"Email")];
    [self.passwordTextField setPlaceholder:AMLocalizedString(@"passwordPlaceholder", @"Password")];
    
    [self.loginButton setTitle:AMLocalizedString(@"login", @"Login") forState:UIControlStateNormal];
    [self.loginButton setBackgroundColor:[UIColor mnz_grayCCCCCC]];
    
    [self.createAccountButton setTitle:AMLocalizedString(@"createAccount", nil) forState:UIControlStateNormal];
    NSString *forgotPasswordString = AMLocalizedString(@"forgotPassword", @"An option to reset the password.");
    forgotPasswordString = [forgotPasswordString stringByReplacingOccurrencesOfString:@"?" withString:@""];
    forgotPasswordString = [forgotPasswordString stringByReplacingOccurrencesOfString:@"¿" withString:@""];
    [self.forgotPasswordButton setTitle:forgotPasswordString forState:UIControlStateNormal];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.navigationItem setTitle:AMLocalizedString(@"login", nil)];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    if ([[UIDevice currentDevice] iPhoneDevice]) {
        return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown;
    }
    
    return UIInterfaceOrientationMaskAll;
}

#pragma mark - IBActions

- (IBAction)tapLogin:(id)sender {
    [self.emailTextField resignFirstResponder];
    [self.passwordTextField resignFirstResponder];
    
    if ([self validateForm]) {
        if ([MEGAReachabilityManager isReachableHUDIfNot]) {
            NSOperationQueue *operationQueue = [NSOperationQueue new];
            
            NSInvocationOperation *operation = [[NSInvocationOperation alloc] initWithTarget:self
                                                                                    selector:@selector(generateKeys)
                                                                                      object:nil];
            [operationQueue addOperation:operation];
        }
    }
}

#pragma mark - Private

- (void)logoTappedFiveTimes:(UITapGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateEnded) {
        BOOL enableLogging = ![[NSUserDefaults standardUserDefaults] boolForKey:@"logging"];
        UIAlertView *logAlertView = [Helper logAlertView:enableLogging];
        logAlertView.delegate = self;
        [logAlertView show];
    }
}

- (void)generateKeys {
    NSString *privateKey = [[MEGASdkManager sharedMEGASdk] base64pwkeyForPassword:self.passwordTextField.text];
    NSString *publicKey  = [[MEGASdkManager sharedMEGASdk] hashForBase64pwkey:privateKey email:self.emailTextField.text];
    
    [[MEGASdkManager sharedMEGASdk] fastLoginWithEmail:self.emailTextField.text stringHash:publicKey base64pwKey:privateKey delegate:self];
}

- (BOOL)validateForm {
    if (![Helper validateEmail:self.emailTextField.text]) {
        [SVProgressHUD showErrorWithStatus:AMLocalizedString(@"emailInvalidFormat", @"Enter a valid email")];
        [self.emailTextField becomeFirstResponder];
        return NO;
    } else if (![self validatePassword:self.passwordTextField.text]) {
        [SVProgressHUD showErrorWithStatus:AMLocalizedString(@"passwordInvalidFormat", @"Enter a valid password")];
        [self.passwordTextField becomeFirstResponder];
        return NO;
    }
    return YES;
}

- (BOOL)validatePassword:(NSString *)password {
    if (password.length == 0) {
        return NO;
    } else {
        return YES;
    }
}

- (NSString *)timeFormatted:(NSUInteger)totalSeconds {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateStyle:NSDateFormatterNoStyle];
    [formatter setTimeStyle:NSDateFormatterMediumStyle];
    
    NSDate *date = [NSDate dateWithTimeIntervalSinceNow:totalSeconds];
    
    return [formatter stringFromDate:date];
}

- (IBAction)forgotPasswordTouchUpInside:(UIButton *)sender {
    MEGANavigationController *navigationController = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"ForgotPasswordNavigationControllerID"];
    [self presentViewController:navigationController animated:YES completion:nil];
}

#pragma mark - UIResponder

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}

#pragma mark - UIViewController

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"CreateAccountStoryboardSegueID"] && [sender isKindOfClass:[NSString class]]) {
        CreateAccountViewController *createAccountVC = (CreateAccountViewController *)segue.destinationViewController;
        [createAccountVC setEmailString:sender];
    }
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        (alertView.tag == 0) ? [Helper enableLog:NO] : [Helper enableLog:YES];
    }
}

#pragma mark - UITextFieldDelegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSString *text = [textField.text stringByReplacingCharactersInRange:range withString:string];
    BOOL shoulBeLoginButtonGray = NO;
    switch ([textField tag]) {
        case 0: {
            if ([text isEqualToString:@""] || [self.passwordTextField.text isEqualToString:@""]) {
                shoulBeLoginButtonGray = YES;
            }
            break;
        }
            
        case 1: {
            if ([text isEqualToString:@""] || [self.emailTextField.text isEqualToString:@""]) {
                shoulBeLoginButtonGray = YES;
            }
            break;
        }
    }
    
    shoulBeLoginButtonGray ? [self.loginButton setBackgroundColor:[UIColor mnz_grayCCCCCC]] : [self.loginButton setBackgroundColor:[UIColor mnz_redFF4C52]];
    
    return YES;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField {
    [self.loginButton setBackgroundColor:[UIColor mnz_grayCCCCCC]];
    
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    switch ([textField tag]) {
        case 0:
            [self.passwordTextField becomeFirstResponder];
            break;
            
        case 1:
            [self.passwordTextField resignFirstResponder];
            [self tapLogin:self.loginButton];
            break;
            
        default:
            break;
    }
    
    return YES;
}

#pragma mark - MEGARequestDelegate

- (void)onRequestStart:(MEGASdk *)api request:(MEGARequest *)request {
    if ([request type] == MEGARequestTypeLogin) {
        [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeClear];
        [SVProgressHUD show];
    }
}

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    if ([error type]) {
        [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeNone];
        [SVProgressHUD dismiss];
        switch ([error type]) {
            case MEGAErrorTypeApiEArgs:
            case MEGAErrorTypeApiENoent: {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:AMLocalizedString(@"error", nil)
                                                                message:AMLocalizedString(@"invalidMailOrPassword", nil)
                                                               delegate:self
                                                      cancelButtonTitle:AMLocalizedString(@"ok", nil)
                                                      otherButtonTitles:nil];
                [alert show];
                
                [self.emailTextField becomeFirstResponder];
                break;
            }
                
            case MEGAErrorTypeApiETooMany: {
                NSString *message = [NSString stringWithFormat:AMLocalizedString(@"tooManyAttemptsLogin", @"Error message when to many attempts to login"), [self timeFormatted:3600]];
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:AMLocalizedString(@"error", nil)
                                                                message:message
                                                               delegate:self
                                                      cancelButtonTitle:AMLocalizedString(@"ok", nil)
                                                      otherButtonTitles:nil];
                [alert show];
            
                break;
            }
                
            case MEGAErrorTypeApiEIncomplete: {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:AMLocalizedString(@"error", nil)
                                                                message:AMLocalizedString(@"accountNotConfirmed", @"Text shown just after creating an account to remenber the user what to do to complete the account creation proccess")
                                                               delegate:self
                                                      cancelButtonTitle:AMLocalizedString(@"ok", nil)
                                                      otherButtonTitles:nil];
                [alert show];
            
                break;
            }
                
            case MEGAErrorTypeApiEBlocked: {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:AMLocalizedString(@"error", nil)
                                                                message:AMLocalizedString(@"accountBlocked", @"Error message when trying to login and the account is suspended")
                                                               delegate:self
                                                      cancelButtonTitle:AMLocalizedString(@"ok", nil)
                                                      otherButtonTitles:nil];
                [alert show];
                break;
            }
                
            default:
                break;
        }
        return;
    }
    
    switch ([request type]) {
        case MEGARequestTypeLogin: {
            NSString *session = [[MEGASdkManager sharedMEGASdk] dumpSession];
            [SAMKeychain setPassword:session forService:@"MEGA" account:@"sessionV3"];
            
            LaunchViewController *launchVC = [[UIStoryboard storyboardWithName:@"Launch" bundle:nil] instantiateViewControllerWithIdentifier:@"LaunchViewControllerID"];
            UIWindow *window = [[[UIApplication sharedApplication] delegate] window];
            [UIView transitionWithView:window duration:0.5 options:(UIViewAnimationOptionTransitionCrossDissolve | UIViewAnimationOptionAllowAnimatedContent) animations:^{
                [window setRootViewController:launchVC];
            } completion:nil];
            [[UIApplication sharedApplication] setStatusBarHidden:YES];
            break;
        }
            
        default:
            break;
    }
}

@end
