#import "TestPasswordViewController.h"

#import "Helper.h"
#import "MEGA-Swift.h"
#import "MEGAReachabilityManager.h"
#import "MEGANavigationController.h"
#import "NSString+MNZCategory.h"
#import "MainTabBarController.h"
#import "UIApplication+MNZCategory.h"

#import "PasswordView.h"
#import "ChangePasswordViewController.h"

#import "MEGAMultiFactorAuthCheckRequestDelegate.h"

#import "LocalizationHelper.h"

@interface TestPasswordViewController () <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (weak, nonatomic) IBOutlet UIButton *confirmButton;
@property (weak, nonatomic) IBOutlet UIButton *backupKeyButton;
@property (weak, nonatomic) IBOutlet UIButton *logoutButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *closeBarButton;
@property (weak, nonatomic) IBOutlet PasswordView *passwordView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *descriptionLabelHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *passwordViewHeightConstraint;

@property (weak, nonatomic) IBOutlet UIStackView *bottomStackView;
@property (weak, nonatomic) IBOutlet UIStackView *centerStackView;

@property (assign, nonatomic) float descriptionLabelHeight;
@property (assign, nonatomic) NSInteger testFailedCount;

@end

@implementation TestPasswordViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

    self.testFailedCount = 0;
    
    [self configureUI];
    
    self.descriptionLabelHeight = self.descriptionLabelHeightConstraint.constant;
    
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
    
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(keyboardDidHide:) name:UIKeyboardDidHideNotification object:nil];
    
    [self updateAppearance];
    
    [self trackScreenView];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    self.passwordView.passwordTextField.clearButtonMode = UITextFieldViewModeNever;
    [self.passwordView.passwordTextField becomeFirstResponder];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self arrangeLogoutButton];
    } completion:nil];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    
    if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
        [self updateAppearance];
    }
}

- (TestPasswordViewModel *)viewModel {
    if (_viewModel == nil) {
        _viewModel = [self makeTestPasswordViewModel];
    }
    
    return _viewModel;
}

#pragma mark - IBActions

- (IBAction)tapConfirm:(id)sender {
    [self trackConfirmButtonTap];
    [self.passwordView.passwordTextField resignFirstResponder];
    if ([MEGASdk.shared checkPassword:self.passwordView.passwordTextField.text]) {
        [self passwordTestSuccess];
        [MEGASdk.shared passwordReminderDialogSucceeded];
        [self trackPasswordAcceptedDisplayed];
    } else {
        [self passwordTestFailed];
        [self trackWrongPasswordDisplayed];
    }
}

- (IBAction)tapBackupRecoveryKey:(id)sender {
    [self trackExportRecoveryKeyButtonTap];
    if ([MEGASdk.shared isLoggedIn]) {
        if (self.isLoggingOut) {
            [Helper showMasterKeyCopiedAlert:^{
                [self trackExportRecoveryKeyCopyOKAlertButtonTap];
            }];
        } else {
            __weak TestPasswordViewController *weakSelf = self;
            
            [self.passwordView.passwordTextField resignFirstResponder];
            
            [Helper showExportMasterKeyInView:self completion:^{
                if (weakSelf.isLoggingOut) {
                    [MEGASdk.shared logout];
                }
            }];
        }
    } else {
        [MEGAReachabilityManager isReachableHUDIfNot];
    }
}

- (IBAction)tapClose:(id)sender {
    [self trackProceedToLogoutButtonTap];
    [self.passwordView.passwordTextField resignFirstResponder];
    
    [self dismissViewControllerAnimated:YES completion:^{
        if (self.isLoggingOut) {
            [MEGASdk.shared logout];
        }
    }];
}

#pragma mark - Private

- (void)updateAppearance {
    self.view.backgroundColor = UIColor.systemBackgroundColor;
    
    self.descriptionLabel.textColor = [UIColor mnz_secondaryTextColor];
    
    [self.passwordView updateAppearance];
    
    if ([self.confirmButton.titleLabel.text isEqualToString:LocalizedString(@"passwordAccepted", 
                                                                            @"Used as a message in the 'Password reminder' dialog that is shown when the user enters his password, clicks confirm and his password is correct.")]) {
        [self.confirmButton mnz_setupBasic:[UIColor succeedTextColor]];
        [self.confirmButton mnz_clearSetup];
      } else {
        [self.confirmButton mnz_setupSecondary];
      }
    
    [self.backupKeyButton mnz_setupPrimary];
    
    [self.logoutButton mnz_setupCancel];
}

- (void)configureUI {
    self.title = LocalizedString(@"testPassword", @"Label for test password button");
    self.passwordView.passwordTextField.delegate = self;
    
    [self arrangeLogoutButton];
    
    if (self.isLoggingOut) {
        self.navigationItem.rightBarButtonItem = nil;
        self.navigationController.navigationBar.topItem.title = @"";
        self.descriptionLabel.text = LocalizedString(@"testPasswordLogoutText", @"Text that described that you are about to logout remenbering why the user should remenber the password and/or test it");
        
        [self.backupKeyButton setTitle:LocalizedString(@"exportRecoveryKey", @"Text 'Export Recovery Key' placed just before two buttons into the 'settings' page to allow see (copy/paste) and export the Recovery Key.") forState:UIControlStateNormal];
    } else {
        self.closeBarButton.title = LocalizedString(@"close", @"A button label.");
        NSString *testPasswordText = LocalizedString(@"testPasswordText", @"Used as a message in the 'Password reminder' dialog as a tip on why confirming the password and/or exporting the recovery key is important and vital for the user to not lose any data.");
        NSString *learnMoreString = [testPasswordText mnz_stringBetweenString:@"[A]" andString:@"[/A]"];
        testPasswordText = [testPasswordText stringByReplacingCharactersInRange:[testPasswordText rangeOfString:learnMoreString] withString:@""];
        self.descriptionLabel.text = [testPasswordText mnz_removeWebclientFormatters];
        
        [self.backupKeyButton setTitle:LocalizedString(@"backupRecoveryKey", @"Label for recovery key button") forState:UIControlStateNormal];
    }
    
    [self.confirmButton setTitle:LocalizedString(@"confirm", @"Title text for the account confirmation.") forState:UIControlStateNormal];
    
    [self.logoutButton setTitle:LocalizedString(@"proceedToLogout", @"Title to confirm that you want to logout") forState:UIControlStateNormal];
}

- (void)arrangeLogoutButton {
    if (self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassCompact) {
        [self.centerStackView addArrangedSubview:self.logoutButton];
    } else {
        [self.bottomStackView addArrangedSubview:self.logoutButton];
    }
}

- (void)passwordTestFailed {
    [self.passwordView setErrorState:YES];
    
    self.testFailedCount++;
    
    if (self.testFailedCount == 3) {
        MEGAMultiFactorAuthCheckRequestDelegate *delegate = [[MEGAMultiFactorAuthCheckRequestDelegate alloc] initWithCompletion:^(MEGARequest *request, MEGAError *error) {
            [self dismissViewControllerAnimated:YES completion:^{
                ChangePasswordViewController *changePasswordVC = [[UIStoryboard storyboardWithName:@"ChangeCredentials" bundle:nil] instantiateViewControllerWithIdentifier:@"ChangePasswordViewControllerID"];
                changePasswordVC.changeType = ChangeTypePasswordFromLogout;
                changePasswordVC.twoFactorAuthenticationEnabled = request.flag;
                
                MEGANavigationController *navigationController = [[MEGANavigationController alloc] initWithRootViewController:changePasswordVC];
                [navigationController addLeftDismissButtonWithText:LocalizedString(@"cancel", @"Button title to cancel something")];
                [UIApplication.mnz_presentingViewController presentViewController:navigationController animated:YES completion:nil];
            }];
        }];
        [MEGASdk.shared multiFactorAuthCheckWithEmail:[MEGASdk.shared myEmail] delegate:delegate];
    }
}

- (void)passwordTestSuccess {
    [self.confirmButton setUserInteractionEnabled:NO];
    [self.confirmButton mnz_clearSetup];
    
    UIColor *textColor = [UIColor succeedTextColor];
    [self.confirmButton setTitleColor:textColor forState:UIControlStateNormal];
    
    [self.confirmButton setImage:[UIImage megaImageWithNamed: @"green_tick"] forState:UIControlStateNormal];
    [self.confirmButton setTitle:LocalizedString(@"passwordAccepted", @"Used as a message in the 'Password reminder' dialog that is shown when the user enters his password, clicks confirm and his password is correct.") forState:UIControlStateNormal];
    
    self.logoutButton.hidden = !self.isLoggingOut;
}

- (void)resetUI {
    [self.passwordView setErrorState:NO];
    [self.confirmButton setUserInteractionEnabled:YES];
    
    if (self.isLoggingOut) {
        [self.confirmButton setTitle:LocalizedString(@"testPassword", @"Label for test password button") forState:UIControlStateNormal];
    } else {
        [self.confirmButton setTitle:LocalizedString(@"confirm", @"Title text for the account confirmation.") forState:UIControlStateNormal];
    }
    
    [self.confirmButton mnz_setupSecondary];
    [self.confirmButton setImage:nil forState:UIControlStateNormal];
}

- (void)keyboardDidShow:(NSNotification *)notification {
    if (self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassCompact) {
        self.descriptionLabelHeightConstraint.constant = 0;
    }
}

- (void)keyboardDidHide:(NSNotification *)notification {
    if (self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassCompact) {
        self.descriptionLabelHeightConstraint.constant = self.descriptionLabelHeight;
    }
}

#pragma mark - UITextFieldDelegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    [self.passwordView setErrorState:NO];
    if (!self.confirmButton.isUserInteractionEnabled) {
        [self resetUI];
    }
    
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    if (textField == self.passwordView.passwordTextField) {
        self.passwordView.toggleSecureButton.hidden = NO;
    }
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    if (textField == self.passwordView.passwordTextField) {
        self.passwordView.passwordTextField.secureTextEntry = YES;
        [self.passwordView configureSecureTextEntry];
    }
}

@end
