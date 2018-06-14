
#import "EnablingTwoFactorAuthenticationTableViewController.h"

#import "SVProgressHUD.h"

#import "MEGASdkManager.h"
#import "UIApplication+MNZCategory.h"
#import "UIImage+MNZCategory.h"

#import "CustomModalAlertViewController.h"

@interface EnablingTwoFactorAuthenticationTableViewController () <UITextViewDelegate, MEGARequestDelegate>

@property (weak, nonatomic) IBOutlet UILabel *firstSectionLabel;

@property (weak, nonatomic) IBOutlet UIImageView *seedQrImageView;
@property (weak, nonatomic) IBOutlet UITextView *seedTextView;

@property (weak, nonatomic) IBOutlet UILabel *secondSectionLabel;
@property (weak, nonatomic) IBOutlet UILabel *secondSectionDescriptionLabel;

@property (weak, nonatomic) IBOutlet UITextField *codeTextField;

@property (weak, nonatomic) IBOutlet UIButton *verifyButton;

@end

@implementation EnablingTwoFactorAuthenticationTableViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = AMLocalizedString(@"twoFactorAuthentication", @"");
    
    self.firstSectionLabel.text = AMLocalizedString(@"scanOrCopyTheSeed", @"");
    self.seedTextView.text = self.seed;
    NSString *qrString = [NSString stringWithFormat:@"otpauth://totp/MEGA:%@?secret=%@&issuer=MEGA", [[MEGASdkManager sharedMEGASdk] myEmail], self.seed];
    self.seedQrImageView.image = [UIImage mnz_qrImageFromString:qrString withSize:self.seedQrImageView.frame.size color:UIColor.blackColor];
    
    self.secondSectionLabel.text = AMLocalizedString(@"testAuthenticator", @"");
    self.secondSectionDescriptionLabel.text = AMLocalizedString(@"testAuthenticatorDescription", @"");
    self.codeTextField.placeholder = AMLocalizedString(@"sixDigitCode", @"");
    
    [self.verifyButton setTitle:AMLocalizedString(@"verify", @"") forState:UIControlStateNormal];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard)];
    tapGesture.cancelsTouchesInView = NO;
    [self.tableView addGestureRecognizer:tapGesture];
}

#pragma mark - Private

- (void)hideKeyboard {
    [self.view endEditing:YES];
}

- (void)noAuthenticatorAppInstaledAlert {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"noAuthenticatorAppInstalled", @"") message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"ok", nil) style:UIAlertActionStyleCancel handler:nil]];
    
    [UIApplication.mnz_visibleViewController presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - IBActions

- (IBAction)openInAuthenticatorApp:(id)sender {
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"otpauth://totp/MEGA:%@?secret=%@&issuer=MEGA", [[MEGASdkManager sharedMEGASdk] myEmail], self.seed]];
    if (@available(iOS 9.0, *)) {
        if ([[UIApplication sharedApplication] openURL:url]) {
            MEGALogInfo(@"URL opened on authenticator app");
        } else {
            MEGALogInfo(@"URL NOT opened");
            [self noAuthenticatorAppInstaledAlert];
        }
    } else {
        [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:^(BOOL success) {
            if (success) {
                MEGALogInfo(@"URL opened on authenticator app");
            } else {
                MEGALogInfo(@"URL NOT opened");
                [self noAuthenticatorAppInstaledAlert];
            }
        }];
    }
}

- (IBAction)verifyTouchUpInside:(UIButton *)sender {
    [self.codeTextField resignFirstResponder];
    
    if (self.codeTextField.text.length == 6) {
        [[MEGASdkManager sharedMEGASdk] multiFactorAuthEnableWithPin:self.codeTextField.text delegate:self];
    }
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    if (action == @selector(copy:)) return YES;
    
    return NO;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSString *resultingText = [textField.text stringByReplacingCharactersInRange:range withString:string];
    
    self.verifyButton.backgroundColor = (resultingText.length == 6) ? UIColor.mnz_redFF4D52 : UIColor.mnz_grayEEEEEE;
    
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self verifyTouchUpInside:self.verifyButton];
    
    return YES;
}

#pragma mark - MEGARequestDelegate

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    if (error.type) {
        switch (error.type) {
            case MEGAErrorTypeApiEFailed:
            case MEGAErrorTypeApiEExpired:
                [SVProgressHUD showErrorWithStatus:AMLocalizedString(@"invalidCode", @"Error text shown when the user scans a QR that is not valid. String as short as possible.")];
                break;
                
            default:
                [SVProgressHUD showErrorWithStatus:error.name];
                break;
        }
        return;
    }
    
    switch (request.type) {
        case MEGARequestTypeMultiFactorAuthSet: {
            if (request.flag) {
                CustomModalAlertViewController *customModalAlertVC = [[CustomModalAlertViewController alloc] init];
                customModalAlertVC.modalPresentationStyle = UIModalPresentationOverCurrentContext;
                customModalAlertVC.image = [UIImage imageNamed:@""];
                customModalAlertVC.viewTitle = AMLocalizedString(@"twoFactorAuthenticationEnabled", @"");
                customModalAlertVC.detail = AMLocalizedString(@"twoFactorAuthenticationEnabledDescription", @"");
                customModalAlertVC.action = AMLocalizedString(@"close", @"");
                
                __weak typeof(CustomModalAlertViewController) *weakCustom = customModalAlertVC;
                customModalAlertVC.completion = ^{
                    [weakCustom dismissViewControllerAnimated:YES completion:^{
                        [self.navigationController popToViewController:self.navigationController.viewControllers[2] animated:YES];
                    }];
                };
                
                [UIApplication.mnz_visibleViewController presentViewController:customModalAlertVC animated:YES completion:nil];
            }
            break;
        }
            
        default:
            break;
    }
}

@end
