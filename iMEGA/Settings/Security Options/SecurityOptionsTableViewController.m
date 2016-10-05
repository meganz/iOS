#import "SecurityOptionsTableViewController.h"

#import "SVProgressHUD.h"

#import "MEGASdkManager.h"

#import "CloudDriveTableViewController.h"
#import "ChangePasswordViewController.h"

@interface SecurityOptionsTableViewController () <UIAlertViewDelegate, UITableViewDataSource, UITableViewDelegate, MEGARequestDelegate> {
    BOOL isMasterKeyExported;
}

@property (weak, nonatomic) IBOutlet UILabel *exportMasterKeyLabel;
@property (weak, nonatomic) IBOutlet UISwitch *masterKeySwitch;

@property (weak, nonatomic) IBOutlet UILabel *changePasswordLabel;
@property (weak, nonatomic) IBOutlet UILabel *resetPasswordLabel;

@property (weak, nonatomic) IBOutlet UILabel *changeEmailLabel;

@property (weak, nonatomic) IBOutlet UILabel *closeOtherSessionsLabel;

@end

@implementation SecurityOptionsTableViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.navigationItem setTitle:AMLocalizedString(@"securityOptions", @"Title for Security Options section")];
    
    [self.exportMasterKeyLabel setText:AMLocalizedString(@"masterKey", nil)];
    [self.changePasswordLabel setText:AMLocalizedString(@"changePasswordLabel", @"The name for the change password label")];
    self.resetPasswordLabel.text = AMLocalizedString(@"forgotPassword", @"An option to reset the password.");
    
    self.changeEmailLabel.text = AMLocalizedString(@"changeEmail", @"The title of the alert dialog to change the email associated to an account.");
    
    self.closeOtherSessionsLabel.text = AMLocalizedString(@"closeOtherSessions", @"Button text to close other login sessions except the current session in use. This will log out other devices which have an active login session.");
    
    [self reloadUI];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self isMasterKeyExported];
    [_masterKeySwitch setOn:isMasterKeyExported animated:YES];
}

#pragma mark - Private

- (void)reloadUI {
    [self isMasterKeyExported];
    
    [self.tableView reloadData];
}

- (void)isMasterKeyExported {
    NSString *fileExist = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    isMasterKeyExported = [[NSFileManager defaultManager] fileExistsAtPath:[fileExist stringByAppendingPathComponent:@"RecoveryKey.txt"]];
}

- (void)pushChangeViewControllerType:(ChangeType)changeType {
    ChangePasswordViewController *changePasswordVC = [self.storyboard instantiateViewControllerWithIdentifier:@"ChangePasswordViewControllerID"];
    changePasswordVC.changeType = changeType;
    [self.navigationController pushViewController:changePasswordVC animated:YES];
}

- (void)passwordReset {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"passwordReset" object:nil];
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - IBActions

- (IBAction)masterKeySwitchValueChanged:(UISwitch *)sender {

    if (isMasterKeyExported) {
        NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        NSString *masterKeyFilePath = [documentsDirectory stringByAppendingPathComponent:@"RecoveryKey.txt"];
        BOOL success = [[NSFileManager defaultManager] removeItemAtPath:masterKeyFilePath error:nil];
        
        if (success) {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:AMLocalizedString(@"masterKeyRemoved", nil) message:AMLocalizedString(@"masterKeyRemoved_alertMessage", @"RecoveryKey.txt was removed to the Documents folder") delegate:nil cancelButtonTitle:AMLocalizedString(@"ok", nil) otherButtonTitles:nil, nil];
            [alertView show];
        }
        
    } else {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:AMLocalizedString(@"exportMasterKey", @"Export Recovery Key") message:AMLocalizedString(@"exportMasterKey_alertMessage", @"Message shown when you try to export the Recovery Key to alert the user.") delegate:self cancelButtonTitle:AMLocalizedString(@"cancel", nil) otherButtonTitles:AMLocalizedString(@"ok", nil), nil];
        [alertView setTag:1];
        [alertView show];
    }
    
    [self reloadUI];
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if ((alertView.tag == 1)) {
        if (buttonIndex == 0) {
            [_masterKeySwitch setOn:NO animated:YES];
        } else if (buttonIndex == 1) {
            NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
            NSString *masterKeyFilePath = [documentsDirectory stringByAppendingPathComponent:@"RecoveryKey.txt"];
            
            BOOL success = [[NSFileManager defaultManager] createFileAtPath:masterKeyFilePath contents:[[[MEGASdkManager sharedMEGASdk] masterKey] dataUsingEncoding:NSUTF8StringEncoding] attributes:@{NSFileProtectionKey:NSFileProtectionComplete}];
            
            if (success) {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:AMLocalizedString(@"masterKeyExported", nil) message:AMLocalizedString(@"masterKeyExported_alertMessage", nil) delegate:nil cancelButtonTitle:AMLocalizedString(@"ok", nil) otherButtonTitles:nil, nil];
                [alertView show];
                
                [_masterKeySwitch setOn:YES animated:YES];
            } else {
                [_masterKeySwitch setOn:NO animated:YES];
            }
        }
        [self reloadUI];
    } else  if (alertView.tag == 2) {
        if (buttonIndex == 1) {
            [[MEGASdkManager sharedMEGASdk] resetPasswordWithEmail:[[MEGASdkManager sharedMEGASdk] myEmail] hasMasterKey:YES delegate:self];
            
        }
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 4;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 1) {
        return 2;
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case 1: {
            if (indexPath.row == 0) {
                [self pushChangeViewControllerType:ChangeTypePassword];
            } else if (indexPath.row == 1) {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:AMLocalizedString(@"youWillReceiveARecoveryLink", @"Text of the alert dialog to inform the user that have to check the email after clicking the option forgot password") message:nil delegate:self cancelButtonTitle:AMLocalizedString(@"cancel", nil) otherButtonTitles:AMLocalizedString(@"ok", nil), nil];
                [alertView setTag:2];
                [alertView show];
            }
            break;
        }
        
        case 2: {
            [self pushChangeViewControllerType:ChangeTypeEmail];
            break;
        }
            
        case 3: { //Close other sessions
            [[MEGASdkManager sharedMEGASdk] killSession:-1 delegate:self];
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
        changePasswordVC.emailIsChangingTitleLabel.text = AMLocalizedString(@"pleaseCheckYourEmail", nil);
        changePasswordVC.emailIsChangingDescriptionLabel.text = AMLocalizedString(@"ifYouCantAccessYourEmailAccount", @"Account closure, warning message to remind user to contact MEGA support after he confirms that he wants to cancel account.");
        self.view = changePasswordVC.emailIsChangingView;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(passwordReset) name:@"passwordReset" object:nil];
    }
}

@end
