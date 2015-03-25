
#import "AdvancedTableViewController.h"
#import "CloudDriveTableViewController.h"
#import "MEGASdkManager.h"

@interface AdvancedTableViewController ()

@property (weak, nonatomic) IBOutlet UILabel *rubbishBinLabel;
@property (weak, nonatomic) IBOutlet UILabel *exportMasterKeyLabel;

@end

@implementation AdvancedTableViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.navigationItem setTitle:NSLocalizedString(@"advancedLabel", "The title for the advanced view")];
    
    [self.rubbishBinLabel setText:NSLocalizedString(@"rubbishBinLabel", "The name for the rubbish bin label")];
    [self.exportMasterKeyLabel setText:NSLocalizedString(@"exportMasterKeyLabel", "The name for the export master key label")];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
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
            return [NSString stringWithFormat:NSLocalizedString(@"exportMasterKeyFooter", "The footer label for the export Master Key section in advanced view")];
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
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *masterKeyFilePath = [documentsDirectory stringByAppendingPathComponent:@"MasterKey.txt"];
        BOOL success = [[NSFileManager defaultManager] createFileAtPath:masterKeyFilePath contents:[[[MEGASdkManager sharedMEGASdk] masterKey] dataUsingEncoding:NSUTF8StringEncoding] attributes:nil];
        
        if (success) {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"exportMasterKeyAlertTitle", nil) message:NSLocalizedString(@"exportMasterKeyAlertMessage", nil) delegate:nil cancelButtonTitle:@"Got it" otherButtonTitles:nil, nil];
            [alertView show];
        }
    }
    
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
