
#import "SecurityOptionsTableViewController.h"

#import "SVProgressHUD.h"

#import "MEGAReachabilityManager.h"
#import "MEGASdkManager.h"

#import "ChangePasswordViewController.h"

@interface SecurityOptionsTableViewController () <UITableViewDataSource, UITableViewDelegate, MEGARequestDelegate>

@property (weak, nonatomic) IBOutlet UILabel *masterKeyLabel;
@property (weak, nonatomic) IBOutlet UILabel *masterKeyRightDetailLabel;

@property (weak, nonatomic) IBOutlet UILabel *changePasswordLabel;

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
    
    self.changeEmailLabel.text = AMLocalizedString(@"changeEmail", @"The title of the alert dialog to change the email associated to an account.");
    
    self.closeOtherSessionsLabel.text = AMLocalizedString(@"closeOtherSessions", @"Button text to close other login sessions except the current session in use. This will log out other devices which have an active login session.");
    
    [self isMasterKeyExported];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self isMasterKeyExported];
    
    [self.tableView reloadData];
}

#pragma mark - Private

- (void)isMasterKeyExported {
    NSString *fileExist = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    BOOL isMasterKeyExported = [[NSFileManager defaultManager] fileExistsAtPath:[fileExist stringByAppendingPathComponent:@"RecoveryKey.txt"]];
    self.masterKeyRightDetailLabel.text = isMasterKeyExported ? AMLocalizedString(@"saved", @"State shown if something is 'Saved' (String as short as possible).") : @"";
}

- (void)pushChangeViewControllerType:(ChangeType)changeType {
    ChangePasswordViewController *changePasswordVC = [self.storyboard instantiateViewControllerWithIdentifier:@"ChangePasswordViewControllerID"];
    changePasswordVC.changeType = changeType;
    [self.navigationController pushViewController:changePasswordVC animated:YES];
}

- (void)passwordReset {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"passwordReset" object:nil];
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 4;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case 0: {
            UIViewController *viewController = [[UIStoryboard storyboardWithName:@"Settings" bundle:nil] instantiateViewControllerWithIdentifier:@"MasterKeyViewControllerID"];
            [self.navigationController pushViewController:viewController animated:YES];
            break;
        }
            
        case 1: {
            [self pushChangeViewControllerType:ChangeTypePassword];
            break;
        }
        
        case 2: {
            [self pushChangeViewControllerType:ChangeTypeEmail];
            break;
        }
            
        case 3: { //Close other sessions
            if ([MEGAReachabilityManager isReachableHUDIfNot]) {
                [[MEGASdkManager sharedMEGASdk] killSession:-1 delegate:self];
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
    
    if (request.type == MEGARequestTypeKillSession) {
        [SVProgressHUD showSuccessWithStatus:AMLocalizedString(@"sessionsClosed", @"Message shown when you click on 'Close other session' to block every session that is opened on other devices except the current one")];
    } else if (request.type == MEGARequestTypeGetRecoveryLink) {
        ChangePasswordViewController *changePasswordVC = [[UIStoryboard storyboardWithName:@"Settings" bundle:nil] instantiateViewControllerWithIdentifier:@"ChangePasswordViewControllerID"];
        changePasswordVC.emailIsChangingTitleLabel.text = AMLocalizedString(@"awaitingEmailConfirmation", @"Title shown just after doing some action that requires confirming the action by an email");
        changePasswordVC.emailIsChangingDescriptionLabel.text = AMLocalizedString(@"ifYouCantAccessYourEmailAccount", @"Account closure, warning message to remind user to contact MEGA support after he confirms that he wants to cancel account.");
        self.view = changePasswordVC.emailIsChangingView;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(passwordReset) name:@"passwordReset" object:nil];
    }
}

@end
