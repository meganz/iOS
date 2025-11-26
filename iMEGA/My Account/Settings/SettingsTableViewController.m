#import "SettingsTableViewController.h"
#import "CameraUploadManager+Settings.h"
#import "MEGAReachabilityManager.h"
#import "MEGA-Swift.h"
#import "NSURL+MNZCategory.h"

#import "LocalizationHelper.h"

@interface SettingsTableViewController ()
@end

@implementation SettingsTableViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    [self bindViewModel];
    [self.tableView registerNib:[UINib nibWithNibName:@"SettingsTableViewCell" bundle:nil] forCellReuseIdentifier:@"SettingsTableViewCell"];
    self.tableView.estimatedRowHeight = 44;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    [self setupColors];
    NSString *title = LocalizedString(@"settingsTitle", @"");
    self.navigationItem.title = title;
    [self setMenuCapableBackButtonWithMenuTitle:title];
}

#pragma mark - Private

- (void)setupColors {
    self.tableView.separatorColor = [UIColor borderStrong];
    self.tableView.backgroundColor = [UIColor pageBackgroundColor];
}

@end
