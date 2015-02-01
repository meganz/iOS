/**
 * @file ConfirmAccountViewController.m
 * @brief View controller that allows to confirm an account on MEGA
 *
 * (c) 2013-2014 by Mega Limited, Auckland, New Zealand
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

#import "SVProgressHUD.h"
#import "Helper.h"

@interface ConfirmAccountViewController () <UITextFieldDelegate, MEGARequestDelegate>

@property (weak, nonatomic) IBOutlet UIView *credentialsView;
@property (weak, nonatomic) IBOutlet UITextField *emailTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UIButton *confirmAccountButton;

@end

@implementation ConfirmAccountViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.navigationItem setTitle:@"Confirm account"];
    
    self.confirmAccountButton.layer.cornerRadius = 6;
    self.confirmAccountButton.layer.masksToBounds = YES;
    
    self.credentialsView.backgroundColor = [megaLightGray colorWithAlphaComponent:.25f];
    self.credentialsView.layer.borderWidth = 2.0f;
    self.credentialsView.layer.borderColor =[megaLightGray CGColor];
    self.credentialsView.layer.cornerRadius = 6;
    self.credentialsView.layer.masksToBounds = YES;
    
    [self.emailTextField setText:_emailString];
}

#pragma mark - Private methods

- (IBAction)confirmTouchUpInside:(id)sender {
    if ([self validateForm]) {
            [[MEGASdkManager sharedMEGASdk] confirmAccountWithLink:self.confirmationLinkString password:[self.passwordTextField text] delegate:self];
    }
}

- (BOOL)validateForm {
    if (![self validatePassword:self.passwordTextField.text]) {
        [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"passwordInvalidFormat", @"Enter a valid password")];
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

- (IBAction)loginTouchUpInside:(id)sender {
    UIViewController *loginVC = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"LoginViewControllerID"];
    [[[[UIApplication sharedApplication] delegate] window] setRootViewController:loginVC];
}


#pragma mark - MEGARequestDelegate

- (void)onRequestStart:(MEGASdk *)api request:(MEGARequest *)request {
    switch ([request type]) {
        case MEGARequestTypeFetchNodes:
            [SVProgressHUD showWithStatus:NSLocalizedString(@"updatingNodes", @"Updating nodes...")];
            break;
        default:
            break;
    }
}

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    if ([error type]) {
        switch ([error type]) {
            case MEGAErrorTypeApiENoent: {
                [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"passwordWrong", @"Wrong password")];
                break;
            }
                
            default:
                break;
        }
        
        return;
    }
    
    switch ([request type]) {
            
        case MEGARequestTypeConfirmAccount: {
            if ([[MEGASdkManager sharedMEGASdk] isLoggedIn]) {
                [[MEGASdkManager sharedMEGASdk] logout];
            }
            
            [[MEGASdkManager sharedMEGASdk] loginWithEmail:[self.emailTextField text] password:[self.passwordTextField text] delegate:self];
            
            MainTabBarController *mainTBC = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"TabBarControllerID"];
            [[[[UIApplication sharedApplication] delegate] window] setRootViewController:mainTBC];
        }
            
        case MEGARequestTypeLogin: {
            [[MEGASdkManager sharedMEGASdk] fetchNodesWithDelegate:self];
        }
            
        default:
            break;
    }
}

- (void)onRequestTemporaryError:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
}

@end
