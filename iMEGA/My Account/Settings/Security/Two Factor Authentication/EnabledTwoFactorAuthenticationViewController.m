#import "EnabledTwoFactorAuthenticationViewController.h"

#import "Helper.h"
#import "MEGA-Swift.h"
#import "UIApplication+MNZCategory.h"

#import "LocalizationHelper.h"

@interface EnabledTwoFactorAuthenticationViewController () <MEGARequestDelegate>

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *firstLabel;
@property (weak, nonatomic) IBOutlet UILabel *secondLabel;
@property (weak, nonatomic) IBOutlet UITextField *recoveryKeyTextField;

@property (weak, nonatomic) IBOutlet UIView *recoveryKeyView;

@property (weak, nonatomic) IBOutlet UIButton *exportRecoveryButton;
@property (weak, nonatomic) IBOutlet UIButton *closeButton;

@property (weak, nonatomic) IBOutlet UIImageView *_2FASetupImageView;
@property (weak, nonatomic) IBOutlet UIImageView *achievementsCheckImageView;
@property (weak, nonatomic) IBOutlet UIImageView *fileTypeTextImageView;

@property (getter=isRecoveryKeyExported) BOOL recoveryKeyExported;

@end

@implementation EnabledTwoFactorAuthenticationViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self configureImages];
    
    self.navigationItem.title = LocalizedString(@"twoFactorAuthentication", @"A title for the Two-Factor Authentication section on the My Account - Security page.");
    self.titleLabel.text = LocalizedString(@"twoFactorAuthenticationEnabled", @"A title on the mobile web client page showing that 2FA has been enabled successfully.");
    self.firstLabel.text = LocalizedString(@"twoFactorAuthenticationEnabledDescription", @"A message on the dialog shown after 2FA was successfully enabled.");
    self.secondLabel.text = LocalizedString(@"twoFactorAuthenticationEnabledWarning", @"An informational message on the Backup Recovery Key dialog.");
    self.recoveryKeyTextField.text = [NSString stringWithFormat:@"%@.txt", LocalizedString(@"general.security.recoveryKeyFile", @"Name for the recovery key file")];
    
    [self.exportRecoveryButton setTitle:LocalizedString(@"exportRecoveryKey", @"A dialog title to export the Recovery Key for the current user.") forState:UIControlStateNormal];
    [self.closeButton setTitle:LocalizedString(@"close", @"A button label. The button allows the user to close the conversation.") forState:UIControlStateNormal];
    
    [MEGASdk.shared isMasterKeyExportedWithDelegate:self];
    
    [self setupColors];
}

#pragma mark - Private
- (void)configureImages {
    self._2FASetupImageView.image = [UIImage megaImageWithNamed:@"2FASetup"];
    self.achievementsCheckImageView.image = [UIImage megaImageWithNamed:@"achievementsCheck"];
    self.fileTypeTextImageView.image = [UIImage megaImageWithNamed:@"filetype_text"];
}

- (void)setupColors {
    self.view.backgroundColor = [UIColor pageBackgroundColor];
    self.titleLabel.textColor = [self primaryTextColor];
    self.firstLabel.textColor = self.secondLabel.textColor = [self secondaryTextColor];
    self.recoveryKeyView.backgroundColor = [UIColor surface1Background];
    self.recoveryKeyView.layer.borderWidth = 0;
    self.recoveryKeyTextField.textColor = [self primaryTextColor];
    [self.exportRecoveryButton mnz_setupPrimary];
    [self.closeButton mnz_setupSecondary];  
}

- (void)showSaveYourRecoveryKeyAlert {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:LocalizedString(@"pleaseSaveYourRecoveryKey", @"A warning message on the Backup Recovery Key dialog to tell the user to backup their Recovery Key to their local computer.") message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:LocalizedString(@"ok", @"") style:UIAlertActionStyleCancel handler:nil]];
    [UIApplication.mnz_presentingViewController presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - IBActions

- (IBAction)exportRecoveryKeyTouchUpInside:(UIButton *)sender {
    [Helper showExportMasterKeyInView:self completion:nil];
}

- (IBAction)closeTouchUpInside:(UIButton *)sender {
    if (self.isRecoveryKeyExported) {
        [self dismissViewControllerAnimated:YES completion:nil];
    } else {
        [self showSaveYourRecoveryKeyAlert];
    }
}

#pragma mark - MEGARequestDelegate

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    if (error.type) {
        return;
    }
    
    if (request.type == MEGARequestTypeGetAttrUser) {
        self.recoveryKeyExported = request.access;
    }              
}

@end
