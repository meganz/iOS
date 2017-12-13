#import "UpgradeTableViewController.h"

#import <MessageUI/MFMailComposeViewController.h>

#import "SVProgressHUD.h"

#import "MEGASdk+MNZCategory.h"
#import "NSString+MNZCategory.h"

#import "Helper.h"
#import "MEGAPurchase.h"
#import "MEGASdkManager.h"
#import "ProductDetailViewController.h"
#import "ProductTableViewCell.h"

#define TOBYTES 1024*1024*1024

@interface UpgradeTableViewController () <MFMailComposeViewControllerDelegate, UITableViewDataSource, UITableViewDelegate, MEGAPurchasePricingDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (strong, nonatomic) IBOutlet UIView *chooseFromOneOfThePlansHeaderView;
@property (strong, nonatomic) IBOutlet UIView *chooseFromOneOfThePlansPROHeaderView;
@property (weak, nonatomic) IBOutlet UILabel *chooseFromOneOfThePlansLabel;

@property (weak, nonatomic) IBOutlet UIView *currentPlanView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *currentPlanViewHeightLayoutConstraint;
@property (weak, nonatomic) IBOutlet UILabel *currentPlanLabel;
@property (weak, nonatomic) IBOutlet UIImageView *currentPlanImageView;
@property (weak, nonatomic) IBOutlet UIView *currentPlanNameView;
@property (weak, nonatomic) IBOutlet UILabel *currentPlanNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *currentPlanStorageLabel;
@property (weak, nonatomic) IBOutlet UILabel *currentPlanBandwidthLabel;
@property (weak, nonatomic) IBOutlet UIView *currentPlanLineView;

@property (weak, nonatomic) IBOutlet UILabel *twoMonthsFreeLabel;
@property (weak, nonatomic) IBOutlet UILabel *autorenewableDescriptionLabel;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *skipBarButtonItem;

@property (weak, nonatomic) IBOutlet UIView *requestAPlanView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *requestAPlanLabelTopLayoutConstraint;
@property (weak, nonatomic) IBOutlet UILabel *requestAPlanLabel;
@property (weak, nonatomic) IBOutlet UILabel *requestAPlanDescriptionLabel;
@property (weak, nonatomic) IBOutlet UIButton *requestAPlanButton;

@property (strong, nonatomic) NSArray *proLevelsMutableArray;
@property (strong, nonatomic) NSMutableDictionary *proLevelsIndexesMutableDictionary;
@property (nonatomic) MEGAAccountType userProLevel;

@end

@implementation UpgradeTableViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = AMLocalizedString(@"upgradeAccount", @"Upgrade account");
    self.chooseFromOneOfThePlansLabel.text = AMLocalizedString(@"choosePlan", @"Header that help you with the upgrading process explaining that you have to choose one of the plans below to continue");
    
    self.currentPlanLabel.text = AMLocalizedString(@"currentPlan", @"Text shown on the upgrade account page above the current PRO plan subscription");
    
    NSMutableAttributedString *asteriskMutableAttributedString = [[NSMutableAttributedString alloc] initWithString:@"* " attributes: @{NSFontAttributeName:[UIFont mnz_SFUIRegularWithSize:12.0f], NSForegroundColorAttributeName:[UIColor mnz_redD90007]}];
    NSAttributedString *twoMonthsFreeAttributedString = [[NSAttributedString alloc] initWithString:AMLocalizedString(@"twoMonthsFree", @"Text shown under the yearly plan to explain that if you select this kind of membership you will save two months money") attributes:@{NSFontAttributeName:[UIFont mnz_SFUIRegularWithSize:12.0f], NSForegroundColorAttributeName:[UIColor mnz_black262626]}];
    [asteriskMutableAttributedString appendAttributedString:twoMonthsFreeAttributedString];
    self.twoMonthsFreeLabel.attributedText = asteriskMutableAttributedString;
    
    _autorenewableDescriptionLabel.text = AMLocalizedString(@"autorenewableDescription", @"Describe how works auto-renewable subscriptions on the Apple Store");
    
    self.navigationItem.rightBarButtonItem = self.skipBarButtonItem;
    self.skipBarButtonItem.title = AMLocalizedString(@"skipButton", @"Button title that skips the current action");
    
    [[MEGAPurchase sharedInstance] setPricingsDelegate:self];
    
    [self getIndexPositionsForProLevels];
    
    [self initCurrentPlan];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

#pragma mark - Private

- (void)initCurrentPlan {
    self.userProLevel = [MEGASdkManager sharedMEGASdk].mnz_accountDetails.type;
    
    self.currentPlanImageView.image = [self imageForProLevel:self.userProLevel];
    self.currentPlanNameView.backgroundColor = [self colorForProLevel:self.userProLevel];
    self.currentPlanNameLabel.text = [self nameForProLevel:self.userProLevel];
    
    if ([[MEGASdkManager sharedMEGASdk] mnz_isProAccount]) {
        self.tableView.tableHeaderView = self.chooseFromOneOfThePlansPROHeaderView;
    }
    
    switch (self.userProLevel) {
        case MEGAAccountTypeFree:
            self.proLevelsMutableArray = @[[NSNumber numberWithInteger:MEGAAccountTypeLite], [NSNumber numberWithInteger:MEGAAccountTypeProI], [NSNumber numberWithInteger:MEGAAccountTypeProII], [NSNumber numberWithInteger:MEGAAccountTypeProIII]];
            
            self.currentPlanViewHeightLayoutConstraint.constant = 0;
            break;
            
        case MEGAAccountTypeLite:
            self.proLevelsMutableArray = @[[NSNumber numberWithInteger:MEGAAccountTypeProI], [NSNumber numberWithInteger:MEGAAccountTypeProII], [NSNumber numberWithInteger:MEGAAccountTypeProIII]];
            break;
            
        case MEGAAccountTypeProI:
            self.proLevelsMutableArray = @[[NSNumber numberWithInteger:MEGAAccountTypeProII], [NSNumber numberWithInteger:MEGAAccountTypeProIII]];
            break;
            
        case MEGAAccountTypeProII:
            self.proLevelsMutableArray = @[[NSNumber numberWithInteger:MEGAAccountTypeProIII]];
            break;
            
        case MEGAAccountTypeProIII: {
            self.proLevelsMutableArray = nil;
            
            self.currentPlanLineView.hidden = NO;
            
            self.tableView.tableHeaderView = nil;
            self.tableView.tableFooterView = nil;
            
            if ([[UIDevice currentDevice] iPhone4X]) {
                self.requestAPlanLabelTopLayoutConstraint.constant = 20.0f;
            }
    
            self.requestAPlanView.hidden = NO;
            self.requestAPlanLabel.text = AMLocalizedString(@"requestAPlan", @"Button on the Pro page to request a custom Pro plan because their storage usage is more than the regular plans.");
            
            NSString *requestAPlanDescriptionString = AMLocalizedString(@"thereAreNoPlansSuitableForYourCurrentUsage", @"Asks the user to request a custom Pro plan from customer support because their storage usage is more than the regular plans.");
            self.requestAPlanDescriptionLabel.text = [requestAPlanDescriptionString mnz_removeWebclientFormatters];
            break;
        }
            
        default:
            break;
    }
    
    NSNumber *userProLevelIndexNumber = [self.proLevelsIndexesMutableDictionary objectForKey:[NSNumber numberWithInteger:self.userProLevel]];
    self.currentPlanStorageLabel.attributedText = [self storageAttributedStringForProLevelAtIndex:userProLevelIndexNumber.integerValue];
    self.currentPlanBandwidthLabel.attributedText = [self bandwidthAttributedStringForProLevelAtIndex:userProLevelIndexNumber.integerValue];
}

- (void)getIndexPositionsForProLevels {
    self.proLevelsIndexesMutableDictionary = [[NSMutableDictionary alloc] init];
    for (NSUInteger i = 0; i < [MEGAPurchase sharedInstance].pricing.products; i++) {
        MEGAAccountType proLevel = [[MEGAPurchase sharedInstance].pricing proLevelAtProductIndex:i];
        if ([[MEGAPurchase sharedInstance].pricing monthsAtProductIndex:i] == 12 || proLevel == MEGAAccountTypeFree) {
            continue;
        }
        
        [self.proLevelsIndexesMutableDictionary setObject:[NSNumber numberWithUnsignedInteger:i] forKey:[NSNumber numberWithInteger:proLevel]];
    }
}

- (UIImage *)imageForProLevel:(MEGAAccountType)proLevel {
    UIImage *proLevelImage;
    switch (proLevel) {
        case MEGAAccountTypeLite:
            proLevelImage = [UIImage imageNamed:@"list_crest_LITE"];
            break;
            
        case MEGAAccountTypeProI:
            proLevelImage = [UIImage imageNamed:@"list_crest_PROI"];
            break;
            
        case MEGAAccountTypeProII:
            proLevelImage = [UIImage imageNamed:@"list_crest_PROII"];
            break;
            
        case MEGAAccountTypeProIII:
            proLevelImage = [UIImage imageNamed:@"list_crest_PROIII"];
            break;
            
        default:
            break;
    }
    
    return proLevelImage;
}

- (UIColor *)colorForProLevel:(MEGAAccountType)proLevel {
    UIColor *proLevelColor;
    switch (proLevel) {
        case MEGAAccountTypeLite:
            proLevelColor = [UIColor mnz_orangeFFA500];
            break;
            
        case MEGAAccountTypeProI:
            proLevelColor = [UIColor mnz_redE13339];
            break;
            
        case MEGAAccountTypeProII:
            proLevelColor = [UIColor mnz_redDC191F];
            break;
            
        case MEGAAccountTypeProIII:
            proLevelColor = [UIColor mnz_redD90007];
            break;
            
        default:
            break;
    }
    
    return proLevelColor;
}

- (NSString *)nameForProLevel:(MEGAAccountType)proLevel {
    NSString *proLevelName;
    switch (proLevel) {
        case MEGAAccountTypeLite:
            proLevelName = @"LITE";
            break;
            
        case MEGAAccountTypeProI:
            proLevelName = @"PRO I";
            break;
            
        case MEGAAccountTypeProII:
            proLevelName = @"PRO II";
            break;
            
        case MEGAAccountTypeProIII:
            proLevelName = @"PRO III";
            break;
            
        default:
            break;
    }
    
    return proLevelName;
}

- (NSAttributedString *)storageAttributedStringForProLevelAtIndex:(NSInteger)index {
    NSMutableAttributedString *storageString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@" %@", AMLocalizedString(@"productSpace", @"Storage related with the MEGA PRO account level you can subscribe")] attributes:@{NSFontAttributeName:[UIFont mnz_SFUIRegularWithSize:12.0f], NSForegroundColorAttributeName:[UIColor mnz_gray666666]}];
    
    NSString *storageFormattedString = [NSByteCountFormatter stringFromByteCount:((long long)[[MEGAPurchase sharedInstance].pricing storageGBAtProductIndex:index] * TOBYTES) countStyle:NSByteCountFormatterCountStyleMemory];
    NSMutableAttributedString *storageMutableAttributedString = [[NSMutableAttributedString alloc] initWithString:storageFormattedString attributes:@{NSFontAttributeName:[UIFont mnz_SFUIRegularWithSize:12.0f], NSForegroundColorAttributeName:[UIColor mnz_black333333]}];
    [storageMutableAttributedString appendAttributedString:storageString];
    
    return storageMutableAttributedString;
}

- (NSAttributedString *)bandwidthAttributedStringForProLevelAtIndex:(NSInteger)index {
    NSMutableAttributedString *bandwidthString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@" %@", AMLocalizedString(@"productBandwidth", @"Bandwich related with the MEGA PRO account level you can subscribe")] attributes:@{NSFontAttributeName:[UIFont mnz_SFUIRegularWithSize:12.0f], NSForegroundColorAttributeName:[UIColor mnz_gray666666]}];
    
    NSString *bandwidthFormattedString = [NSByteCountFormatter stringFromByteCount:((long long)[[MEGAPurchase sharedInstance].pricing transferGBAtProductIndex:index] * TOBYTES) countStyle:NSByteCountFormatterCountStyleMemory];
    NSMutableAttributedString *bandwidthMutableAttributedString = [[NSMutableAttributedString alloc] initWithString:bandwidthFormattedString attributes:@{NSFontAttributeName:[UIFont mnz_SFUIRegularWithSize:12.0f], NSForegroundColorAttributeName:[UIColor mnz_black333333]}];
    [bandwidthMutableAttributedString appendAttributedString:bandwidthString];
    
    return bandwidthMutableAttributedString;
}

#pragma mark - IBActions

- (IBAction)skipTouchUpInside:(UIBarButtonItem *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)requestAPlanTouchUpInside:(UIButton *)sender {
    if ([MFMailComposeViewController canSendMail]) {
        MFMailComposeViewController *mailComposeVC = [[MFMailComposeViewController alloc] init];
        mailComposeVC.mailComposeDelegate = self;
        mailComposeVC.toRecipients = @[@"support@mega.nz"];
        
        mailComposeVC.subject = [NSString stringWithFormat:@"Request a plan"];
        
        //TODO: Add a message body to facilitate the transition to a custom plan.
        
        [self presentViewController:mailComposeVC animated:YES completion:nil];
    } else {
        [SVProgressHUD showImage:[UIImage imageNamed:@"hudWarning"] status:AMLocalizedString(@"noEmailAccountConfigured", @"Text shown when you want to send feedback of the app and you don't have an email account set up on your device")];
    }
}
    
#pragma mark - MFMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.proLevelsMutableArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ProductTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"productCell" forIndexPath:indexPath];
    
    NSNumber *proLevelNumber = [self.proLevelsMutableArray objectAtIndex:indexPath.row];
    cell.productImageView.image = [self imageForProLevel:proLevelNumber.integerValue];
    cell.productNameLabel.text = [self nameForProLevel:proLevelNumber.integerValue];
    cell.productNameView.backgroundColor = [self colorForProLevel:proLevelNumber.integerValue];
    cell.productPriceLabel.textColor = [self colorForProLevel:proLevelNumber.integerValue];
    
    if ((indexPath.row == 0) && ![[MEGASdkManager sharedMEGASdk] mnz_isProAccount]) {
        cell.upperLineView.hidden = YES;
    }
    
    if (indexPath.row == (self.proLevelsMutableArray.count - 1)) {
        cell.underLineView.hidden = NO;
    }
    
    NSNumber *proLevelIndexNumber = [self.proLevelsIndexesMutableDictionary objectForKey:proLevelNumber];
    cell.productStorageLabel.attributedText = [self storageAttributedStringForProLevelAtIndex:proLevelIndexNumber.integerValue];
    cell.productBandwidthLabel.attributedText = [self bandwidthAttributedStringForProLevelAtIndex:proLevelIndexNumber.integerValue];
    
    NSString *productPriceString = [NSString stringWithFormat:AMLocalizedString(@"productPricePerMonth", @"Price asociated with the MEGA PRO account level you can subscribe"), (float)[[MEGAPurchase sharedInstance].pricing amountAtProductIndex:proLevelIndexNumber.integerValue] / 100, [[MEGAPurchase sharedInstance].pricing currencyAtProductIndex:proLevelIndexNumber.integerValue]];
    cell.productPriceLabel.text = productPriceString;
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    ProductDetailViewController *productDetailVC = [self.storyboard instantiateViewControllerWithIdentifier:@"productDetailID"];
    NSNumber *proPlanNumber = [self.proLevelsMutableArray objectAtIndex:indexPath.row];
    productDetailVC.megaAccountType = proPlanNumber.integerValue;
    
    NSNumber *proLevelIndexNumber = [self.proLevelsIndexesMutableDictionary objectForKey:proPlanNumber];
    productDetailVC.storageString = [NSByteCountFormatter stringFromByteCount:((long long)[[MEGAPurchase sharedInstance].pricing storageGBAtProductIndex:proLevelIndexNumber.integerValue] * TOBYTES) countStyle:NSByteCountFormatterCountStyleMemory];
    productDetailVC.bandwidthString = [NSByteCountFormatter stringFromByteCount:((long long)[[MEGAPurchase sharedInstance].pricing transferGBAtProductIndex:proLevelIndexNumber.integerValue] * TOBYTES) countStyle:NSByteCountFormatterCountStyleMemory];
    productDetailVC.priceMonthString = [NSString stringWithFormat:@"%.2f %@", (float)[[MEGAPurchase sharedInstance].pricing amountAtProductIndex:proLevelIndexNumber.integerValue] / 100, [[MEGAPurchase sharedInstance].pricing currencyAtProductIndex:proLevelIndexNumber.integerValue]];
    productDetailVC.priceYearlyString = [NSString stringWithFormat:@"%.2f %@", (float)[[MEGAPurchase sharedInstance].pricing amountAtProductIndex:(proLevelIndexNumber.integerValue + 1)] / 100, [[MEGAPurchase sharedInstance].pricing currencyAtProductIndex:proLevelIndexNumber.integerValue]];
    productDetailVC.iOSIDMonthlyString = [[MEGAPurchase sharedInstance].pricing iOSIDAtProductIndex:proLevelIndexNumber.integerValue];
    productDetailVC.iOSIDYearlyString = [[MEGAPurchase sharedInstance].pricing iOSIDAtProductIndex:(proLevelIndexNumber.integerValue + 1)];
    [self.navigationController pushViewController:productDetailVC animated:YES];
    
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - MEGAPurchasePricingDelegate

- (void)pricingsReady {
    [self.tableView reloadData];
}

@end
