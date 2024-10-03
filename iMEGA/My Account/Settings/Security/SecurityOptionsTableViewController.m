#import "SecurityOptionsTableViewController.h"

#import "SVProgressHUD.h"

#import "MEGAMultiFactorAuthCheckRequestDelegate.h"
#import "MEGAReachabilityManager.h"
#import "MEGA-Swift.h"

#import "AwaitingEmailConfirmationView.h"
#import "SetupTwoFactorAuthenticationTableViewController.h"
#import "QRSettingsTableViewController.h"

@import MEGAL10nObjc;
@import MEGASDKRepo;

@interface SecurityOptionsTableViewController () <UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UILabel *twoFactorAuthenticationLabel;
@property (weak, nonatomic) IBOutlet UILabel *twoFactorAuthenticationRightDetailLabel;
@property (getter=isTwoFactorAuthenticationEnabled) BOOL twoFactorAuthenticationEnabled;

@property (weak, nonatomic) IBOutlet UILabel *passcodeLabel;
@property (weak, nonatomic) IBOutlet UILabel *passcodeDetailLabel;

@property (weak, nonatomic) IBOutlet UILabel *qrCodeLabel;

@property (weak, nonatomic) IBOutlet UILabel *closeOtherSessionsLabel;

@end

@implementation SecurityOptionsTableViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSString *title = LocalizedString(@"settings.section.security", @"Title for Security section");
    [self.navigationItem setTitle:title];
    [self setMenuCapableBackButtonWithMenuTitle:title];
    
    self.twoFactorAuthenticationLabel.text = LocalizedString(@"twoFactorAuthentication", @"");
    self.twoFactorAuthenticationRightDetailLabel.text = @"";
    
    self.passcodeLabel.text = LocalizedString(@"passcode", @"");
    self.passcodeDetailLabel.text = @"";
    
    self.qrCodeLabel.text = LocalizedString(@"qrCode", @"QR Code label, used in Settings as title. String as short as possible");
    
    self.closeOtherSessionsLabel.text = LocalizedString(@"closeOtherSessions", @"Button text to close other login sessions except the current session in use. This will log out other devices which have an active login session.");
    
    [self updateAppearance];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self twoFactorAuthenticationStatus];
    
    [self configPasscodeView];
    
    [self.tableView reloadData];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    
    if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
        [self updateAppearance];
        
        [self.tableView reloadData];
    }
}

#pragma mark - Private

- (void)updateAppearance {
    self.tableView.separatorColor = [UIColor mnz_separator];
    self.tableView.backgroundColor = [UIColor mnz_backgroundGroupedForTraitCollection:self.traitCollection];
    
    self.twoFactorAuthenticationLabel.textColor = UIColor.primaryTextColor;
    self.passcodeLabel.textColor = UIColor.primaryTextColor;

    self.twoFactorAuthenticationRightDetailLabel.textColor = UIColor.mnz_secondaryTextColor;
    self.passcodeDetailLabel.textColor = UIColor.mnz_secondaryTextColor;

    self.closeOtherSessionsLabel.textColor = [UIColor mnz_errorRed];
}

- (void)twoFactorAuthenticationStatus {
    MEGAMultiFactorAuthCheckRequestDelegate *delegate = [[MEGAMultiFactorAuthCheckRequestDelegate alloc] initWithCompletion:^(MEGARequest *request, MEGAError *error) {
        self.twoFactorAuthenticationEnabled = request.flag;
        self.twoFactorAuthenticationRightDetailLabel.text = self.twoFactorAuthenticationEnabled ? LocalizedString(@"on", @"") : LocalizedString(@"off", @"");
        [self.tableView reloadData];
    }];
    [MEGASdk.shared multiFactorAuthCheckWithEmail:[MEGASdk.shared myEmail] delegate:delegate];
}

- (void)configPasscodeView {
    self.passcodeDetailLabel.text = ([LTHPasscodeViewController doesPasscodeExist] ? LocalizedString(@"on", @"") : LocalizedString(@"off", @""));
}

- (void)pushQRSettings {
    QRSettingsTableViewController *qrSettingsTVC = [self.storyboard instantiateViewControllerWithIdentifier:@"QRSettingsTableViewControllerID"];
    qrSettingsTVC.navigationItem.rightBarButtonItem = nil;
    [self.navigationController pushViewController:qrSettingsTVC animated:YES];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return MEGASdk.shared.multiFactorAuthAvailable ? 1 : 0;
    }
    
    return 1;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = [UIColor mnz_backgroundElevated];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case 0: {
            SetupTwoFactorAuthenticationTableViewController *setupTwoFactorAuthenticationTVC = [[UIStoryboard storyboardWithName:@"TwoFactorAuthentication" bundle:nil] instantiateViewControllerWithIdentifier:@"SetupTwoFactorAuthenticationTableViewControllerID"];
            [self.navigationController pushViewController:setupTwoFactorAuthenticationTVC animated:YES];
            break;
        }
            
        case 1:
            break;
            
        case 2:
            [self pushQRSettings];
            break;
            
        case 3: { //Close other sessions
            if ([MEGAReachabilityManager isReachableHUDIfNot]) {
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:LocalizedString(@"Do you want to close all other sessions? This will log you out on all other active sessions except the current one.", @"Confirmation dialog for the button that logs the user out of all sessions except the current one.") preferredStyle:UIAlertControllerStyleAlert];
                [alertController addAction:[UIAlertAction actionWithTitle:LocalizedString(@"ok", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    RequestDelegate *delegate = [RequestDelegate.alloc initWithCompletion:^(MEGARequest * _Nullable request, MEGAError * _Nullable error) {
                        if (error.type) {
                            [SVProgressHUD showErrorWithStatus:LocalizedString(error.name, @"")];
                        }
                        [SVProgressHUD showSuccessWithStatus:LocalizedString(@"sessionsClosed", @"Message shown when you click on 'Close other session' to block every session that is opened on other devices except the current one")];
                    }];
                    [MEGASdk.shared killSession:-1 delegate:delegate];
                }]];
                [alertController addAction:[UIAlertAction actionWithTitle:LocalizedString(@"cancel", @"") style:UIAlertActionStyleCancel handler:nil]];
                [self presentViewController:alertController animated:YES completion:nil];
                
                break;
            }
        }
            
        default:
            break;
    }
    
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
