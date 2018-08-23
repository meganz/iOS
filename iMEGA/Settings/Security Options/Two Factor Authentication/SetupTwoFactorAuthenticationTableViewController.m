
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
    
}

- (void)viewWillAppear:(BOOL)animated {
    MEGAMultiFactorAuthCheckRequestDelegate *delegate = [[MEGAMultiFactorAuthCheckRequestDelegate alloc] initWithCompletion:^(MEGARequest *request, MEGAError *error) {
        self.twoFactorAuthenticationEnabled = request.flag;
        
        self.twoFactorAuthenticationSwitch.on = self.twoFactorAuthenticationEnabled;
    }];
    [[MEGASdkManager sharedMEGASdk] multiFactorAuthCheckWithEmail:[[MEGASdkManager sharedMEGASdk] myEmail] delegate:delegate];
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
        customModalAlertVC.action = AMLocalizedString(@"beginSetup", @"Button title to start the setup of a feature. For example 'Begin Setup' for Two-Factor Authentication");
        customModalAlertVC.actionColor = [UIColor mnz_green00BFA5];
        customModalAlertVC.dismiss = AMLocalizedString(@"cancel", @"");
        customModalAlertVC.dismissColor = [UIColor colorFromHexString:@"899B9C"];
        __weak typeof(CustomModalAlertViewController) *weakCustom = customModalAlertVC;
        customModalAlertVC.completion = ^{
            [SVProgressHUD show];
            [[MEGASdkManager sharedMEGASdk] multiFactorAuthGetCodeWithDelegate:self];
            
            [weakCustom dismissViewControllerAnimated:YES completion:nil];
        };
        
        customModalAlertVC.onDismiss = ^{
            [weakCustom dismissViewControllerAnimated:YES completion:nil];
        };
        
        [UIApplication.mnz_visibleViewController presentViewController:customModalAlertVC animated:YES completion:nil];
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
            
            [self.navigationController pushViewController:enablingTwoFactorAuthenticationTVC animated:YES];
            break;
        }
            
        default:
            break;
    }
}

@end
