
#import "TestPasswordViewController.h"

#import "Helper.h"
#import "MEGASdkManager.h"
#import "MEGAReachabilityManager.h"
#import "NSString+MNZCategory.h"

#import "PasswordView.h"

@interface TestPasswordViewController () <PasswordViewDelegate>

@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (weak, nonatomic) IBOutlet UIButton *confirmButton;
@property (weak, nonatomic) IBOutlet UIButton *backupKeyButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *closeBarButton;
@property (weak, nonatomic) IBOutlet PasswordView *passwordView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *descriptionLabelHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *passwordViewHeightConstraint;

@property (assign, nonatomic) float descriptionLabelHeight;

@end

@implementation TestPasswordViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

    [self configureUI];
    
    self.descriptionLabelHeight = self.descriptionLabelHeightConstraint.constant;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardDidShow:)
                                                 name:UIKeyboardDidShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardDidHide:)
                                                 name:UIKeyboardDidHideNotification
                                               object:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    self.passwordView.passwordTextField.clearButtonMode = UITextFieldViewModeNever;
    [self.passwordView.passwordTextField becomeFirstResponder];
}

#pragma mark - IBActions

- (IBAction)tapConfirm:(id)sender {
    [self.passwordView.passwordTextField resignFirstResponder];
    if ([[MEGASdkManager sharedMEGASdk] checkPassword:self.passwordView.passwordTextField.text]) {
        [self passwordTestSuccess];
        [[MEGASdkManager sharedMEGASdk] passwordReminderDialogSucceeded];
    } else {
        [self passwordTestFailed];
    }
}

- (IBAction)tapBackupRecoveryKey:(id)sender {
    if ([[MEGASdkManager sharedMEGASdk] isLoggedIn]) {
        if (self.isLoggingOut) {
            [Helper showMasterKeyCopiedAlert];
        } else {
            __weak TestPasswordViewController *weakSelf = self;
            
            [self.passwordView.passwordTextField resignFirstResponder];
            
            [Helper showExportMasterKeyInView:self completion:^{
                if (weakSelf.isLoggingOut) {
                    [Helper logoutAfterPasswordReminder];
                }
            }];
        }
    } else {
        [MEGAReachabilityManager isReachableHUDIfNot];
    }
}

- (IBAction)tapClose:(id)sender {
    [self.passwordView.passwordTextField resignFirstResponder];
    
    [self dismissViewControllerAnimated:YES completion:^{
        if (self.isLoggingOut) {
            [Helper logoutAfterPasswordReminder];
        }
    }];
}

#pragma mark - Private

- (void)configureUI {
    self.title = AMLocalizedString(@"testPassword", @"Label for test password button");
    if (self.isLoggingOut) {
        self.closeBarButton.title = AMLocalizedString(@"logoutLabel", @"Title of the button which logs out from your account.");
        self.descriptionLabel.text = AMLocalizedString(@"testPasswordLogoutText", @"Text that described that you are about to logout remenbering why the user should remenber the password and/or test it");
        
        self.confirmButton.layer.borderWidth = 0.0f;
        self.confirmButton.layer.borderColor = nil;
        [self.confirmButton setTitleColor:UIColor.mnz_gray666666 forState:UIControlStateNormal];
        self.confirmButton.backgroundColor = [UIColor colorFromHexString:@"F2F2F2"];
        [self.confirmButton setTitle:AMLocalizedString(@"testPassword", @"Label for test password button") forState:UIControlStateNormal];
        
        [self.backupKeyButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
        self.backupKeyButton.backgroundColor = UIColor.mnz_redFF4D52;
        [self.backupKeyButton setTitle:AMLocalizedString(@"exportRecoveryKey", @"Text 'Export Recovery Key' placed just before two buttons into the 'settings' page to allow see (copy/paste) and export the Recovery Key.") forState:UIControlStateNormal];
    } else {
        self.closeBarButton.title = AMLocalizedString(@"close", @"A button label.");
        NSString *testPasswordText = AMLocalizedString(@"testPasswordText", @"Used as a message in the 'Password reminder' dialog as a tip on why confirming the password and/or exporting the recovery key is important and vital for the user to not lose any data.");
        NSString *learnMoreString = [testPasswordText mnz_stringBetweenString:@"[A]" andString:@"[/A]"];
        testPasswordText = [testPasswordText stringByReplacingCharactersInRange:[testPasswordText rangeOfString:learnMoreString] withString:@""];
        self.descriptionLabel.text = [testPasswordText mnz_removeWebclientFormatters];
        
        self.confirmButton.layer.borderWidth = 1.0;
        self.confirmButton.layer.borderColor = [UIColor colorFromHexString:@"F2F2F2"].CGColor;
        [self.confirmButton setTitle:AMLocalizedString(@"confirm", @"Title text for the account confirmation.") forState:UIControlStateNormal];
        
        [self.backupKeyButton setTitleColor:UIColor.mnz_gray666666 forState:UIControlStateNormal];
        self.backupKeyButton.backgroundColor = [UIColor colorFromHexString:@"F2F2F2"];
        [self.backupKeyButton setTitle:AMLocalizedString(@"backupRecoveryKey", @"Label for recovery key button") forState:UIControlStateNormal];
    }
}

- (void)passwordTestFailed {
    self.passwordViewHeightConstraint.constant = 101;
    self.passwordView.wrongPasswordView.hidden = NO;

    self.passwordView.passwordTextField.textColor = UIColor.mnz_redF0373A;
    
    [self.backupKeyButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    self.backupKeyButton.backgroundColor = UIColor.mnz_redFF4D52;
}

- (void)passwordTestSuccess {
    self.passwordView.passwordTextField.textColor = UIColor.mnz_green31B500;
    
    if (self.isLoggingOut) {
        self.confirmButton.layer.borderWidth = 1.0f;
        self.confirmButton.layer.borderColor = [UIColor colorFromHexString:@"F2F2F2"].CGColor;
        self.confirmButton.backgroundColor = UIColor.whiteColor;
        
        [self.backupKeyButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
        self.backupKeyButton.backgroundColor = UIColor.mnz_redFF4D52;
    } else {
        [self.backupKeyButton setTitleColor:UIColor.mnz_gray666666 forState:UIControlStateNormal];
        self.backupKeyButton.backgroundColor = [UIColor colorFromHexString:@"F2F2F2"];
    }
    
    [self.confirmButton setTitleColor:UIColor.mnz_green31B500 forState:UIControlStateNormal];
    self.confirmButton.titleLabel.font = [UIFont mnz_SFUIRegularWithSize:12.0f];
    [self.confirmButton setImage:[UIImage imageNamed:@"contact_request_accept"] forState:UIControlStateNormal];
    [self.confirmButton setTitle:AMLocalizedString(@"passwordAccepted", @"Used as a message in the 'Password reminder' dialog that is shown when the user enters his password, clicks confirm and his password is correct.") forState:UIControlStateNormal];
}

- (void)resetUI {
    self.passwordView.passwordTextField.textColor = UIColor.mnz_gray666666;
    
    self.passwordViewHeightConstraint.constant = 62;
    self.passwordView.wrongPasswordView.hidden = YES;
        
    if (self.isLoggingOut) {
        self.confirmButton.layer.borderWidth = 0.0f;
        self.confirmButton.layer.borderColor = nil;
        self.confirmButton.backgroundColor = [UIColor colorFromHexString:@"F2F2F2"];
        [self.confirmButton setTitle:AMLocalizedString(@"testPassword", @"Label for test password button") forState:UIControlStateNormal];
    } else {
        self.confirmButton.layer.borderWidth = 1.0;
        self.confirmButton.layer.borderColor = [UIColor colorFromHexString:@"F2F2F2"].CGColor;
        [self.confirmButton setTitle:AMLocalizedString(@"confirm", @"Title text for the account confirmation.") forState:UIControlStateNormal];
    }
    
    [self.confirmButton setImage:nil forState:UIControlStateNormal];
    self.confirmButton.titleLabel.font = [UIFont mnz_SFUIRegularWithSize:16.0f];
    [self.confirmButton setTitleColor:UIColor.mnz_gray666666 forState:UIControlStateNormal];
}

- (void)keyboardDidShow:(NSNotification *)notification {
    if (UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation) && (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)) {
        self.descriptionLabelHeightConstraint.constant = 0;
    }
}

- (void)keyboardDidHide:(NSNotification *)notification {
    if (UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation) && (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)) {
        self.descriptionLabelHeightConstraint.constant = self.descriptionLabelHeight;
    }
}

#pragma mark - PasswordViewDelegate

- (void)passwordViewBeginEditing {
    [self resetUI];
}

@end
