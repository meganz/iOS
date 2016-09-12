#import "ChangePasswordViewController.h"
#import "MEGASdkManager.h"
#import "MEGAReachabilityManager.h"
#import "SVProgressHUD.h"

@interface ChangePasswordViewController () <MEGARequestDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *currentPasswordImageView;
@property (weak, nonatomic) IBOutlet UITextField *currentPasswordTextField;
@property (weak, nonatomic) IBOutlet UIImageView *theNewPasswordImageView;
@property (weak, nonatomic) IBOutlet UITextField *theNewPasswordTextField;
@property (weak, nonatomic) IBOutlet UIImageView *confirmPasswordImageView;
@property (weak, nonatomic) IBOutlet UITextField *confirmPasswordTextField;

@property (weak, nonatomic) IBOutlet UIButton *changePasswordButton;

@end

@implementation ChangePasswordViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.navigationItem setTitle:AMLocalizedString(@"changePasswordLabel", @"The title of the change password view")];
    
    [_currentPasswordTextField setPlaceholder:AMLocalizedString(@"currentPassword", @"Placeholder text to explain that the current password should be written on this text field.")];
    [_theNewPasswordTextField setPlaceholder:AMLocalizedString(@"newPassword", @"Placeholder text to explain that the new password should be written on this text field.")];
    [_confirmPasswordTextField setPlaceholder:AMLocalizedString(@"confirmPassword", @"Placeholder text to explain that the new password should be re-written on this text field.")];
    
    [_changePasswordButton setTitle:AMLocalizedString(@"changePasswordLabel", nil) forState:UIControlStateNormal];
    [self.changePasswordButton.layer setBorderWidth:2.0f];
    [self.changePasswordButton.layer setBorderColor:[[UIColor mnz_redD90007] CGColor]];
    [self.changePasswordButton.layer setCornerRadius:4];
    [self.changePasswordButton.layer setMasksToBounds:YES];
    
    [_currentPasswordTextField becomeFirstResponder];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)validateForm {
    if (_currentPasswordTextField.text.length == 0) {
        [SVProgressHUD showErrorWithStatus:AMLocalizedString(@"passwordInvalidFormat", @"Enter a valid password")];
        [_currentPasswordTextField becomeFirstResponder];
        return NO;
    }
    if (![self validatePassword:self.theNewPasswordTextField.text]) {
        if ([self.theNewPasswordTextField.text length] == 0) {
            [SVProgressHUD showErrorWithStatus:AMLocalizedString(@"passwordInvalidFormat", @"Enter a valid password")];
            [self.theNewPasswordTextField becomeFirstResponder];
        } else {
            [SVProgressHUD showErrorWithStatus:AMLocalizedString(@"passwordsDoNotMatch", @"Passwords do not match")];
            [self.theNewPasswordTextField setText:@""];
            [self.confirmPasswordTextField setText:@""];
            [self.theNewPasswordTextField becomeFirstResponder];
        }
        return NO;
    }
    
    if ([_currentPasswordTextField.text isEqualToString:self.theNewPasswordTextField.text]) {
        [SVProgressHUD showErrorWithStatus:AMLocalizedString(@"oldAndNewPasswordMatch", @"The old and the new password can not match")];
        [self.theNewPasswordTextField setText:@""];
        [self.confirmPasswordTextField setText:@""];
        [self.theNewPasswordTextField becomeFirstResponder];
        return NO;
    }
    
    return YES;
}

- (BOOL)validatePassword:(NSString *)password {
    if (password.length == 0 || ![password isEqualToString:_confirmPasswordTextField.text]) {
        return NO;
    } else {
        return YES;
    }
}

#pragma mark - IBAction

- (IBAction)changePasswordTouchUpIndise:(UIButton *)sender {
    if ([self validateForm]) {
        [_changePasswordButton setEnabled:NO];
        if ([MEGAReachabilityManager isReachableHUDIfNot]) {
            [[MEGASdkManager sharedMEGASdk] changePassword:[_currentPasswordTextField text] newPassword:[self.theNewPasswordTextField text] delegate:self];
        } else {
            [_changePasswordButton setEnabled:YES];
        }
    }
}

#pragma mark - UITextFieldDelegate

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    
    switch ([textField tag]) {
        case 0:
            [self.theNewPasswordTextField becomeFirstResponder];
            break;
            
        case 1:
            [_confirmPasswordTextField becomeFirstResponder];
            break;
            
        case 2:
            [_confirmPasswordTextField resignFirstResponder];
            break;
            
        default:
            break;
    }
    
    return YES;
}

#pragma mark - MEGARequestDelegate

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    if ([error type]) {
        [_currentPasswordTextField setText:@""];
        [self.theNewPasswordTextField setText:@""];
        [_confirmPasswordTextField setText:@""];
        [_currentPasswordTextField becomeFirstResponder];
        [SVProgressHUD showErrorWithStatus:AMLocalizedString(@"passwordInvalidFormat", @"Enter a valid password")];
        [_changePasswordButton setEnabled:YES];
        return;
    }
    
    if ([request type] == MEGARequestTypeChangePassword) {
        [SVProgressHUD showSuccessWithStatus:AMLocalizedString(@"passwordChanged", @"The label showed when your password has been changed")];
        [self.navigationController popViewControllerAnimated:YES];
    }
}

@end
