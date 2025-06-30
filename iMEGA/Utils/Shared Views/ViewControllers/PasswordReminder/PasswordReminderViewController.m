#import "PasswordReminderViewController.h"

#import "MEGA-Swift.h"
#import "MEGAReachabilityManager.h"
#import "Helper.h"
#import "UIApplication+MNZCategory.h"
#import "TestPasswordViewController.h"

@import MEGAL10nObjc;
@import MEGASDKRepo;

@interface PasswordReminderViewController ()

@end

@implementation PasswordReminderViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

    [self configureUI];
    
    [self updateAppearance];
    
    [self trackScreenView];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (!self.logout) {
        [self fadeInBackgroundCompletion:nil];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (self.logout) {
        self.navigationItem.title = LocalizedString(@"Password Reminder", @"Title for feature Password Reminder");
    }
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    
    if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
        [self updateAppearance];
    }
}

- (PasswordReminderViewModel *)viewModel {
    if (_viewModel == nil) {
        _viewModel = [self makePasswordReminderViewModel];
    }
    
    return _viewModel;
}

#pragma mark - IBActions

- (IBAction)tapClose:(id)sender {
    [self trackCloseButtonTap];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)tapTestPassword:(id)sender {
    [self trackTestPasswordButtonTap];
    
    if (self.isLoggingOut) {
        TestPasswordViewController *testPasswordViewController = [[UIStoryboard storyboardWithName:@"PasswordReminder" bundle:nil] instantiateViewControllerWithIdentifier:@"TestPasswordViewID"];
        testPasswordViewController.logout = self.isLoggingOut;
        [self.navigationController pushViewController:testPasswordViewController animated:YES];
    } else {
        [self dismissViewControllerAnimated:YES completion:^{
            UINavigationController *testPasswordNavigation = [[UIStoryboard storyboardWithName:@"PasswordReminder" bundle:nil] instantiateViewControllerWithIdentifier:@"TestPasswordNavigationControllerID"];
            TestPasswordViewController *testPasswordViewController = testPasswordNavigation.viewControllers.firstObject;
            testPasswordViewController.logout = self.isLoggingOut;
            
            [UIApplication.mnz_presentingViewController presentViewController:testPasswordNavigation animated:YES completion:nil];
        }];
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
            __weak PasswordReminderViewController *weakSelf = self;
            
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

- (IBAction)tapDismiss:(id)sender {
    [self trackDismissButtonTap];
    
    [self dismissViewControllerAnimated:YES completion:^{
        [self notifyUserSkippedOrBlockedPasswordReminder];
    }];
}

- (void)notifyUserSkippedOrBlockedPasswordReminder {
    RequestDelegate *delegate = [[RequestDelegate alloc] initWithCompletion:^(MEGARequest *request, MEGAError *error) {
        if (self.isLoggingOut) {
            [MEGASdk.shared logout];
        }
    }];
    if (self.dontShowAgainSwitch.isOn) {
        [MEGASdk.shared passwordReminderDialogBlockedWithDelegate:delegate];
    } else {
        [MEGASdk.shared passwordReminderDialogSkippedWithDelegate:delegate];
    }
    [OverDiskQuotaService.sharedService invalidate];
    [self requestStopAudioPlayerSession];
    [TabManager setDesignatedTabWithTab:nil];
}

- (void)configureUI {
    if (self.logout) {
        UIBarButtonItem *cancelBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:LocalizedString(@"close", @"") style:UIBarButtonItemStylePlain target:self action:@selector(tapClose:)];
        self.navigationItem.rightBarButtonItem = cancelBarButtonItem;
    }
    
    self.keyImageView.image = [UIImage megaImageWithNamed:@"keyIcon"];
    
    self.titleLabel.text = LocalizedString(@"remindPasswordTitle", @"Title for Remind Password View, inviting user to test password");
    self.switchInfoLabel.text = LocalizedString(@"dontShowAgain", @"Text for don't show again Remind Password View option");
    [self.testPasswordButton setTitle:LocalizedString(@"testPassword", @"Label for test password button") forState:UIControlStateNormal];
    
    if (self.isLoggingOut) {
        self.descriptionLabel.text = LocalizedString(@"remindPasswordLogoutText", @" Text to describe why the user should test his/her password before logging out");
        [self.backupKeyButton setTitle:LocalizedString(@"exportRecoveryKey", @"Text 'Export Recovery Key' placed just before two buttons into the 'settings' page to allow see (copy/paste) and export the Recovery Key.") forState:UIControlStateNormal];
        [self.dismissButton setTitle:LocalizedString(@"proceedToLogout", @"Title of the button which logs out from your account.") forState:UIControlStateNormal];
    } else {
        self.descriptionLabel.text = LocalizedString(@"remindPasswordText", @"Text for Remind Password View, explainig why user should test password");
        [self.backupKeyButton setTitle:LocalizedString(@"backupRecoveryKey", @"Label for recovery key button") forState:UIControlStateNormal];
        [self.dismissButton setTitle:LocalizedString(@"dismiss", @"Label for any 'Dismiss' button, link, text, title, etc. - (String as short as possible).") forState:UIControlStateNormal];
    }
}

- (void)fadeInBackgroundCompletion:(void (^ __nullable)(void))fadeInCompletion {
    [UIView animateWithDuration:.3 animations:^{
        self.alphaView.alpha = 1;
    } completion:^(BOOL finished) {
        if (fadeInCompletion && finished) {
            fadeInCompletion();
        }
    }];
}

@end
