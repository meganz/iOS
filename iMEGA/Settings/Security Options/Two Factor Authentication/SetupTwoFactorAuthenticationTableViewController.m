
#import "SetupTwoFactorAuthenticationTableViewController.h"

#import "SVProgressHUD.h"

#import "UIApplication+MNZCategory.h"

#import "CustomModalAlertViewController.h"
#import "EnablingTwoFactorAuthenticationViewController.h"
#import "MEGASdkManager.h"
#import "MEGAMultiFactorAuthCheckRequestDelegate.h"
#import "TwoFactorAuthentication.h"
#import "TwoFactorAuthenticationViewController.h"

@interface SetupTwoFactorAuthenticationTableViewController () <MEGARequestDelegate>

@property (weak, nonatomic) IBOutlet UISwitch *twoFactorAuthenticationSwitch;

@property (weak, nonatomic) IBOutlet UILabel *twoFactorAuthenticationLabel;
@property (getter=isTwoFactorAuthenticationEnabled) BOOL twoFactorAuthenticationEnabled;

@end

@implementation SetupTwoFactorAuthenticationTableViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = AMLocalizedString(@"twoFactorAuthentication", @"");
    
    self.twoFactorAuthenticationLabel.text = AMLocalizedString(@"twoFactorAuthentication", @"");
    
    [self updateUI];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    MEGAMultiFactorAuthCheckRequestDelegate *delegate = [[MEGAMultiFactorAuthCheckRequestDelegate alloc] initWithCompletion:^(MEGARequest *request, MEGAError *error) {
        self.twoFactorAuthenticationEnabled = request.flag;
        
        self.twoFactorAuthenticationSwitch.on = self.twoFactorAuthenticationEnabled;
    }];
    [[MEGASdkManager sharedMEGASdk] multiFactorAuthCheckWithEmail:[[MEGASdkManager sharedMEGASdk] myEmail] delegate:delegate];
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

#pragma mark - IBActions

- (IBAction)twoFactorAuthenticationTouchUpInside:(UIButton *)sender {
    if (self.twoFactorAuthenticationSwitch.isOn) {
        TwoFactorAuthenticationViewController *twoFactorAuthenticationVC = [[UIStoryboard storyboardWithName:@"TwoFactorAuthentication" bundle:nil] instantiateViewControllerWithIdentifier:@"TwoFactorAuthenticationViewControllerID"];
        twoFactorAuthenticationVC.twoFAMode = TwoFactorAuthenticationDisable;
        
        [self.navigationController pushViewController:twoFactorAuthenticationVC animated:YES];
    } else {
        CustomModalAlertViewController *customModalAlertVC = [[CustomModalAlertViewController alloc] init];
        customModalAlertVC.modalPresentationStyle = UIModalPresentationOverCurrentContext;
        customModalAlertVC.image = [UIImage imageNamed:@"2FASetup"];
        customModalAlertVC.viewTitle = AMLocalizedString(@"whyYouDoNeedTwoFactorAuthentication", @"Title shown when you start the process to enable Two-Factor Authentication");
        customModalAlertVC.detail = AMLocalizedString(@"whyYouDoNeedTwoFactorAuthenticationDescription", @"Description text of the dialog displayed to start setup the Two-Factor Authentication");
        customModalAlertVC.firstButtonTitle = AMLocalizedString(@"beginSetup", @"Button title to start the setup of a feature. For example 'Begin Setup' for Two-Factor Authentication");
        customModalAlertVC.dismissButtonTitle = AMLocalizedString(@"cancel", @"");
        __weak typeof(CustomModalAlertViewController) *weakCustom = customModalAlertVC;
        customModalAlertVC.firstCompletion = ^{
            [SVProgressHUD show];
            [[MEGASdkManager sharedMEGASdk] multiFactorAuthGetCodeWithDelegate:self];
            
            [weakCustom dismissViewControllerAnimated:YES completion:nil];
        };
        
        customModalAlertVC.dismissCompletion = ^{
            [weakCustom dismissViewControllerAnimated:YES completion:nil];
        };
        
        [UIApplication.mnz_presentingViewController presentViewController:customModalAlertVC animated:YES completion:nil];
    }
}

#pragma mark - UITableViewDataSource

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return AMLocalizedString(@"whatIsTwoFactorAuthentication", @"Text shown as explanation of what is Two-Factor Authentication");
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

#pragma mark - MEGARequestDelegate

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    if (error.type) {
        [SVProgressHUD showErrorWithStatus:error.name];
        return;
    }
    
    switch (request.type) {
        case MEGARequestTypeMultiFactorAuthGet: {
            [SVProgressHUD dismiss];
            
            EnablingTwoFactorAuthenticationViewController *enablingTwoFactorAuthenticationTVC = [[UIStoryboard storyboardWithName:@"TwoFactorAuthentication" bundle:nil] instantiateViewControllerWithIdentifier:@"EnablingTwoFactorAuthenticationViewControllerID"];
            enablingTwoFactorAuthenticationTVC.seed = request.text; //Returns the Base32 secret code needed to configure multi-factor authentication.
            enablingTwoFactorAuthenticationTVC.hidesBottomBarWhenPushed = YES;
            
            [self.navigationController pushViewController:enablingTwoFactorAuthenticationTVC animated:YES];
            break;
        }
            
        default:
            break;
    }
}

@end
