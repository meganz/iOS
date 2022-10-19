#import "UpgradeTableViewController.h"

#import <MessageUI/MFMailComposeViewController.h>

#import "SVProgressHUD.h"

#import "MEGASdk+MNZCategory.h"
#import "NSString+MNZCategory.h"
#import "NSURL+MNZCategory.h"
#import "NSArray+MNZCategory.h"

#import "MEGAPurchase.h"
#import "MEGASdkManager.h"
#import "MEGA-Swift.h"
#import "MEGAReachabilityManager.h"
#import "ProductDetailViewController.h"
#import "ProductTableViewCell.h"

@import MEGAUIKit;

typedef NS_ENUM(NSInteger, SubscriptionOrder) {
    SubscriptionOrderLite = 0,
    SubscriptionOrderProI,
    SubscriptionOrderProII,
    SubscriptionOrderProIII
};

@interface UpgradeTableViewController () <MFMailComposeViewControllerDelegate, UITableViewDataSource, UITableViewDelegate, MEGARestoreDelegate>

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

@property (weak, nonatomic) IBOutlet UILabel *customPlanLabel;
@property (weak, nonatomic) IBOutlet UIButton *customPlanButton;

@property (weak, nonatomic) IBOutlet UILabel *twoMonthsFreeLabel;
@property (weak, nonatomic) IBOutlet UILabel *autorenewableDescriptionLabel;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *skipBarButtonItem;

@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *termsAndPoliciesBarButtonItem;

@property (strong, nonatomic) NSMutableArray *proLevelsMutableArray;
@property (strong, nonatomic) NSMutableDictionary *proLevelsIndexesMutableDictionary;
@property (nonatomic) MEGAAccountType userProLevel;

@property (strong, nonatomic) NSNumberFormatter *numberFormatter;

@property (nonatomic, getter=shouldHideSkipButton) BOOL hideSkipButton;
@property (nonatomic, getter=isPurchased) BOOL purchased;

@end

@implementation UpgradeTableViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [MEGAPurchase.sharedInstance.restoreDelegateMutableArray addObject:self];
    self.purchased = NO;
    
    self.numberFormatter = NSNumberFormatter.alloc.init;
    self.numberFormatter.numberStyle = NSNumberFormatterCurrencyStyle;
    SKProduct *product = MEGAPurchase.sharedInstance.products.firstObject;
    self.numberFormatter.locale = product.priceLocale;
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:self.navigationItem.backBarButtonItem.style target:nil action:nil];
    
    NSString *navigationTitle = MEGASdkManager.sharedMEGASdk.mnz_isProAccount ? NSLocalizedString(@"Manage Account", @"account management button title in business account’s landing page") : NSLocalizedString(@"upgradeAccount", @"Button title which triggers the action to upgrade your MEGA account level");
    self.title = (self.isChoosingTheAccountType) ? NSLocalizedString(@"chooseYourAccountType", nil) : navigationTitle;
    
    self.chooseFromOneOfThePlansLabel.text = (self.isChoosingTheAccountType) ? NSLocalizedString(@"selectOneAccountType", @"") : NSLocalizedString(@"choosePlan", @"Header that help you with the upgrading process explaining that you have to choose one of the plans below to continue");
    
    self.chooseFromOneOfThePlansProLabel.text = NSLocalizedString(@"choosePlan", @"Header that help you with the upgrading process explaining that you have to choose one of the plans below to continue");
    
    self.currentPlanLabel.text = NSLocalizedString(@"inAppPurchase.upgrade.label.currentPlan", @"Text shown on the upgrade account page above the current PRO plan subscription");
    
    _autorenewableDescriptionLabel.text = NSLocalizedString(@"autorenewableDescription", @"Describe how works auto-renewable subscriptions on the Apple Store");
    
    self.termsAndPoliciesBarButtonItem.title = NSLocalizedString(@"settings.section.termsAndPolicies", @"Title of one of the Settings sections where you can see MEGA's 'Terms and Policies'");
    self.navigationController.topViewController.toolbarItems = self.toolbar.items;

    if (self.presentingViewController || self.navigationController.presentingViewController.presentedViewController == self.navigationController || [self.tabBarController.presentingViewController isKindOfClass:UITabBarController.class]) {
        self.hideSkipButton = NO;
        self.skipBarButtonItem.title = NSLocalizedString(@"skipButton", @"Button title that skips the current action");
    } else {
        self.hideSkipButton = YES;
    }
    
    if (self.isChoosingTheAccountType) {
        self.navigationItem.rightBarButtonItem = nil;
    } else {
        UIBarButtonItem *restoreBarButtonItem = [UIBarButtonItem.alloc initWithTitle:NSLocalizedString(@"restore", @"Button title to restore failed purchases") style:UIBarButtonItemStylePlain target:self action:@selector(restoreTouchUpInside)];
        self.navigationItem.rightBarButtonItem = restoreBarButtonItem;
        if (self.shouldHideSkipButton) {
            self.navigationItem.rightBarButtonItem = restoreBarButtonItem;
        } else {
            self.navigationItem.leftBarButtonItem = restoreBarButtonItem;
            self.navigationItem.rightBarButtonItem = self.skipBarButtonItem;
        }
    }
    
    [self getIndexPositionsForProLevels];
    
    [self initCurrentPlan];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self updateAppearance];
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
    
    if (self.isMovingFromParentViewController) {
        [MEGAPurchase.sharedInstance.restoreDelegateMutableArray removeObject:self];
    }
    
    self.navigationController.toolbarHidden = YES;
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    
    if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
        [self updateAppearance];
        
        [self.tableView reloadData];
    }
    
    if (self.traitCollection.preferredContentSizeCategory != previousTraitCollection.preferredContentSizeCategory) {
        [self setupTableViewHeaderAndFooter];
    }
}

#pragma mark - Private

- (void)updateAppearance {
    self.navigationController.toolbarHidden = YES;
    self.view.backgroundColor = self.tableView.backgroundColor = [UIColor mnz_backgroundGroupedForTraitCollection:self.traitCollection];
    self.tableView.separatorColor = [UIColor mnz_separatorForTraitCollection:self.traitCollection];
    
    self.chooseFromOneOfThePlansHeaderView.backgroundColor = self.chooseFromOneOfThePlansPROHeaderView.backgroundColor = [UIColor mnz_mainBarsForTraitCollection:self.traitCollection];
    
    [self setupCurrentPlanView];
    
    self.chooseFromOneOfThePlansLabel.textColor = self.chooseFromOneOfThePlansProLabel.textColor = [UIColor mnz_primaryGrayForTraitCollection:self.traitCollection];
    
    [self setupTableViewHeaderAndFooter];
    self.navigationController.toolbarHidden = NO;
    [self.navigationItem.rightBarButtonItem setTitleTextAttributes:@{NSFontAttributeName:[UIFont preferredFontForTextStyle:UIFontTextStyleBody],
                                                                     NSForegroundColorAttributeName:[UIColor mnz_primaryGrayForTraitCollection:self.traitCollection]}
                                                          forState:UIControlStateNormal];
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
    
    self.customPlanLabel.textColor = [UIColor mnz_primaryGrayForTraitCollection:self.traitCollection];
    NSString *toUpgradeYourCurrentSubscriptionString = NSLocalizedString(@"To upgrade your current subscription, please contact support for a [A]custom plan[/A].", @"When user is on PRO 3 plan, we will display an extra label to notify user that they can still contact support to have a customised plan.");
    NSString *customPlanString = [toUpgradeYourCurrentSubscriptionString mnz_stringBetweenString:@"[A]" andString:@"[/A]"];
    toUpgradeYourCurrentSubscriptionString = toUpgradeYourCurrentSubscriptionString.mnz_removeWebclientFormatters;
    NSMutableAttributedString *customPlanMutableAttributedString = [NSMutableAttributedString.new initWithString:toUpgradeYourCurrentSubscriptionString attributes:@{NSForegroundColorAttributeName:[UIColor mnz_primaryGrayForTraitCollection:self.traitCollection]}];
    [customPlanMutableAttributedString setAttributes:@{NSFontAttributeName:[UIFont mnz_preferredFontWithStyle:UIFontTextStyleCaption1 weight:UIFontWeightMedium], NSForegroundColorAttributeName:[UIColor mnz_turquoiseForTraitCollection:self.traitCollection]} range:[toUpgradeYourCurrentSubscriptionString rangeOfString:customPlanString]];
    self.customPlanLabel.attributedText = customPlanMutableAttributedString;
    
    self.twoMonthsFreeLabel.textColor = [UIColor mnz_secondaryGrayForTraitCollection:self.traitCollection];
    NSMutableAttributedString *asteriskMutableAttributedString = [NSMutableAttributedString.alloc initWithString:NSLocalizedString(@"* ", nil) attributes: @{NSFontAttributeName:[UIFont mnz_preferredFontWithStyle:UIFontTextStyleCaption1 weight:UIFontWeightMedium], NSForegroundColorAttributeName:[UIColor mnz_redForTraitCollection:(self.traitCollection)]}];
    NSAttributedString *twoMonthsFreeAttributedString = [NSAttributedString.alloc initWithString:NSLocalizedString(@"twoMonthsFree", @"Text shown in the purchase plan view to explain that annual subscription is 17% cheaper than 12 monthly payments") attributes:@{NSFontAttributeName:[UIFont mnz_preferredFontWithStyle:UIFontTextStyleCaption1 weight:UIFontWeightMedium], NSForegroundColorAttributeName:[UIColor mnz_secondaryGrayForTraitCollection:self.traitCollection]}];
    [asteriskMutableAttributedString appendAttributedString:twoMonthsFreeAttributedString];
    self.twoMonthsFreeLabel.attributedText = asteriskMutableAttributedString;
    self.autorenewableDescriptionLabel.textColor = [UIColor mnz_secondaryGrayForTraitCollection:self.traitCollection];
    [self.tableView sizeFooterToFit];
}

- (void)initCurrentPlan {
    self.userProLevel = [MEGASdkManager sharedMEGASdk].mnz_accountDetails.type;
    
    self.currentPlanImageView.image = [self imageForProLevel:self.userProLevel];
    self.currentPlanNameView.backgroundColor = [UIColor mnz_colorWithProLevel:self.userProLevel];
    self.currentPlanNameLabel.text = NSLocalizedString([MEGAAccountDetails stringForAccountType:self.userProLevel], nil);
    
    if ([[MEGASdkManager sharedMEGASdk] mnz_isProAccount]) {
        self.tableView.tableHeaderView = self.chooseFromOneOfThePlansPROHeaderView;
    }
    
    self.proLevelsMutableArray = [NSMutableArray arrayWithArray:@[[NSNumber numberWithInteger:MEGAAccountTypeLite], [NSNumber numberWithInteger:MEGAAccountTypeProI], [NSNumber numberWithInteger:MEGAAccountTypeProII], [NSNumber numberWithInteger:MEGAAccountTypeProIII]]];
    
    switch (self.userProLevel) {
        case MEGAAccountTypeFree:
            if (self.isChoosingTheAccountType) {
                [self.proLevelsMutableArray insertObject:[NSNumber numberWithInteger:MEGAAccountTypeFree] atIndex:0];
            }
            
            self.currentPlanLabelView.hidden = self.currentPlanCellView.hidden = YES;
            break;
        
        case MEGAAccountTypeLite:
            [self.proLevelsMutableArray removeObjectAtIndex:SubscriptionOrderLite];
            break;
            
        case MEGAAccountTypeProI:
            [self.proLevelsMutableArray removeObjectAtIndex:SubscriptionOrderProI];
            break;
            
        case MEGAAccountTypeProII:
            [self.proLevelsMutableArray removeObjectAtIndex:SubscriptionOrderProII];
            break;
            
        case MEGAAccountTypeProIII:
            self.customPlanLabel.hidden = self.customPlanButton.hidden = NO;
            
            [self.proLevelsMutableArray removeObjectAtIndex:SubscriptionOrderProIII];
            break;
            
        default:
            break;
    }
}

- (void)getIndexPositionsForProLevels {
    self.proLevelsIndexesMutableDictionary = [[NSMutableDictionary alloc] init];
    BOOL yearPlan;
    for (NSUInteger i = 0; i < [MEGAPurchase sharedInstance].products.count; i++) {
        SKProduct *product = [[MEGAPurchase sharedInstance].products objectOrNilAtIndex:i];
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
    NSString *storageString = NSLocalizedString(@"account.storageQuota", @"Text listed that includes the amount of storage that a user gets with a certain package. For example: '2 TB Storage'.");
    NSMutableAttributedString *storageMutableAttributedString = [NSMutableAttributedString.alloc initWithString:storageString attributes:@{NSFontAttributeName:[UIFont mnz_preferredFontWithStyle:UIFontTextStyleCaption1 weight:UIFontWeightMedium], NSForegroundColorAttributeName:[UIColor mnz_primaryGrayForTraitCollection:self.traitCollection]}];
    
    SKProduct *product = [[MEGAPurchase sharedInstance].products objectOrNilAtIndex:index];
    NSString *storageValueString = [self storageAndUnitsByProduct:product];
    NSMutableAttributedString *storageValueMutableAttributedString = [NSMutableAttributedString.alloc initWithString:storageValueString attributes:@{NSFontAttributeName:[UIFont mnz_preferredFontWithStyle:UIFontTextStyleCaption1 weight:UIFontWeightMedium], NSForegroundColorAttributeName:UIColor.mnz_label}];
    NSRange storageValueRange = [storageString rangeOfString:@"%@"];
    [storageMutableAttributedString replaceCharactersInRange:storageValueRange withAttributedString:storageValueMutableAttributedString];
    
    return storageMutableAttributedString;
}

- (NSAttributedString *)bandwidthAttributedStringForProLevelAtIndex:(NSInteger)index {
    NSString *transferQuotaString = NSLocalizedString(@"account.transferQuota.perMonth", @"Text listed that includes the amount of transfer quota a user gets per month with a certain package. For example: '8 TB Transfer'.");
    NSMutableAttributedString *transferQuotaMutableAttributedString = [NSMutableAttributedString.alloc initWithString:transferQuotaString attributes:@{NSFontAttributeName:[UIFont mnz_preferredFontWithStyle:UIFontTextStyleCaption1 weight:UIFontWeightMedium], NSForegroundColorAttributeName:[UIColor mnz_primaryGrayForTraitCollection:self.traitCollection]}];
    
    SKProduct *product = [[MEGAPurchase sharedInstance].products objectOrNilAtIndex:index];
    NSString *transferQuotaValueString = [self transferAndUnitsByProduct:product];
    NSMutableAttributedString *transferQuotaValueMutableAttributedString = [NSMutableAttributedString.alloc initWithString:transferQuotaValueString attributes:@{NSFontAttributeName:[UIFont mnz_preferredFontWithStyle:UIFontTextStyleCaption1 weight:UIFontWeightMedium], NSForegroundColorAttributeName:UIColor.mnz_label}];
    NSRange transferQuotaValueRange = [transferQuotaString rangeOfString:@"%@"];
    [transferQuotaMutableAttributedString replaceCharactersInRange:transferQuotaValueRange withAttributedString:transferQuotaValueMutableAttributedString];
    
    return transferQuotaMutableAttributedString;
}

- (NSAttributedString *)freeStorageAttributedString {
    NSString *freeStorageString = NSLocalizedString(@"account.storage.freePlan", @"Text listed that includes the amount of storage that a free user gets");
    NSString *freeStorageValueString = [freeStorageString mnz_stringBetweenString:@"[B]" andString:@"[/B]"];
    freeStorageString = freeStorageString.mnz_removeWebclientFormatters;
    NSMutableAttributedString *freeStorageMutableAttributedString = [NSMutableAttributedString.alloc initWithString:freeStorageString attributes:@{NSFontAttributeName:[UIFont mnz_preferredFontWithStyle:UIFontTextStyleCaption1 weight:UIFontWeightMedium], NSForegroundColorAttributeName:[UIColor mnz_primaryGrayForTraitCollection:self.traitCollection]}];
    
    NSMutableAttributedString *storageMutableAttributedString = [NSMutableAttributedString.alloc initWithString:freeStorageValueString attributes:@{NSFontAttributeName:[UIFont mnz_preferredFontWithStyle:UIFontTextStyleCaption1 weight:UIFontWeightMedium], NSForegroundColorAttributeName:UIColor.mnz_label}];
    NSRange freeStorageValueRange = [freeStorageString rangeOfString:freeStorageValueString];
    [freeStorageMutableAttributedString replaceCharactersInRange:freeStorageValueRange withAttributedString:storageMutableAttributedString];
    
    NSAttributedString *superscriptOneAttributedString = [NSAttributedString.alloc initWithString:NSLocalizedString(@" ¹", nil) attributes:@{NSFontAttributeName:[UIFont mnz_preferredFontWithStyle:UIFontTextStyleCaption1 weight:UIFontWeightMedium], NSForegroundColorAttributeName:[UIColor mnz_redForTraitCollection:(self.traitCollection)]}];
    [freeStorageMutableAttributedString appendAttributedString:superscriptOneAttributedString];
    
    return freeStorageMutableAttributedString;
}

- (NSAttributedString *)freeTransferQuotaAttributedString {
    NSString *transferQuotaString = NSLocalizedString(@"account.transferQuota.freePlan", @"Text listed that explain that a free user gets a limited amount of transfer quota.");
    NSString *limitedString = [transferQuotaString mnz_stringBetweenString:@"[B]" andString:@"[/B]"];
    transferQuotaString = transferQuotaString.mnz_removeWebclientFormatters;
    NSMutableAttributedString *transferQuotaMutableAttributedString = [NSMutableAttributedString.alloc initWithString:transferQuotaString attributes:@{NSFontAttributeName:[UIFont mnz_preferredFontWithStyle:UIFontTextStyleCaption1 weight:UIFontWeightMedium], NSForegroundColorAttributeName:[UIColor mnz_primaryGrayForTraitCollection:self.traitCollection]}];
    
    NSMutableAttributedString *limitedTransferQuotaMutableAttributedString = [NSMutableAttributedString.alloc initWithString:limitedString attributes:@{NSFontAttributeName:[UIFont mnz_preferredFontWithStyle:UIFontTextStyleCaption1 weight:UIFontWeightMedium], NSForegroundColorAttributeName:UIColor.mnz_label}];
    NSRange limitedStringRange = [transferQuotaString rangeOfString:limitedString];
    [transferQuotaMutableAttributedString replaceCharactersInRange:limitedStringRange withAttributedString:limitedTransferQuotaMutableAttributedString];
    
    return transferQuotaMutableAttributedString;
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

- (void)pushProductDetailWithAccountType:(MEGAAccountType)accountType {
    ProductDetailViewController *productDetailVC = [self.storyboard instantiateViewControllerWithIdentifier:@"ProductDetailViewControllerID"];
    productDetailVC.chooseAccountType = self.isChoosingTheAccountType;
    productDetailVC.currentAccountType = self.userProLevel;
    productDetailVC.megaAccountType = accountType;
    
    NSNumber *proLevelIndexNumber = [self.proLevelsIndexesMutableDictionary objectForKey:[NSNumber numberWithInteger:accountType]];
    SKProduct *monthlyProduct = [MEGAPurchase.sharedInstance.products objectOrNilAtIndex:proLevelIndexNumber.integerValue];
    SKProduct *yearlyProduct = [MEGAPurchase.sharedInstance.products objectOrNilAtIndex:proLevelIndexNumber.integerValue+1];
    NSString *storageFormattedString = [self storageAndUnitsByProduct:monthlyProduct];
    NSString *bandwidthFormattedString = [self transferAndUnitsByProduct:monthlyProduct];
    
    productDetailVC.storageString = storageFormattedString;
    productDetailVC.bandwidthString = bandwidthFormattedString;
    productDetailVC.priceMonthString = [self.numberFormatter stringFromNumber:monthlyProduct.price];
    productDetailVC.priceYearlyString = [self.numberFormatter stringFromNumber:yearlyProduct.price];
    productDetailVC.monthlyProduct = monthlyProduct;
    productDetailVC.yearlyProduct = yearlyProduct;
    
    [self.navigationController pushViewController:productDetailVC animated:YES];
}

#pragma mark - IBActions

- (IBAction)skipTouchUpInside:(UIBarButtonItem *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)currentPlanTouchUpInside:(UITapGestureRecognizer *)sender {
    [self pushProductDetailWithAccountType:self.userProLevel];
}

- (IBAction)requestAPlanTouchUpInside:(UIButton *)sender {
    if ([MFMailComposeViewController canSendMail]) {
        MFMailComposeViewController *mailComposeVC = [[MFMailComposeViewController alloc] init];
        mailComposeVC.mailComposeDelegate = self;
        mailComposeVC.toRecipients = @[@"support@mega.nz"];
        
        mailComposeVC.subject = NSLocalizedString(@"Upgrade to a custom plan", @"Mail title to upgrade to a custom plan");
        [mailComposeVC setMessageBody:NSLocalizedString(@"Ask us how you can upgrade to a custom plan:", @"Mail subject to upgrade to a custom plan") isHTML:NO];
        
        [self presentViewController:mailComposeVC animated:YES completion:nil];
    } else {
        [SVProgressHUD showImage:[UIImage imageNamed:@"hudWarning"] status:NSLocalizedString(@"noEmailAccountConfigured", @"Text shown when you want to send feedback of the app and you don't have an email account set up on your device")];
    }
}

- (IBAction)termsAndPoliciesTouchUpInside:(id)sender {
    [[TermsAndPoliciesRouter.alloc initWithNavigationController:self.navigationController] start];
}

- (void)restoreTouchUpInside {
    [MEGAPurchase.sharedInstance restorePurchase];
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
        NSMutableAttributedString *superscriptOneAttributedString = [NSMutableAttributedString.alloc initWithString:NSLocalizedString(@"¹ ", nil) attributes:@{NSFontAttributeName:[UIFont mnz_preferredFontWithStyle:UIFontTextStyleCaption1 weight:UIFontWeightMedium], NSForegroundColorAttributeName:[UIColor mnz_redForTraitCollection:(self.traitCollection)]}];
        
        NSAttributedString *subjectToYourParticipationAttributedString = [NSAttributedString.alloc initWithString:NSLocalizedString(@"subjectToYourParticipationInOurAchievementsProgram", @"") attributes:@{NSFontAttributeName:[UIFont mnz_preferredFontWithStyle:UIFontTextStyleCaption1 weight:UIFontWeightMedium], NSForegroundColorAttributeName:[UIColor mnz_primaryGrayForTraitCollection:self.traitCollection]}];
        [superscriptOneAttributedString appendAttributedString:subjectToYourParticipationAttributedString];
        
        cell.subjectToYourParticipationLabel.attributedText = superscriptOneAttributedString;
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:@"productCell" forIndexPath:indexPath];
    }
    
    NSNumber *proLevelNumber = [self.proLevelsMutableArray objectOrNilAtIndex:indexPath.row];
    cell.productImageView.image = [self imageForProLevel:proLevelNumber.integerValue];
    cell.productNameLabel.text = NSLocalizedString([MEGAAccountDetails stringForAccountType:proLevelNumber.integerValue], nil);
    cell.productNameView.backgroundColor = [UIColor mnz_colorWithProLevel:proLevelNumber.integerValue];
    cell.productPriceLabel.textColor = [UIColor mnz_colorForPriceLabelWithProLevel:proLevelNumber.integerValue traitCollection:self.traitCollection];
    
    NSNumber *proLevelIndexNumber = [self.proLevelsIndexesMutableDictionary objectForKey:proLevelNumber];
    cell.productStorageLabel.attributedText = (self.isChoosingTheAccountType && indexPath.row == 0) ? [self freeStorageAttributedString] : [self storageAttributedStringForProLevelAtIndex:proLevelIndexNumber.integerValue];
    cell.productBandwidthLabel.attributedText = (self.isChoosingTheAccountType && indexPath.row == 0) ? [self freeTransferQuotaAttributedString] :[self bandwidthAttributedStringForProLevelAtIndex:proLevelIndexNumber.integerValue];
    
    SKProduct *product = [[MEGAPurchase sharedInstance].products objectOrNilAtIndex:proLevelIndexNumber.integerValue];
    
    NSString *productPriceString = [NSString stringWithFormat:NSLocalizedString(@"productPricePerMonth", @"Price asociated with the MEGA PRO account level you can subscribe"), [self.numberFormatter stringFromNumber:product.price]];
    NSAttributedString *asteriskAttributedString = [NSAttributedString.alloc initWithString:NSLocalizedString(@" *", nil) attributes:@{NSFontAttributeName:[UIFont mnz_preferredFontWithStyle:UIFontTextStyleCaption1 weight:UIFontWeightMedium], NSForegroundColorAttributeName:[UIColor mnz_redForTraitCollection:(self.traitCollection)]}];
    NSMutableAttributedString *productPriceMutableAttributedString = [NSMutableAttributedString.alloc initWithString:productPriceString attributes:@{NSFontAttributeName : [UIFont mnz_preferredFontWithStyle:UIFontTextStyleCaption1 weight:UIFontWeightMedium], NSForegroundColorAttributeName : [UIColor mnz_colorWithProLevel:proLevelNumber.integerValue]}];
    [productPriceMutableAttributedString appendAttributedString:asteriskAttributedString];
    cell.productPriceLabel.attributedText = productPriceMutableAttributedString;
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.isChoosingTheAccountType && indexPath.row == 0) {
        [self dismissViewControllerAnimated:YES completion:nil];
        return;
    }
    
    NSNumber *accountTypeNumber = [self.proLevelsMutableArray objectOrNilAtIndex:indexPath.row];
    MEGAAccountType accountType = accountTypeNumber.integerValue;
    [self pushProductDetailWithAccountType:accountType];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - MEGARestoreDelegate

- (void)successfulRestore:(MEGAPurchase *)megaPurchase {
    if (!self.isPurchased) {
        self.purchased = YES;
        
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"thankYou_title", nil)  message:NSLocalizedString(@"purchaseRestore_message", nil) preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"ok", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            if (UIApplication.mnz_presentingViewController) {
                [UIApplication.mnz_presentingViewController dismissViewControllerAnimated:YES completion:nil];
            }
        }]];
        
        [self presentViewController:alertController animated:YES completion:nil];
    }
}

- (void)incompleteRestore {
    [SVProgressHUD dismiss];
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"incompleteRestore_title", @"Alert title shown when a restore hasn't been completed correctly")  message:NSLocalizedString(@"incompleteRestore_message", @"Alert message shown when a restore hasn't been completed correctly") preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"ok", nil) style:UIAlertActionStyleDefault handler:nil]];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)failedRestore:(NSInteger)errorCode message:(NSString *)errorMessage {
    [SVProgressHUD dismiss];
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"failedRestore_title", @"Alert title shown when the restoring process has stopped for some reason")  message:NSLocalizedString(@"failedRestore_message", @"Alert message shown when the restoring process has stopped for some reason") preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"ok", nil) style:UIAlertActionStyleDefault handler:nil]];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

@end
