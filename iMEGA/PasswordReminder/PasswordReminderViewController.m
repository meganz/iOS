
#import "PasswordReminderViewController.h"

#import "MEGASdkManager.h"
#import "MEGAReachabilityManager.h"

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

@end

@implementation PasswordReminderViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self configureUI];
}

#pragma mark - IBActions

- (IBAction)tapTestPassword:(id)sender {
    [self sendDontShowAgainToApi];
    [self dismissViewControllerAnimated:YES completion:^{
        TestPasswordViewController *testPasswordViewController = [[UIStoryboard storyboardWithName:@"PasswordReminder" bundle:nil] instantiateViewControllerWithIdentifier:@"TestPasswordNavigationControllerID"];
        [[UIApplication mnz_visibleViewController] presentViewController:testPasswordViewController animated:YES completion:nil];
    }];
}

- (IBAction)tapBackupRecoveryKey:(id)sender {
    if ([[MEGASdkManager sharedMEGASdk] isLoggedIn]) {
        NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        NSString *masterKeyFilePath = [documentsDirectory stringByAppendingPathComponent:@"RecoveryKey.txt"];
        
        BOOL success = [[NSFileManager defaultManager] createFileAtPath:masterKeyFilePath contents:[[[MEGASdkManager sharedMEGASdk] masterKey] dataUsingEncoding:NSUTF8StringEncoding] attributes:@{NSFileProtectionKey:NSFileProtectionComplete}];
        if (success) {
            UIAlertController *recoveryKeyAlertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"masterKeyExported", @"Alert title shown when you have exported your MEGA Recovery Key") message:AMLocalizedString(@"masterKeyExported_alertMessage", @"The Recovery Key has been exported into the Offline section as RecoveryKey.txt. Note: It will be deleted if you log out, please store it in a safe place.")  preferredStyle:UIAlertControllerStyleAlert];
            [recoveryKeyAlertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"ok", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                [[MEGASdkManager sharedMEGASdk] masterKeyExported];
                [self.view setBackgroundColor:[UIColor clearColor]];
                [self dismissViewControllerAnimated:YES completion:nil];
            }]];

            [self presentViewController:recoveryKeyAlertController animated:YES completion:nil];
        }
    } else {
        [MEGAReachabilityManager isReachableHUDIfNot];
    }
}

- (IBAction)tapDismiss:(id)sender {
    [self.view setBackgroundColor:[UIColor clearColor]];
    [self dismissViewControllerAnimated:YES completion:^{
        [self sendDontShowAgainToApi];
    }];
}

#pragma mark - Private

- (void)sendDontShowAgainToApi {
    if (self.dontShowAgainSwitch.isOn) {
        //TODO: call sdk to save this state
    }
}

- (void)configureUI {
    self.titleLabel.text = AMLocalizedString(@"remindPasswordTitle", @"Title for Remind Password View, inviting user to test password");
    self.descriptionLabel.text = AMLocalizedString(@"remindPasswordText", @"Text for Remind Password View, explainig why user should test password");
    self.switchInfoLabel.text = AMLocalizedString(@"dontShowAgain", @"Text for don't show again Remind Password View option");
    [self.dismissButton setTitle:AMLocalizedString(@"dismiss", @"Label for any 'Dismiss' button, link, text, title, etc. - (String as short as possible).") forState:UIControlStateNormal];
    [self.testPasswordButton setTitle:AMLocalizedString(@"testPassword", @"Label for test password button") forState:UIControlStateNormal];
    [self.backupKeyButton setTitle:AMLocalizedString(@"backupRecoveryKey", @"Label for recovery key button") forState:UIControlStateNormal];
}

@end
