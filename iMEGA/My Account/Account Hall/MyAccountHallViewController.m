
#import "MyAccountHallViewController.h"

#import "AchievementsViewController.h"
#import "ContactLinkQRViewController.h"
#import "ContactsViewController.h"
#import "Helper.h"
#import "MEGAPurchase.h"
#import "MEGASdk+MNZCategory.h"
#import "MEGAReachabilityManager.h"
#import "MEGASdkManager.h"
#import "MEGA-Swift.h"
#import "MyAccountHallTableViewCell.h"
#import "NotificationsTableViewController.h"
#import "OfflineViewController.h"
#import "SettingsTableViewController.h"
#import "TransfersWidgetViewController.h"
#import "UIImage+MNZCategory.h"
#import "UsageViewController.h"

@import MEGAData;

@interface MyAccountHallViewController () <UITableViewDelegate, MEGAPurchasePricingDelegate, MEGAGlobalDelegate, MEGARequestDelegate, AudioPlayerPresenterProtocol>

@property (weak, nonatomic) IBOutlet UIView *profileView;
@property (weak, nonatomic) IBOutlet UILabel *viewAndEditProfileLabel;
@property (weak, nonatomic) IBOutlet UIButton *viewAndEditProfileButton;
@property (weak, nonatomic) IBOutlet UIImageView *viewAndEditProfileImageView;
@property (weak, nonatomic) IBOutlet UIView *profileBottomSeparatorView;

@property (weak, nonatomic) IBOutlet UIView *addPhoneNumberView;
@property (weak, nonatomic) IBOutlet UIImageView *addPhoneNumberImageView;
@property (weak, nonatomic) IBOutlet UILabel *addPhoneNumberTitle;
@property (weak, nonatomic) IBOutlet UILabel *addPhoneNumberDescription;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *addPhoneNumberActivityIndicator;

@property (weak, nonatomic) IBOutlet MEGALabel *nameLabel;
@property (weak, nonatomic) IBOutlet UIImageView *avatarImageView;
@property (weak, nonatomic) IBOutlet UIImageView *qrCodeImageView;

@property (weak, nonatomic) IBOutlet UIView *tableFooterView;
@property (weak, nonatomic) IBOutlet UIView *tableFooterContainerView;
@property (weak, nonatomic) IBOutlet UILabel *tableFooterLabel;

@end

@implementation MyAccountHallViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.viewAndEditProfileLabel.text = NSLocalizedString(@"viewAndEditProfile", @"Title show on the hall of My Account section that describes a place where you can view, edit and upgrade your account and profile");
    self.viewAndEditProfileButton.accessibilityLabel = NSLocalizedString(@"viewAndEditProfile", @"Title show on the hall of My Account section that describes a place where you can view, edit and upgrade your account and profile");
    
    [self registerCustomCells];
    
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(viewAndEditProfileTouchUpInside:)];
    self.profileView.gestureRecognizers = @[tapGestureRecognizer];
    
    self.avatarImageView.image = self.avatarImageView.image.imageFlippedForRightToLeftLayoutDirection;
    self.qrCodeImageView.image = self.qrCodeImageView.image.imageFlippedForRightToLeftLayoutDirection;
    self.viewAndEditProfileImageView.image = self.viewAndEditProfileImageView.image.imageFlippedForRightToLeftLayoutDirection;
    self.addPhoneNumberImageView.image = self.addPhoneNumberImageView.image.imageFlippedForRightToLeftLayoutDirection;
    
    [MEGAPurchase.sharedInstance.pricingsDelegateMutableArray addObject:self];
    
    UITapGestureRecognizer *tapAvatarGestureRecognizer = [UITapGestureRecognizer.alloc initWithTarget:self action:@selector(avatarTapped:)];
    self.avatarImageView.gestureRecognizers = @[tapAvatarGestureRecognizer];
    self.avatarImageView.userInteractionEnabled = YES;
    self.avatarImageView.accessibilityIgnoresInvertColors = YES;
    self.addPhoneNumberView.hidden = YES;
    
    [self configAddPhoneNumberTexts];
    
    [self updateAppearance];
    
    [self setUpInvokeCommands];
    
    self.isBackupSectionVisible = false;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[MEGASdkManager sharedMEGASdk] addMEGARequestDelegate:self];
    [[MEGASdkManager sharedMEGASdk] addMEGAGlobalDelegate:self];
    
    if (MEGASdkManager.sharedMEGASdk.mnz_shouldRequestAccountDetails) {
        [MEGASdkManager.sharedMEGASdk getAccountDetails];
    }
    [self reloadUI];
    [self reloadContent];
    
    if ([self isNewUpgradeAccountPlanFeatureFlagEnabled]) {
        self.buyPROBarButtonItem.title = nil;
        self.buyPROBarButtonItem.enabled = false;
    } else {
        self.buyPROBarButtonItem.enabled = [MEGAPurchase sharedInstance].products.count;
    }
    
    if (self.navigationController.isNavigationBarHidden) {
        [self.navigationController setNavigationBarHidden:NO animated:YES];
    }
    
    [self configAddPhoneNumberView];
    
    [self checkIfBackupRootNodeExistsAndIsNotEmpty];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[MEGASdkManager sharedMEGASdk] removeMEGARequestDelegateAsync:self];
    [[MEGASdkManager sharedMEGASdk] removeMEGAGlobalDelegateAsync:self];
    
    if (self.isMovingFromParentViewController) {
        [MEGAPurchase.sharedInstance.pricingsDelegateMutableArray removeObject:self];
    }
    
    NSInteger index = self.navigationController.viewControllers.count-1;
    if (![self.navigationController.viewControllers[index] isKindOfClass:OfflineViewController.class] &&
        !self.isMovingFromParentViewController) {
        [AudioPlayerManager.shared removeDelegate:self];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [TransfersWidgetViewController.sharedTransferViewController.progressView hideWidget];
    [AudioPlayerManager.shared addDelegate:self];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    NSInteger index = self.navigationController.viewControllers.count-1;
    if ([self.navigationController.viewControllers[index] isKindOfClass:OfflineViewController.class] ||
        self.isMovingFromParentViewController) {
        [AudioPlayerManager.shared removeDelegate:self];
    }
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    
    if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
        [self updateAppearance];
        
        [self.tableView reloadData];
    }
}

#pragma mark - Private

- (void)updateAppearance {
    self.view.backgroundColor = [UIColor mnz_backgroundGroupedForTraitCollection:self.traitCollection];
    
    self.tableView.backgroundColor = [UIColor mnz_backgroundGroupedForTraitCollection:self.traitCollection];
    self.tableView.separatorColor = [UIColor mnz_separatorForTraitCollection:self.traitCollection];
    
    self.profileView.backgroundColor = [UIColor mnz_mainBarsForTraitCollection:self.traitCollection];
    self.viewAndEditProfileLabel.textColor = [UIColor mnz_primaryGrayForTraitCollection:self.traitCollection];
    self.qrCodeImageView.image = [UIImage imageNamed:@"qrCodeIcon"].imageFlippedForRightToLeftLayoutDirection;
    self.profileBottomSeparatorView.backgroundColor = [UIColor mnz_separatorForTraitCollection:self.traitCollection];
    
    self.addPhoneNumberView.backgroundColor = [UIColor mnz_secondaryBackgroundGrouped:self.traitCollection];
    
    if ([MEGASdkManager.sharedMEGASdk isAccountType:MEGAAccountTypeBusiness] ||
        [MEGASdkManager.sharedMEGASdk isAccountType:MEGAAccountTypeProFlexi]) {
        self.accountTypeLabel.textColor = [UIColor mnz_subtitlesForTraitCollection:self.traitCollection];
        
        self.tableFooterContainerView.backgroundColor = [UIColor mnz_tertiaryBackgroundGrouped:self.traitCollection];
        self.tableFooterLabel.textColor = [UIColor mnz_subtitlesForTraitCollection:self.traitCollection];
    }
    
    [self.navigationItem.rightBarButtonItem setTitleTextAttributes:@{NSFontAttributeName:[UIFont preferredFontForTextStyle:UIFontTextStyleBody],
                                                                     NSForegroundColorAttributeName:[UIColor mnz_primaryGrayForTraitCollection:self.traitCollection]}
                                                          forState:UIControlStateNormal];
    
    [self setupNavigationBarColorWith:self.traitCollection];
}

- (void)configAddPhoneNumberTexts {
    self.addPhoneNumberTitle.text = NSLocalizedString(@"Add Your Phone Number", nil);
    
    if (!MEGASdkManager.sharedMEGASdk.isAchievementsEnabled) {
        self.addPhoneNumberDescription.text = NSLocalizedString(@"Add your phone number to MEGA. This makes it easier for your contacts to find you on MEGA.", nil);
    } else {
        [self.addPhoneNumberActivityIndicator startAnimating];
        [MEGASdkManager.sharedMEGASdk getAccountAchievementsWithDelegate:[[MEGAGenericRequestDelegate alloc] initWithCompletion:^(MEGARequest * _Nonnull request, MEGAError * _Nonnull error) {
            [self.addPhoneNumberActivityIndicator stopAnimating];
            if (error.type == MEGAErrorTypeApiOk) {
                NSString *storageText = [NSString memoryStyleStringFromByteCount:[request.megaAchievementsDetails classStorageForClassId:MEGAAchievementAddPhone]];
                self.addPhoneNumberDescription.text = [NSString stringWithFormat:NSLocalizedString(@"Get free %@ when you add your phone number. This makes it easier for your contacts to find you on MEGA.", nil), storageText];
            }
        }]];
    }
}

- (void)configAddPhoneNumberView {
    if (MEGASdkManager.sharedMEGASdk.smsVerifiedPhoneNumber != nil || MEGASdkManager.sharedMEGASdk.smsAllowedState != SMSStateOptInAndUnblock) {
        self.profileBottomSeparatorView.hidden = YES;
        self.addPhoneNumberView.hidden = YES;
    } else {
        self.profileBottomSeparatorView.hidden = NO;
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
    
    self.nameLabel.text = [MEGAUser mnz_fullName:MEGASdk.currentUserHandle.unsignedLongLongValue];
    [self setUserAvatar];
    
    [self.tableView reloadData];
}

- (void)avatarTapped:(UITapGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateEnded) {
        ContactLinkQRViewController *contactLinkVC = [[UIStoryboard storyboardWithName:@"ContactLinkQR" bundle:nil] instantiateViewControllerWithIdentifier:@"ContactLinkQRViewControllerID"];
        contactLinkVC.scanCode = NO;
        contactLinkVC.modalPresentationStyle = UIModalPresentationFullScreen;
        
        [self presentViewController:contactLinkVC animated:YES completion:nil];
    }
}

- (void)setUserAvatar {
    [self.avatarImageView mnz_setImageForUserHandle:MEGASdk.currentUserHandle.unsignedLongLongValue];
}

- (void)configTableFooterView {
    if (MEGASdkManager.sharedMEGASdk.isMasterBusinessAccount) {
        self.tableFooterLabel.text = NSLocalizedString(@"User management is only available from a desktop web browser.", @"Label presented to Admins that full management of the business is only available in a desktop web browser");
        self.tableView.tableFooterView = self.tableFooterView;
    } else {
        self.tableView.tableFooterView = [UIView.alloc initWithFrame:CGRectZero];
    }
}

#pragma mark - IBActions

- (IBAction)scanQrCode:(UIBarButtonItem *)sender {
    ContactLinkQRViewController *contactLinkVC = [[UIStoryboard storyboardWithName:@"ContactLinkQR" bundle:nil] instantiateViewControllerWithIdentifier:@"ContactLinkQRViewControllerID"];
    contactLinkVC.scanCode = YES;
    contactLinkVC.modalPresentationStyle = UIModalPresentationFullScreen;
    
    [self presentViewController:contactLinkVC animated:YES completion:nil];
}

- (IBAction)buyPROTouchUpInside:(UIBarButtonItem *)sender {
    [UpgradeAccountRouter.new pushUpgradeTVCWithNavigationController:self.navigationController];
}

- (IBAction)viewAndEditProfileTouchUpInside:(UIButton *)sender {
    ProfileViewController *profileViewController = [[UIStoryboard storyboardWithName:@"Profile" bundle:nil] instantiateViewControllerWithIdentifier:@"ProfileViewControllerID"];
    [self.navigationController pushViewController:profileViewController animated:YES];
}

- (IBAction)didTapAddPhoneNumberView {
    [[[SMSVerificationViewRouter alloc] initWithVerificationType:SMSVerificationTypeAddPhoneNumber presenter:self onPhoneNumberVerified: nil] start];
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == MyAccountSectionOther) {
        [self showSettings];
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
        return;
    }
    
    NSInteger rowIndex = [self menuRowIndex:indexPath];
    switch (rowIndex) {
        case MyAccountMegaSectionStorage: {
            if ([[MEGASdkManager sharedMEGASdk] mnz_accountDetails]) {
                UsageViewController *usageVC = [[UIStoryboard storyboardWithName:@"Usage" bundle:nil] instantiateViewControllerWithIdentifier:@"UsageViewControllerID"];
                [self.navigationController pushViewController:usageVC animated:YES];
            } else {
                MEGALogError(@"Account details unavailable");
            }
            
            break;
        }
            
        case MyAccountMegaSectionNotifications: {
            NotificationsTableViewController *notificationsTVC = [[UIStoryboard storyboardWithName:@"Notifications" bundle:nil] instantiateViewControllerWithIdentifier:@"NotificationsTableViewControllerID"];
            [self.navigationController pushViewController:notificationsTVC animated:YES];
            break;
        }
            
        case MyAccountMegaSectionContacts: {
            ContactsViewController *contactsVC = [[UIStoryboard storyboardWithName:@"Contacts" bundle:nil] instantiateViewControllerWithIdentifier:@"ContactsViewControllerID"];
            [self.navigationController pushViewController:contactsVC animated:YES];
            break;
        }
            
        case MyAccountMegaSectionBackups: {
            [self navigateToBackups];
            break;
        }
            
        case MyAccountMegaSectionAchievements: {
            AchievementsViewController *achievementsVC = [[UIStoryboard storyboardWithName:@"Achievements" bundle:nil] instantiateViewControllerWithIdentifier:@"AchievementsViewControllerID"];
            [self.navigationController pushViewController:achievementsVC animated:YES];
            break;
        }
            
        case MyAccountMegaSectionTransfers: {
            TransfersWidgetViewController *transferVC = [[UIStoryboard storyboardWithName:@"Transfers" bundle:nil] instantiateViewControllerWithIdentifier:@"TransfersWidgetViewControllerID"];
            [self.navigationController pushViewController:transferVC animated:YES];
            break;
        }
            
        case MyAccountMegaSectionOffline: {
            OfflineViewController *offlineVC = [[UIStoryboard storyboardWithName:@"Offline" bundle:nil] instantiateViewControllerWithIdentifier:@"OfflineViewControllerID"];
            [self.navigationController pushViewController:offlineVC animated:YES];
            break;
        }
            
        case MyAccountMegaSectionRubbishBin: {
            CloudDriveViewController *cloudDriveVC = [[UIStoryboard storyboardWithName:@"Cloud" bundle:nil] instantiateViewControllerWithIdentifier:@"CloudDriveID"];
            cloudDriveVC.parentNode = [[MEGASdkManager sharedMEGASdk] rubbishNode];
            cloudDriveVC.displayMode = DisplayModeRubbishBin;
            [self.navigationController pushViewController:cloudDriveVC animated:YES];
            break;
        }
    }
    
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

//To remove the space between the table view and the profile view or the add phone number view
- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 0.01f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger rowIndex = [self menuRowIndex:indexPath];
    return (rowIndex == MyAccountMegaSectionAchievements &&
            ![MEGASdkManager.sharedMEGASdk isAchievementsEnabled] | [MEGASdkManager.sharedMEGASdk isAccountType:MEGAAccountTypeBusiness]) ||
    (rowIndex == MyAccountMegaSectionBackups && !self.isBackupSectionVisible) ? 0.0f : UITableViewAutomaticDimension;
}

#pragma mark - MEGAPurchasePricingDelegate

- (void)pricingsReady {
    BOOL isEnabled = ![self isNewUpgradeAccountPlanFeatureFlagEnabled];
    self.buyPROBarButtonItem.enabled = isEnabled;
}

#pragma mark - MEGAGlobalDelegate

- (void)onContactRequestsUpdate:(MEGASdk *)api contactRequestList:(MEGAContactRequestList *)contactRequestList {
    NSIndexPath *contactsIndexPath = [NSIndexPath indexPathForRow:MyAccountMegaSectionContacts inSection:MyAccountSectionMega];
    [self.tableView reloadRowsAtIndexPaths:@[contactsIndexPath] withRowAnimation:UITableViewRowAnimationNone];
}

- (void)onUserAlertsUpdate:(MEGASdk *)api userAlertList:(MEGAUserAlertList *)userAlertList {
    NSIndexPath *notificationsIndexPath = [NSIndexPath indexPathForRow:MyAccountMegaSectionNotifications inSection:MyAccountSectionMega];
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
            
            if ((request.paramType == MEGAUserAttributeFirstname || request.paramType == MEGAUserAttributeLastname) && request.email == nil) {
                self.nameLabel.text = [MEGAUser mnz_fullName:MEGASdk.currentUserHandle.unsignedLongLongValue];
            }
            break;
        }
            
        default:
            break;
    }
}

#pragma mark - AudioPlayer

- (void)updateContentView:(CGFloat)height {
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, height, 0);
}

@end
