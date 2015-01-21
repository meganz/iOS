/**
 * @file CreateAccountViewController.m
 * @brief View controller that allows to create an account on MEGA
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

#import "CreateAccountViewController.h"

#import "SVProgressHUD.h"
#import "Helper.h"

@interface CreateAccountViewController () <UINavigationControllerDelegate, UITextFieldDelegate, MEGARequestDelegate>

@property (weak, nonatomic) IBOutlet UIView *credentialsView;
@property (weak, nonatomic) IBOutlet UITextField *nameTextField;
@property (weak, nonatomic) IBOutlet UITextField *emailTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UITextField *retypePasswordTextField;

@property (weak, nonatomic) IBOutlet UIButton *termsCheckboxButton;
@property (weak, nonatomic) IBOutlet UIButton *termsOfServiceButton;

@property (weak, nonatomic) IBOutlet UIButton *createAccountButton;

@end

@implementation CreateAccountViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.navigationItem setTitle:@"Create account"];
    
    self.createAccountButton.layer.cornerRadius = 6;
    self.createAccountButton.layer.masksToBounds = YES;
    
    self.credentialsView.backgroundColor = [megaLightGray colorWithAlphaComponent:.25f];
    self.credentialsView.layer.borderWidth = 2.0f;
    self.credentialsView.layer.borderColor =[megaLightGray CGColor];
    self.credentialsView.layer.cornerRadius = 6;
    self.credentialsView.layer.masksToBounds = YES;
    
    [self.nameTextField becomeFirstResponder];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:NO];
}

#pragma mark - Private methods

- (IBAction)termsCheckboxTouchUpInside:(id)sender {
    self.termsCheckboxButton.selected = !self.termsCheckboxButton.selected;
    
    [self.nameTextField resignFirstResponder];
    [self.emailTextField resignFirstResponder];
    [self.passwordTextField resignFirstResponder];
    [self.retypePasswordTextField resignFirstResponder];
}

- (IBAction)createAccountTouchUpInside:(id)sender {
    if ([self validateForm]) {
        [[MEGASdkManager sharedMEGASdk] createAccountWithEmail:[self.emailTextField text] password:[self.passwordTextField text] name:[self.nameTextField text] delegate:self];
    }
}

- (BOOL)validateForm {
    if (![self validateName:self.nameTextField.text]) {
        [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"nameInvalidFormat", @"Enter a valid name")];
        [self.nameTextField becomeFirstResponder];
        return NO;
    } else if (![self validateEmail:self.emailTextField.text]) {
        [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"emailInvalidFormat", @"Enter a valid email")];
        [self.emailTextField becomeFirstResponder];
        return NO;
    } else if (![self validatePassword:self.passwordTextField.text]) {
        if ([self.passwordTextField.text length] == 0) {
            [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"passwordInvalidFormat", @"Enter a valid password")];
            [self.passwordTextField becomeFirstResponder];
        } else {
            [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"passwordsDoNotMatch", @"Passwords do not match")];
            [self.retypePasswordTextField becomeFirstResponder];
        }
        return NO;
    } else if (![self.termsCheckboxButton isSelected]) {
        [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"termsCheckboxUnselected", @"You need to agree with the terms of service to register an account on MEGA.")];
        return NO;
    }
    return YES;
}

- (BOOL)validateName:(NSString *)name {
    if (name.length == 0) {
        return NO;
    } else {
        return YES;
    }
}

- (BOOL)validatePassword:(NSString *)password {
    if (password.length == 0 || ![password isEqualToString:self.retypePasswordTextField.text]) {
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

- (IBAction)loginTouchUpInside:(id)sender {
    [self.nameTextField resignFirstResponder];
    [self.emailTextField resignFirstResponder];
    [self.passwordTextField resignFirstResponder];
    [self.retypePasswordTextField resignFirstResponder];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UITextFieldDelegate

-(BOOL)textFieldShouldReturn:(UITextField *)textField {

    switch ([textField tag]) {
        case 0:
            [self.emailTextField becomeFirstResponder];
            break;
            
        case 1:
            [self.passwordTextField becomeFirstResponder];
            break;
            
        case 2:
            [self.retypePasswordTextField becomeFirstResponder];
            break;
            
        case 3:
            [self.retypePasswordTextField resignFirstResponder];
            break;
            
        default:
            break;
    }
    
    return YES;
}

#pragma mark - MEGARequestDelegate

- (void)onRequestStart:(MEGASdk *)api request:(MEGARequest *)request {
}

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    if ([error type]) {
        switch ([error type]) {
                
            case MEGAErrorTypeApiEExist: {
                [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"emailAlreadyRegistered", @"This e-mail address has already registered an account with MEGA")];
                [self.emailTextField becomeFirstResponder];
                break;
            }
                
            default:
                break;
        }
        return;
    }
    
    switch ([request type]) {
        case MEGARequestTypeCreateAccount: {
            
            [self.nameTextField setEnabled:NO];
            [self.emailTextField setEnabled:NO];
            [self.passwordTextField setEnabled:NO];
            [self.retypePasswordTextField setEnabled:NO];
            [self.termsCheckboxButton setUserInteractionEnabled:NO];
            [self.createAccountButton setEnabled:NO];
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"awesome", @"Awesome")
                                                            message:NSLocalizedString(@"accountCreated", @"Please check your e-mail and click the link to confirm your account.")
                                                           delegate:self
                                                  cancelButtonTitle:NSLocalizedString(@"ok", @"OK")
                                                  otherButtonTitles:nil];
            [alert show];
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
