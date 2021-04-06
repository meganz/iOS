
#import "ProductDetailViewController.h"

#import "MEGANavigationController.h"
#import "MEGAPurchase.h"
#import "MEGA-Swift.h"

#import "ProductDetailTableViewCell.h"
#import "UIApplication+MNZCategory.h"

@interface ProductDetailViewController () <MEGAPurchaseDelegate, UITableViewDataSource, UITableViewDelegate> {
    BOOL isPurchased;
}

@property (weak, nonatomic) IBOutlet UITableView *tableView;

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
        UILabel *label = [Helper customNavigationBarLabelWithTitle:NSLocalizedString(@"Current plan", @"A label which shows the user's current PRO plan.") subtitle:title];
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
    
    [[MEGAPurchase sharedInstance] setDelegate:self];
    isPurchased = NO;
    
    self.storageLabel.text = NSLocalizedString(@"Storage", @"Label for any ‘Storage’ button, link, text, title, etc. - (String as short as possible).");
    self.bandwidthLabel.text = NSLocalizedString(@"Transfer Quota", @"Some text listed after the amount of transfer quota a user gets with a certain package. For example: '8 TB Transfer quota'.");
    [_selectMembershiptLabel setText:NSLocalizedString(@"selectMembership", nil)];
    [_save17Label setText:NSLocalizedString(@"save17", nil)];
    
    [self updateAppearance];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.navigationController.toolbarHidden = YES;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[MEGAPurchase sharedInstance] setDelegate:nil];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    
    if (@available(iOS 13.0, *)) {
        if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
            [self updateAppearance];
            
            [self.tableView reloadData];
        }
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
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"productNotAvailable", nil) message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"ok", nil) style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)manageSubscriptions {
    [UIApplication openAppleIDSubscriptionsPage];
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
    if (indexPath.row == 0) {
        if (self.monthlyProduct) {
            [[MEGAPurchase sharedInstance] purchaseProduct:self.monthlyProduct];
        } else {
            [self presentProductUnavailableAlertController];
        }
    } else {
        if (self.yearlyProduct) {
            [[MEGAPurchase sharedInstance] purchaseProduct:self.yearlyProduct];
        } else {
            [self presentProductUnavailableAlertController];
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
