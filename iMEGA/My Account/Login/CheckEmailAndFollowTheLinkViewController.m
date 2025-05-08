#import "CheckEmailAndFollowTheLinkViewController.h"

#import "SAMKeychain.h"

#import "NSString+MNZCategory.h"

#import "InputView.h"
#import "Helper.h"
#import "MEGALoginRequestDelegate.h"
#import "MEGAReachabilityManager.h"
#import "MEGA-Swift.h"

@import MEGAL10nObjc;
@import MEGAAppSDKRepo;

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

    self.awaitingEmailConfirmationLabel.text = LocalizedString(@"awaitingEmailConfirmation", @"Title shown just after doing some action that requires confirming the action by an email");
    self.checkYourEmailLabel.text = LocalizedString(@"accountNotConfirmed", @"Text shown just after creating an account to remenber the user what to do to complete the account creation proccess");
    
    self.emailInputView.inputTextField.text = self.email;
    
    self.misspelledLabel.text = LocalizedString(@"misspelledEmailAddress", @"A hint shown at the bottom of the Send Signup Link dialog to tell users they can edit the provided email.");
    [self.resendButton setTitle:LocalizedString(@"resend", @"A button to resend the email confirmation.") forState:UIControlStateNormal];
    
    [self.cancelButton setTitle:LocalizedString(@"cancel", @"") forState:UIControlStateNormal];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    [self.view addGestureRecognizer:tap];
    
    self.emailInputView.inputTextField.delegate = self;
    self.emailInputView.inputTextField.keyboardType = UIKeyboardTypeEmailAddress;
    self.emailInputView.inputTextField.textContentType = UITextContentTypeUsername;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [MEGASdk.shared addMEGAGlobalDelegate:self];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [MEGASdk.shared removeMEGAGlobalDelegate:self];
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
        self.emailInputView.topLabel.text = LocalizedString(@"emailInvalidFormat", @"Message shown when the user writes an invalid format in the email field");
        self.emailInputView.topLabel.textColor = UIColor.systemRedColor;
        self.emailInputView.inputTextField.textColor = UIColor.systemRedColor;
    } else {
        self.emailInputView.topLabel.text = LocalizedString(@"emailPlaceholder", @"");
        self.emailInputView.topLabel.textColor = [UIColor iconSecondaryColor];
        self.emailInputView.inputTextField.textColor = UIColor.labelColor;
    }
}

- (void)updateAppearance {
    self.view.backgroundColor = [UIColor pageBackgroundColor];
    
    self.checkYourEmailLabel.textColor = [UIColor mnz_secondaryTextColor];
    
    [self.emailInputView updateAppearance];
    
    self.misspelledLabel.textColor = [UIColor iconSecondaryColor];
    
    [self.resendButton mnz_setupPrimary];
    [self.cancelButton mnz_setupCancel];
}

#pragma mark - IBActions

- (IBAction)cancelTouchUpInside:(UIButton *)sender {
    NSString *message = LocalizedString(@"areYouSureYouWantToAbortTheRegistration", @"Asking whether the user really wants to abort/stop the registration process or continue on.");
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:message preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:LocalizedString(@"cancel", @"") style:UIAlertActionStyleCancel handler:nil]];
    [alertController addAction:[UIAlertAction actionWithTitle:LocalizedString(@"ok", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [MEGASdk.shared cancelCreateAccount];        
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
            RequestDelegate *delegate = [[RequestDelegate alloc] initWithCompletion:^(MEGARequest *request, MEGAError *error) {
                if (error.type) {
                    NSString *title;
                    NSString *message;
                    switch (error.type) {
                        case MEGAErrorTypeApiEExist:
                            title = @"";
                            message = LocalizedString(@"emailAlreadyRegistered", @"Error text shown when the users tries to create an account with an email already in use");
                            break;
                            
                        case MEGAErrorTypeApiEFailed:
                            title = @"";
                            message = LocalizedString(@"emailAddressChangeAlreadyRequested", @"Error message shown when you try to change your account email to one that you already requested.");
                            break;
                            
                        default:
                            title = LocalizedString(@"error", @"");
                            message = [NSString stringWithFormat:@"%@", LocalizedString(error.name, @"")];
                            break;
                    }
                    
                    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
                    [alertController addAction:[UIAlertAction actionWithTitle:LocalizedString(@"ok", @"") style:UIAlertActionStyleCancel handler:nil]];
                    
                    [self presentViewController:alertController animated:YES completion:nil];
                    
                    return;
                } else {
                    [SAMKeychain setPassword:request.email forService:@"MEGA" account:@"email"];
                    [SVProgressHUD showInfoWithStatus:LocalizedString(@"awaitingEmailConfirmation", @"Title shown just after doing some action that requires confirming the action by an email")];
                }
            }];
            [MEGASdk.shared resendSignupLinkWithEmail:self.emailInputView.inputTextField.text
                                                             name:self.name
                                                         delegate:delegate];
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
        MEGAChatInit chatInit = [MEGAChatSdk.shared initKarereWithSid:nil];
        if (chatInit != MEGAChatInitWaitingNewSession) {
            MEGALogError(@"Init Karere without sesion must return waiting for a new sesion");
            [MEGAChatSdk.shared logout];
        }

        MEGALoginRequestDelegate *loginRequestDelegate = [[MEGALoginRequestDelegate alloc] init];
        loginRequestDelegate.confirmAccountInOtherClient = YES;
        loginRequestDelegate.isNewUserRegistration = YES;
        [api loginWithEmail:self.email password:self.password delegate:loginRequestDelegate];
    }
}

@end
