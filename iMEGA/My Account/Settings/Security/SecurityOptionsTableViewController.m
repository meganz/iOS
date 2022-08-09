
#import "SecurityOptionsTableViewController.h"

#import "SVProgressHUD.h"

#import "MEGAGenericRequestDelegate.h"
#import "MEGAMultiFactorAuthCheckRequestDelegate.h"
#import "MEGAReachabilityManager.h"
#import "MEGASdkManager.h"
#import "MEGA-Swift.h"

#import "AwaitingEmailConfirmationView.h"
#import "SetupTwoFactorAuthenticationTableViewController.h"
#import "QRSettingsTableViewController.h"

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
    
    [self.navigationItem setTitle:NSLocalizedString(@"settings.section.security", @"Title for Security section")];
    
    self.twoFactorAuthenticationLabel.text = NSLocalizedString(@"twoFactorAuthentication", @"");
    self.twoFactorAuthenticationRightDetailLabel.text = @"";
    
    self.passcodeLabel.text = NSLocalizedString(@"passcode", @"");
    self.passcodeDetailLabel.text = @"";
    
    self.qrCodeLabel.text = NSLocalizedString(@"qrCode", @"QR Code label, used in Settings as title. String as short as possible");
    
    self.closeOtherSessionsLabel.text = NSLocalizedString(@"closeOtherSessions", @"Button text to close other login sessions except the current session in use. This will log out other devices which have an active login session.");
    
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
    self.tableView.separatorColor = [UIColor mnz_separatorForTraitCollection:self.traitCollection];
    self.tableView.backgroundColor = [UIColor mnz_backgroundGroupedForTraitCollection:self.traitCollection];
    
    self.twoFactorAuthenticationRightDetailLabel.textColor = UIColor.mnz_secondaryLabel;
    self.passcodeDetailLabel.textColor = UIColor.mnz_secondaryLabel;
    
    self.closeOtherSessionsLabel.textColor = [UIColor mnz_redForTraitCollection:self.traitCollection];
}

- (void)twoFactorAuthenticationStatus {
    MEGAMultiFactorAuthCheckRequestDelegate *delegate = [[MEGAMultiFactorAuthCheckRequestDelegate alloc] initWithCompletion:^(MEGARequest *request, MEGAError *error) {
        self.twoFactorAuthenticationEnabled = request.flag;
        self.twoFactorAuthenticationRightDetailLabel.text = self.twoFactorAuthenticationEnabled ? NSLocalizedString(@"on", nil) : NSLocalizedString(@"off", nil);
        [self.tableView reloadData];
    }];
    [[MEGASdkManager sharedMEGASdk] multiFactorAuthCheckWithEmail:[[MEGASdkManager sharedMEGASdk] myEmail] delegate:delegate];
}

- (void)configPasscodeView {
    self.passcodeDetailLabel.text = ([LTHPasscodeViewController doesPasscodeExist] ? NSLocalizedString(@"on", nil) : NSLocalizedString(@"off", nil));
}

- (void)pushQRSettings {
    QRSettingsTableViewController *qrSettingsTVC = [self.storyboard instantiateViewControllerWithIdentifier:@"QRSettingsTableViewControllerID"];
    qrSettingsTVC.navigationItem.rightBarButtonItem = nil;
    [self.navigationController pushViewController:qrSettingsTVC animated:YES];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return MEGASdkManager.sharedMEGASdk.multiFactorAuthAvailable ? 1 : 0;
    }
    
    return 1;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = [UIColor mnz_secondaryBackgroundGrouped:self.traitCollection];
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
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:NSLocalizedString(@"Do you want to close all other sessions? This will log you out on all other active sessions except the current one.", @"Confirmation dialog for the button that logs the user out of all sessions except the current one.") preferredStyle:UIAlertControllerStyleAlert];
                [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"ok", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    MEGAGenericRequestDelegate *delegate = [MEGAGenericRequestDelegate.alloc initWithCompletion:^(MEGARequest *request, MEGAError *error) {
                        if (error.type) {
                            [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"%@", NSLocalizedString(error.name, nil)]];
                        }
                        [SVProgressHUD showSuccessWithStatus:NSLocalizedString(@"sessionsClosed", @"Message shown when you click on 'Close other session' to block every session that is opened on other devices except the current one")];
                    }];
                    [MEGASdkManager.sharedMEGASdk killSession:-1 delegate:delegate];
                }]];
                [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"cancel", nil) style:UIAlertActionStyleCancel handler:nil]];
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
