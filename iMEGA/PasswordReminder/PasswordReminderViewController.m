
#import "PasswordReminderViewController.h"

#import "MEGASdkManager.h"
#import "MEGAReachabilityManager.h"
#import "Helper.h"

#import "UIApplication+MNZCategory.h"

#import "TestPasswordViewController.h"

@interface PasswordReminderViewController ()

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (weak, nonatomic) IBOutlet UILabel *switchInfoLabel;
@property (weak, nonatomic) IBOutlet UIButton *testPasswordButton;
@property (weak, nonatomic) IBOutlet UIButton *backupKeyButton;
@property (weak, nonatomic) IBOutlet UIButton *dismissButton;
@property (weak, nonatomic) IBOutlet UISwitch *dontShowAgainSwitch;
@property (weak, nonatomic) IBOutlet UIView *alphaView;

@end

@implementation PasswordReminderViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

    [self configureUI];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self fadeInBackgroundCompletion:nil];
}

#pragma mark - IBActions

- (IBAction)tapTestPassword:(id)sender {
    [self dismissViewControllerAnimated:YES completion:^{
        UINavigationController *testPasswordNavigation = [[UIStoryboard storyboardWithName:@"PasswordReminder" bundle:nil] instantiateViewControllerWithIdentifier:@"TestPasswordNavigationControllerID"];
        TestPasswordViewController *testPasswordViewController = testPasswordNavigation.viewControllers.firstObject;
        testPasswordViewController.logout = self.logout;
        [[UIApplication mnz_visibleViewController] presentViewController:testPasswordNavigation animated:YES completion:nil];
    }];
}

- (IBAction)tapBackupRecoveryKey:(id)sender {
    if ([[MEGASdkManager sharedMEGASdk] isLoggedIn]) {
        __weak PasswordReminderViewController *weakSelf = self;
        [self.view setBackgroundColor:[UIColor clearColor]];

        [Helper showExportMasterKeyInView:self completion:^{
            if (weakSelf.logout) {
                [Helper logoutAfterPasswordReminder];
            }
        }];
    } else {
        [MEGAReachabilityManager isReachableHUDIfNot];
    }
}

- (IBAction)tapDismiss:(id)sender {
    [self.view setBackgroundColor:[UIColor clearColor]];
    [self dismissViewControllerAnimated:YES completion:^{
        [self notifyUserSkippedOrBlockedPasswordReminder];
    }];
}

#pragma mark - Private

- (void)notifyUserSkippedOrBlockedPasswordReminder {
    if (self.dontShowAgainSwitch.isOn) {
        [[MEGASdkManager sharedMEGASdk] passwordReminderDialogBlocked];
    } else {
        [[MEGASdkManager sharedMEGASdk] passwordReminderDialogSkipped];
    }
    
    if (self.logout) {
        [Helper logoutAfterPasswordReminder];
    }
}

- (void)configureUI {
    [self.alphaView setAlpha:0];
    
    self.titleLabel.text = AMLocalizedString(@"remindPasswordTitle", @"Title for Remind Password View, inviting user to test password");
    self.descriptionLabel.text = AMLocalizedString(@"remindPasswordText", @"Text for Remind Password View, explainig why user should test password");
    self.switchInfoLabel.text = AMLocalizedString(@"dontShowAgain", @"Text for don't show again Remind Password View option");
    [self.dismissButton setTitle:AMLocalizedString(@"dismiss", @"Label for any 'Dismiss' button, link, text, title, etc. - (String as short as possible).") forState:UIControlStateNormal];
    [self.testPasswordButton setTitle:AMLocalizedString(@"testPassword", @"Label for test password button") forState:UIControlStateNormal];
    [self.backupKeyButton setTitle:AMLocalizedString(@"backupRecoveryKey", @"Label for recovery key button") forState:UIControlStateNormal];
}

- (void)fadeInBackgroundCompletion:(void (^ __nullable)(void))fadeInCompletion {
    [UIView animateWithDuration:.3 animations:^{
        [self.alphaView setAlpha:1];
    } completion:^(BOOL finished) {
        if (fadeInCompletion && finished) {
            fadeInCompletion();
        }
    }];
}

@end
