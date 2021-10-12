
#import "PasswordReminderViewController.h"

#import "MEGASdkManager.h"
#import "MEGA-Swift.h"
#import "MEGAReachabilityManager.h"
#import "Helper.h"
#import "UIApplication+MNZCategory.h"
#import "TestPasswordViewController.h"
#import "MEGAGenericRequestDelegate.h"

@interface PasswordReminderViewController ()

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (weak, nonatomic) IBOutlet UILabel *switchInfoLabel;
@property (weak, nonatomic) IBOutlet UIButton *testPasswordButton;
@property (weak, nonatomic) IBOutlet UIButton *backupKeyButton;
@property (weak, nonatomic) IBOutlet UIButton *dismissButton;

@property (weak, nonatomic) IBOutlet UIView *doNotShowMeAgainView;
@property (weak, nonatomic) IBOutlet UIView *doNotShowMeAgainTopSeparatorView;
@property (weak, nonatomic) IBOutlet UISwitch *dontShowAgainSwitch;
@property (weak, nonatomic) IBOutlet UIView *doNotShowMeAgainBottomSeparatorView;

@property (weak, nonatomic) IBOutlet UIView *alphaView;
@property (weak, nonatomic) IBOutlet UIImageView *keyImageView;

@property (weak, nonatomic) IBOutlet UIView *backgroundView;

@end

@implementation PasswordReminderViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

    [self configureUI];
    
    [self updateAppearance];
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
        self.navigationItem.title = NSLocalizedString(@"Password Reminder", @"Title for feature Password Reminder");
    }
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    
    if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
        [self updateAppearance];
    }
}

#pragma mark - IBActions

- (IBAction)tapClose:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)tapTestPassword:(id)sender {
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
    if ([[MEGASdkManager sharedMEGASdk] isLoggedIn]) {
        if (self.isLoggingOut) {
            [Helper showMasterKeyCopiedAlert];
        } else {
            __weak PasswordReminderViewController *weakSelf = self;
            
            [Helper showExportMasterKeyInView:self completion:^{
                if (weakSelf.isLoggingOut) {
                    [MEGASdkManager.sharedMEGASdk logout];
                }
            }];
        }
    } else {
        [MEGAReachabilityManager isReachableHUDIfNot];
    }
}

- (IBAction)tapDismiss:(id)sender {
    [self dismissViewControllerAnimated:YES completion:^{
        [self notifyUserSkippedOrBlockedPasswordReminder];
    }];
}

#pragma mark - Private

- (void)updateAppearance {
    self.backgroundView.backgroundColor = UIColor.mnz_background;
    
    self.descriptionLabel.textColor = [UIColor mnz_subtitlesForTraitCollection:self.traitCollection];
    
    self.doNotShowMeAgainView.backgroundColor = [UIColor mnz_secondaryBackgroundElevated:self.traitCollection];
    self.doNotShowMeAgainTopSeparatorView.backgroundColor = self.doNotShowMeAgainBottomSeparatorView.backgroundColor = [UIColor mnz_separatorForTraitCollection:self.traitCollection];
    
    [self.testPasswordButton mnz_setupBasic:self.traitCollection];
    [self.backupKeyButton mnz_setupPrimary:self.traitCollection];
    
    [self.dismissButton mnz_setupCancel:self.traitCollection];
}

- (void)notifyUserSkippedOrBlockedPasswordReminder {
    MEGAGenericRequestDelegate *delegate = [[MEGAGenericRequestDelegate alloc] initWithCompletion:^(MEGARequest *request, MEGAError *error) {
        if (self.isLoggingOut) {
            [MEGASdkManager.sharedMEGASdk logout];
        }
    }];
    if (self.dontShowAgainSwitch.isOn) {
        [[MEGASdkManager sharedMEGASdk] passwordReminderDialogBlockedWithDelegate:delegate];
    } else {
        [[MEGASdkManager sharedMEGASdk] passwordReminderDialogSkippedWithDelegate:delegate];
    }
    [OverDiskQuotaService.sharedService invalidate];
    [[SearchFileUseCase.alloc init] clearFileSearchHistoryEntries];
}

- (void)configureUI {
    if (self.logout) {
        UIBarButtonItem *cancelBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"close", nil) style:UIBarButtonItemStylePlain target:self action:@selector(tapClose:)];
        self.navigationItem.rightBarButtonItem = cancelBarButtonItem;
    }
    
    self.titleLabel.text = NSLocalizedString(@"remindPasswordTitle", @"Title for Remind Password View, inviting user to test password");
    self.switchInfoLabel.text = NSLocalizedString(@"dontShowAgain", @"Text for don't show again Remind Password View option");
    [self.testPasswordButton setTitle:NSLocalizedString(@"testPassword", @"Label for test password button") forState:UIControlStateNormal];
    
    if (self.isLoggingOut) {
        self.descriptionLabel.text = NSLocalizedString(@"remindPasswordLogoutText", @" Text to describe why the user should test his/her password before logging out");
        [self.backupKeyButton setTitle:NSLocalizedString(@"exportRecoveryKey", @"Text 'Export Recovery Key' placed just before two buttons into the 'settings' page to allow see (copy/paste) and export the Recovery Key.") forState:UIControlStateNormal];
        [self.dismissButton setTitle:NSLocalizedString(@"proceedToLogout", @"Title of the button which logs out from your account.") forState:UIControlStateNormal];
    } else {
        self.descriptionLabel.text = NSLocalizedString(@"remindPasswordText", @"Text for Remind Password View, explainig why user should test password");
        [self.backupKeyButton setTitle:NSLocalizedString(@"backupRecoveryKey", @"Label for recovery key button") forState:UIControlStateNormal];
        [self.dismissButton setTitle:NSLocalizedString(@"dismiss", @"Label for any 'Dismiss' button, link, text, title, etc. - (String as short as possible).") forState:UIControlStateNormal];
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
