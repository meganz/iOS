#import "ProductDetailViewController.h"

#import "MEGANavigationController.h"
#import "MEGAPurchase.h"
#import "MEGA-Swift.h"

#import "ProductDetailTableViewCell.h"
#import "UIApplication+MNZCategory.h"

@import MEGAL10nObjc;
@import MEGAUIKit;
@import MEGASDKRepo;

@interface ProductDetailViewController () <MEGAPurchaseDelegate, UITableViewDataSource, UITableViewDelegate> {
    BOOL isPurchased;
}

@property (weak, nonatomic) IBOutlet UIView *headerView;
@property (weak, nonatomic) IBOutlet UIImageView *crestImageView;

@property (weak, nonatomic) IBOutlet UILabel *storageSizeLabel;
@property (weak, nonatomic) IBOutlet UILabel *bandwidthSizeLabel;

@property (weak, nonatomic) IBOutlet UILabel *storageLabel;
@property (weak, nonatomic) IBOutlet UILabel *bandwidthLabel;
@property (weak, nonatomic) IBOutlet UILabel *selectMembershiptLabel;
@property (weak, nonatomic) IBOutlet UILabel *save17Label;

@end

@implementation ProductDetailViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIColor *proLevelColor = [UIColor mnz_colorWithProLevel:_megaAccountType];
    self.headerView.backgroundColor = proLevelColor;
    
    NSString *title;
    switch (_megaAccountType) {
        case MEGAAccountTypeLite:
            [_crestImageView setImage:[UIImage imageNamed:@"white_crest_LITE"]];
            title = LocalizedString(@"Pro Lite", @"");
            self.selectMembershiptLabel.textColor = proLevelColor;
            break;
            
        case MEGAAccountTypeProI:
            [_crestImageView setImage:[UIImage imageNamed:@"white_crest_PROI"]];
            title = LocalizedString(@"Pro I", @"");
            break;
            
        case MEGAAccountTypeProII:
            [_crestImageView setImage:[UIImage imageNamed:@"white_crest_PROII"]];
            title = LocalizedString(@"Pro II", @"");
            break;
            
        case MEGAAccountTypeProIII:
            [_crestImageView setImage:[UIImage imageNamed:@"white_crest_PROIII"]];
            title = LocalizedString(@"Pro III", @"");
            break;
            
        default:
            title = @"";
            break;
    }
    
    if (self.currentAccountType == self.megaAccountType) {
        UILabel *label = [UILabel
         customNavigationBarLabelWithTitle:LocalizedString(@"inAppPurchase.productDetail.navigation.currentPlan", @"A label which shows the user's current PRO plan.")
         subtitle:title
         traitCollection:self.traitCollection];
        label.adjustsFontSizeToFitWidth = YES;
        label.minimumScaleFactor = 0.8f;
        label.frame = CGRectMake(0, 0, self.navigationItem.titleView.bounds.size.width, 44);
        [self.navigationItem setTitleView:label];
    } else {
        self.title = title;
    }
    
    [_storageSizeLabel setText:_storageString];
    [_bandwidthSizeLabel setText:_bandwidthString];
    
    if (!self.isChoosingTheAccountType) {
        UIBarButtonItem *manageBarButtonItem = [UIBarButtonItem.alloc initWithTitle:LocalizedString(@"Manage", @"Text indicating to the user some action should be addressed. E.g. Navigate to Settings/File Management to clear cache.") style:UIBarButtonItemStylePlain target:self action:@selector(manageSubscriptions)];
        self.navigationItem.rightBarButtonItem = manageBarButtonItem;
    }
    
    [MEGAPurchase.sharedInstance.purchaseDelegateMutableArray addObject:self];
    isPurchased = NO;
    
    self.storageLabel.text = LocalizedString(@"Storage", @"Label for any ‘Storage’ button, link, text, title, etc. - (String as short as possible).");
    self.bandwidthLabel.text = LocalizedString(@"Transfer Quota", @"Some text listed after the amount of transfer quota a user gets with a certain package. For example: '8 TB Transfer quota'.");
    [_selectMembershiptLabel setText:LocalizedString(@"selectMembership", @"")];
    [_save17Label setText:LocalizedString(@"save17", @"")];
    
    [self updateAppearance];
    [self.tableView sizeHeaderToFit];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.navigationController.toolbarHidden = YES;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    if (self.isMovingFromParentViewController) {
        [MEGAPurchase.sharedInstance.purchaseDelegateMutableArray removeObject:self];
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
    self.tableView.separatorColor = [UIColor mnz_separator];
    
    self.storageLabel.textColor = self.storageSizeLabel.textColor = self.bandwidthLabel.textColor = self.bandwidthSizeLabel.textColor = [self whiteTextColor];
    
    self.selectMembershiptLabel.textColor = self.megaAccountType == MEGAAccountTypeLite ? [UIColor mnz_colorWithProLevel:_megaAccountType] : [UIColor mnz_red];
    
    self.save17Label.textColor = [UIColor mnz_red];
    self.view.backgroundColor = self.tableView.backgroundColor = [self defaultBackgroundColor];
}

- (void)presentProductUnavailableAlertController {
    UIAlertController *alertController = [UIAlertController inAppPurchaseAlertWithAppStoreSettingsButton:LocalizedString(@"inAppPurchase.error.alert.title.notAvailable", @"Alert title to remenber the user that needs to enable purchases") alertMessage:nil];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)manageSubscriptions {
    [UIApplication openAppleIDSubscriptionsPage];
}

- (void)presentAlreadyHaveActiveSubscriptionAlertWithProduct:(SKProduct *)product {
    MEGAAccountDetails *accountDetails = MEGASdk.shared.mnz_accountDetails;
    
    NSString *title = LocalizedString(@"account.upgrade.alreadyHaveASubscription.title", @"");
    NSString *message;
    BOOL canCancelSubscription = (accountDetails.subscriptionMethodId == MEGAPaymentMethodECP) || (accountDetails.subscriptionMethodId == MEGAPaymentMethodSabadell) || (accountDetails.subscriptionMethodId == MEGAPaymentMethodStripe2);
    
    if (canCancelSubscription) {
        message = LocalizedString(@"account.upgrade.alreadyHaveACancellableSubscription.message", @"");
    } else {
        message = LocalizedString(@"account.upgrade.alreadyHaveASubscription.message", @"");
    }
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    
    if (canCancelSubscription) {
        [alertController addAction:[UIAlertAction actionWithTitle:LocalizedString(@"no", @"") style:UIAlertActionStyleCancel handler:nil]];
        [alertController addAction:[UIAlertAction actionWithTitle:LocalizedString(@"yes", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {            
            [self cancelCreditCardSubscriptionsBeforeContinuePurchasingProduct:product];
        }]];
    } else {
        [alertController addAction:[UIAlertAction actionWithTitle:LocalizedString(@"ok", @"") style:UIAlertActionStyleCancel handler:nil]];
    }
    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ProductDetailTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"productDetailCell" forIndexPath:indexPath];
    
    if (indexPath.row == 0) {
        cell.periodLabel.text = LocalizedString(@"monthly", @"");
        cell.priceLabel.text = _priceMonthString;
    } else {
        cell.periodLabel.text = LocalizedString(@"yearly", @"");
        cell.priceLabel.text = _priceYearlyString;
    }
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    SKProduct *product;
    if (indexPath.row == 0) {
        if (self.monthlyProduct) {
            product = self.monthlyProduct;
        }
    } else {
        if (self.monthlyProduct) {
            product = self.yearlyProduct;
        }
    }
    
    if (product == nil) {
        [self presentProductUnavailableAlertController];
    } else {
        MEGAAccountDetails *accountDetails = MEGASdk.shared.mnz_accountDetails;
        if (accountDetails.type != MEGAAccountTypeFree &&
            accountDetails.subscriptionStatus == MEGASubscriptionStatusValid &&
            accountDetails.subscriptionMethodId != MEGAPaymentMethodItunes) {
            [self presentAlreadyHaveActiveSubscriptionAlertWithProduct:product];
        } else {
            [[MEGAPurchase sharedInstance] purchaseProduct:product];
        }
    }

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - MEGAPurchaseDelegate

- (void)successfulPurchase:(MEGAPurchase *)megaPurchase {
    if (!isPurchased) {
        isPurchased = YES;
                
        [self postDismissOnboardingProPlanDialog];
        
        if (self.presentingViewController) {
            [self dismissViewControllerAnimated:YES completion:nil];
        } else {
            [self.navigationController popToRootViewControllerAnimated:YES];
        }
    }
}

- (void)failedPurchase:(NSInteger)errorCode message:(NSString *)errorMessage {
    if ([self isPurchaseCancelledWithErrorCode:errorCode]) { return; }

    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:LocalizedString(@"failedPurchase_title", @"")  message:LocalizedString(@"failedPurchase_message", @"") preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:LocalizedString(@"ok", @"") style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alertController animated:YES completion:nil];
}

@end
