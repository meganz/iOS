
#import "SecurityOptionsTableViewController.h"

#import "SVProgressHUD.h"

#import "MEGAMultiFactorAuthCheckRequestDelegate.h"
#import "MEGAReachabilityManager.h"
#import "MEGASdkManager.h"

#import "AwaitingEmailConfirmationView.h"
#import "ChangePasswordViewController.h"
#import "SetupTwoFactorAuthenticationTableViewController.h"
#import "QRSettingsTableViewController.h"

@interface SecurityOptionsTableViewController () <UITableViewDataSource, UITableViewDelegate, MEGARequestDelegate>

@property (weak, nonatomic) IBOutlet UILabel *masterKeyLabel;
@property (weak, nonatomic) IBOutlet UILabel *masterKeyRightDetailLabel;

@property (weak, nonatomic) IBOutlet UILabel *changePasswordLabel;

@property (weak, nonatomic) IBOutlet UILabel *twoFactorAuthenticationLabel;
@property (weak, nonatomic) IBOutlet UILabel *twoFactorAuthenticationRightDetailLabel;
@property (getter=isTwoFactorAuthenticationEnabled) BOOL twoFactorAuthenticationEnabled;

@property (weak, nonatomic) IBOutlet UILabel *qrCodeLabel;

@property (weak, nonatomic) IBOutlet UILabel *changeEmailLabel;

@property (weak, nonatomic) IBOutlet UILabel *closeOtherSessionsLabel;

@end

@implementation SecurityOptionsTableViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.navigationItem setTitle:AMLocalizedString(@"securityOptions", @"Title for Security Options section")];
    
    self.masterKeyLabel.text = AMLocalizedString(@"masterKey", nil);
    self.masterKeyRightDetailLabel.text = @"";
    
    [self.changePasswordLabel setText:AMLocalizedString(@"changePasswordLabel", @"The name for the change password label")];
    
    self.twoFactorAuthenticationLabel.text = AMLocalizedString(@"twoFactorAuthentication", @"");
    self.twoFactorAuthenticationRightDetailLabel.text = @"";
    
    self.qrCodeLabel.text = AMLocalizedString(@"qrCode", @"QR Code label, used in Settings as title. String as short as possible");
    
    self.changeEmailLabel.text = AMLocalizedString(@"changeEmail", @"The title of the alert dialog to change the email associated to an account.");
    
    self.closeOtherSessionsLabel.text = AMLocalizedString(@"closeOtherSessions", @"Button text to close other login sessions except the current session in use. This will log out other devices which have an active login session.");
    
    [self isMasterKeyExported];
    
    self.closeOtherSessionsLabel.textColor = [UIColor mnz_redMainForTraitCollection:self.traitCollection];
    self.masterKeyRightDetailLabel.textColor = self.twoFactorAuthenticationRightDetailLabel.textColor = [UIColor mnz_primaryGrayForTraitCollection:self.traitCollection];
    self.tableView.backgroundColor = [UIColor mnz_settingsBackgroundForTraitCollection:self.traitCollection];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self isMasterKeyExported];
    
    [self twoFactorAuthenticationStatus];
    
    [self.tableView reloadData];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    
    if (@available(iOS 13.0, *)) {
        if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
            [self updateUI];
        }
    }
}

#pragma mark - Private

- (void)updateUI {
    self.tableView.separatorColor = [UIColor mnz_separatorColorForTraitCollection:self.traitCollection];
    self.tableView.backgroundColor = [UIColor mnz_settingsBackgroundForTraitCollection:self.traitCollection];
    
    [self.tableView reloadData];
}

- (void)isMasterKeyExported {
    NSString *fileExist = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    BOOL isMasterKeyExported = [[NSFileManager defaultManager] fileExistsAtPath:[fileExist stringByAppendingPathComponent:@"RecoveryKey.txt"]];
    self.masterKeyRightDetailLabel.text = isMasterKeyExported ? AMLocalizedString(@"saved", @"State shown if something is 'Saved' (String as short as possible).") : @"";
}

- (void)twoFactorAuthenticationStatus {
    MEGAMultiFactorAuthCheckRequestDelegate *delegate = [[MEGAMultiFactorAuthCheckRequestDelegate alloc] initWithCompletion:^(MEGARequest *request, MEGAError *error) {
        self.twoFactorAuthenticationEnabled = request.flag;
        self.twoFactorAuthenticationRightDetailLabel.text = self.twoFactorAuthenticationEnabled ? AMLocalizedString(@"on", nil) : AMLocalizedString(@"off", nil);
        [self.tableView reloadData];
    }];
    [[MEGASdkManager sharedMEGASdk] multiFactorAuthCheckWithEmail:[[MEGASdkManager sharedMEGASdk] myEmail] delegate:delegate];
}

- (void)pushChangeViewControllerType:(ChangeType)changeType {
    ChangePasswordViewController *changePasswordVC = [self.storyboard instantiateViewControllerWithIdentifier:@"ChangePasswordViewControllerID"];
    changePasswordVC.changeType = changeType;
    changePasswordVC.twoFactorAuthenticationEnabled = self.twoFactorAuthenticationEnabled;
    
    [self.navigationController pushViewController:changePasswordVC animated:YES];
}

- (void)passwordReset {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"passwordReset" object:nil];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)pushQRSettings {
    QRSettingsTableViewController *qrSettingsTVC = [self.storyboard instantiateViewControllerWithIdentifier:@"QRSettingsTableViewControllerID"];
    qrSettingsTVC.navigationItem.rightBarButtonItem = nil;
    [self.navigationController pushViewController:qrSettingsTVC animated:YES];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 1) {
        return [[MEGASdkManager sharedMEGASdk] multiFactorAuthAvailable] ? 2 : 1;
    }
    
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return AMLocalizedString(@"exportMasterKeyFooter", @"The footer label for the export Recovery Key section in advanced view");
            break;
            
        default:
            return @"";
            break;
    }
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = [UIColor mnz_settingsDetailsBackgroundForTraitCollection:self.traitCollection];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case 0: {
            UIViewController *viewController = [[UIStoryboard storyboardWithName:@"Settings" bundle:nil] instantiateViewControllerWithIdentifier:@"MasterKeyViewControllerID"];
            [self.navigationController pushViewController:viewController animated:YES];
            break;
        }
            
        case 1: {
            if (indexPath.row == 0) {
                [self pushChangeViewControllerType:ChangeTypePassword];
            } else {
                SetupTwoFactorAuthenticationTableViewController *setupTwoFactorAuthenticationTVC = [[UIStoryboard storyboardWithName:@"TwoFactorAuthentication" bundle:nil] instantiateViewControllerWithIdentifier:@"SetupTwoFactorAuthenticationTableViewControllerID"];
                [self.navigationController pushViewController:setupTwoFactorAuthenticationTVC animated:YES];
            }
            break;
        }
            
        case 2:
            [self pushQRSettings];
            break;
        
        case 3: {
            [self pushChangeViewControllerType:ChangeTypeEmail];
            break;
        }
            
        case 4: { //Close other sessions
            if ([MEGAReachabilityManager isReachableHUDIfNot]) {
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:AMLocalizedString(@"Do you want to close all other sessions? This will log you out on all other active sessions except the current one.", @"Confirmation dialog for the button that logs the user out of all sessions except the current one.") preferredStyle:UIAlertControllerStyleAlert];
                [alertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"ok", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    [[MEGASdkManager sharedMEGASdk] killSession:-1 delegate:self];
                }]];
                [alertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"cancel", nil) style:UIAlertActionStyleCancel handler:nil]];
                [self presentViewController:alertController animated:YES completion:nil];
            }
        }
            
        default:
            break;
    }
    
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - MEGARequestDelegate

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    if (error.type) {
        return;
    }
    
    switch (request.type) {
        case MEGARequestTypeKillSession:
            [SVProgressHUD showSuccessWithStatus:AMLocalizedString(@"sessionsClosed", @"Message shown when you click on 'Close other session' to block every session that is opened on other devices except the current one")];
            break;
            
        case MEGARequestTypeGetRecoveryLink: {
            AwaitingEmailConfirmationView *awaitingEmailConfirmationView = [[[NSBundle mainBundle] loadNibNamed:@"AwaitingEmailConfirmationView" owner:self options: nil] firstObject];
            awaitingEmailConfirmationView.titleLabel.text = AMLocalizedString(@"awaitingEmailConfirmation", @"Title shown just after doing some action that requires confirming the action by an email");
            awaitingEmailConfirmationView.descriptionLabel.text = AMLocalizedString(@"ifYouCantAccessYourEmailAccount", @"Account closure, warning message to remind user to contact MEGA support after he confirms that he wants to cancel account.");
            awaitingEmailConfirmationView.frame = self.view.bounds;
            
            self.view = awaitingEmailConfirmationView;
            
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(passwordReset) name:@"passwordReset" object:nil];
            break;
        }
            
        default:
            break;
    }
}

@end
