
#import "MyAccountHallViewController.h"

#import "AchievementsViewController.h"
#import "ContactLinkQRViewController.h"
#import "ContactsViewController.h"
#import "Helper.h"
#import "MEGAContactLinkCreateRequestDelegate.h"
#import "MEGAPurchase.h"
#import "MEGASdk+MNZCategory.h"
#import "MEGAUser+MNZCategory.h"
#import "MEGAUserAlertList+MNZCategory.h"
#import "MEGAReachabilityManager.h"
#import "MEGASdkManager.h"
#import "MyAccountHallTableViewCell.h"
#import "NotificationsTableViewController.h"
#import "OfflineViewController.h"
#import "SettingsTableViewController.h"
#import "TransfersViewController.h"
#import "UIImage+MNZCategory.h"
#import "UpgradeTableViewController.h"
#import "UsageViewController.h"
#import "MEGA-Swift.h"

@interface MyAccountHallViewController () <UITableViewDataSource, UITableViewDelegate, MEGAPurchasePricingDelegate, MEGAGlobalDelegate, MEGARequestDelegate>

@property (weak, nonatomic) IBOutlet UIBarButtonItem *buyPROBarButtonItem;

@property (weak, nonatomic) IBOutlet UIView *profileView;
@property (weak, nonatomic) IBOutlet UILabel *viewAndEditProfileLabel;
@property (weak, nonatomic) IBOutlet UIButton *viewAndEditProfileButton;
@property (weak, nonatomic) IBOutlet UIImageView *viewAndEditProfileDisclosureImageView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIView *addPhoneNumberView;
@property (weak, nonatomic) IBOutlet UILabel *addPhoneNumberTitle;
@property (weak, nonatomic) IBOutlet UILabel *addPhoneNumberDescription;

@property (strong, nonatomic) NSNumberFormatter *numberFormatter;

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UIImageView *avatarImageView;
@property (weak, nonatomic) IBOutlet UIImageView *qrCodeImageView;

@property (weak, nonatomic) IBOutlet UIView *tableFooterView;
@property (weak, nonatomic) IBOutlet UILabel *tableFooterLabel;

@end

@implementation MyAccountHallViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
        
    self.viewAndEditProfileLabel.text = AMLocalizedString(@"viewAndEditProfile", @"Title show on the hall of My Account section that describes a place where you can view, edit and upgrade your account and profile");
    self.viewAndEditProfileButton.accessibilityLabel = AMLocalizedString(@"viewAndEditProfile", @"Title show on the hall of My Account section that describes a place where you can view, edit and upgrade your account and profile");

    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(viewAndEditProfileTouchUpInside:)];
    self.profileView.gestureRecognizers = @[tapGestureRecognizer];
    
    self.viewAndEditProfileDisclosureImageView.image = self.viewAndEditProfileDisclosureImageView.image.imageFlippedForRightToLeftLayoutDirection;
    
    _numberFormatter = [[NSNumberFormatter alloc] init];
    [_numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
    [_numberFormatter setLocale:[NSLocale currentLocale]];
    [_numberFormatter setMaximumFractionDigits:0];
    
    MEGAContactLinkCreateRequestDelegate *delegate = [[MEGAContactLinkCreateRequestDelegate alloc] initWithCompletion:^(MEGARequest *request) {
        CGSize qrImageSie = self.qrCodeImageView.frame.size;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            NSString *destination = [NSString stringWithFormat:@"https://mega.nz/C!%@", [MEGASdk base64HandleForHandle:request.nodeHandle]];
            UIImage *image = [UIImage mnz_qrImageFromString:destination withSize:qrImageSie color:UIColor.mnz_redMain];
            dispatch_async(dispatch_get_main_queue(), ^{
                self.qrCodeImageView.image = image;
                self.avatarImageView.layer.borderColor = [UIColor whiteColor].CGColor;
                self.avatarImageView.layer.borderWidth = 6.0f;
                self.avatarImageView.layer.cornerRadius = 40.0f;
            });
        });
    }];
    [[MEGASdkManager sharedMEGASdk] contactLinkCreateRenew:NO delegate:delegate];

    [[MEGAPurchase sharedInstance] setPricingsDelegate:self];
    
    UITapGestureRecognizer *tapAvatarGestureRecognizer = [UITapGestureRecognizer.alloc initWithTarget:self action:@selector(avatarTapped:)];
    self.avatarImageView.gestureRecognizers = @[tapAvatarGestureRecognizer];
    self.avatarImageView.userInteractionEnabled = YES;
    
    if (@available(iOS 11.0, *)) {
        self.avatarImageView.accessibilityIgnoresInvertColors = YES;
    }
    self.addPhoneNumberView.hidden = YES;
    
    [self configAddPhoneNumberTexts];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[MEGASdkManager sharedMEGASdk] addMEGARequestDelegate:self];
    [[MEGASdkManager sharedMEGASdk] addMEGAGlobalDelegate:self];
    
    
    if (MEGASdkManager.sharedMEGASdk.mnz_shouldRequestAccountDetails) {
        [MEGASdkManager.sharedMEGASdk getAccountDetails];
    }
    [self reloadUI];
    self.buyPROBarButtonItem.enabled = [MEGAPurchase sharedInstance].products.count;
    
    if (self.navigationController.isNavigationBarHidden) {
        [self.navigationController setNavigationBarHidden:NO animated:YES];
    }
    
    [self configAddPhoneNumberView];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[MEGASdkManager sharedMEGASdk] removeMEGAGlobalDelegate:self];
    [MEGASdkManager.sharedMEGASdk removeMEGARequestDelegate:self];
}

#pragma mark - Private

- (void)configAddPhoneNumberTexts {
    self.addPhoneNumberTitle.text = AMLocalizedString(@"Add Your Phone Number", nil);

    if (!MEGASdkManager.sharedMEGASdk.isAchievementsEnabled) {
        self.addPhoneNumberDescription.text = AMLocalizedString(@"Add your phone number to MEGA. This makes it easier for your contacts to find you on MEGA.", nil);
    } else {
        [MEGASdkManager.sharedMEGASdk getAccountAchievementsWithDelegate:[[MEGAGenericRequestDelegate alloc] initWithCompletion:^(MEGARequest * _Nonnull request, MEGAError * _Nonnull error) {
            if (error.type == MEGAErrorTypeApiOk) {
                NSString *storageText = [Helper memoryStyleStringFromByteCount:[request.megaAchievementsDetails classStorageForClassId:MEGAAchievementAddPhone]];
                self.addPhoneNumberDescription.text = [NSString stringWithFormat:AMLocalizedString(@"Get free %@ when you add your phone number. This makes it easier for your contacts to find you on MEGA.", nil), storageText];
            }
        }]];
    }
}

- (void)configAddPhoneNumberView {
    if (MEGASdkManager.sharedMEGASdk.smsVerifiedPhoneNumber != nil || MEGASdkManager.sharedMEGASdk.smsAllowedState != SMSStateOptInAndUnblock) {
        self.addPhoneNumberView.hidden = YES;
    } else {
        if (self.addPhoneNumberView.isHidden) {
            [UIView animateWithDuration:.75 animations:^{
                self.addPhoneNumberView.hidden = NO;
            }];
        }
    }
}

- (void)reloadUI {
    [self configNavigationItem];
    [self configTableFooterView];
    
    self.nameLabel.text = [[[MEGASdkManager sharedMEGASdk] myUser] mnz_fullName];
    [self setUserAvatar];
    
    [self.tableView reloadData];
}

- (void)openAchievements {
    NSArray *viewControllers = self.navigationController.viewControllers;
    if (viewControllers.count > 1) {
        [self.navigationController popToRootViewControllerAnimated:NO];
    }
    
    NSIndexPath *achievementsIndexPath = [NSIndexPath indexPathForRow:3 inSection:0];
    [self tableView:self.tableView didSelectRowAtIndexPath:achievementsIndexPath];
}

- (void)openOffline {
    NSArray *viewControllers = self.navigationController.viewControllers;
    if (viewControllers.count > 1) {
        [self.navigationController popToRootViewControllerAnimated:NO];
    }
    
    NSIndexPath *offlineIndexPath = [NSIndexPath indexPathForRow:5 inSection:0];
    [self tableView:self.tableView didSelectRowAtIndexPath:offlineIndexPath];
}

- (void)avatarTapped:(UITapGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateEnded) {
        ContactLinkQRViewController *contactLinkVC = [[UIStoryboard storyboardWithName:@"Contacts" bundle:nil] instantiateViewControllerWithIdentifier:@"ContactLinkQRViewControllerID"];
        contactLinkVC.scanCode = NO;
        [self presentViewController:contactLinkVC animated:YES completion:nil];
    }
}

- (void)setUserAvatar {
    MEGAUser *myUser = MEGASdkManager.sharedMEGASdk.myUser;
    [self.avatarImageView mnz_setImageForUserHandle:myUser.handle];
}

- (void)configNavigationItem {
    if (MEGASdkManager.sharedMEGASdk.isBusinessAccount) {
        self.navigationItem.rightBarButtonItem = nil;
        UILabel *label = [Helper customNavigationBarLabelWithTitle:AMLocalizedString(@"myAccount", @"Title of the app section where you can see your account details") subtitle:AMLocalizedString(@"Business", nil)];
        label.frame = CGRectMake(0, 0, self.navigationItem.titleView.bounds.size.width, 44);
        self.navigationItem.titleView = label;
    } else {
        self.buyPROBarButtonItem.title = AMLocalizedString(@"upgrade", @"Caption of a button to upgrade the account to Pro status");
        self.navigationItem.title = AMLocalizedString(@"myAccount", @"Title of the app section where you can see your account details");
    }
}

- (void)configTableFooterView {
    if (MEGASdkManager.sharedMEGASdk.isMasterBusinessAccount) {
        self.tableFooterLabel.text = AMLocalizedString(@"User management is only available from a desktop web browser.", @"Label presented to Admins that full management of the business is only available in a desktop web browser");
        self.tableView.tableFooterView = self.tableFooterView;
    } else {
        self.tableView.tableFooterView = [UIView.alloc initWithFrame:CGRectZero];
    }
}

#pragma mark - IBActions

- (IBAction)buyPROTouchUpInside:(UIBarButtonItem *)sender {
    if ([[MEGASdkManager sharedMEGASdk] mnz_accountDetails]) {
        UpgradeTableViewController *upgradeTVC = [[UIStoryboard storyboardWithName:@"MyAccount" bundle:nil] instantiateViewControllerWithIdentifier:@"UpgradeID"];        
        [self.navigationController pushViewController:upgradeTVC animated:YES];
    } else {
         [MEGAReachabilityManager isReachableHUDIfNot];
    }
}

- (IBAction)viewAndEditProfileTouchUpInside:(UIButton *)sender {
    ProfileViewController *profileViewController = [[UIStoryboard storyboardWithName:@"Profile" bundle:nil] instantiateViewControllerWithIdentifier:@"ProfileViewControllerID"];
    [self.navigationController pushViewController:profileViewController animated:YES];
}

- (IBAction)didTapAddPhoneNumberView {
    SMSNavigationViewController *smsNavigationController = [[SMSNavigationViewController alloc] initWithRootViewController:[SMSVerificationViewController instantiateWith:SMSVerificationTypeAddPhoneNumber]];
    smsNavigationController.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:smsNavigationController animated:YES completion:nil];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 7;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *identifier;
    if (indexPath.row == 0) {
        if (MEGASdkManager.sharedMEGASdk.isBusinessAccount) {
            identifier = @"MyAccountHallBusinessUsageTableViewCellID";
        } else {
            identifier = @"MyAccountHallUsedStorageTableViewCellID";
        }
    } else if (indexPath.row == 3) {
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
            if (MEGASdkManager.sharedMEGASdk.isBusinessAccount) {
                cell.sectionLabel.text = AMLocalizedString(@"Usage", @"Button title that goes to the section Usage where you can see how your MEGA space is used");
                cell.storageLabel.text = AMLocalizedString(@"productSpace", nil);
                cell.transferLabel.text = AMLocalizedString(@"Transfer", nil);
                MEGAAccountDetails *accountDetails = MEGASdkManager.sharedMEGASdk.mnz_accountDetails;
                if (accountDetails) {
                    cell.storageUsedLabel.text = [Helper memoryStyleStringFromByteCount:accountDetails.storageUsed.longLongValue];
                    cell.transferUsedLabel.text = [Helper memoryStyleStringFromByteCount:accountDetails.transferOwnUsed.longLongValue];
                } else {
                    cell.storageUsedLabel.text = @"";
                    cell.transferUsedLabel.text = @"";
                }
            } else {
                cell.sectionLabel.text = AMLocalizedString(@"usedStorage", @"Title of the Used Storage section");
                
                if (MEGASdkManager.sharedMEGASdk.mnz_accountDetails) {
                    MEGAAccountDetails *accountDetails = MEGASdkManager.sharedMEGASdk.mnz_accountDetails;
                    cell.usedLabel.text = [Helper memoryStyleStringFromByteCount:accountDetails.storageUsed.longLongValue];
                    NSNumber *number = [NSNumber numberWithFloat:((accountDetails.storageUsed.floatValue / accountDetails.storageMax.floatValue) * 100)];
                    NSString *percentageString = [self.numberFormatter stringFromNumber:number];
                    NSString *ofString = [NSString stringWithFormat:AMLocalizedString(@"of %@", @"Sentece showed under the used space percentage to complete the info with the maximum storage."), [Helper memoryStyleStringFromByteCount:accountDetails.storageMax.longLongValue]];
                    cell.usedPercentageLabel.text = [NSString stringWithFormat:@"%@ %% %@", percentageString, ofString];
                } else {
                    cell.usedLabel.text = @"";
                    cell.usedPercentageLabel.text = @"";                    
                }
            }
            break;
        }
            
        case 1: { // Notifications
            cell.sectionLabel.text = AMLocalizedString(@"notifications", nil);
            cell.iconImageView.image = [UIImage imageNamed:@"myAccountNotificationsIcon"];
            NSUInteger unseenUserAlerts = [MEGASdkManager sharedMEGASdk].userAlertList.mnz_relevantUnseenCount;
            if (unseenUserAlerts == 0) {
                cell.pendingView.hidden = YES;
                cell.pendingLabel.text = nil;
            } else {
                if (cell.pendingView.hidden) {
                    cell.pendingView.hidden = NO;
                    cell.pendingView.clipsToBounds = YES;
                }
                
                cell.pendingLabel.text = [NSString stringWithFormat:@"%tu", unseenUserAlerts];
            }
            break;
        }
            
        case 2: { // Contacts
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
                
                cell.pendingLabel.text = [NSString stringWithFormat:@"%tu", incomingContacts];
            }
            break;
        }
            
        case 3: { // Achievements
            cell.sectionLabel.text = AMLocalizedString(@"achievementsTitle", @"Title of the Achievements section");
            cell.subtitleLabel.text = AMLocalizedString(@"inviteFriendsAndGetRewards", @"Subtitle show under the Achievements label to explain what is this section");
            cell.iconImageView.image = [UIImage imageNamed:@"myAccountAchievementsIcon"];
            cell.pendingView.hidden = YES;
            cell.pendingLabel.text = nil;
            break;
        }
            
        case 4: { // Transfers
            cell.sectionLabel.text = AMLocalizedString(@"transfers", @"Title of the Transfers section");
            cell.iconImageView.image = [UIImage imageNamed:@"myAccountTransfersIcon"];
            cell.pendingView.hidden = YES;
            cell.pendingLabel.text = nil;
            break;
        }
            
        case 5: { // Offline
            cell.sectionLabel.text = AMLocalizedString(@"offline", @"Title of the Offline section");
            cell.iconImageView.image = [UIImage imageNamed:@"myAccountOfflineIcon"];
            cell.pendingView.hidden = YES;
            cell.pendingLabel.text = nil;
            break;
        }
            
        case 6: { // Settings
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
    if (indexPath.row == 3 && (![[MEGASdkManager sharedMEGASdk] isAchievementsEnabled] | MEGASdkManager.sharedMEGASdk.isBusinessAccount)) {
        heightForRow = 0.0f;
    } else if (indexPath.row == 0 && MEGASdkManager.sharedMEGASdk.isBusinessAccount) {
        heightForRow = 94;
    } else {
        heightForRow = 60;
    }
    
    return heightForRow;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.row) {
        case 0: { // Used Storage
            if ([[MEGASdkManager sharedMEGASdk] mnz_accountDetails]) {
                UsageViewController *usageVC = [[UIStoryboard storyboardWithName:@"MyAccount" bundle:nil] instantiateViewControllerWithIdentifier:@"UsageViewControllerID"];
                [self.navigationController pushViewController:usageVC animated:YES];
            } else {
                MEGALogError(@"Account details unavailable");
            }
            
            break;
        }
            
        case 1: { // Notifications
            NotificationsTableViewController *notificationsTVC = [[UIStoryboard storyboardWithName:@"Notifications" bundle:nil] instantiateViewControllerWithIdentifier:@"NotificationsTableViewControllerID"];
            [self.navigationController pushViewController:notificationsTVC animated:YES];
            break;
        }
            
        case 2: { // Contacts
            ContactsViewController *contactsVC = [[UIStoryboard storyboardWithName:@"Contacts" bundle:nil] instantiateViewControllerWithIdentifier:@"ContactsViewControllerID"];
            [self.navigationController pushViewController:contactsVC animated:YES];
            break;
        }
            
        case 3: { // Achievements
            AchievementsViewController *achievementsVC = [[UIStoryboard storyboardWithName:@"MyAccount" bundle:nil] instantiateViewControllerWithIdentifier:@"AchievementsViewControllerID"];
            [self.navigationController pushViewController:achievementsVC animated:YES];
            break;
        }
            
        case 4: { // Transfers
            TransfersViewController *transferVC = [[UIStoryboard storyboardWithName:@"Transfers" bundle:nil] instantiateViewControllerWithIdentifier:@"TransfersViewControllerID"];
            [self.navigationController pushViewController:transferVC animated:YES];
            break;
        }
            
        case 5: { // Offline
            OfflineViewController *offlineVC = [[UIStoryboard storyboardWithName:@"Offline" bundle:nil] instantiateViewControllerWithIdentifier:@"OfflineViewControllerID"];
            [self.navigationController pushViewController:offlineVC animated:YES];
            break;
        }
            
        case 6: { // Settings
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
    NSIndexPath *contactsIndexPath = [NSIndexPath indexPathForRow:2 inSection:0];
    [self.tableView reloadRowsAtIndexPaths:@[contactsIndexPath] withRowAnimation:UITableViewRowAnimationNone];
}

- (void)onUserAlertsUpdate:(MEGASdk *)api userAlertList:(MEGAUserAlertList *)userAlertList {
    NSIndexPath *notificationsIndexPath = [NSIndexPath indexPathForRow:1 inSection:0];
    [self.tableView reloadRowsAtIndexPaths:@[notificationsIndexPath] withRowAnimation:UITableViewRowAnimationNone];
}

#pragma mark - MEGARequestDelegate

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    switch (request.type) {
        case MEGARequestTypeAccountDetails:
            if (error.type) {
                return;
            }
            [self reloadUI];
            
            break;
            
        case MEGARequestTypeGetAttrUser: {
            if (error.type) {
                return;
            }
            
            if (request.file) {
                [self setUserAvatar];
            }
            
            if (request.paramType == MEGAUserAttributeFirstname || request.paramType == MEGAUserAttributeLastname) {
                self.nameLabel.text = api.myUser.mnz_fullName;
            }
            break;
        }
            
        default:
            break;
    }
}

@end
