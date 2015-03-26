/**
 * @file AdvancedTableViewController.m
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

#import "AdvancedTableViewController.h"
#import "CloudDriveTableViewController.h"
#import "MEGASdkManager.h"

@interface AdvancedTableViewController () {
    BOOL existMasterKey;
}

@property (weak, nonatomic) IBOutlet UILabel *rubbishBinLabel;
@property (weak, nonatomic) IBOutlet UILabel *exportMasterKeyLabel;
@property (weak, nonatomic) IBOutlet UILabel *changePasswordLabel;

@end

@implementation AdvancedTableViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.navigationItem setTitle:NSLocalizedString(@"advancedLabel", "The title for the advanced view")];
    
    [self.rubbishBinLabel setText:NSLocalizedString(@"rubbishBinLabel", "The name for the rubbish bin label")];
    [self.exportMasterKeyLabel setText:NSLocalizedString(@"exportMasterKeyLabel", "The name for the export master key label")];
    [self.changePasswordLabel setText:NSLocalizedString(@"changePasswordLabel", "The name for the change password label")];
    
    [self reloadUI];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)reloadUI {
    NSString *fileExist = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    existMasterKey = [[NSFileManager defaultManager] fileExistsAtPath:[fileExist stringByAppendingPathComponent:@"MasterKey.txt"]];
    
    if (existMasterKey) {
        [self.exportMasterKeyLabel setText:NSLocalizedString(@"cleanupMasterKeyLabel", "Cleanup Master Key")];
    } else {
        [self.exportMasterKeyLabel setText:NSLocalizedString(@"exportMasterKeyLabel", "The name for the export master key label")];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return [NSString stringWithFormat:NSLocalizedString(@"rubbishBinFooter", "The footer label for the rubbish bin section in advanced view")];
            break;
            
        case 1:
            if (existMasterKey) {
                return [NSString stringWithFormat:NSLocalizedString(@"cleanupMasterKeyFooter", "Delete the Master Key from the sandbox of the application")];
            } else {
                return [NSString stringWithFormat:NSLocalizedString(@"exportMasterKeyFooter", "The footer label for the export Master Key section in advanced view")];
            }
            
            break;
            
        default:
            return @"";
            break;
    }
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    //Rubbish bin
    if (indexPath.section == 0) {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Cloud" bundle:nil];
        CloudDriveTableViewController *cloud = [storyboard instantiateViewControllerWithIdentifier:@"CloudDriveID"];
        
        [self.navigationController pushViewController:cloud animated:YES];
        cloud.navigationItem.title = NSLocalizedString(@"rubbishBinLabel", "The name for the rubbish bin label");
        
        [cloud setParentNode:[[MEGASdkManager sharedMEGASdk] rubbishNode]];
        [cloud setDisplayMode:DisplayModeRubbishBin];
    }
    
    //Export Master Key
    if (indexPath.section == 1) {
        NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        NSString *masterKeyFilePath = [documentsDirectory stringByAppendingPathComponent:@"MasterKey.txt"];
        
        if (existMasterKey) {
            BOOL success = [[NSFileManager defaultManager] removeItemAtPath:masterKeyFilePath error:nil];
            
            if (success) {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"cleanupMasterKeyAlertTitle", "Master Key cleaned") message:NSLocalizedString(@"cleanupMasterKeyAlertMessage", "MasterKey.txt was removed to the Documents folder") delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
                [alertView show];
            }
        
        } else {
            BOOL success = [[NSFileManager defaultManager] createFileAtPath:masterKeyFilePath contents:[[[MEGASdkManager sharedMEGASdk] masterKey] dataUsingEncoding:NSUTF8StringEncoding] attributes:@{NSFileProtectionKey:NSFileProtectionComplete}];
            
            if (success) {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"exportMasterKeyAlertTitle", nil) message:NSLocalizedString(@"exportMasterKeyAlertMessage", nil) delegate:nil cancelButtonTitle:@"Got it" otherButtonTitles:nil, nil];
                [alertView show];
            }
        }
        
        [self reloadUI];
        [self.tableView reloadData];
    }
    
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
