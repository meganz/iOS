
#import "EnableTwoFactorAuthenticationTableViewController.h"

#import "SVProgressHUD.h"

#import "MEGASdkManager.h"

#import "EnablingTwoFactorAuthenticationTableViewController.h"

@interface EnableTwoFactorAuthenticationTableViewController () <MEGARequestDelegate>

@property (weak, nonatomic) IBOutlet UILabel *whyYouNeedTwoFactorAuthenticationLabel;
@property (weak, nonatomic) IBOutlet UILabel *whyYouNeedTwoFactorAuthenticationDescriptionLabel;

@property (weak, nonatomic) IBOutlet UILabel *setupTwoFactorAuthenticationLabel;

@end

@implementation EnableTwoFactorAuthenticationTableViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = AMLocalizedString(@"twoFactorAuthentication", @"");
    
    self.whyYouNeedTwoFactorAuthenticationLabel.text = AMLocalizedString(@"whyYouDoNeedTwoFactorAuthentication", @"");
    
    self.whyYouNeedTwoFactorAuthenticationDescriptionLabel.text = AMLocalizedString(@"whyYouDoNeedTwoFactorAuthenticationDescription", @"");
    
    self.setupTwoFactorAuthenticationLabel.text = AMLocalizedString(@"setupTwoFactorAuthentication", @"");
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 0) {
        [SVProgressHUD show];
        [[MEGASdkManager sharedMEGASdk] multiFactorAuthGetCodeWithDelegate:self];
    }
    
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
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
            
            EnablingTwoFactorAuthenticationTableViewController *enablingTwoFactorAuthenticationTVC = [[UIStoryboard storyboardWithName:@"TwoFactorAuthentication" bundle:nil] instantiateViewControllerWithIdentifier:@"EnablingTwoFactorAuthenticationTableViewControllerID"];
            enablingTwoFactorAuthenticationTVC.seed = request.text; //Returns the Base32 secret code needed to configure multi-factor authentication.
            
            [self.navigationController pushViewController:enablingTwoFactorAuthenticationTVC animated:YES];
            break;
        }
            
        default:
            break;
    }
}

@end
