/**
 * @file ConfirmAccountViewController.m
 * @brief View controller that allows to confirm an account on MEGA
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

#import "ConfirmAccountViewController.h"
#import "MainTabBarController.h"

#import "SSKeychain.h"
#import "SVProgressHUD.h"
#import "Helper.h"
#import "MEGAReachabilityManager.h"

@interface ConfirmAccountViewController () <UIAlertViewDelegate, UITextFieldDelegate, MEGARequestDelegate>

@property (weak, nonatomic) IBOutlet UILabel *confirmTextLabel;

@property (weak, nonatomic) IBOutlet UITextField *emailTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UIButton *confirmAccountButton;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;

@end

@implementation ConfirmAccountViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.confirmTextLabel setText:AMLocalizedString(@"confirmText", @"Please enter your password to confirm your account")];
    
    self.confirmAccountButton.layer.cornerRadius = 4.0f;
    self.confirmAccountButton.layer.masksToBounds = YES;
    [self.confirmAccountButton setTitle:AMLocalizedString(@"confirmAccountButton", @"Confirm your account") forState:UIControlStateNormal];
    [self.confirmAccountButton setBackgroundColor:[UIColor mnz_redFF4C52]];
    
    self.cancelButton.layer.cornerRadius = 4.0f;
    self.cancelButton.layer.masksToBounds = YES;
    [self.cancelButton setTitle:AMLocalizedString(@"cancel", nil) forState:UIControlStateNormal];
    
    [self.emailTextField setPlaceholder:AMLocalizedString(@"emailPlaceholder", @"Email")];
    [self.passwordTextField setPlaceholder:AMLocalizedString(@"passwordPlaceholder", @"Password")];
    
    [self.emailTextField setText:_emailString];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    if ([[UIDevice currentDevice] iPhoneDevice]) {
        return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown;
    }
    
    return UIInterfaceOrientationMaskAll;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationPortrait;
}

#pragma mark - IBActions

- (IBAction)confirmTouchUpInside:(id)sender {
    if ([self validateForm]) {
        if ([MEGAReachabilityManager isReachableHUDIfNot]) {
            [SVProgressHUD show];
            [self lockUI:YES];
            [[MEGASdkManager sharedMEGASdk] confirmAccountWithLink:self.confirmationLinkString password:[self.passwordTextField text] delegate:self];
        }
    }
}

- (IBAction)cancelTouchUpInside:(UIButton *)sender {
    [self.passwordTextField resignFirstResponder];
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Private

- (BOOL)validateForm {
    if (![self validatePassword:self.passwordTextField.text]) {
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

- (void)lockUI:(BOOL)boolValue {
    [self.passwordTextField setEnabled:!boolValue];
    [self.confirmAccountButton setEnabled:!boolValue];
    [self.cancelButton setEnabled:!boolValue];
}

#pragma mark - UIResponder

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if ([alertView tag] == 0) {
        if (buttonIndex == 0) {
            [self lockUI:NO];
        } else if (buttonIndex == 1) {
            [self lockUI:YES];
            [SVProgressHUD show];
            [[MEGASdkManager sharedMEGASdk] logoutWithDelegate:self];
        }
    }
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [_passwordTextField resignFirstResponder];
    return YES;
}


#pragma mark - MEGARequestDelegate

- (void)onRequestStart:(MEGASdk *)api request:(MEGARequest *)request {
}

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    if ([error type]) {
        switch ([error type]) {
            case MEGAErrorTypeApiENoent: {
                [self lockUI:NO];
                [SVProgressHUD showErrorWithStatus:AMLocalizedString(@"passwordWrong", @"Wrong password")];
                break;
            }
                
            case MEGAErrorTypeApiEAccess: {
                [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeNone];
                [SVProgressHUD dismiss];
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:AMLocalizedString(@"alreadyLoggedInAlertTitle", @"You are logged with another account")
                                                                    message:AMLocalizedString(@"alreadyLoggedInAlertMessage", @"If you agree, the current account will be logged out and all Offline data will be erased. Do you want to continue?")
                                                                   delegate:self
                                                          cancelButtonTitle:AMLocalizedString(@"cancel", nil)
                                                          otherButtonTitles:AMLocalizedString(@"ok", nil), nil];
                [alertView setTag:0];
                [alertView show];
                break;
            }

            default:
                break;
        }
        
        return;
    }
    
    switch ([request type]) {
            
        case MEGARequestTypeConfirmAccount: {
            if (![[MEGASdkManager sharedMEGASdk] isLoggedIn]) {
                [[MEGASdkManager sharedMEGASdk] loginWithEmail:[self.emailTextField text] password:[self.passwordTextField text] delegate:self];
            }
            break;
        }
            
        case MEGARequestTypeLogout: {
            [Helper logoutFromConfirmAccount];
            [[MEGASdkManager sharedMEGASdk] confirmAccountWithLink:self.confirmationLinkString password:[self.passwordTextField text] delegate:self];
            break;
        }
            
        case MEGARequestTypeLogin: {
            NSString *session = [[MEGASdkManager sharedMEGASdk] dumpSession];
            [SSKeychain setPassword:session forService:@"MEGA" account:@"sessionV3"];
        }
            
        default:
            break;
    }
}

- (void)onRequestTemporaryError:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
}

@end
