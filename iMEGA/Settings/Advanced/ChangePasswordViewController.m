/**
 * @file ChangePasswordViewController.m
 * @brief View controller that allows change the password
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

#import "ChangePasswordViewController.h"
#import "MEGASdkManager.h"
#import "SVProgressHUD.h"

@interface ChangePasswordViewController () <MEGARequestDelegate>

@property (weak, nonatomic) IBOutlet UIView *changePasswordView;

@property (weak, nonatomic) IBOutlet UITextField *oldPasswordTextField;
@property (weak, nonatomic) IBOutlet UITextField *theNewPasswordTextField;
@property (weak, nonatomic) IBOutlet UITextField *retypeNewPasswordTextField;

@property (weak, nonatomic) IBOutlet UIButton *changePasswordButton;

@end

@implementation ChangePasswordViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.navigationItem setTitle:AMLocalizedString(@"changePasswordLabel", @"The title of the change password view")];
    
    self.changePasswordButton.layer.cornerRadius = 6;
    self.changePasswordButton.layer.masksToBounds = YES;
    
    self.changePasswordView.backgroundColor = [[UIColor colorWithWhite:0.933 alpha:1.000] colorWithAlphaComponent:.25f];
    self.changePasswordView.layer.borderWidth = 2.0f;
    self.changePasswordView.layer.borderColor =[[UIColor colorWithWhite:0.933 alpha:1.000] CGColor];
    self.changePasswordView.layer.cornerRadius = 6;
    self.changePasswordView.layer.masksToBounds = YES;
    
    [self.oldPasswordTextField becomeFirstResponder];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)validateForm {
    if (self.oldPasswordTextField.text.length == 0) {
        [SVProgressHUD showErrorWithStatus:AMLocalizedString(@"passwordInvalidFormat", @"Enter a valid password")];
        [self.oldPasswordTextField becomeFirstResponder];
        return NO;
    }
    if (![self validatePassword:self.theNewPasswordTextField.text]) {
        if ([self.theNewPasswordTextField.text length] == 0) {
            [SVProgressHUD showErrorWithStatus:AMLocalizedString(@"passwordInvalidFormat", @"Enter a valid password")];
            [self.theNewPasswordTextField becomeFirstResponder];
        } else {
            [SVProgressHUD showErrorWithStatus:AMLocalizedString(@"passwordsDoNotMatch", @"Passwords do not match")];
            [self.theNewPasswordTextField setText:@""];
            [self.retypeNewPasswordTextField setText:@""];
            [self.theNewPasswordTextField becomeFirstResponder];
        }
        return NO;
    }
    
    if ([self.oldPasswordTextField.text isEqualToString:self.theNewPasswordTextField.text]) {
        [SVProgressHUD showErrorWithStatus:AMLocalizedString(@"oldAndNewPasswordMatch", @"The old and the new password can not match")];
        [self.theNewPasswordTextField setText:@""];
        [self.retypeNewPasswordTextField setText:@""];
        [self.theNewPasswordTextField becomeFirstResponder];
        return NO;
    }
    
    return YES;
}

- (BOOL)validatePassword:(NSString *)password {
    if (password.length == 0 || ![password isEqualToString:self.retypeNewPasswordTextField.text]) {
        return NO;
    } else {
        return YES;
    }
}

#pragma mark - IBAction

- (IBAction)changePasswordTouchUpIndise:(UIButton *)sender {
    if ([self validateForm]) {
        [[MEGASdkManager sharedMEGASdk] changePassword:[self.oldPasswordTextField text] newPassword:[self.theNewPasswordTextField text] delegate:self];
    }
}

#pragma mark - MEGARequestDelegate

- (void)onRequestStart:(MEGASdk *)api request:(MEGARequest *)request {
}

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    if ([error type]) {
        [self.oldPasswordTextField setText:@""];
        [self.theNewPasswordTextField setText:@""];
        [self.retypeNewPasswordTextField setText:@""];
        [self.oldPasswordTextField becomeFirstResponder];
        [SVProgressHUD showErrorWithStatus:AMLocalizedString(@"passwordInvalidFormat", @"Enter a valid password")];
        return;
    }
    
    if ([request type] == MEGARequestTypeChangePassword) {
        [SVProgressHUD showSuccessWithStatus:AMLocalizedString(@"passwordChanged", @"The label showed when your password has been changed")];
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)onRequestTemporaryError:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
}


@end
