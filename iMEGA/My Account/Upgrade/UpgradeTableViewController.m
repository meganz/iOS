#import "UpgradeTableViewController.h"

#import <MessageUI/MFMailComposeViewController.h>
#import <SafariServices/SafariServices.h>

#import "SVProgressHUD.h"

#import "MEGASdk+MNZCategory.h"
#import "NSString+MNZCategory.h"

#import "Helper.h"
#import "MEGAPurchase.h"
#import "MEGASdkManager.h"
#import "MEGAReachabilityManager.h"
#import "ProductDetailViewController.h"
#import "ProductTableViewCell.h"

@interface UpgradeTableViewController () <MFMailComposeViewControllerDelegate, UITableViewDataSource, UITableViewDelegate>

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

@property (strong, nonatomic) NSMutableArray *proLevelsMutableArray;
@property (strong, nonatomic) NSMutableDictionary *proLevelsIndexesMutableDictionary;
@property (nonatomic) MEGAAccountType userProLevel;

@end

@implementation UpgradeTableViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:self.navigationItem.backBarButtonItem.style target:nil action:nil];
    
    self.title = (self.isChoosingTheAccountType) ? AMLocalizedString(@"chooseYourAccountType", nil) : AMLocalizedString(@"upgradeAccount", @"Button title which triggers the action to upgrade your MEGA account level");
    self.chooseFromOneOfThePlansLabel.text = (self.isChoosingTheAccountType) ? AMLocalizedString(@"selectOneAccountType", @"") : AMLocalizedString(@"choosePlan", @"Header that help you with the upgrading process explaining that you have to choose one of the plans below to continue");
    
    self.currentPlanLabel.text = AMLocalizedString(@"currentPlan", @"Text shown on the upgrade account page above the current PRO plan subscription");
    
    NSMutableAttributedString *asteriskMutableAttributedString = [[NSMutableAttributedString alloc] initWithString:@"* " attributes: @{NSFontAttributeName:[UIFont mnz_SFUIRegularWithSize:12.0f], NSForegroundColorAttributeName:[UIColor mnz_redD90007]}];
    NSAttributedString *twoMonthsFreeAttributedString = [[NSAttributedString alloc] initWithString:AMLocalizedString(@"twoMonthsFree", @"Text shown in the purchase plan view to explain that annual subscription is 17% cheaper than 12 monthly payments") attributes:@{NSFontAttributeName:[UIFont mnz_SFUIRegularWithSize:12.0f], NSForegroundColorAttributeName:[UIColor mnz_black262626]}];
    [asteriskMutableAttributedString appendAttributedString:twoMonthsFreeAttributedString];
    self.twoMonthsFreeLabel.attributedText = asteriskMutableAttributedString;
    
    _autorenewableDescriptionLabel.text = AMLocalizedString(@"autorenewableDescription", @"Describe how works auto-renewable subscriptions on the Apple Store");
    
    self.navigationItem.rightBarButtonItem = (self.isChoosingTheAccountType) ? nil : self.skipBarButtonItem;
    self.skipBarButtonItem.title = AMLocalizedString(@"skipButton", @"Button title that skips the current action");
    
    [[MEGAPurchase sharedInstance] setPricingsDelegate:self];
    
    [self getIndexPositionsForProLevels];
    
    [self initCurrentPlan];
    
    [self setupToolbar];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.navigationController.toolbarHidden = NO;
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
            self.proLevelsMutableArray = [NSMutableArray arrayWithArray:@[[NSNumber numberWithInteger:MEGAAccountTypeLite], [NSNumber numberWithInteger:MEGAAccountTypeProI], [NSNumber numberWithInteger:MEGAAccountTypeProII], [NSNumber numberWithInteger:MEGAAccountTypeProIII]]];
            
            if (self.isChoosingTheAccountType) {
                [self.proLevelsMutableArray insertObject:[NSNumber numberWithInteger:MEGAAccountTypeFree] atIndex:0];
            }
            
            self.currentPlanViewHeightLayoutConstraint.constant = 0;
            break;
            
        case MEGAAccountTypeLite:
            self.proLevelsMutableArray = [NSMutableArray arrayWithArray:@[[NSNumber numberWithInteger:MEGAAccountTypeProI], [NSNumber numberWithInteger:MEGAAccountTypeProII], [NSNumber numberWithInteger:MEGAAccountTypeProIII]]];
            break;
            
        case MEGAAccountTypeProI:
            self.proLevelsMutableArray = [NSMutableArray arrayWithArray:@[[NSNumber numberWithInteger:MEGAAccountTypeProII], [NSNumber numberWithInteger:MEGAAccountTypeProIII]]];
            break;
            
        case MEGAAccountTypeProII:
            self.proLevelsMutableArray = [NSMutableArray arrayWithArray:@[[NSNumber numberWithInteger:MEGAAccountTypeProIII]]];
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
    BOOL yearPlan;
    for (NSUInteger i = 0; i < [MEGAPurchase sharedInstance].products.count; i++) {
        SKProduct *product = [[MEGAPurchase sharedInstance].products objectAtIndex:i];
        MEGAAccountType proLevel;
        if ([product.productIdentifier containsString:@"pro1"]) {
            proLevel = MEGAAccountTypeProI;
        } else if ([product.productIdentifier containsString:@"pro2"]) {
            proLevel = MEGAAccountTypeProII;
        } else if ([product.productIdentifier containsString:@"pro3"]) {
            proLevel = MEGAAccountTypeProIII;
        } else {
            proLevel = MEGAAccountTypeLite;
        }
        
        if ([product.productIdentifier containsString:@"oneYear"]) {
            yearPlan = YES;
        } else {
            yearPlan = NO;
        }
        
        if (yearPlan) {
            continue;
        }
        
        [self.proLevelsIndexesMutableDictionary setObject:[NSNumber numberWithUnsignedInteger:i] forKey:[NSNumber numberWithInteger:proLevel]];
    }
}

- (UIImage *)imageForProLevel:(MEGAAccountType)proLevel {
    UIImage *proLevelImage;
    switch (proLevel) {
        case MEGAAccountTypeFree:
            proLevelImage =  [UIImage imageNamed:@"list_crest_FREE"];
            break;
            
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
        case MEGAAccountTypeFree:
            proLevelColor = [UIColor mnz_green31B500];
            break;
            
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
        case MEGAAccountTypeFree:
            proLevelName = AMLocalizedString(@"free", @"Text relative to the MEGA account level. UPPER CASE");
            break;
            
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
    
    SKProduct *product = [[MEGAPurchase sharedInstance].products objectAtIndex:index];
    NSString *storageFormattedString = [self storageAndUnitsByProduct:product];
    NSMutableAttributedString *storageMutableAttributedString = [[NSMutableAttributedString alloc] initWithString:storageFormattedString attributes:@{NSFontAttributeName:[UIFont mnz_SFUIRegularWithSize:12.0f], NSForegroundColorAttributeName:[UIColor mnz_black333333]}];
    [storageMutableAttributedString appendAttributedString:storageString];
    
    return storageMutableAttributedString;
}

- (NSAttributedString *)bandwidthAttributedStringForProLevelAtIndex:(NSInteger)index {
    NSMutableAttributedString *bandwidthString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@" %@", AMLocalizedString(@"transferQuota", @"Some text listed after the amount of transfer quota a user gets with a certain package. For example: '8 TB Transfer quota'.")] attributes:@{NSFontAttributeName:[UIFont mnz_SFUIRegularWithSize:12.0f], NSForegroundColorAttributeName:[UIColor mnz_gray666666]}];
    
    SKProduct *product = [[MEGAPurchase sharedInstance].products objectAtIndex:index];
    NSString *bandwidthFormattedString = [self transferAndUnitsByProduct:product];
    NSMutableAttributedString *bandwidthMutableAttributedString = [[NSMutableAttributedString alloc] initWithString:bandwidthFormattedString attributes:@{NSFontAttributeName:[UIFont mnz_SFUIRegularWithSize:12.0f], NSForegroundColorAttributeName:[UIColor mnz_black333333]}];
    [bandwidthMutableAttributedString appendAttributedString:bandwidthString];
    
    return bandwidthMutableAttributedString;
}

- (NSAttributedString *)freeStorageAttributedString {
    NSMutableAttributedString *storageString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@" %@", AMLocalizedString(@"productSpace", @"Storage related with the MEGA PRO account level you can subscribe")] attributes:@{NSFontAttributeName:[UIFont mnz_SFUIRegularWithSize:12.0f], NSForegroundColorAttributeName:[UIColor mnz_gray666666]}];
    
    NSMutableAttributedString *storageMutableAttributedString = [[NSMutableAttributedString alloc] initWithString:@"50 GB" attributes:@{NSFontAttributeName:[UIFont mnz_SFUIRegularWithSize:12.0f], NSForegroundColorAttributeName:[UIColor mnz_black333333]}];
    [storageMutableAttributedString appendAttributedString:storageString];
    
    NSAttributedString *superscriptOneAttributedString = [[NSAttributedString alloc] initWithString:@" ¹" attributes:@{NSFontAttributeName:[UIFont mnz_SFUIRegularWithSize:12.0f], NSForegroundColorAttributeName:[UIColor mnz_redD90007]}];
    [storageMutableAttributedString appendAttributedString:superscriptOneAttributedString];
    
    return storageMutableAttributedString;
}

- (NSAttributedString *)freeTransferQuotaAttributedString {
    NSMutableAttributedString *transferQuotaString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@" %@", AMLocalizedString(@"transferQuota", @"Some text listed after the amount of transfer quota a user gets with a certain package. For example: '8 TB Transfer quota'.")] attributes:@{NSFontAttributeName:[UIFont mnz_SFUIRegularWithSize:12.0f], NSForegroundColorAttributeName:[UIColor mnz_gray666666]}];
    
    NSString *limitedTransferQuotaString = [AMLocalizedString(@"limited", @" Label for any 'Limited' button, link, text, title, etc. - (String as short as possible).") uppercaseString];
    NSMutableAttributedString *transferQuotaMutableAttributedString = [[NSMutableAttributedString alloc] initWithString:limitedTransferQuotaString attributes:@{NSFontAttributeName:[UIFont mnz_SFUIRegularWithSize:12.0f], NSForegroundColorAttributeName:[UIColor mnz_black333333]}];
    [transferQuotaMutableAttributedString appendAttributedString:transferQuotaString];
    
    return transferQuotaMutableAttributedString;
}

- (void)setupToolbar {
    self.navigationController.toolbarHidden = NO;
    
    UIBarButtonItem *termsOfServiceBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:AMLocalizedString(@"termsOfServicesLabel", @"Title of one of the Settings sections where you can see the MEGA's 'Terms of Service'") style:UIBarButtonItemStylePlain target:self action:@selector(showTermsOfService)];
    UIBarButtonItem *flexibleBarButtomItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem *privacyPolicyBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:AMLocalizedString(@"privacyPolicyLabel", @"Title of one of the Settings sections where you can see the MEGA's 'Privacy Policy'") style:UIBarButtonItemStylePlain target:self action:@selector(showPrivacyPolicy)];
    
    [self setToolbarItems:@[termsOfServiceBarButtonItem, flexibleBarButtomItem, privacyPolicyBarButtonItem]];
}

- (void)showTermsOfService {
    if ([MEGAReachabilityManager isReachableHUDIfNot]) {
        [self showURL:@"https://mega.nz/ios_terms.html"];
    }
}

- (void)showPrivacyPolicy {
    if ([MEGAReachabilityManager isReachableHUDIfNot]) {
        [self showURL:@"https://mega.nz/ios_privacy.html"];
    }
}

- (void)showURL:(NSString *)urlString {
    NSURL *url = [NSURL URLWithString:urlString];
    SFSafariViewController *safariViewController = [[SFSafariViewController alloc] initWithURL:url];
    if (@available(iOS 10.0, *)) {
        safariViewController.preferredControlTintColor = [UIColor mnz_redD90007];
    } else {
        safariViewController.view.tintColor = [UIColor mnz_redD90007];
    }
    
    [self presentViewController:safariViewController animated:YES completion:nil];
}

- (NSString *)storageAndUnitsByProduct:(SKProduct *)product {
    NSArray *storageTransferArray = [product.localizedDescription componentsSeparatedByString:@";"];
    NSArray *storageArray = [[storageTransferArray objectAtIndex:0] componentsSeparatedByString:@" "];
    return [NSString stringWithFormat:@"%@ %@", [storageArray objectAtIndex:0], [storageArray objectAtIndex:1]];
}

- (NSString *)transferAndUnitsByProduct:(SKProduct *)product {
    NSArray *storageTransferArray = [product.localizedDescription componentsSeparatedByString:@";"];
    NSArray *transferArray = [[storageTransferArray objectAtIndex:1] componentsSeparatedByString:@" "];
    return [NSString stringWithFormat:@"%@ %@", [transferArray objectAtIndex:0], [transferArray objectAtIndex:1]];
}

- (NSString *)priceByProduct:(SKProduct *)product {
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setNumberStyle: NSNumberFormatterCurrencyStyle];
    numberFormatter.locale = product.priceLocale;
    return [numberFormatter stringFromNumber:product.price];
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
    ProductTableViewCell *cell;
    if (self.isChoosingTheAccountType && indexPath.row == 0) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"freeProductCell" forIndexPath:indexPath];
        NSMutableAttributedString *superscriptOneAttributedString = [[NSMutableAttributedString alloc] initWithString:@"¹ " attributes:@{NSFontAttributeName:[UIFont mnz_SFUIRegularWithSize:12.0f], NSForegroundColorAttributeName:[UIColor mnz_redD90007]}];
        
        NSAttributedString *subjectToYourParticipationAttributedString = [[NSAttributedString alloc] initWithString:AMLocalizedString(@"subjectToYourParticipationInOurAchievementsProgram", @"") attributes:@{NSFontAttributeName:[UIFont mnz_SFUIRegularWithSize:12.0f], NSForegroundColorAttributeName:[UIColor mnz_black262626]}];
        [superscriptOneAttributedString appendAttributedString:subjectToYourParticipationAttributedString];
        
        cell.subjectToYourParticipationLabel.attributedText = superscriptOneAttributedString;
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:@"productCell" forIndexPath:indexPath];
    }
    
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
    cell.productStorageLabel.attributedText = (self.isChoosingTheAccountType && indexPath.row == 0) ? [self freeStorageAttributedString] : [self storageAttributedStringForProLevelAtIndex:proLevelIndexNumber.integerValue];
    cell.productBandwidthLabel.attributedText = (self.isChoosingTheAccountType && indexPath.row == 0) ? [self freeTransferQuotaAttributedString] :[self bandwidthAttributedStringForProLevelAtIndex:proLevelIndexNumber.integerValue];
    
    
    SKProduct *product = [[MEGAPurchase sharedInstance].products objectAtIndex:proLevelIndexNumber.integerValue];
    
    NSString *productPriceString = [NSString stringWithFormat:AMLocalizedString(@"productPricePerMonth", @"Price asociated with the MEGA PRO account level you can subscribe"), [self priceByProduct:product]];
    NSAttributedString *asteriskAttributedString = [[NSAttributedString alloc] initWithString:@" *" attributes:@{NSFontAttributeName:[UIFont mnz_SFUIRegularWithSize:12.0f], NSForegroundColorAttributeName:[UIColor mnz_redD90007]}];
    NSMutableAttributedString *productPriceMutableAttributedString = [[NSMutableAttributedString alloc] initWithString:productPriceString attributes:@{NSFontAttributeName:[UIFont mnz_SFUIRegularWithSize:12.0f], NSForegroundColorAttributeName:[self colorForProLevel:proLevelNumber.integerValue]}];
    [productPriceMutableAttributedString appendAttributedString:asteriskAttributedString];
    cell.productPriceLabel.attributedText = productPriceMutableAttributedString;
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat heightForRow;
    if (self.isChoosingTheAccountType && indexPath.row == 0) {
        heightForRow = 104.0f;
    } else {
        heightForRow = 86.0f;
    }
    
    return heightForRow;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.isChoosingTheAccountType && indexPath.row == 0) {
        [self dismissViewControllerAnimated:YES completion:nil];
        return;
    }
    
    ProductDetailViewController *productDetailVC = [self.storyboard instantiateViewControllerWithIdentifier:@"productDetailID"];
    NSNumber *proPlanNumber = [self.proLevelsMutableArray objectAtIndex:indexPath.row];
    productDetailVC.chooseAccountType = self.isChoosingTheAccountType;
    productDetailVC.megaAccountType = proPlanNumber.integerValue;
    
    NSNumber *proLevelIndexNumber = [self.proLevelsIndexesMutableDictionary objectForKey:proPlanNumber];
    
    SKProduct *monthlyProduct = [[MEGAPurchase sharedInstance].products objectAtIndex:proLevelIndexNumber.integerValue];
    SKProduct *yearlyProduct = [[MEGAPurchase sharedInstance].products objectAtIndex:proLevelIndexNumber.integerValue+1];
    NSString *storageFormattedString = [self storageAndUnitsByProduct:monthlyProduct];
    NSString *bandwidthFormattedString = [self transferAndUnitsByProduct:monthlyProduct];
    
    productDetailVC.storageString = storageFormattedString;
    productDetailVC.bandwidthString = bandwidthFormattedString;
    productDetailVC.priceMonthString = [self priceByProduct:monthlyProduct];
    productDetailVC.priceYearlyString = [self priceByProduct:yearlyProduct];
    productDetailVC.monthlyProduct = monthlyProduct;
    productDetailVC.yearlyProduct = yearlyProduct;
    [self.navigationController pushViewController:productDetailVC animated:YES];
    
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
