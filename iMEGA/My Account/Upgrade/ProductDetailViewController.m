
#import "ProductDetailViewController.h"
#import "ProductDetailTableViewCell.h"
#import "Helper.h"
#import "MEGAPurchase.h"
#import "AppDelegate.h"

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
            [_crestImageView setImage:[UIImage imageNamed:@"white_crest_LITE"]];
            [_headerView setBackgroundColor:megaOrange];
            [self setTitle:@"LITE"];
            break;
            
        case MEGAAccountTypeProI:
            [_crestImageView setImage:[UIImage imageNamed:@"white_crest_PROI"]];
            [_headerView setBackgroundColor:[UIColor colorWithRed:225.0/255.0 green:51.0/255.0 blue:57.0/255.0 alpha:1.0]];
            [self setTitle:@"PRO I"];
            break;
            
        case MEGAAccountTypeProII:
            [_crestImageView setImage:[UIImage imageNamed:@"white_crest_PROII"]];
            [_headerView setBackgroundColor:[UIColor colorWithRed:220.0/255.0 green:25.0/255.0 blue:31.0/255.0 alpha:1.0]];
            [self setTitle:@"PRO II"];
            break;
            
        case MEGAAccountTypeProIII:
            [_crestImageView setImage:[UIImage imageNamed:@"white_crest_PROIII"]];
            [_headerView setBackgroundColor:megaRed];
            [self setTitle:@"PRO III"];
            break;
            
        default:
            break;
    }
    
    [_storageSizeLabel setText:_storageString];
    [_bandwidthSizeLabel setText:_bandwidthString];
    
    UIBarButtonItem *restoreBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:AMLocalizedString(@"restore", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(restore)];
    [self.navigationItem setRightBarButtonItem:restoreBarButtonItem];
    
    [[MEGAPurchase sharedInstance] setDelegate:self];
    isPurchased = NO;
    
    [_storageLabel setText:AMLocalizedString(@"productSpace", nil)];
    [_bandwidthLabel setText:AMLocalizedString(@"productBandwidth", nil)];
    [_selectMembershiptLabel setText:AMLocalizedString(@"selectMembership", nil)];
    [_save17Label setText:AMLocalizedString(@"save17", nil)];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[MEGAPurchase sharedInstance] setDelegate:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Private

- (void)restore{
    [[MEGAPurchase sharedInstance] restorePurchase];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

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
        [[MEGAPurchase sharedInstance] requestProduct:_iOSIDMonthlyString];
    } else {
        [[MEGAPurchase sharedInstance] requestProduct:_iOSIDYearlyString];
    }
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - MEGAPurchaseDelegate

- (void)requestedProduct {
    if ([MEGAPurchase sharedInstance].validProduct != nil) {
        [[MEGAPurchase sharedInstance] purchaseProduct:[MEGAPurchase sharedInstance].validProduct];
        
    } else {
        // Product is NOT available in the App Store, so notify user.
        
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        UIAlertView *unavailAlert = [[UIAlertView alloc] initWithTitle:AMLocalizedString(@"productNotAvailable", nil) message:nil delegate:nil cancelButtonTitle:AMLocalizedString(@"ok", nil) otherButtonTitles:nil];
        [unavailAlert show];
    }
}

- (void)successfulPurchase:(MEGAPurchase *)megaPurchase restored:(BOOL)isRestore identifier:(NSString *)productId receipt:(NSData *)receipt {    
    // Purchase or Restore request was successful, so...
    // 1 - Unlock the purchased content for your new customer!
    // 2 - Notify the user that the transaction was successful.
    
    if (!isPurchased) {
        // If paid status has not yet changed, then do so now. Checking
        // isPurchased boolean ensures user is only shown Thank You message
        // once even if multiple transaction receipts are successfully
        // processed (such as past subscription renewals).
        
        isPurchased = YES;
        
        //-------------------------------------
        
        // 1 - Unlock the purchased content and update the app's stored settings.
        
        //-------------------------------------
        
        // 2 - Notify the user that the transaction was successful.
        
        if (isRestore) {
            // This was a Restore request.
            UIAlertView *updatedAlert = [[UIAlertView alloc] initWithTitle:AMLocalizedString(@"thankYou_title", nil) message:AMLocalizedString(@"purchaseRestore_message", nil) delegate:nil cancelButtonTitle:AMLocalizedString(@"ok", nil) otherButtonTitles:nil];
            [updatedAlert show];
        }
        
        [[MEGASdkManager sharedMEGASdk] submitPurchase:MEGAPaymentMethodItunes receipt:[receipt base64EncodedStringWithOptions:0]];
    }
}

- (void)failedPurchase:(NSInteger)errorCode message:(NSString *)errorMessage {
    UIAlertView *failedPurchaseAlert = [[UIAlertView alloc] initWithTitle:AMLocalizedString(@"failedPurchase_title", nil) message:AMLocalizedString(@"failedPurchase_message", nil) delegate:nil cancelButtonTitle:AMLocalizedString(@"ok", nil) otherButtonTitles:nil];
    [failedPurchaseAlert show];
}

- (void)incompleteRestore {
    // Restore queue did not include any transactions, so either the user has not yet made a purchase
    // or the user's prior purchase is unavailable, so notify user to make a purchase within the app.
    // If the user previously purchased the item, they will NOT be re-charged again, but it should
    // restore their purchase.
    
    UIAlertView *incompleteRestoreAlert = [[UIAlertView alloc] initWithTitle:AMLocalizedString(@"incompleteRestore_title", nil) message:AMLocalizedString(@"incompleteRestore_message", nil) delegate:nil cancelButtonTitle:AMLocalizedString(@"ok", nil) otherButtonTitles:nil];
    [incompleteRestoreAlert show];
}

- (void)failedRestore:(NSInteger)errorCode message:(NSString *)errorMessage {
    UIAlertView *failedRestoreAlert = [[UIAlertView alloc] initWithTitle:AMLocalizedString(@"failedRestore_title", nil) message:AMLocalizedString(@"failedRestore_message", nil) delegate:nil cancelButtonTitle:AMLocalizedString(@"ok", nil) otherButtonTitles:nil];
    [failedRestoreAlert show];
}

@end
