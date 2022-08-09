
#import "EnabledTwoFactorAuthenticationViewController.h"

#import "Helper.h"
#import "MEGASdkManager.h"
#import "MEGA-Swift.h"
#import "UIApplication+MNZCategory.h"

@interface EnabledTwoFactorAuthenticationViewController () <MEGARequestDelegate>

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *firstLabel;
@property (weak, nonatomic) IBOutlet UILabel *secondLabel;
@property (weak, nonatomic) IBOutlet UITextField *recoveryKeyTextField;

@property (weak, nonatomic) IBOutlet UIView *recoveryKeyView;

@property (weak, nonatomic) IBOutlet UIButton *exportRecoveryButton;
@property (weak, nonatomic) IBOutlet UIButton *closeButton;

@property (getter=isRecoveryKeyExported) BOOL recoveryKeyExported;

@end

@implementation EnabledTwoFactorAuthenticationViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = NSLocalizedString(@"twoFactorAuthentication", @"A title for the Two-Factor Authentication section on the My Account - Security page.");
    self.titleLabel.text = NSLocalizedString(@"twoFactorAuthenticationEnabled", @"A title on the mobile web client page showing that 2FA has been enabled successfully.");
    self.firstLabel.text = NSLocalizedString(@"twoFactorAuthenticationEnabledDescription", @"A message on the dialog shown after 2FA was successfully enabled.");
    self.secondLabel.text = NSLocalizedString(@"twoFactorAuthenticationEnabledWarning", @"An informational message on the Backup Recovery Key dialog.");
    self.recoveryKeyTextField.text = [NSString stringWithFormat:@"%@.txt", NSLocalizedString(@"general.security.recoveryKeyFile", @"Name for the recovery key file")];

    self.recoveryKeyView.layer.borderColor = [UIColor mnz_secondaryGrayForTraitCollection:self.traitCollection].CGColor;
    
    [self.exportRecoveryButton setTitle:NSLocalizedString(@"exportRecoveryKey", @"A dialog title to export the Recovery Key for the current user.") forState:UIControlStateNormal];
    [self.closeButton setTitle:NSLocalizedString(@"close", @"A button label. The button allows the user to close the conversation.") forState:UIControlStateNormal];
    self.closeButton.layer.borderColor = [UIColor mnz_secondaryGrayForTraitCollection:self.traitCollection].CGColor;
    
    [[MEGASdkManager sharedMEGASdk] isMasterKeyExportedWithDelegate:self];
    
    [self updateAppearance];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    
    if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
        [self updateAppearance];
    }
}

#pragma mark - Private

- (void)updateAppearance {
    self.view.backgroundColor = [UIColor mnz_mainBarsForTraitCollection:self.traitCollection];
    
    self.firstLabel.textColor = self.secondLabel.textColor = [UIColor mnz_subtitlesForTraitCollection:self.traitCollection];
    
    self.recoveryKeyView.backgroundColor = [UIColor mnz_tertiaryBackground:self.traitCollection];
    self.recoveryKeyView.layer.borderColor = [UIColor mnz_separatorForTraitCollection:self.traitCollection].CGColor;
    
    [self.exportRecoveryButton mnz_setupPrimary:self.traitCollection];
    [self.closeButton mnz_setupBasic:self.traitCollection];
}

- (void)showSaveYourRecoveryKeyAlert {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"pleaseSaveYourRecoveryKey", @"A warning message on the Backup Recovery Key dialog to tell the user to backup their Recovery Key to their local computer.") message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"ok", nil) style:UIAlertActionStyleCancel handler:nil]];
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
