
#import "CheckEmailAndFollowTheLinkViewController.h"

#import "SAMKeychain.h"

#import "NSString+MNZCategory.h"

#import "InputView.h"
#import "Helper.h"
#import "MEGALoginRequestDelegate.h"
#import "MEGASendSignupLinkRequestDelegate.h"
#import "MEGAReachabilityManager.h"
#import "MEGASdkManager.h"
#import "MEGA-Swift.h"

@interface CheckEmailAndFollowTheLinkViewController () <UITextFieldDelegate, MEGAGlobalDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *mailImageView;
@property (weak, nonatomic) IBOutlet UILabel *awaitingEmailConfirmationLabel;
@property (weak, nonatomic) IBOutlet UILabel *checkYourEmailLabel;
@property (weak, nonatomic) IBOutlet InputView *emailInputView;
@property (weak, nonatomic) IBOutlet UILabel *misspelledLabel;
@property (weak, nonatomic) IBOutlet UIButton *resendButton;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;

@property (nonatomic, copy) NSString *email;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *password;

@end

@implementation CheckEmailAndFollowTheLinkViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self updateAppearance];
    
    self.email = [SAMKeychain passwordForService:@"MEGA" account:@"email"];
    self.name = [SAMKeychain passwordForService:@"MEGA" account:@"name"];
    self.password = [SAMKeychain passwordForService:@"MEGA" account:@"password"];

    self.awaitingEmailConfirmationLabel.text = NSLocalizedString(@"awaitingEmailConfirmation", @"Title shown just after doing some action that requires confirming the action by an email");
    self.checkYourEmailLabel.text = NSLocalizedString(@"accountNotConfirmed", @"Text shown just after creating an account to remenber the user what to do to complete the account creation proccess");
    
    self.emailInputView.inputTextField.text = self.email;
    
    self.misspelledLabel.text = NSLocalizedString(@"misspelledEmailAddress", @"A hint shown at the bottom of the Send Signup Link dialog to tell users they can edit the provided email.");
    [self.resendButton setTitle:NSLocalizedString(@"resend", @"A button to resend the email confirmation.") forState:UIControlStateNormal];
    
    [self.cancelButton setTitle:NSLocalizedString(@"cancel", nil) forState:UIControlStateNormal];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    [self.view addGestureRecognizer:tap];
    
    self.emailInputView.inputTextField.delegate = self;
    self.emailInputView.inputTextField.keyboardType = UIKeyboardTypeEmailAddress;
    self.emailInputView.inputTextField.textContentType = UITextContentTypeUsername;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[MEGASdkManager sharedMEGASdk] addMEGAGlobalDelegate:self];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[MEGASdkManager sharedMEGASdk] removeMEGAGlobalDelegate:self];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    
    if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
        [self updateAppearance];
    }
}

#pragma mark - Private

- (void)dismissKeyboard {
    [self.emailInputView.inputTextField resignFirstResponder];
}

- (void)setErrorState:(BOOL)error {
    if (error) {
        self.emailInputView.topLabel.text = NSLocalizedString(@"emailInvalidFormat", @"Message shown when the user writes an invalid format in the email field");
        self.emailInputView.topLabel.textColor = UIColor.mnz_redError;
        self.emailInputView.inputTextField.textColor = UIColor.mnz_redError;
    } else {
        self.emailInputView.topLabel.text = NSLocalizedString(@"emailPlaceholder", nil);
        self.emailInputView.topLabel.textColor = [UIColor mnz_secondaryGrayForTraitCollection:self.traitCollection];
        self.emailInputView.inputTextField.textColor = UIColor.mnz_label;
    }
}

- (void)updateAppearance {
    self.view.backgroundColor = [UIColor mnz_backgroundGroupedForTraitCollection:self.traitCollection];
    
    self.checkYourEmailLabel.textColor = [UIColor mnz_subtitlesForTraitCollection:self.traitCollection];
    
    [self.emailInputView updateAppearance];
    
    self.misspelledLabel.textColor = [UIColor mnz_secondaryGrayForTraitCollection:self.traitCollection];
    
    [self.resendButton mnz_setupPrimary:self.traitCollection];
    [self.cancelButton mnz_setupCancel:self.traitCollection];
}

#pragma mark - IBActions

- (IBAction)cancelTouchUpInside:(UIButton *)sender {
    NSString *message = NSLocalizedString(@"areYouSureYouWantToAbortTheRegistration", @"Asking whether the user really wants to abort/stop the registration process or continue on.");
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:message preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"cancel", nil) style:UIAlertActionStyleCancel handler:nil]];
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"ok", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [MEGASdkManager.sharedMEGASdk cancelCreateAccount];        
        [Helper clearEphemeralSession];
        [self dismissViewControllerAnimated:YES completion:nil];
    }]];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (IBAction)resendTouchUpInside:(UIButton *)sender {
    if ([MEGAReachabilityManager isReachableHUDIfNot]) {
        self.emailInputView.inputTextField.text = self.emailInputView.inputTextField.text.mnz_removeWhitespacesAndNewlinesFromBothEnds;
        BOOL validEmail = [self.emailInputView.inputTextField.text mnz_isValidEmail];
        if (validEmail) {
            [self.emailInputView.inputTextField resignFirstResponder];
            MEGASendSignupLinkRequestDelegate *sendSignupLinkRequestDelegate = [[MEGASendSignupLinkRequestDelegate alloc] init];
            [MEGASdkManager.sharedMEGASdk sendSignupLinkWithEmail:self.emailInputView.inputTextField.text
                                                             name:self.name
                                                         password:self.password
                                                         delegate:sendSignupLinkRequestDelegate];
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
        MEGAChatInit chatInit = [[MEGASdkManager sharedMEGAChatSdk] initKarereWithSid:nil];
        if (chatInit != MEGAChatInitWaitingNewSession) {
            MEGALogError(@"Init Karere without sesion must return waiting for a new sesion");
            [[MEGASdkManager sharedMEGAChatSdk] logout];
        }

        MEGALoginRequestDelegate *loginRequestDelegate = [[MEGALoginRequestDelegate alloc] init];
        loginRequestDelegate.confirmAccountInOtherClient = YES;
        [api loginWithEmail:self.email password:self.password delegate:loginRequestDelegate];
    }
}

@end
