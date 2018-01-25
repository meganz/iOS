
#import "TestPasswordViewController.h"
#import "MEGASdkManager.h"
#import "MEGAReachabilityManager.h"
#import "PasswordView.h"

@interface TestPasswordViewController () <PasswordViewDelegate>

@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (weak, nonatomic) IBOutlet UIButton *confirmButton;
@property (weak, nonatomic) IBOutlet UIButton *backupKeyButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *closeBarButton;
@property (weak, nonatomic) IBOutlet PasswordView *passwordView;
@property (weak, nonatomic) IBOutlet UIView *wrongPasswordView;

@end

@implementation TestPasswordViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self configureUI];
    [self resetUI];
}

#pragma mark - IBActions

- (IBAction)tapConfirm:(id)sender {
    [self.passwordView hideKeyboard];
    //TODO: call sdk to test password
    [self passwordTestSuccess];
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
                [self dismissViewControllerAnimated:YES completion:nil];
            }]];
            
            [self presentViewController:recoveryKeyAlertController animated:YES completion:nil];
        }
    } else {
        [MEGAReachabilityManager isReachableHUDIfNot];
    }
}

- (IBAction)tapClose:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Private

- (void)configureUI {
    self.title = @"Test Password";
    self.confirmButton.layer.borderWidth = 2.0;
    self.confirmButton.layer.borderColor = [UIColor colorWithRed:0.95 green:0.95 blue:0.95 alpha:1.0].CGColor;
}

- (void)passwordTestFailed {
    [self.wrongPasswordView setHidden:NO];
    [self.passwordView passwordTextFieldColor:[UIColor colorWithRed:0.85 green:0 blue:0.03 alpha:1.0]];
}

- (void)passwordTestSuccess {
    [self.confirmButton setTitle:@"Password accepted" forState:UIControlStateNormal];
    [self.confirmButton setImage:[UIImage imageNamed:@"contact_request_accept"] forState:UIControlStateNormal];
    [self.confirmButton setTitleColor:[UIColor colorWithRed:0.19 green:0.71 blue:0 alpha:1.0] forState:UIControlStateNormal];
    [self.passwordView passwordTextFieldColor:[UIColor colorWithRed:0.19 green:0.71 blue:0 alpha:1.0]];
}

- (void)resetUI {
    [self.confirmButton setImage:nil forState:UIControlStateNormal];
    [self.confirmButton setTitle:AMLocalizedString(@"confirm", @"Title text for the account confirmation.") forState:UIControlStateNormal];
    [self.confirmButton setTitleColor:[UIColor colorWithRed:0.4 green:0.4 blue:0.4 alpha:1.0] forState:UIControlStateNormal];
    [self.wrongPasswordView setHidden:YES];
    [self.passwordView passwordTextFieldColor:[UIColor colorWithRed:0.4 green:0.4 blue:0.4 alpha:1.0]];
}

#pragma mark - PasswordViewDelegate

- (void)passwordViewBeginEditing {
    [self resetUI];
}

@end
