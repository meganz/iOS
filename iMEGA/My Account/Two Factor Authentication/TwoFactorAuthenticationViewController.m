#import "TwoFactorAuthenticationViewController.h"

#import "SVProgressHUD.h"

#import "Helper.h"
#import "MEGALoginRequestDelegate.h"
#import "MEGA-Swift.h"
#import "NSString+MNZCategory.h"
#import "NSURL+MNZCategory.h"
#import "UIApplication+MNZCategory.h"

#import "MEGANavigationController.h"

@import MEGAL10nObjc;

@interface TwoFactorAuthenticationViewController () <UITextViewDelegate, MEGARequestDelegate>

@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;

@property (weak, nonatomic) IBOutlet UIView *firstDigitContainerView;
@property (weak, nonatomic) IBOutlet UIView *secondDigitContainerView;
@property (weak, nonatomic) IBOutlet UIView *thirdDigitContainerView;
@property (weak, nonatomic) IBOutlet UIView *fourthDigitContainerView;
@property (weak, nonatomic) IBOutlet UIView *fifthDigitContainerView;
@property (weak, nonatomic) IBOutlet UIView *sixthDigitContainerView;

@property (weak, nonatomic) IBOutlet UIImageView *invalidCodeImageView;
@property (weak, nonatomic) IBOutlet UILabel *invalidCodeLabel;

@property (weak, nonatomic) IBOutlet UIButton *lostYourAuthenticatorDeviceButton;
@property (weak, nonatomic) IBOutlet UIImageView *lostYourAuthenticatorDeviceImage;

@property (nonatomic) NSString *invalidCode;

@end

@implementation TwoFactorAuthenticationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    
    self.navigationItem.title = LocalizedString(@"twoFactorAuthentication", @"");
    
    self.descriptionLabel.text = LocalizedString(@"pleaseEnterTheSixDigitCode", @"A message on the Verify Login page telling the user to enter their 2FA code.");
    
    self.invalidCodeLabel.text = LocalizedString(@"invalidCode", @"Error text shown when the user scans a QR that is not valid. String as short as possible.");
    
    [self.lostYourAuthenticatorDeviceButton setTitle:LocalizedString(@"lostYourAuthenticatorDevice", @"A button to help them restore their account if they have lost their 2FA device.") forState:UIControlStateNormal];
    if (self.twoFAMode != TwoFactorAuthenticationEnable) {
        self.lostYourAuthenticatorDeviceButton.hidden = self.lostYourAuthenticatorDeviceImage.hidden = NO;
        self.lostYourAuthenticatorDeviceButton.enabled = YES;
    }
    
    UITextView *firstTextView = [self.view viewWithTag:1];
    [firstTextView becomeFirstResponder];
    
    [self updateAppearance];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    
    if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
        [self updateAppearance];
    }
}

#pragma mark - Private

- (void)updateAppearance {
    self.view.backgroundColor = [self defaultBackgroundColor];

    self.firstDigitContainerView.backgroundColor = [self defaultBackgroundColor];
    self.secondDigitContainerView.backgroundColor = [self defaultBackgroundColor];
    self.thirdDigitContainerView.backgroundColor = [self defaultBackgroundColor];
    self.fourthDigitContainerView.backgroundColor = [self defaultBackgroundColor];
    self.fifthDigitContainerView.backgroundColor = [self defaultBackgroundColor];
    self.sixthDigitContainerView.backgroundColor = [self defaultBackgroundColor];

    self.firstDigitContainerView.layer.borderColor = [self separatorColor].CGColor;
    self.secondDigitContainerView.layer.borderColor = [self separatorColor].CGColor;
    self.thirdDigitContainerView.layer.borderColor = [self separatorColor].CGColor;
    self.fourthDigitContainerView.layer.borderColor = [self separatorColor].CGColor;
    self.fifthDigitContainerView.layer.borderColor = [self separatorColor].CGColor;
    self.sixthDigitContainerView.layer.borderColor = [self separatorColor].CGColor;

    self.invalidCodeLabel.textColor = [self errorColor];
    self.invalidCodeImageView.tintColor = [self errorColor];
    [self.lostYourAuthenticatorDeviceButton setTitleColor:[self labelColor] forState:UIControlStateNormal];
}

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
            [self verifyCode];
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
    [self tintCodeWithColor:UIColor.systemRedColor];
    self.invalidCodeImageView.hidden = self.invalidCodeLabel.hidden = NO;
}

- (void)verifyCode {
    if ([self validateCode]) {
        NSString *code = [self code];
        if ([code isEqualToString:self.invalidCode]) {
            [self showInvalidCode];
            return;
        }
        
        switch (self.twoFAMode) {
            case TwoFactorAuthenticationLogin: {
                __weak TwoFactorAuthenticationViewController *weakSelf = self;
                MEGALoginRequestDelegate *loginRequestDelegate = [[MEGALoginRequestDelegate alloc] init];
                loginRequestDelegate.errorCompletion = ^(MEGAError *error) {
                    switch (error.type) {
                        case MEGAErrorTypeApiENoent:
                            [weakSelf.navigationController popViewControllerAnimated:YES];
                            break;
                            
                        case MEGAErrorTypeApiEFailed:
                        case MEGAErrorTypeApiEExpired:
                            weakSelf.invalidCode = code;
                            [weakSelf showInvalidCode];
                            break;
                            
                        default:
                            break;
                    }
                };
                [MEGASdk.shared multiFactorAuthLoginWithEmail:self.email password:self.password pin:code delegate:loginRequestDelegate];
                break;
            }
                
            case TwoFactorAuthenticationChangePassword:
            case TwoFactorAuthenticationChangePasswordFromLogout:
                [MEGASdk.shared multiFactorAuthChangePassword:nil newPassword:self.newerPassword pin:code delegate:self];
                break;
                
            case TwoFactorAuthenticationChangeEmail:
                [MEGASdk.shared multiFactorAuthChangeEmail:self.email pin:code delegate:self];
                break;
                
            case TwoFactorAuthenticationCancelAccount:
                [MEGASdk.shared multiFactorAuthCancelAccountWithPin:code delegate:self];
                break;
                
            case TwoFactorAuthenticationEnable:
                [MEGASdk.shared multiFactorAuthEnableWithPin:code delegate:self];
                break;
                
            case TwoFactorAuthenticationDisable:
                 [MEGASdk.shared multiFactorAuthDisableWithPin:code delegate:self];
                break;
                
            default:
                break;
        }
    }
}


#pragma mark - IBActions

- (IBAction)lostYourAuthenticatorDeviceTouchUpInside:(UIButton *)sender {
    [[NSURL URLWithString:@"https://mega.nz/recovery"] mnz_presentSafariViewController];
}

#pragma mark - UITextViewDelegate

- (void)textViewDidBeginEditing:(UITextView *)textView {
    //When a text view become first responder, the cursor should be at the end of text view.
    dispatch_async(dispatch_get_main_queue(), ^{
        UITextPosition *end = textView.endOfDocument;
        textView.selectedTextRange = [textView textRangeFromPosition:end toPosition:end];
    });
    
    [self tintCodeWithColor:UIColor.labelColor];
    self.invalidCodeImageView.hidden = self.invalidCodeLabel.hidden = YES;
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if (![text mnz_isDecimalNumber]) {
        return NO;
    }
    
    if (text.length == 6 && [text mnz_isDecimalNumber]) {
        if ([text isEqualToString:self.invalidCode]) {
            [self showInvalidCode];
            return NO;
        }
        
        //Code copied in any text view
        [self distributeCode:text];
        [self verifyCode];
        
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

#pragma mark - UIResponder

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    NSString *code = [self code];
    if (code.mnz_isEmpty) {
        return;
    }
    
    if ([code isEqualToString:self.invalidCode]) {
        [self showInvalidCode];
        return;
    }
    
    [self.view endEditing:YES];
    [self verifyCode];
}

#pragma mark - MEGARequestDelegate

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    if (error.type) {
        switch (error.type) {
            case MEGAErrorTypeApiEFailed:
            case MEGAErrorTypeApiEExpired:
                self.invalidCode = request.password;
                [self showInvalidCode];
                break;
                
            default:
                [SVProgressHUD showErrorWithStatus:LocalizedString(error.name, @"")];
                break;
        }
        return;
    }
    
    self.invalidCode = nil;
    switch (request.type) {
        case MEGARequestTypeChangePassword: {
            [SVProgressHUD showSuccessWithStatus:LocalizedString(@"passwordChanged", @"The label showed when your password has been changed")];
            
            if (self.twoFAMode == TwoFactorAuthenticationChangePassword) {
                [self.navigationController dismissViewControllerAnimated:YES completion:nil];
            } else if (self.twoFAMode == TwoFactorAuthenticationChangePasswordFromLogout) {
                [MEGASdk.shared logout];
            }
            break;
        }
            
        case MEGARequestTypeGetChangeEmailLink:
        case MEGARequestTypeGetCancelLink: {
            [self.navigationController popViewControllerAnimated:YES];
            [[NSNotificationCenter defaultCenter] postNotificationName:MEGAAwaitingEmailConfirmationNotification object:nil];
            break;
        }
            
        case MEGARequestTypeMultiFactorAuthSet:
            if (request.flag) {
                MEGANavigationController *navigationController = [[UIStoryboard storyboardWithName:@"TwoFactorAuthentication" bundle:nil] instantiateViewControllerWithIdentifier:@"EnabledTwoFactorAuthenticationNavigationControllerID"];
                
                [UIApplication.mnz_presentingViewController presentViewController:navigationController animated:YES completion:nil];

                //Go back to the enable Two-Factor Authentication view or to the Cloud Drive
                if (self.navigationController.viewControllers.count > 3) {
                    [self.navigationController popToViewController:self.navigationController.viewControllers[3] animated:YES];
                } else {
                    [self.navigationController popToRootViewControllerAnimated:YES];
                }
            } else {
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:LocalizedString(@"twoFactorAuthenticationDisabled", @"A message on a dialog to say that 2FA has been successfully disabled.") message:nil preferredStyle:UIAlertControllerStyleAlert];
                
                [alertController addAction:[UIAlertAction actionWithTitle:LocalizedString(@"ok", @"") style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
                    [self.navigationController popViewControllerAnimated:YES];
                }]];
                
                [self presentViewController:alertController animated:YES completion:nil];
            }
            break;
            
        default:
            break;
    }
}

@end
