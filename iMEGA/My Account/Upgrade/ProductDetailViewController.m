
#import "ProductDetailViewController.h"

#import "CameraUploadsPopUpViewController.h"
#import "ProductDetailTableViewCell.h"

#import "MEGANavigationController.h"
#import "MEGAPurchase.h"

@interface ProductDetailViewController () <MEGAPurchaseDelegate, UIAlertViewDelegate, UITableViewDataSource, UITableViewDelegate> {
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
            [_crestImageView setImage:[UIImage imageNamed:@"white_crest_LITE"]];
            [_headerView setBackgroundColor:[UIColor mnz_orangeFFA500]];
            [self setTitle:@"LITE"];
            self.selectMembershiptLabel.textColor = [UIColor mnz_orangeFFA500];
            break;
            
        case MEGAAccountTypeProI:
            [_crestImageView setImage:[UIImage imageNamed:@"white_crest_PROI"]];
            [_headerView setBackgroundColor:[UIColor mnz_redE13339]];
            [self setTitle:@"PRO I"];
            break;
            
        case MEGAAccountTypeProII:
            [_crestImageView setImage:[UIImage imageNamed:@"white_crest_PROII"]];
            [_headerView setBackgroundColor:[UIColor mnz_redDC191F]];
            [self setTitle:@"PRO II"];
            break;
            
        case MEGAAccountTypeProIII:
            [_crestImageView setImage:[UIImage imageNamed:@"white_crest_PROIII"]];
            [_headerView setBackgroundColor:[UIColor mnz_redD90007]];
            [self setTitle:@"PRO III"];
            break;
            
        default:
            break;
    }
    
    [_storageSizeLabel setText:_storageString];
    [_bandwidthSizeLabel setText:_bandwidthString];
    
    if (!self.isChoosingTheAccountType) {
        UIBarButtonItem *restoreBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:AMLocalizedString(@"restore", @"Button title to restore failed purchases") style:UIBarButtonItemStylePlain target:self action:@selector(restore)];
        [restoreBarButtonItem setTitleTextAttributes:@{NSFontAttributeName:[UIFont mnz_SFUIRegularWithSize:17.0f], NSForegroundColorAttributeName:[UIColor mnz_redD90007]} forState:UIControlStateNormal];
        self.navigationItem.rightBarButtonItem = restoreBarButtonItem;
    }
    
    [[MEGAPurchase sharedInstance] setDelegate:self];
    isPurchased = NO;
    
    [_storageLabel setText:AMLocalizedString(@"productSpace", nil)];
    self.bandwidthLabel.text = AMLocalizedString(@"transferQuota", @"Some text listed after the amount of transfer quota a user gets with a certain package. For example: '8 TB Transfer quota'.");
    [_selectMembershiptLabel setText:AMLocalizedString(@"selectMembership", nil)];
    [_save17Label setText:AMLocalizedString(@"save17", nil)];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.navigationController.toolbarHidden = YES;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[MEGAPurchase sharedInstance] setDelegate:nil];
}

#pragma mark - Private

- (void)restore{
    [[MEGAPurchase sharedInstance] restorePurchase];
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ((alertView.tag) == 0 && (buttonIndex == 0)) {
        if ([[[[[UIApplication sharedApplication] delegate] window] rootViewController] presentedViewController] != nil) {
            [[[[[[UIApplication sharedApplication] delegate] window] rootViewController] presentedViewController] dismissViewControllerAnimated:YES completion:nil];
        }
    }
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
            UIAlertView *updatedAlert = [[UIAlertView alloc] initWithTitle:AMLocalizedString(@"thankYou_title", nil) message:AMLocalizedString(@"purchaseRestore_message", nil) delegate:nil cancelButtonTitle:AMLocalizedString(@"ok", nil) otherButtonTitles:nil];
            [updatedAlert setDelegate:self];
            [updatedAlert setTag:0];
            [updatedAlert show];
        } else {
            if (self.presentingViewController) {
                [self dismissViewControllerAnimated:YES completion:nil];
            }
        }
    }
}

- (void)failedPurchase:(NSInteger)errorCode message:(NSString *)errorMessage {
    UIAlertView *failedPurchaseAlert = [[UIAlertView alloc] initWithTitle:AMLocalizedString(@"failedPurchase_title", nil) message:AMLocalizedString(@"failedPurchase_message", nil) delegate:nil cancelButtonTitle:AMLocalizedString(@"ok", nil) otherButtonTitles:nil];
    [failedPurchaseAlert show];
}

- (void)incompleteRestore {
    UIAlertView *incompleteRestoreAlert = [[UIAlertView alloc] initWithTitle:AMLocalizedString(@"incompleteRestore_title", nil) message:AMLocalizedString(@"incompleteRestore_message", nil) delegate:nil cancelButtonTitle:AMLocalizedString(@"ok", nil) otherButtonTitles:nil];
    [incompleteRestoreAlert show];
}

- (void)failedRestore:(NSInteger)errorCode message:(NSString *)errorMessage {
    UIAlertView *failedRestoreAlert = [[UIAlertView alloc] initWithTitle:AMLocalizedString(@"failedRestore_title", nil) message:AMLocalizedString(@"failedRestore_message", nil) delegate:nil cancelButtonTitle:AMLocalizedString(@"ok", nil) otherButtonTitles:nil];
    [failedRestoreAlert show];
}

@end
