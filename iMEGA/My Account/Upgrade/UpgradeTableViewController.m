#import "UpgradeTableViewController.h"

#import <MessageUI/MFMailComposeViewController.h>

#import "SVProgressHUD.h"

#import "MEGASdk+MNZCategory.h"
#import "NSString+MNZCategory.h"
#import "NSURL+MNZCategory.h"

#import "MEGAPurchase.h"
#import "MEGASdkManager.h"
#import "MEGA-Swift.h"
#import "MEGAReachabilityManager.h"
#import "ProductDetailViewController.h"
#import "ProductTableViewCell.h"

@interface UpgradeTableViewController () <MFMailComposeViewControllerDelegate, UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (weak, nonatomic) IBOutlet UIView *chooseFromOneOfThePlansHeaderView;
@property (weak, nonatomic) IBOutlet UIView *chooseFromOneOfThePlansPROHeaderView;
@property (weak, nonatomic) IBOutlet UILabel *chooseFromOneOfThePlansLabel;
@property (weak, nonatomic) IBOutlet UILabel *chooseFromOneOfThePlansProLabel;
@property (weak, nonatomic) IBOutlet UIView *chooseFromOneOfThePlansBottomLineView;
@property (weak, nonatomic) IBOutlet UIView *chooseFromOneOfThePlansPROBottomLineView;

@property (weak, nonatomic) IBOutlet UIView *currentPlanLabelView;
@property (weak, nonatomic) IBOutlet UILabel *currentPlanLabel;
@property (weak, nonatomic) IBOutlet UIView *currentPlanLabelLineView;

@property (weak, nonatomic) IBOutlet UIView *currentPlanCellView;
@property (weak, nonatomic) IBOutlet UIImageView *currentPlanImageView;
@property (weak, nonatomic) IBOutlet UIView *currentPlanNameView;
@property (weak, nonatomic) IBOutlet UILabel *currentPlanNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *currentPlanStorageLabel;
@property (weak, nonatomic) IBOutlet UILabel *currentPlanBandwidthLabel;
@property (weak, nonatomic) IBOutlet UIView *currentPlanBottomLineCellView;

@property (weak, nonatomic) IBOutlet UIView *footerTopLineView;
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

@property (strong, nonatomic) NSNumberFormatter *numberFormatter;

@property (nonatomic, getter=shouldHideSkipButton) BOOL hideSkipButton;

@end

@implementation UpgradeTableViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.numberFormatter = NSNumberFormatter.alloc.init;
    self.numberFormatter.numberStyle = NSNumberFormatterCurrencyStyle;
    SKProduct *product = MEGAPurchase.sharedInstance.products.firstObject;
    self.numberFormatter.locale = product.priceLocale;
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:self.navigationItem.backBarButtonItem.style target:nil action:nil];
    
    self.title = (self.isChoosingTheAccountType) ? NSLocalizedString(@"chooseYourAccountType", nil) : NSLocalizedString(@"upgradeAccount", @"Button title which triggers the action to upgrade your MEGA account level");
    self.chooseFromOneOfThePlansLabel.text = (self.isChoosingTheAccountType) ? NSLocalizedString(@"selectOneAccountType", @"") : NSLocalizedString(@"choosePlan", @"Header that help you with the upgrading process explaining that you have to choose one of the plans below to continue");
    
    self.chooseFromOneOfThePlansProLabel.text = NSLocalizedString(@"choosePlan", @"Header that help you with the upgrading process explaining that you have to choose one of the plans below to continue");
    
    self.currentPlanLabel.text = NSLocalizedString(@"currentPlan", @"Text shown on the upgrade account page above the current PRO plan subscription");
    
    _autorenewableDescriptionLabel.text = NSLocalizedString(@"autorenewableDescription", @"Describe how works auto-renewable subscriptions on the Apple Store");
    
    
    if (self.presentingViewController || self.navigationController.presentingViewController.presentedViewController == self.navigationController || [self.tabBarController.presentingViewController isKindOfClass:UITabBarController.class]) {
        self.hideSkipButton = NO;
        self.skipBarButtonItem.title = NSLocalizedString(@"skipButton", @"Button title that skips the current action");
    } else {
        self.hideSkipButton = YES;
    }
    
    self.navigationItem.rightBarButtonItem = (self.isChoosingTheAccountType || self.shouldHideSkipButton) ? nil : self.skipBarButtonItem;
    
    [self getIndexPositionsForProLevels];
    
    [self initCurrentPlan];
    
    [self updateAppearance];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.navigationController.toolbarHidden = NO;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if ([MEGASdkManager.sharedMEGASdk mnz_isProAccount]) {
        //This method is called here so the storage and transfer quota label of the current plan show the correct attributed string
        [self setupCurrentPlanView];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    self.navigationController.toolbarHidden = YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
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
    self.view.backgroundColor = self.tableView.backgroundColor = [UIColor mnz_backgroundGroupedForTraitCollection:self.traitCollection];
    self.tableView.separatorColor = [UIColor mnz_separatorForTraitCollection:self.traitCollection];
    
    self.chooseFromOneOfThePlansHeaderView.backgroundColor = self.chooseFromOneOfThePlansPROHeaderView.backgroundColor = [UIColor mnz_mainBarsForTraitCollection:self.traitCollection];
    
    [self setupCurrentPlanView];
    
    self.chooseFromOneOfThePlansLabel.textColor = self.chooseFromOneOfThePlansProLabel.textColor = [UIColor mnz_primaryGrayForTraitCollection:self.traitCollection];
    
    [self setupTableViewHeaderAndFooter];
    
    [self.requestAPlanButton mnz_setupPrimary:self.traitCollection];
    
    [self setupToolbar];
}

- (void)setupCurrentPlanView {
    self.currentPlanLabel.textColor = [UIColor mnz_primaryGrayForTraitCollection:self.traitCollection];
    self.currentPlanLabelLineView.backgroundColor = [UIColor mnz_separatorForTraitCollection:self.traitCollection];
    
    self.currentPlanNameLabel.textColor = UIColor.whiteColor;
    NSNumber *userProLevelIndexNumber = [self.proLevelsIndexesMutableDictionary objectForKey:[NSNumber numberWithInteger:self.userProLevel]];
    self.currentPlanStorageLabel.attributedText = [self storageAttributedStringForProLevelAtIndex:userProLevelIndexNumber.integerValue];
    self.currentPlanBandwidthLabel.attributedText = [self bandwidthAttributedStringForProLevelAtIndex:userProLevelIndexNumber.integerValue];
    self.currentPlanCellView.backgroundColor = [UIColor mnz_secondaryBackgroundGrouped:self.traitCollection];
    self.currentPlanBottomLineCellView.backgroundColor = [UIColor mnz_separatorForTraitCollection:self.traitCollection];
}

- (void)setupTableViewHeaderAndFooter {
    self.chooseFromOneOfThePlansBottomLineView.backgroundColor = [UIColor mnz_separatorForTraitCollection:self.traitCollection];
    
    self.chooseFromOneOfThePlansPROBottomLineView.backgroundColor = [UIColor mnz_separatorForTraitCollection:self.traitCollection];
    
    self.footerTopLineView.backgroundColor = [UIColor mnz_separatorForTraitCollection:self.traitCollection];
    
    self.twoMonthsFreeLabel.textColor = [UIColor mnz_secondaryGrayForTraitCollection:self.traitCollection];
    NSMutableAttributedString *asteriskMutableAttributedString = [NSMutableAttributedString.alloc initWithString:@"* " attributes: @{NSFontAttributeName:[UIFont systemFontOfSize:12.0f], NSForegroundColorAttributeName:[UIColor mnz_redForTraitCollection:(self.traitCollection)]}];
    NSAttributedString *twoMonthsFreeAttributedString = [NSAttributedString.alloc initWithString:NSLocalizedString(@"twoMonthsFree", @"Text shown in the purchase plan view to explain that annual subscription is 17% cheaper than 12 monthly payments") attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:12.0f], NSForegroundColorAttributeName:[UIColor mnz_secondaryGrayForTraitCollection:self.traitCollection]}];
    [asteriskMutableAttributedString appendAttributedString:twoMonthsFreeAttributedString];
    self.twoMonthsFreeLabel.attributedText = asteriskMutableAttributedString;
    self.autorenewableDescriptionLabel.textColor = [UIColor mnz_secondaryGrayForTraitCollection:self.traitCollection];
}

- (void)initCurrentPlan {
    self.userProLevel = [MEGASdkManager sharedMEGASdk].mnz_accountDetails.type;
    
    self.currentPlanImageView.image = [self imageForProLevel:self.userProLevel];
    self.currentPlanNameView.backgroundColor = [UIColor mnz_colorWithProLevel:self.userProLevel];
    self.currentPlanNameLabel.text = NSLocalizedString([MEGAAccountDetails stringForAccountType:self.userProLevel], nil);
    
    if ([[MEGASdkManager sharedMEGASdk] mnz_isProAccount]) {
        self.tableView.tableHeaderView = self.chooseFromOneOfThePlansPROHeaderView;
    }
    
    switch (self.userProLevel) {
        case MEGAAccountTypeFree:
            self.proLevelsMutableArray = [NSMutableArray arrayWithArray:@[[NSNumber numberWithInteger:MEGAAccountTypeLite], [NSNumber numberWithInteger:MEGAAccountTypeProI], [NSNumber numberWithInteger:MEGAAccountTypeProII], [NSNumber numberWithInteger:MEGAAccountTypeProIII]]];
            
            if (self.isChoosingTheAccountType) {
                [self.proLevelsMutableArray insertObject:[NSNumber numberWithInteger:MEGAAccountTypeFree] atIndex:0];
            }
            
            self.currentPlanLabelView.hidden = self.currentPlanCellView.hidden = YES;
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
            
            self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
            self.tableView.tableHeaderView = nil;
            self.tableView.tableFooterView = nil;
            
            if ([[UIDevice currentDevice] iPhone4X]) {
                self.requestAPlanLabelTopLayoutConstraint.constant = 20.0f;
            }
    
            self.requestAPlanView.hidden = NO;
            self.requestAPlanLabel.text = NSLocalizedString(@"requestAPlan", @"Button on the Pro page to request a custom Pro plan because their storage usage is more than the regular plans.");
            
            NSString *requestAPlanDescriptionString = NSLocalizedString(@"thereAreNoPlansSuitableForYourCurrentUsage", @"Asks the user to request a custom Pro plan from customer support because their storage usage is more than the regular plans.");
            self.requestAPlanDescriptionLabel.text = [requestAPlanDescriptionString mnz_removeWebclientFormatters];
            break;
        }
            
        default:
            break;
    }
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

- (NSAttributedString *)storageAttributedStringForProLevelAtIndex:(NSInteger)index {
    NSMutableAttributedString *storageString = [NSMutableAttributedString.alloc initWithString:[NSString stringWithFormat:@" %@", NSLocalizedString(@"Storage", @"Label for any ‘Storage’ button, link, text, title, etc. - (String as short as possible).")] attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:12.0f], NSForegroundColorAttributeName:[UIColor mnz_primaryGrayForTraitCollection:self.traitCollection]}];
    
    SKProduct *product = [[MEGAPurchase sharedInstance].products objectAtIndex:index];
    NSString *storageFormattedString = [self storageAndUnitsByProduct:product];
    NSMutableAttributedString *storageMutableAttributedString = [NSMutableAttributedString.alloc initWithString:storageFormattedString attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:12.0f], NSForegroundColorAttributeName:UIColor.mnz_label}];
    [storageMutableAttributedString appendAttributedString:storageString];
    
    return storageMutableAttributedString;
}

- (NSAttributedString *)bandwidthAttributedStringForProLevelAtIndex:(NSInteger)index {
    NSMutableAttributedString *bandwidthString = [NSMutableAttributedString.alloc initWithString:[NSString stringWithFormat:@" %@", NSLocalizedString(@"Transfer Quota", @"Some text listed after the amount of transfer quota a user gets with a certain package. For example: '8 TB Transfer quota'.")] attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:12.0f], NSForegroundColorAttributeName:[UIColor mnz_primaryGrayForTraitCollection:self.traitCollection]}];
    
    SKProduct *product = [[MEGAPurchase sharedInstance].products objectAtIndex:index];
    NSString *bandwidthFormattedString = [self transferAndUnitsByProduct:product];
    NSMutableAttributedString *bandwidthMutableAttributedString = [NSMutableAttributedString.alloc initWithString:bandwidthFormattedString attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:12.0f], NSForegroundColorAttributeName:UIColor.mnz_label}];
    [bandwidthMutableAttributedString appendAttributedString:bandwidthString];
    
    return bandwidthMutableAttributedString;
}

- (NSAttributedString *)freeStorageAttributedString {
    NSMutableAttributedString *storageString = [NSMutableAttributedString.alloc initWithString:[NSString stringWithFormat:@" %@", NSLocalizedString(@"Storage", @"Label for any ‘Storage’ button, link, text, title, etc. - (String as short as possible).")] attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:12.0f], NSForegroundColorAttributeName:[UIColor mnz_primaryGrayForTraitCollection:self.traitCollection]}];
    
    NSMutableAttributedString *storageMutableAttributedString = [NSMutableAttributedString.alloc initWithString:@"50 GB" attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:12.0f], NSForegroundColorAttributeName:UIColor.mnz_label}];
    [storageMutableAttributedString appendAttributedString:storageString];
    
    NSAttributedString *superscriptOneAttributedString = [NSAttributedString.alloc initWithString:@" ¹" attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:12.0f], NSForegroundColorAttributeName:[UIColor mnz_redForTraitCollection:(self.traitCollection)]}];
    [storageMutableAttributedString appendAttributedString:superscriptOneAttributedString];
    
    return storageMutableAttributedString;
}

- (NSAttributedString *)freeTransferQuotaAttributedString {
    NSMutableAttributedString *transferQuotaString = [NSMutableAttributedString.alloc initWithString:[NSString stringWithFormat:@" %@", NSLocalizedString(@"Transfer Quota", @"Some text listed after the amount of transfer quota a user gets with a certain package. For example: '8 TB Transfer quota'.")] attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:12.0f], NSForegroundColorAttributeName:[UIColor mnz_primaryGrayForTraitCollection:self.traitCollection]}];
    
    NSString *limitedTransferQuotaString = [NSLocalizedString(@"limited", @" Label for any 'Limited' button, link, text, title, etc. - (String as short as possible).") uppercaseString];
    NSMutableAttributedString *transferQuotaMutableAttributedString = [NSMutableAttributedString.alloc initWithString:limitedTransferQuotaString attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:12.0f], NSForegroundColorAttributeName:UIColor.mnz_label}];
    [transferQuotaMutableAttributedString appendAttributedString:transferQuotaString];
    
    return transferQuotaMutableAttributedString;
}

- (void)setupToolbar {
    self.navigationController.toolbarHidden = NO;
    
    UIBarButtonItem *termsOfServiceBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"termsOfServicesLabel", @"Title of one of the Settings sections where you can see the MEGA's 'Terms of Service'") style:UIBarButtonItemStylePlain target:self action:@selector(showTermsOfService)];
    [termsOfServiceBarButtonItem setTitleTextAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:17.0f], NSForegroundColorAttributeName:[UIColor mnz_primaryGrayForTraitCollection:(self.traitCollection)]} forState:UIControlStateNormal];

    UIBarButtonItem *flexibleBarButtomItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    UIBarButtonItem *privacyPolicyBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"privacyPolicyLabel", @"Title of one of the Settings sections where you can see the MEGA's 'Privacy Policy'") style:UIBarButtonItemStylePlain target:self action:@selector(showPrivacyPolicy)];
    [privacyPolicyBarButtonItem setTitleTextAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:17.0f], NSForegroundColorAttributeName:[UIColor mnz_primaryGrayForTraitCollection:(self.traitCollection)]} forState:UIControlStateNormal];
    
    [self setToolbarItems:@[termsOfServiceBarButtonItem, flexibleBarButtomItem, privacyPolicyBarButtonItem]];
}

- (void)showTermsOfService {
    [[NSURL URLWithString:@"https://mega.nz/terms"] mnz_presentSafariViewController];
}

- (void)showPrivacyPolicy {
    [[NSURL URLWithString:@"https://mega.nz/privacy"] mnz_presentSafariViewController];
}

- (NSString *)storageAndUnitsByProduct:(SKProduct *)product {
    NSUInteger index = [MEGAPurchase.sharedInstance pricingProductIndexForProduct:product];
    NSInteger storageValue = [MEGAPurchase.sharedInstance.pricing storageGBAtProductIndex:index];
    return [self displayStringForGBValue:storageValue];
}

- (NSString *)transferAndUnitsByProduct:(SKProduct *)product {
    NSUInteger index = [MEGAPurchase.sharedInstance pricingProductIndexForProduct:product];
    NSInteger transferValue = [MEGAPurchase.sharedInstance.pricing transferGBAtProductIndex:index];
    return [self displayStringForGBValue:transferValue];
}

- (NSString *)displayStringForGBValue:(NSInteger)gbValue {
    // 1 GB = 1024 * 1024 * 1024 Bytes
    long long valueInBytes = (gbValue * 1024 * 1024 * 1024);
    return [NSByteCountFormatter stringFromByteCount:valueInBytes
                                          countStyle:NSByteCountFormatterCountStyleBinary];
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
        [SVProgressHUD showImage:[UIImage imageNamed:@"hudWarning"] status:NSLocalizedString(@"noEmailAccountConfigured", @"Text shown when you want to send feedback of the app and you don't have an email account set up on your device")];
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
        NSMutableAttributedString *superscriptOneAttributedString = [NSMutableAttributedString.alloc initWithString:@"¹ " attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:12.0f], NSForegroundColorAttributeName:[UIColor mnz_redForTraitCollection:(self.traitCollection)]}];
        
        NSAttributedString *subjectToYourParticipationAttributedString = [NSAttributedString.alloc initWithString:NSLocalizedString(@"subjectToYourParticipationInOurAchievementsProgram", @"") attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:12.0f], NSForegroundColorAttributeName:[UIColor mnz_primaryGrayForTraitCollection:self.traitCollection]}];
        [superscriptOneAttributedString appendAttributedString:subjectToYourParticipationAttributedString];
        
        cell.subjectToYourParticipationLabel.attributedText = superscriptOneAttributedString;
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:@"productCell" forIndexPath:indexPath];
    }
    
    NSNumber *proLevelNumber = [self.proLevelsMutableArray objectAtIndex:indexPath.row];
    cell.productImageView.image = [self imageForProLevel:proLevelNumber.integerValue];
    cell.productNameLabel.text = NSLocalizedString([MEGAAccountDetails stringForAccountType:proLevelNumber.integerValue], nil);
    cell.productNameView.backgroundColor = [UIColor mnz_colorWithProLevel:proLevelNumber.integerValue];
    cell.productPriceLabel.textColor = [UIColor mnz_colorForPriceLabelWithProLevel:proLevelNumber.integerValue traitCollection:self.traitCollection];
    
    NSNumber *proLevelIndexNumber = [self.proLevelsIndexesMutableDictionary objectForKey:proLevelNumber];
    cell.productStorageLabel.attributedText = (self.isChoosingTheAccountType && indexPath.row == 0) ? [self freeStorageAttributedString] : [self storageAttributedStringForProLevelAtIndex:proLevelIndexNumber.integerValue];
    cell.productBandwidthLabel.attributedText = (self.isChoosingTheAccountType && indexPath.row == 0) ? [self freeTransferQuotaAttributedString] :[self bandwidthAttributedStringForProLevelAtIndex:proLevelIndexNumber.integerValue];
    
    SKProduct *product = [[MEGAPurchase sharedInstance].products objectAtIndex:proLevelIndexNumber.integerValue];
    
    NSString *productPriceString = [NSString stringWithFormat:NSLocalizedString(@"productPricePerMonth", @"Price asociated with the MEGA PRO account level you can subscribe"), [self.numberFormatter stringFromNumber:product.price]];
    NSAttributedString *asteriskAttributedString = [NSAttributedString.alloc initWithString:@" *" attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:12.0f], NSForegroundColorAttributeName:[UIColor mnz_redForTraitCollection:(self.traitCollection)]}];
    NSMutableAttributedString *productPriceMutableAttributedString = [NSMutableAttributedString.alloc initWithString:productPriceString attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:12.0f], NSForegroundColorAttributeName : [UIColor mnz_colorWithProLevel:proLevelNumber.integerValue]}];
    [productPriceMutableAttributedString appendAttributedString:asteriskAttributedString];
    cell.productPriceLabel.attributedText = productPriceMutableAttributedString;
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat heightForRow;
    if (self.isChoosingTheAccountType && indexPath.row == 0) {
        heightForRow = 118.0f;
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
    
    ProductDetailViewController *productDetailVC = [self.storyboard instantiateViewControllerWithIdentifier:@"ProductDetailViewControllerID"];
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
    productDetailVC.priceMonthString = [self.numberFormatter stringFromNumber:monthlyProduct.price];
    productDetailVC.priceYearlyString = [self.numberFormatter stringFromNumber:yearlyProduct.price];
    productDetailVC.monthlyProduct = monthlyProduct;
    productDetailVC.yearlyProduct = yearlyProduct;
    [self.navigationController pushViewController:productDetailVC animated:YES];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
