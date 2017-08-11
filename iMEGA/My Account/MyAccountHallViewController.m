
#import "MyAccountHallViewController.h"

#import "MEGASdkManager.h"
#import "UIImageView+MNZCategory.h"

#import "ContactsViewController.h"
#import "OfflineTableViewController.h"
#import "MEGAUser+MNZCategory.h"
#import "MyAccountHallTableViewCell.h"
#import "MyAccountViewController.h"
#import "SettingsTableViewController.h"
#import "TransfersViewController.h"

@interface MyAccountHallViewController () <UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UIView *profileView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *viewAndEditProfileLabel;
@property (weak, nonatomic) IBOutlet UIButton *viewAndEditProfileButton;
@property (weak, nonatomic) IBOutlet UIImageView *avatarImageView;

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation MyAccountHallViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = AMLocalizedString(@"myAccount", @"Title of the app section where you can see your account details");
    
    self.nameLabel.text = [[[MEGASdkManager sharedMEGASdk] myUser] mnz_fullName];
    self.viewAndEditProfileLabel.text = AMLocalizedString(@"viewAndEditProfile", @"Title show on the hall of My Account section that describes a place where you can view, edit and upgrade your account and profile");
    
    MEGAUser *myUser = [[MEGASdkManager sharedMEGASdk] myUser];
    [self.avatarImageView mnz_setImageForUserHandle:myUser.handle];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.tableView reloadData];
}

#pragma mark - IBActions

- (IBAction)viewAndEditProfileTouchUpInside:(UIButton *)sender {
    MyAccountViewController *myAccountVC = [[UIStoryboard storyboardWithName:@"MyAccount" bundle:nil] instantiateViewControllerWithIdentifier:@"MyAccountViewControllerID"];
    [self.navigationController pushViewController:myAccountVC animated:YES];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 4;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    MyAccountHallTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MyAccountHallTableViewCellID" forIndexPath:indexPath];
    if (cell == nil) {
        cell = [[MyAccountHallTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"MyAccountHallTableViewCellID"];
    }
    
    switch (indexPath.row) {
        case 0: { //Offline
            cell.sectionLabel.text = AMLocalizedString(@"offline", @"Title of the Offline section");
            cell.iconImageView.image = [UIImage imageNamed:@"offlineIcon"];
            cell.pendingView.hidden = YES;
            cell.pendingLabel.text = nil;
            break;
        }
            
        case 1: { //Contacts
            cell.sectionLabel.text = AMLocalizedString(@"contactsTitle", @"Title of the Contacts section");
            cell.iconImageView.image = [UIImage imageNamed:@"contactsIcon"];
            MEGAContactRequestList *incomingContactsLists = [[MEGASdkManager sharedMEGASdk] incomingContactRequests];
            NSUInteger incomingContacts = incomingContactsLists.size.unsignedIntegerValue;
            if (incomingContacts == 0) {
                cell.pendingView.hidden = YES;
                cell.pendingLabel.text = nil;
            } else {
                if (cell.pendingView.hidden) {
                    cell.pendingView.hidden = NO;
                    cell.pendingView.clipsToBounds = YES;
                }
        
                cell.pendingLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)incomingContacts];
            }
            break;
        }
            
        case 2: { //Transfers
            cell.sectionLabel.text = AMLocalizedString(@"transfers", @"Title of the Transfers section");
            cell.iconImageView.image = [UIImage imageNamed:@"transfersIcon"];
            cell.pendingView.hidden = YES;
            cell.pendingLabel.text = nil;
            break;
        }
        
        case 3: { //Settings
            cell.sectionLabel.text = AMLocalizedString(@"settingsTitle", @"Title of the Settings section");
            cell.iconImageView.image = [UIImage imageNamed:@"settingsIcon"];
            cell.pendingView.hidden = YES;
            cell.pendingLabel.text = nil;
            break;
        }
    }
    
    [cell.sectionLabel sizeToFit];
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.row) {
        case 0: { //Offline
            OfflineTableViewController *offlineTVC = [[UIStoryboard storyboardWithName:@"Offline" bundle:nil] instantiateViewControllerWithIdentifier:@"OfflineTableViewControllerID"];
            [self.navigationController pushViewController:offlineTVC animated:YES];
            break;
        }
            
        case 1: { //Contacts
            ContactsViewController *contactsVC = [[UIStoryboard storyboardWithName:@"Contacts" bundle:nil] instantiateViewControllerWithIdentifier:@"ContactsViewControllerID"];
            [self.navigationController pushViewController:contactsVC animated:YES];
            break;
        }
            
        case 2: { //Transfers
            TransfersViewController *transferVC = [[UIStoryboard storyboardWithName:@"Transfers" bundle:nil] instantiateViewControllerWithIdentifier:@"TransfersViewControllerID"];
            [self.navigationController pushViewController:transferVC animated:YES];
            break;
        }
            
        case 3: { //Settings
            SettingsTableViewController *settingsTVC = [[UIStoryboard storyboardWithName:@"Settings" bundle:nil] instantiateViewControllerWithIdentifier:@"SettingsTableViewControllerID"];
            [self.navigationController pushViewController:settingsTVC animated:YES];
            break;
        }
    }
    
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}


@end
