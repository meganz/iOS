#import "MyAccountHallViewController.h"

#import "ContactLinkQRViewController.h"
#import "MEGA-Swift.h"
#import "OfflineViewController.h"
#import "TransfersWidgetViewController.h"

@import MEGAL10nObjc;
@import MEGASDKRepo;

@interface MyAccountHallViewController () <UITableViewDelegate, MEGAGlobalDelegate, MEGARequestDelegate, AudioPlayerPresenterProtocol>

@property (weak, nonatomic) IBOutlet UIView *profileBottomSeparatorView;
@property (weak, nonatomic) IBOutlet UIView *addPhoneNumberView;
@property (weak, nonatomic) IBOutlet UIImageView *addPhoneNumberImageView;
@property (weak, nonatomic) IBOutlet UILabel *addPhoneNumberTitle;
@property (weak, nonatomic) IBOutlet UILabel *addPhoneNumberDescription;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *addPhoneNumberActivityIndicator;
@property (weak, nonatomic) IBOutlet UIImageView *qrCodeImageView;
@property (weak, nonatomic) IBOutlet UIView *tableFooterContainerView;

@end

@implementation MyAccountHallViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self registerCustomCells];
        
    self.avatarImageView.image = self.avatarImageView.image.imageFlippedForRightToLeftLayoutDirection;
    self.qrCodeImageView.image = self.qrCodeImageView.image.imageFlippedForRightToLeftLayoutDirection;
    self.addPhoneNumberImageView.image = self.addPhoneNumberImageView.image.imageFlippedForRightToLeftLayoutDirection;
    
    UITapGestureRecognizer *tapAvatarGestureRecognizer = [UITapGestureRecognizer.alloc initWithTarget:self action:@selector(avatarTapped:)];
    self.avatarImageView.gestureRecognizers = @[tapAvatarGestureRecognizer];
    self.avatarImageView.userInteractionEnabled = YES;
    self.avatarImageView.accessibilityIgnoresInvertColors = YES;
    self.addPhoneNumberView.hidden = YES;
    
    [self configAddPhoneNumberTexts];
    
    [self updateAppearance];
    
    [self setUpInvokeCommands];
    
    [self notifyViewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self dispatchOnViewAppearAction];
    
    [self loadContent];
    
    [self configAddPhoneNumberView];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self dispatchOnViewWillDisappearAction];
    
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

- (BOOL)hidesBottomBarWhenPushed {
    return YES;
}

#pragma mark - Private

- (void)updateAppearance {
    self.view.backgroundColor = [UIColor pageBackgroundColor];
    
    self.tableView.backgroundColor = [UIColor pageBackgroundColor];
    self.tableView.separatorColor = [UIColor borderStrong];
    
    self.profileView.backgroundColor = [UIColor surface1Background];
    self.profileBottomSeparatorView.backgroundColor = [UIColor borderStrong];
    
    self.addPhoneNumberView.backgroundColor = [UIColor pageBackgroundColor];
    
    UIColor *primaryTextColor = [UIColor primaryTextColor];
    
    self.nameLabel.textColor = primaryTextColor;
    self.addPhoneNumberTitle.textColor = primaryTextColor;
    self.addPhoneNumberDescription.textColor = primaryTextColor;
    self.qrCodeImageView.image = [UIImage imageNamed:@"qrCode"].imageFlippedForRightToLeftLayoutDirection;
    
    if ([MEGASdk.shared isAccountType:MEGAAccountTypeBusiness] ||
        [MEGASdk.shared isAccountType:MEGAAccountTypeProFlexi]) {
        self.accountTypeLabel.textColor = [UIColor mnz_secondaryTextColor];
        
        self.tableFooterContainerView.backgroundColor = [UIColor surface1Background];
        self.tableFooterLabel.textColor = primaryTextColor;
    }
    
    [self setMenuCapableBackButtonWithMenuTitle:LocalizedString(@"My Account", @"")];
    
    [self setupNavigationBarColorWith:self.traitCollection];
}

- (void)configAddPhoneNumberTexts {
    self.addPhoneNumberTitle.text = LocalizedString(@"Add Your Phone Number", @"");
    
    if (!MEGASdk.shared.isAchievementsEnabled) {
        self.addPhoneNumberDescription.text = LocalizedString(@"Add your phone number to MEGA. This makes it easier for your contacts to find you on MEGA.", @"");
    } else {
        [self.addPhoneNumberActivityIndicator startAnimating];
        [MEGASdk.shared getAccountAchievementsWithDelegate:[[RequestDelegate alloc] initWithCompletion:^(MEGARequest * _Nullable request, MEGAError * _Nullable error) {
            [self.addPhoneNumberActivityIndicator stopAnimating];
            if (request) {
                NSString *storageText = [NSString memoryStyleStringFromByteCount:[request.megaAchievementsDetails classStorageForClassId:MEGAAchievementAddPhone]];
                self.addPhoneNumberDescription.text = [NSString stringWithFormat:LocalizedString(@"Get free %@ when you add your phone number. This makes it easier for your contacts to find you on MEGA.", @""), storageText];
            }
        }]];
    }
}

- (void)configAddPhoneNumberView {
    if (MEGASdk.shared.smsVerifiedPhoneNumber != nil || MEGASdk.shared.smsAllowedState != SMSStateOptInAndUnblock) {
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

- (void)avatarTapped:(UITapGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateEnded) {
        ContactLinkQRViewController *contactLinkVC = [[UIStoryboard storyboardWithName:@"ContactLinkQR" bundle:nil] instantiateViewControllerWithIdentifier:@"ContactLinkQRViewControllerID"];
        contactLinkVC.scanCode = NO;
        contactLinkVC.modalPresentationStyle = UIModalPresentationFullScreen;
        
        [self presentViewController:contactLinkVC animated:YES completion:nil];
    }
}

#pragma mark - IBActions

- (IBAction)scanQrCode:(UIBarButtonItem *)sender {
    ContactLinkQRViewController *contactLinkVC = [[UIStoryboard storyboardWithName:@"ContactLinkQR" bundle:nil] instantiateViewControllerWithIdentifier:@"ContactLinkQRViewControllerID"];
    contactLinkVC.scanCode = YES;
    contactLinkVC.modalPresentationStyle = UIModalPresentationFullScreen;
    
    [self presentViewController:contactLinkVC animated:YES completion:nil];
}

- (IBAction)didTapAddPhoneNumberView {
    [[[SMSVerificationViewRouter alloc] initWithVerificationType:SMSVerificationTypeAddPhoneNumber presenter:self onPhoneNumberVerified: nil] start];
}

#pragma mark - AudioPlayer

- (void)updateContentView:(CGFloat)height {
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, height, 0);
}

@end
