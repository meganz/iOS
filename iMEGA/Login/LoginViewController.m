/**
 * @file LoginViewController.m
 * @brief View controller that allows to login in your MEGA account
 *
 * (c) 2013-2015 by Mega Limited, Auckland, New Zealand
 *
 * This file is part of the MEGA SDK - Client Access Engine.
 *
 * Applications using the MEGA API must present a valid application key
 * and comply with the the rules set forth in the Terms of Service.
 *
 * The MEGA SDK is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 *
 * @copyright Simplified (2-clause) BSD License.
 *
 * You should have received a copy of the license along with this
 * program.
 */

#import "SSKeychain.h"
#import "SVProgressHUD.h"

#import "Helper.h"
#import "MEGAReachabilityManager.h"

#import "CreateAccountViewController.h"
#import "LaunchViewController.h"
#import "LoginViewController.h"

@interface LoginViewController () <UITextFieldDelegate, MEGARequestDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *logoImageView;

@property (weak, nonatomic) IBOutlet UITextField *emailTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;

@property (weak, nonatomic) IBOutlet UIButton *loginButton;

@property (weak, nonatomic) IBOutlet UIButton *createAccountButton;

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
    [self.loginButton setBackgroundColor:[UIColor mnz_redFF4C52]];
    
    [self.createAccountButton setTitle:AMLocalizedString(@"createAccount", nil) forState:UIControlStateNormal];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.navigationItem setTitle:AMLocalizedString(@"login", nil)];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationPortrait;
}

#pragma mark - IBActions

- (IBAction)tapLogin:(id)sender {
    [self.emailTextField resignFirstResponder];
    [self.passwordTextField resignFirstResponder];
    
    if ([self validateForm]) {
        if ([MEGAReachabilityManager isReachable]) {
            NSOperationQueue *operationQueue = [NSOperationQueue new];
            
            NSInvocationOperation *operation = [[NSInvocationOperation alloc] initWithTarget:self
                                                                                    selector:@selector(generateKeys)
                                                                                      object:nil];
            [operationQueue addOperation:operation];
        } else if ([self validateForm]) {
            [SVProgressHUD showImage:[UIImage imageNamed:@"hudForbidden"] status:AMLocalizedString(@"noInternetConnection", nil)];
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
    if (![self validateEmail:self.emailTextField.text]) {
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

- (BOOL)validateEmail:(NSString *)email {
    NSString *emailRegex =
    @"(?:[a-z0-9!#$%\\&'*+/=?\\^_`{|}~-]+(?:\\.[a-z0-9!#$%\\&'*+/=?\\^_`{|}"
    @"~-]+)*|\"(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21\\x23-\\x5b\\x5d-\\"
    @"x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])*\")@(?:(?:[a-z0-9](?:[a-"
    @"z0-9-]*[a-z0-9])?\\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\\[(?:(?:25[0-5"
    @"]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-"
    @"9][0-9]?|[a-z0-9-]*[a-z0-9]:(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21"
    @"-\\x5a\\x53-\\x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])+)\\])";
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES[c] %@", emailRegex];
    
    return [emailTest evaluateWithObject:email];
    
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

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    
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
    [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeClear];
}

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    if ([error type]) {
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
                
            default:
                break;
        }
        return;
    }
    
    switch ([request type]) {
        case MEGARequestTypeLogin: {
            NSString *session = [[MEGASdkManager sharedMEGASdk] dumpSession];
            [SSKeychain setPassword:session forService:@"MEGA" account:@"sessionV3"];
            
            LaunchViewController *launchVC = [[UIStoryboard storyboardWithName:@"Launch" bundle:nil] instantiateViewControllerWithIdentifier:@"LaunchViewControllerID"];
            UIWindow *window = [[[UIApplication sharedApplication] delegate] window];
            [UIView transitionWithView:window duration:0.5 options:(UIViewAnimationOptionTransitionCrossDissolve | UIViewAnimationOptionAllowAnimatedContent) animations:^{
                [window setRootViewController:launchVC];
            } completion:nil];
            [launchVC.progressView setHidden:NO];
            [[UIApplication sharedApplication] setStatusBarHidden:YES];
            break;
        }
            
        default:
            break;
    }
}

- (void)onRequestUpdate:(MEGASdk *)api request:(MEGARequest *)request {
}

- (void)onRequestTemporaryError:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
}

@end
