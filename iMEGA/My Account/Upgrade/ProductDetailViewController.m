
#import "ProductDetailViewController.h"

#import "MEGANavigationController.h"
#import "MEGAPurchase.h"
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

- (void)viewDidLoad {
    [super viewDidLoad];
    
    switch (_megaAccountType) {
        case MEGAAccountTypeLite:
            self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:242.0/255.0 green:156.0/255.0 blue:0 alpha:1.0];
            [_crestImageView setImage:[UIImage imageNamed:@"white_crest_LITE"]];
            [_headerView setBackgroundColor:[UIColor mnz_orangeFFA500]];
            [self setTitle:@"LITE"];
            self.selectMembershiptLabel.textColor = [UIColor mnz_orangeFFA500];
            break;
            
        case MEGAAccountTypeProI:
            self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:213.0/255.0 green:48.0/255.0 blue:54.0/255.0 alpha:1.0];
            [_crestImageView setImage:[UIImage imageNamed:@"white_crest_PROI"]];
            [_headerView setBackgroundColor:UIColor.mnz_redProI];
            [self setTitle:@"PRO I"];
            break;
            
        case MEGAAccountTypeProII:
            self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:208.0/255.0 green:23.0/255.0 blue:29.0/255.0 alpha:1.0];
            [_crestImageView setImage:[UIImage imageNamed:@"white_crest_PROII"]];
            [_headerView setBackgroundColor:UIColor.mnz_redProII];
            [self setTitle:@"PRO II"];
            break;
            
        case MEGAAccountTypeProIII:
            self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:205.0/255.0 green:0 blue:6.0/255.0 alpha:1.0];
            [_crestImageView setImage:[UIImage imageNamed:@"white_crest_PROIII"]];
            [_headerView setBackgroundColor:UIColor.mnz_redProIII];
            [self setTitle:@"PRO III"];
            break;
            
        default:
            break;
    }
    
    [_storageSizeLabel setText:_storageString];
    [_bandwidthSizeLabel setText:_bandwidthString];
    
    if (!self.isChoosingTheAccountType) {
        UIBarButtonItem *restoreBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:AMLocalizedString(@"restore", @"Button title to restore failed purchases") style:UIBarButtonItemStylePlain target:self action:@selector(restore)];
        self.navigationItem.rightBarButtonItem = restoreBarButtonItem;
    }
    
    [[MEGAPurchase sharedInstance] setDelegate:self];
    isPurchased = NO;
    
    [_storageLabel setText:AMLocalizedString(@"productSpace", nil)];
    self.bandwidthLabel.text = AMLocalizedString(@"Transfer Quota", @"Some text listed after the amount of transfer quota a user gets with a certain package. For example: '8 TB Transfer quota'.");
    [_selectMembershiptLabel setText:AMLocalizedString(@"selectMembership", nil)];
    [_save17Label setText:AMLocalizedString(@"save17", nil)];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.navigationController.toolbarHidden = YES;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    self.navigationController.navigationBar.barTintColor = UIColor.mnz_redMain;
    
    [[MEGAPurchase sharedInstance] setDelegate:nil];
}

#pragma mark - Private

- (void)restore{
    [[MEGAPurchase sharedInstance] restorePurchase];
}

- (void)presentProductUnavailableAlertController {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"productNotAvailable", nil) message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"ok", nil) style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ProductDetailTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"productDetailCell" forIndexPath:indexPath];
    
    if (indexPath.row == 0) {
        cell.periodLabel.text = AMLocalizedString(@"monthly", nil);
        cell.priceLabel.text = _priceMonthString;
    } else {
        cell.periodLabel.text = AMLocalizedString(@"yearly", nil);
        cell.priceLabel.text = _priceYearlyString;
    }
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 0) {
        if (self.monthlyProduct) {
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
            [[MEGAPurchase sharedInstance] purchaseProduct:self.monthlyProduct];
        } else {
            [self presentProductUnavailableAlertController];
        }
    } else {
        if (self.yearlyProduct) {
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
            [[MEGAPurchase sharedInstance] purchaseProduct:self.yearlyProduct];
        } else {
            [self presentProductUnavailableAlertController];
        }
    }

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)successfulPurchase:(MEGAPurchase *)megaPurchase restored:(BOOL)isRestore {
    if (!isPurchased) {
        isPurchased = YES;
        
        if (isRestore) {
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"thankYou_title", nil)  message:AMLocalizedString(@"purchaseRestore_message", nil) preferredStyle:UIAlertControllerStyleAlert];
            [alertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"ok", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                if (UIApplication.mnz_presentingViewController) {
                    [UIApplication.mnz_presentingViewController dismissViewControllerAnimated:YES completion:nil];
                }
            }]];
            
            [self presentViewController:alertController animated:YES completion:nil];
        } else {
            if (self.presentingViewController) {
                [self dismissViewControllerAnimated:YES completion:nil];
            }
        }
    }
}

- (void)failedPurchase:(NSInteger)errorCode message:(NSString *)errorMessage {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"failedPurchase_title", nil)  message:AMLocalizedString(@"failedPurchase_message", nil) preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"ok", nil) style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)incompleteRestore {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"incompleteRestore_title", nil)  message:AMLocalizedString(@"incompleteRestore_message", nil) preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"ok", nil) style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)failedRestore:(NSInteger)errorCode message:(NSString *)errorMessage {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"failedRestore_title", nil)  message:AMLocalizedString(@"failedRestore_message", nil) preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"ok", nil) style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alertController animated:YES completion:nil];
}

@end
