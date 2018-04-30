
#import "MyAccountHallViewController.h"

#import "AchievementsViewController.h"
#import "ContactsViewController.h"
#import "OfflineTableViewController.h"
#import "MEGANavigationController.h"
#import "MEGAPurchase.h"
#import "MEGASdk+MNZCategory.h"
#import "MEGAUser+MNZCategory.h"
#import "MEGAReachabilityManager.h"
#import "MEGASdkManager.h"
#import "MyAccountHallTableViewCell.h"
#import "MyAccountViewController.h"
#import "SettingsTableViewController.h"
#import "TransfersViewController.h"
#import "UpgradeTableViewController.h"
#import "UsageViewController.h"

@interface MyAccountHallViewController () <UITableViewDataSource, UITableViewDelegate, MEGAPurchasePricingDelegate, MEGAGlobalDelegate, MEGARequestDelegate>

@property (weak, nonatomic) IBOutlet UIBarButtonItem *buyPROBarButtonItem;

@property (weak, nonatomic) IBOutlet UIView *profileView;

@property (weak, nonatomic) IBOutlet UILabel *viewAndEditProfileLabel;

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (strong, nonatomic) NSByteCountFormatter *byteCountFormatter;
@property (strong, nonatomic) NSNumberFormatter *numberFormatter;
@property (strong, nonatomic) NSNumber *cloudDriveSize;
@property (strong, nonatomic) NSNumber *rubbishBinSize;
@property (strong, nonatomic) NSNumber *incomingSharesSize;
@property (strong, nonatomic) NSNumber *usedStorage;
@property (strong, nonatomic) NSNumber *maxStorage;

@end

@implementation MyAccountHallViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = AMLocalizedString(@"myAccount", @"Title of the app section where you can see your account details");
    
    self.buyPROBarButtonItem.title = AMLocalizedString(@"upgrade", @"Caption of a button to upgrade the account to Pro status");
    
    self.viewAndEditProfileLabel.text = AMLocalizedString(@"viewAndEditProfile", @"Title show on the hall of My Account section that describes a place where you can view, edit and upgrade your account and profile");
    
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(viewAndEditProfileTouchUpInside:)];
    self.profileView.gestureRecognizers = @[tapGestureRecognizer];
    
    _byteCountFormatter = [[NSByteCountFormatter alloc] init];
    [_byteCountFormatter setCountStyle:NSByteCountFormatterCountStyleMemory];
    
    _numberFormatter = [[NSNumberFormatter alloc] init];
    [_numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
    [_numberFormatter setLocale:[NSLocale currentLocale]];
    [_numberFormatter setMaximumFractionDigits:0];
    
    [[MEGAPurchase sharedInstance] setPricingsDelegate:self];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[MEGASdkManager sharedMEGASdk] addMEGARequestDelegate:self];
    [[MEGASdkManager sharedMEGASdk] addMEGAGlobalDelegate:self];
    
    [self reloadUI];
    self.buyPROBarButtonItem.enabled = [MEGAPurchase sharedInstance].products.count;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[MEGASdkManager sharedMEGASdk] removeMEGAGlobalDelegate:self];
}

#pragma mark - Private

- (void)reloadUI {
    self.nameLabel.text = [[[MEGASdkManager sharedMEGASdk] myUser] mnz_fullName];
    [self setUserAvatar];
    
    [self.tableView reloadData];
}

- (void)initializeStorageInfo {
    MEGAAccountDetails *accountDetails = [[MEGASdkManager sharedMEGASdk] mnz_accountDetails];
    
    self.cloudDriveSize = [accountDetails storageUsedForHandle:[[[MEGASdkManager sharedMEGASdk] rootNode] handle]];
    self.rubbishBinSize = [accountDetails storageUsedForHandle:[[[MEGASdkManager sharedMEGASdk] rubbishNode] handle]];
    
    MEGANodeList *incomingShares = [[MEGASdkManager sharedMEGASdk] inShares];
    NSUInteger count = incomingShares.size.unsignedIntegerValue;
    long long incomingSharesSizeLongLong = 0;
    for (NSUInteger i = 0; i < count; i++) {
        MEGANode *node = [incomingShares nodeAtIndex:i];
        incomingSharesSizeLongLong += [[[MEGASdkManager sharedMEGASdk] sizeForNode:node] longLongValue];
    }
    self.incomingSharesSize = [NSNumber numberWithLongLong:incomingSharesSizeLongLong];
    
    self.usedStorage = accountDetails.storageUsed;
    self.maxStorage = accountDetails.storageMax;
}

- (void)openOffline {
    NSArray *viewControllers = self.navigationController.viewControllers;
    if (viewControllers.count > 1) {
        [self.navigationController popToRootViewControllerAnimated:NO];
    }
    
    NSIndexPath *offlineIndexPath = [NSIndexPath indexPathForRow:4 inSection:0];
    [self tableView:self.tableView didSelectRowAtIndexPath:offlineIndexPath];
}

#pragma mark - IBActions

- (IBAction)buyPROTouchUpInside:(UIBarButtonItem *)sender {
    if ([[MEGASdkManager sharedMEGASdk] mnz_accountDetails]) {
        UpgradeTableViewController *upgradeTVC = [[UIStoryboard storyboardWithName:@"MyAccount" bundle:nil] instantiateViewControllerWithIdentifier:@"UpgradeID"];
        MEGANavigationController *navigationController = [[MEGANavigationController alloc] initWithRootViewController:upgradeTVC];
        
        [self presentViewController:navigationController animated:YES completion:nil];
    } else {
         [MEGAReachabilityManager isReachableHUDIfNot];
    }
}

- (IBAction)viewAndEditProfileTouchUpInside:(UIButton *)sender {
    MyAccountViewController *myAccountVC = [[UIStoryboard storyboardWithName:@"MyAccount" bundle:nil] instantiateViewControllerWithIdentifier:@"MyAccountViewControllerID"];
    [self.navigationController pushViewController:myAccountVC animated:YES];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 6;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *identifier;
    if (indexPath.row == 0) {
        identifier = @"MyAccountHallUsedStorageTableViewCellID";
    } else if (indexPath.row == 2) {
        identifier = @"MyAccountHallWithSubtitleTableViewCellID";
    } else {
        identifier = @"MyAccountHallTableViewCellID";
    }
    
    MyAccountHallTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier forIndexPath:indexPath];
    if (cell == nil) {
        cell = [[MyAccountHallTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
    
    switch (indexPath.row) {
        case 0: { // Used Storage
            cell.sectionLabel.text = AMLocalizedString(@"usedStorage", @"Title of the Used Storage section");
            
            if ([[MEGASdkManager sharedMEGASdk] mnz_accountDetails]) {
                MEGAAccountDetails *accountDetails = [[MEGASdkManager sharedMEGASdk] mnz_accountDetails];
                cell.usedLabel.text = [self.byteCountFormatter stringFromByteCount:accountDetails.storageUsed.longLongValue];
                NSNumber *number = [NSNumber numberWithFloat:((accountDetails.storageUsed.floatValue / accountDetails.storageMax.floatValue) * 100)];
                NSString *percentageString = [self.numberFormatter stringFromNumber:number];
                NSString *ofString = [NSString stringWithFormat:AMLocalizedString(@"of %@", @"Sentece showed under the used space percentage to complete the info with the maximum storage."), [self.byteCountFormatter stringFromByteCount:accountDetails.storageMax.longLongValue]];
                cell.usedPercentageLabel.text = [NSString stringWithFormat:@"%@ %% %@", percentageString, ofString];
                cell.usedProgressView.progress = number.floatValue / 100;
            } else {
                cell.usedLabel.text = @"";
                cell.usedPercentageLabel.text = @"";
                cell.usedProgressView.progress = 0;
            }
            break;
        }
            
        case 1: {  //Contacts
            cell.sectionLabel.text = AMLocalizedString(@"contactsTitle", @"Title of the Contacts section");
            cell.iconImageView.image = [UIImage imageNamed:@"myAccountContactsIcon"];
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
            
        case 2: { //Achievements
            cell.sectionLabel.text = AMLocalizedString(@"achievementsTitle", @"Title of the Achievements section");
            cell.subtitleLabel.text = AMLocalizedString(@"inviteFriendsAndGetRewards", @"Subtitle show under the Achievements label to explain what is this section");
            cell.iconImageView.image = [UIImage imageNamed:@"myAccountAchievementsIcon"];
            cell.pendingView.hidden = YES;
            cell.pendingLabel.text = nil;
            break;
        }
            
        case 3: { //Transfers
            cell.sectionLabel.text = AMLocalizedString(@"transfers", @"Title of the Transfers section");
            cell.iconImageView.image = [UIImage imageNamed:@"myAccountTransfersIcon"];
            cell.pendingView.hidden = YES;
            cell.pendingLabel.text = nil;
            break;
        }
            
        case 4: { //Offline
            cell.sectionLabel.text = AMLocalizedString(@"offline", @"Title of the Offline section");
            cell.iconImageView.image = [UIImage imageNamed:@"myAccountOfflineIcon"];
            cell.pendingView.hidden = YES;
            cell.pendingLabel.text = nil;
            break;
        }
            
        case 5: {
            //Settings
            cell.sectionLabel.text = AMLocalizedString(@"settingsTitle", @"Title of the Settings section");
            cell.iconImageView.image = [UIImage imageNamed:@"myAccountSettingsIcon"];
            cell.pendingView.hidden = YES;
            cell.pendingLabel.text = nil;
            break;
        }
    }
    
    [cell.sectionLabel sizeToFit];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat heightForRow;
    if (indexPath.row == 2 && ![[MEGASdkManager sharedMEGASdk] isAchievementsEnabled]) {
        heightForRow = 0.0f;
    } else {
        heightForRow = 60.0f;
    }
    
    return heightForRow;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.row) {
        case 0: { // Used Storage
            if ([[MEGASdkManager sharedMEGASdk] mnz_accountDetails]) {
                if (!self.cloudDriveSize || !self.rubbishBinSize || !self.incomingSharesSize || !self.usedStorage || !self.maxStorage) {
                    [self initializeStorageInfo];
                }
                NSArray *sizesArray = @[self.cloudDriveSize, self.rubbishBinSize, self.incomingSharesSize, self.usedStorage, self.maxStorage];
                UsageViewController *usageVC = [[UIStoryboard storyboardWithName:@"MyAccount" bundle:nil] instantiateViewControllerWithIdentifier:@"UsageViewControllerID"];
                usageVC.sizesArray = sizesArray;
                [self.navigationController pushViewController:usageVC animated:YES];
            } else {
                MEGALogError(@"Account details unavailable");
            }
            
            break;
        }
        case 1: { //Contacts
            ContactsViewController *contactsVC = [[UIStoryboard storyboardWithName:@"Contacts" bundle:nil] instantiateViewControllerWithIdentifier:@"ContactsViewControllerID"];
            [self.navigationController pushViewController:contactsVC animated:YES];
            break;
        }
            
        case 2: { //Achievements
            AchievementsViewController *achievementsVC = [[UIStoryboard storyboardWithName:@"MyAccount" bundle:nil] instantiateViewControllerWithIdentifier:@"AchievementsViewControllerID"];
            [self.navigationController pushViewController:achievementsVC animated:YES];
            break;
        }
            
        case 3: { //Transfers
            TransfersViewController *transferVC = [[UIStoryboard storyboardWithName:@"Transfers" bundle:nil] instantiateViewControllerWithIdentifier:@"TransfersViewControllerID"];
            [self.navigationController pushViewController:transferVC animated:YES];
            break;
        }
            
        case 4: { //Offline
            OfflineTableViewController *offlineTVC = [[UIStoryboard storyboardWithName:@"Offline" bundle:nil] instantiateViewControllerWithIdentifier:@"OfflineTableViewControllerID"];
            [self.navigationController pushViewController:offlineTVC animated:YES];
            break;
        }
            
        case 5: { //Settings
            SettingsTableViewController *settingsTVC = [[UIStoryboard storyboardWithName:@"Settings" bundle:nil] instantiateViewControllerWithIdentifier:@"SettingsTableViewControllerID"];
            [self.navigationController pushViewController:settingsTVC animated:YES];
            break;
        }
    }
    
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - MEGAPurchasePricingDelegate

- (void)pricingsReady {
    self.buyPROBarButtonItem.enabled = YES;
}

#pragma mark - MEGAGlobalDelegate

- (void)onContactRequestsUpdate:(MEGASdk *)api contactRequestList:(MEGAContactRequestList *)contactRequestList {
    NSIndexPath *contactsIndexPath = [NSIndexPath indexPathForRow:1 inSection:0];
    [self.tableView reloadRowsAtIndexPaths:@[contactsIndexPath] withRowAnimation:UITableViewRowAnimationNone];
}

#pragma mark - MEGARequestDelegate

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    [super onRequestFinish:api request:request error:error];
    
    if (request.type == MEGARequestTypeAccountDetails) {
        if (error.type) {
            return;
        }
        
        [self reloadUI];
    }
}

@end
