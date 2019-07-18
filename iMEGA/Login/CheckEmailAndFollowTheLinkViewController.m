
#import "CheckEmailAndFollowTheLinkViewController.h"

#import "SAMKeychain.h"

#import "NSString+MNZCategory.h"

#import "InputView.h"
#import "Helper.h"
#import "MEGALoginRequestDelegate.h"
#import "MEGASendSignupLinkRequestDelegate.h"
#import "MEGAReachabilityManager.h"
#import "MEGASdkManager.h"

@interface CheckEmailAndFollowTheLinkViewController () <UITextFieldDelegate, MEGAGlobalDelegate>

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mailImageTopLayoutConstraint;
@property (weak, nonatomic) IBOutlet UIImageView *mailImageView;
@property (weak, nonatomic) IBOutlet UILabel *awaitingEmailConfirmationLabel;
@property (weak, nonatomic) IBOutlet UILabel *checkYourEmailLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *checkYourEmailBottomLayoutConstraint;
@property (weak, nonatomic) IBOutlet InputView *emailInputView;
@property (weak, nonatomic) IBOutlet UILabel *misspelledLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *resendButtonTopLayoutConstraint;
@property (weak, nonatomic) IBOutlet UIButton *resendButton;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;

@property (nonatomic, copy) NSString *email;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *base64pwkey;

@end

@implementation CheckEmailAndFollowTheLinkViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.email = [SAMKeychain passwordForService:@"MEGA" account:@"email"];
    self.name = [SAMKeychain passwordForService:@"MEGA" account:@"name"];
    self.base64pwkey = [SAMKeychain passwordForService:@"MEGA" account:@"base64pwkey"];
    
    if (UIDevice.currentDevice.iPhone4X) {
        self.mailImageTopLayoutConstraint.constant = 24.0f;
        self.checkYourEmailBottomLayoutConstraint.constant = 6.0f;
        self.resendButtonTopLayoutConstraint.constant = 20.0f;
    } else if (UIDevice.currentDevice.iPhone5X) {
        self.mailImageTopLayoutConstraint.constant = 24.0f;
    }

    self.awaitingEmailConfirmationLabel.text = AMLocalizedString(@"awaitingEmailConfirmation", @"Title shown just after doing some action that requires confirming the action by an email");
    self.checkYourEmailLabel.text = AMLocalizedString(@"accountNotConfirmed", @"Text shown just after creating an account to remenber the user what to do to complete the account creation proccess");
    self.emailInputView.inputTextField.text = self.email;
    self.misspelledLabel.text = AMLocalizedString(@"misspelledEmailAddress", @"A hint shown at the bottom of the Send Signup Link dialog to tell users they can edit the provided email.");
    [self.resendButton setTitle:AMLocalizedString(@"resend", @"A button to resend the email confirmation.") forState:UIControlStateNormal];
    [self.cancelButton setTitle:AMLocalizedString(@"cancel", nil) forState:UIControlStateNormal];
    
    self.resendButton.layer.borderColor = [UIColor mnz_gray999999].CGColor;
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    [self.view addGestureRecognizer:tap];
    
    self.emailInputView.inputTextField.delegate = self;
    self.emailInputView.inputTextField.keyboardType = UIKeyboardTypeEmailAddress;
    if (@available(iOS 11.0, *)) {
        self.emailInputView.inputTextField.textContentType = UITextContentTypeUsername;
    }

}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[MEGASdkManager sharedMEGASdk] addMEGAGlobalDelegate:self];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[MEGASdkManager sharedMEGASdk] removeMEGAGlobalDelegate:self];
}

#pragma mark - Private

- (void)dismissKeyboard {
    [self.emailInputView.inputTextField resignFirstResponder];
}

- (void)setErrorState:(BOOL)error {
    if (error) {
        self.emailInputView.topLabel.text = AMLocalizedString(@"emailInvalidFormat", @"Message shown when the user writes an invalid format in the email field");
        self.emailInputView.topLabel.textColor = UIColor.mnz_redError;
        self.emailInputView.inputTextField.textColor = UIColor.mnz_redError;
    } else {
        self.emailInputView.topLabel.text = AMLocalizedString(@"emailPlaceholder", nil);
        self.emailInputView.topLabel.textColor = UIColor.mnz_gray999999;
        self.emailInputView.inputTextField.textColor = UIColor.blackColor;
    }
}

#pragma mark - IBActions

- (IBAction)cancelTouchUpInside:(UIButton *)sender {
    NSString *message = AMLocalizedString(@"areYouSureYouWantToAbortTheRegistration", @"Asking whether the user really wants to abort/stop the registration process or continue on.");
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:message preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"cancel", nil) style:UIAlertActionStyleCancel handler:nil]];
    [alertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"ok", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [MEGASdkManager.sharedMEGASdk cancelCreateAccount];        
        [Helper clearEphemeralSession];
        [self dismissViewControllerAnimated:YES completion:nil];
    }]];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (IBAction)resendTouchUpInside:(UIButton *)sender {
    if ([MEGAReachabilityManager isReachableHUDIfNot]) {
        BOOL validEmail = [self.emailInputView.inputTextField.text mnz_isValidEmail];
        if (validEmail) {
            [self.emailInputView.inputTextField resignFirstResponder];
            MEGASendSignupLinkRequestDelegate *sendSignupLinkRequestDelegate = [[MEGASendSignupLinkRequestDelegate alloc] init];
            [[MEGASdkManager sharedMEGASdk] fastSendSignupLinkWithEmail:self.emailInputView.inputTextField.text base64pwkey:self.base64pwkey name:self.name delegate:sendSignupLinkRequestDelegate];
        }
        [self setErrorState:!validEmail];
    }
}


#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self.emailInputView.inputTextField resignFirstResponder];
    [self resendTouchUpInside:nil];
    
    return YES;
}

#pragma mark - MEGAGlobalDelegate

- (void)onEvent:(MEGASdk *)api event:(MEGAEvent *)event {
    if (event.type == EventAccountConfirmation) {
        [MEGASdkManager createSharedMEGAChatSdk];
        MEGAChatInit chatInit = [[MEGASdkManager sharedMEGAChatSdk] initKarereWithSid:nil];
        if (chatInit != MEGAChatInitWaitingNewSession) {
            MEGALogError(@"Init Karere without sesion must return waiting for a new sesion");
            [[MEGASdkManager sharedMEGAChatSdk] logout];
        }

        MEGALoginRequestDelegate *loginRequestDelegate = [[MEGALoginRequestDelegate alloc] init];
        loginRequestDelegate.confirmAccountInOtherClient = YES;
        NSString *stringHash = [api hashForBase64pwkey:self.base64pwkey email:event.text];
        [api fastLoginWithEmail:event.text stringHash:stringHash base64pwKey:self.base64pwkey delegate:loginRequestDelegate];
    }
}

@end
