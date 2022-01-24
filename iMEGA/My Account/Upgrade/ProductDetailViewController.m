
#import "ProductDetailViewController.h"

#import "MEGANavigationController.h"
#import "MEGAPurchase.h"
#import "MEGA-Swift.h"

#import "ProductDetailTableViewCell.h"
#import "UIApplication+MNZCategory.h"

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
    
    NSString *title;
    switch (_megaAccountType) {
        case MEGAAccountTypeLite:
            [_crestImageView setImage:[UIImage imageNamed:@"white_crest_LITE"]];
            self.headerView.backgroundColor = UIColor.mnz_proLITE;
            title = NSLocalizedString(@"Pro Lite", nil);
            self.selectMembershiptLabel.textColor = UIColor.mnz_proLITE;
            break;
            
        case MEGAAccountTypeProI:
            [_crestImageView setImage:[UIImage imageNamed:@"white_crest_PROI"]];
            [_headerView setBackgroundColor:UIColor.mnz_redProI];
            title = @"Pro I";
            break;
            
        case MEGAAccountTypeProII:
            [_crestImageView setImage:[UIImage imageNamed:@"white_crest_PROII"]];
            [_headerView setBackgroundColor:UIColor.mnz_redProII];
            title = @"Pro II";
            break;
            
        case MEGAAccountTypeProIII:
            [_crestImageView setImage:[UIImage imageNamed:@"white_crest_PROIII"]];
            [_headerView setBackgroundColor:UIColor.mnz_redProIII];
            title = @"Pro III";
            break;
            
        default:
            break;
    }
    
    if (self.currentAccountType == self.megaAccountType) {
        UILabel *label = [Helper customNavigationBarLabelWithTitle:NSLocalizedString(@"inAppPurchase.productDetail.navigation.currentPlan", @"A label which shows the user's current PRO plan.") subtitle:title];
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
        UIBarButtonItem *manageBarButtonItem = [UIBarButtonItem.alloc initWithTitle:NSLocalizedString(@"Manage", @"Text indicating to the user some action should be addressed. E.g. Navigate to Settings/File Management to clear cache.") style:UIBarButtonItemStylePlain target:self action:@selector(manageSubscriptions)];
        self.navigationItem.rightBarButtonItem = manageBarButtonItem;
    }
    
    [MEGAPurchase.sharedInstance.purchaseDelegateMutableArray addObject:self];
    isPurchased = NO;
    
    self.storageLabel.text = NSLocalizedString(@"Storage", @"Label for any ‘Storage’ button, link, text, title, etc. - (String as short as possible).");
    self.bandwidthLabel.text = NSLocalizedString(@"Transfer Quota", @"Some text listed after the amount of transfer quota a user gets with a certain package. For example: '8 TB Transfer quota'.");
    [_selectMembershiptLabel setText:NSLocalizedString(@"selectMembership", nil)];
    [_save17Label setText:NSLocalizedString(@"save17", nil)];
    
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
    self.tableView.separatorColor = [UIColor mnz_separatorForTraitCollection:self.traitCollection];
    
    self.storageLabel.textColor = self.storageSizeLabel.textColor = self.bandwidthLabel.textColor = self.bandwidthSizeLabel.textColor = UIColor.whiteColor;
    
    self.selectMembershiptLabel.textColor = self.megaAccountType == MEGAAccountTypeLite ? UIColor.mnz_proLITE : [UIColor mnz_redForTraitCollection:self.traitCollection];
    
    self.save17Label.textColor = [UIColor mnz_redForTraitCollection:self.traitCollection];
}

- (void)presentProductUnavailableAlertController {
    UIAlertController *alertController = [UIAlertController inAppPurchaseAlertWithAppStoreSettingsButton:NSLocalizedString(@"inAppPurchase.error.alert.title.notAvailable", @"Alert title to remenber the user that needs to enable purchases") alertMessage:nil];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)manageSubscriptions {
    [UIApplication openAppleIDSubscriptionsPage];
}

- (void)presentAlreadyHaveActiveSubscriptionAlertWithProduct:(SKProduct *)product {
    MEGAAccountDetails *accountDetails = MEGASdkManager.sharedMEGASdk.mnz_accountDetails;
    
    NSString *title = NSLocalizedString(@"account.upgrade.alreadyHaveASubscription.title", nil);
    NSString *message;
    BOOL canCancelSubscription = (accountDetails.subscriptionMethodId == MEGAPaymentMethodECP) || (accountDetails.subscriptionMethodId == MEGAPaymentMethodSabadell) || (accountDetails.subscriptionMethodId == MEGAPaymentMethodStripe2);
    
    if (canCancelSubscription) {
        message = NSLocalizedString(@"account.upgrade.alreadyHaveACancellableSubscription.message", nil);
    } else {
        message = NSLocalizedString(@"account.upgrade.alreadyHaveASubscription.message", nil);
    }
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    
    if (canCancelSubscription) {
        [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"no", nil) style:UIAlertActionStyleCancel handler:nil]];
        [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"yes", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [MEGASdkManager.sharedMEGASdk creditCardCancelSubscriptions:nil delegate:[MEGAGenericRequestDelegate.alloc initWithCompletion:^(MEGARequest * _Nonnull request, MEGAError * _Nonnull error) {
                if (error.type == MEGAErrorTypeApiOk) {
                    [[MEGAPurchase sharedInstance] purchaseProduct:product];
                }
            }]];
        }]];
    } else {
        [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"ok", nil) style:UIAlertActionStyleCancel handler:nil]];
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
        cell.periodLabel.text = NSLocalizedString(@"monthly", nil);
        cell.priceLabel.text = _priceMonthString;
    } else {
        cell.periodLabel.text = NSLocalizedString(@"yearly", nil);
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
        MEGAAccountDetails *accountDetails = MEGASdkManager.sharedMEGASdk.mnz_accountDetails;
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
        
        if (self.presentingViewController) {
            [self dismissViewControllerAnimated:YES completion:nil];
        } else {
            [self.navigationController popToRootViewControllerAnimated:YES];
        }
    }
}

- (void)failedPurchase:(NSInteger)errorCode message:(NSString *)errorMessage {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"failedPurchase_title", nil)  message:NSLocalizedString(@"failedPurchase_message", nil) preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"ok", nil) style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alertController animated:YES completion:nil];
}

@end
