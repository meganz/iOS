
#import "TwoFactorAuthenticationViewController.h"

#import "SVProgressHUD.h"

#import "MEGALoginRequestDelegate.h"
#import "MEGASdkManager.h"
#import "NSString+MNZCategory.h"
#import "UIApplication+MNZCategory.h"

#import "CustomModalAlertViewController.h"

@interface TwoFactorAuthenticationViewController () <UITextViewDelegate, MEGARequestDelegate>

@property (weak, nonatomic) IBOutlet UILabel *authenticatorAppLabel;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;

@property (weak, nonatomic) IBOutlet UIImageView *invalidCodeImageView;
@property (weak, nonatomic) IBOutlet UILabel *invalidCodeLabel;

@property (weak, nonatomic) IBOutlet UIButton *lostYourAuthenticatorDeviceButton;

@property (weak, nonatomic) IBOutlet UIButton *verifyButton;

@end

@implementation TwoFactorAuthenticationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    
    self.navigationItem.title = AMLocalizedString(@"twoFactorAuthentication", @"");
    
    self.authenticatorAppLabel.text = AMLocalizedString(@"authenticatorApp", @"");
    self.descriptionLabel.text = AMLocalizedString(@"authenticatorAppDescription", @"");
    
    self.invalidCodeLabel.text = AMLocalizedString(@"invalidCode", @"Error text shown when the user scans a QR that is not valid. String as short as possible.");
    
    [self.lostYourAuthenticatorDeviceButton setTitle:AMLocalizedString(@"lostYourAuthenticationDevice", @"") forState:UIControlStateNormal];
    
    [self.verifyButton setTitle:AMLocalizedString(@"verify", @"") forState:UIControlStateNormal];
    
    UITextView *firstTextView = [self.view viewWithTag:1];
    [firstTextView becomeFirstResponder];
}

#pragma mark - Private

- (void)previousTextViewShouldBecomeFirstResponder:(UITextView *)textView {
    NSInteger currentTextViewTag = textView.tag;
    if (currentTextViewTag == 1) {
        [textView becomeFirstResponder];
    } else {
        NSInteger previousTextViewTag = currentTextViewTag - 1;
        UITextView *previousTextView = [self.view viewWithTag:previousTextViewTag];
        [previousTextView becomeFirstResponder];
    }
}

- (void)nextTextViewShouldBecomeFirstResponder:(UITextView *)textView {
    NSInteger currentTextViewTag = textView.tag;
    if (currentTextViewTag >= 1) {
        if (currentTextViewTag == 6) {
            [textView resignFirstResponder];
            //Finished introducing the code
            [self verifyTouchUpInside:self.verifyButton];
        } else {
            NSInteger nextTextViewTag = currentTextViewTag + 1;
            UITextView *nextTextView = [self.view viewWithTag:nextTextViewTag];
            [nextTextView becomeFirstResponder];
        }
    }
}

- (BOOL)validateCode {
    for (NSInteger i = 1; i < 7; i++) {
        UITextView *textView = (UITextView *)[self.view viewWithTag:i];
        if ((textView.text.length == 0) || textView.text.mnz_isEmpty) {
            [textView becomeFirstResponder];
            
            return NO;
        }
    }
    
    return YES;
}

- (NSString *)code {
    NSString *code = [NSString new];
    for (NSInteger i = 1; i < 7; i++) {
        UITextView *textView = (UITextView *)[self.view viewWithTag:i];
        code = [code stringByAppendingString:textView.text];
    }
    
    return code;
}

- (void)tintCodeWithColor:(UIColor *)color {
    for (NSInteger i = 1; i < 7; i++) {
        UITextView *textView = (UITextView *)[self.view viewWithTag:i];
        textView.textColor = color;
    }
}

- (void)distributeCode:(NSString *)code {
    for (NSInteger i = 0; i < code.length; i++) {
        NSRange range = NSMakeRange(i, 1);
        NSString *character = [code substringWithRange:range];
        
        UITextView *textView = (UITextView *)[self.view viewWithTag:(i + 1)];
        textView.text = character;
    }
}

- (void)showInvalidCode {
    [self tintCodeWithColor:UIColor.mnz_redD90007];
    self.invalidCodeImageView.hidden = self.invalidCodeLabel.hidden = NO;
    self.verifyButton.backgroundColor = UIColor.mnz_grayEEEEEE;
}

#pragma mark - IBActions

- (IBAction)lostYourAuthenticatorDeviceTouchUpInside:(UIButton *)sender {
    
}

- (IBAction)verifyTouchUpInside:(UIButton *)sender {
    if ([self validateCode]) {
        NSString *code = [self code];
        
        switch (self.twoFAMode) {
            case TwoFactorAuthenticationLogin: {
                MEGALoginRequestDelegate *loginRequestDelegate = [[MEGALoginRequestDelegate alloc] init];
                loginRequestDelegate.errorCompletion = ^(MEGAError *error) {
                    switch (error.type) {
                        case MEGAErrorTypeApiENoent:
                            [self.navigationController popViewControllerAnimated:YES];
                            break;
                            
                        case MEGAErrorTypeApiEFailed:
                            [self showInvalidCode];
                            break;
                            
                        default:
                            break;
                    }
                };
                [[MEGASdkManager sharedMEGASdk] multiFactorAuthLoginWithEmail:self.email password:self.password pin:code delegate:loginRequestDelegate];
                break;
            }
                
            case TwoFactorAuthenticationChangePassword:
                [[MEGASdkManager sharedMEGASdk] multiFactorAuthChangePassword:nil newPassword:self.newerPassword pin:code delegate:self];
                break;
                
            case TwoFactorAuthenticationChangeEmail:
                [[MEGASdkManager sharedMEGASdk] multiFactorAuthChangeEmail:self.email pin:code delegate:self];
                break;
                
            case TwoFactorAuthenticationCancelAccount:
                [[MEGASdkManager sharedMEGASdk] multiFactorAuthCancelAccountWithPin:code delegate:self];
                break;
                
            case TwoFactorAuthenticationEnable:
                [[MEGASdkManager sharedMEGASdk] multiFactorAuthEnableWithPin:code delegate:self];
                break;
                
            case TwoFactorAuthenticationDisable:
                 [[MEGASdkManager sharedMEGASdk] multiFactorAuthDisableWithPin:code delegate:self];
                break;
                
            default:
                break;
        }
    }
}

#pragma mark - UITextViewDelegate

- (void)textViewDidBeginEditing:(UITextView *)textView {
    //When a text view become first responder, the cursor should be at the end of text view.
    dispatch_async(dispatch_get_main_queue(), ^{
        UITextPosition *end = textView.endOfDocument;
        textView.selectedTextRange = [textView textRangeFromPosition:end toPosition:end];
    });
    
    [self tintCodeWithColor:UIColor.mnz_black333333];
    self.invalidCodeImageView.hidden = self.invalidCodeLabel.hidden = YES;
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    NSString *code = [self code];
    self.verifyButton.backgroundColor = (code.length == 6) ? UIColor.mnz_redFF4D52 : UIColor.mnz_grayEEEEEE;
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if (![text mnz_isDecimalNumber]) {
        return NO;
    }
    
    if (text.length == 6 && [text mnz_isDecimalNumber]) {
        //Code copied in any text view
        [self distributeCode:text];
        
        [textView resignFirstResponder];
        return NO;
    }
    
    NSString *resultingText = [textView.text stringByReplacingCharactersInRange:range withString:text];
    if ((textView.text.length == 0 || textView.text.mnz_isEmpty) && (resultingText.length == 0 || resultingText.mnz_isEmpty)) {
        textView.text = resultingText;
        [self previousTextViewShouldBecomeFirstResponder:textView];
        return NO;
    } else if ((textView.text.length == 1) && (range.location == 0) && text.mnz_isEmpty) {
        textView.text = @"";
        return NO;
    } else if (textView.text.length == 0) {
        textView.text = text;
        [self nextTextViewShouldBecomeFirstResponder:textView];
        return NO;
    } else if (textView.text.length >= 1) {
        textView.text = text;
        [self nextTextViewShouldBecomeFirstResponder:textView];
        return NO;
    }
    
    return YES;
}


#pragma mark - MEGARequestDelegate

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    if (error.type) {
        switch (error.type) {
            case MEGAErrorTypeApiEFailed:
            case MEGAErrorTypeApiEExpired:
                [self showInvalidCode];
                break;
                
            default:
                [SVProgressHUD showErrorWithStatus:error.name];
                break;
        }
        return;
    }
    
    switch (request.type) {
        case MEGARequestTypeChangePassword: {
            [SVProgressHUD showSuccessWithStatus:AMLocalizedString(@"passwordChanged", @"The label showed when your password has been changed")];
            
            [self.navigationController popToViewController:self.navigationController.viewControllers[2] animated:YES];
            break;
        }
            
        case MEGARequestTypeGetChangeEmailLink:
        case MEGARequestTypeGetCancelLink: {
            [self.navigationController popViewControllerAnimated:YES];
            break;
        }
            
        case MEGARequestTypeMultiFactorAuthSet:
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
            } else {
                
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"twoFactorAuthenticationDisabled", @"") message:message preferredStyle:UIAlertControllerStyleAlert];
                
                [alertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"ok", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
                    [self.navigationController popToViewController:self.navigationController.viewControllers[2] animated:YES];
                }]];
                
                [self presentViewController:alertController animated:YES completion:nil];
            }
            break;
            
        default:
            break;
    }
}

@end
