/**
 * @file SecurityOptionsTableViewController.m
 * @brief View controller that shows advanved settings
 *
 * (c) 2013-2015 by Mega Limited, Auckland, New Zealand
 *
 * This file is part of the MEGA SDK - Client Access Engine.
 *
 * Applications using the MEGA API must present a valid application key
 * and comply with the the rules set forth in the Terms of Service.
 *
 * The MEGA SDK is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 *
 * @copyright Simplified (2-clause) BSD License.
 *
 * You should have received a copy of the license along with this
 * program.
 */

#import "MEGASdkManager.h"

#import "SecurityOptionsTableViewController.h"
#import "CloudDriveTableViewController.h"
#import "ChangePasswordViewController.h"

@interface SecurityOptionsTableViewController () <UIAlertViewDelegate, UITableViewDataSource, UITableViewDelegate> {
    BOOL isMasterKeyExported;
}

@property (weak, nonatomic) IBOutlet UILabel *exportMasterKeyLabel;
@property (weak, nonatomic) IBOutlet UISwitch *masterKeySwitch;
@property (weak, nonatomic) IBOutlet UILabel *changePasswordLabel;

@end

@implementation SecurityOptionsTableViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.navigationItem setTitle:AMLocalizedString(@"securityOptions", @"Title for Security Options section")];
    
    [self.exportMasterKeyLabel setText:AMLocalizedString(@"masterKey", nil)];
    [self.changePasswordLabel setText:AMLocalizedString(@"changePasswordLabel", @"The name for the change password label")];
    
    [self reloadUI];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self isMasterKeyExported];
    [_masterKeySwitch setOn:isMasterKeyExported animated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
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
        case 1: {
            ChangePasswordViewController *changePasswordVC = [self.storyboard instantiateViewControllerWithIdentifier:@"ChangePasswordViewControllerID"];
            [self.navigationController pushViewController:changePasswordVC animated:YES];
            
            break;
        }
            
        default:
            break;
    }
}

@end
