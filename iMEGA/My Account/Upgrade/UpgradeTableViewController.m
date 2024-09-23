#import "UpgradeTableViewController.h"

#import <MessageUI/MFMailComposeViewController.h>

#import "SVProgressHUD.h"

#import "MEGASdk+MNZCategory.h"
#import "NSString+MNZCategory.h"
#import "NSURL+MNZCategory.h"
#import "NSArray+MNZCategory.h"

#import "MEGAPurchase.h"
#import "MEGA-Swift.h"
#import "MEGAReachabilityManager.h"
#import "ProductDetailViewController.h"
#import "ProductTableViewCell.h"

@import MEGAL10nObjc;
@import MEGAUIKit;

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
@property (weak, nonatomic) IBOutlet UIView *currentPlanBottomLineCellView;
@property (weak, nonatomic) IBOutlet UIImageView *currentPlanDisclosureImageView;

@property (weak, nonatomic) IBOutlet UIView *footerTopLineView;

@property (weak, nonatomic) IBOutlet UILabel *customPlanLabel;
@property (weak, nonatomic) IBOutlet UIButton *customPlanButton;

@property (weak, nonatomic) IBOutlet UILabel *twoMonthsFreeLabel;
@property (weak, nonatomic) IBOutlet UILabel *autorenewableDescriptionLabel;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *skipBarButtonItem;

@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *termsAndPoliciesBarButtonItem;
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
    
    NSString *navigationTitle = MEGASdk.shared.mnz_isProAccount ? LocalizedString(@"Manage Account", @"account management button title in business account’s landing page") : LocalizedString(@"upgradeAccount", @"Button title which triggers the action to upgrade your MEGA account level");
    self.title = (self.isChoosingTheAccountType) ? LocalizedString(@"chooseYourAccountType", @"") : navigationTitle;
    
    [self setMenuCapableBackButtonWithMenuTitle:self.title];
    
    self.chooseFromOneOfThePlansLabel.text = (self.isChoosingTheAccountType) ? LocalizedString(@"selectOneAccountType", @"") : LocalizedString(@"choosePlan", @"Header that help you with the upgrading process explaining that you have to choose one of the plans below to continue");
    
    self.chooseFromOneOfThePlansProLabel.text = LocalizedString(@"choosePlan", @"Header that help you with the upgrading process explaining that you have to choose one of the plans below to continue");
    
    self.currentPlanLabel.text = LocalizedString(@"inAppPurchase.upgrade.label.currentPlan", @"Text shown on the upgrade account page above the current PRO plan subscription");
    
    _autorenewableDescriptionLabel.text = LocalizedString(@"autorenewableDescription", @"Describe how works auto-renewable subscriptions on the Apple Store");
    
    self.termsAndPoliciesBarButtonItem.title = LocalizedString(@"settings.section.termsAndPolicies", @"Title of one of the Settings sections where you can see MEGA's 'Terms and Policies'");
    self.navigationController.topViewController.toolbarItems = self.toolbar.items;

    if (self.presentingViewController || self.navigationController.presentingViewController.presentedViewController == self.navigationController || [self.tabBarController.presentingViewController isKindOfClass:UITabBarController.class]) {
        self.hideSkipButton = NO;
        self.skipBarButtonItem.title = LocalizedString(@"skipButton", @"Button title that skips the current action");
    } else {
        self.hideSkipButton = YES;
    }
    
    if (self.isChoosingTheAccountType) {
        self.navigationItem.rightBarButtonItem = nil;
    } else {
        UIBarButtonItem *restoreBarButtonItem = [UIBarButtonItem.alloc initWithTitle:LocalizedString(@"restore", @"Button title to restore failed purchases") style:UIBarButtonItemStylePlain target:self action:@selector(restoreTouchUpInside)];
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
    
    if ([MEGASdk.shared mnz_isProAccount]) {
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

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self.tableView reloadData];
    } completion:nil];
}

#pragma mark - Private

- (UpgradeAccountViewModel *)viewModel {
    if (_viewModel == nil) {
        _viewModel = [self createUpgradeAccountViewModel];
    }
    
    return _viewModel;
}

- (void)updateAppearance {
    self.navigationController.toolbarHidden = YES;
    
    [AppearanceManager forceNavigationBarUpdate:self.navigationController.navigationBar traitCollection:self.traitCollection];
    self.termsAndPoliciesBarButtonItem.tintColor = [self primaryTextColor];
    
    self.view.backgroundColor = self.tableView.backgroundColor = [self defaultBackgroundColor];
    self.tableView.separatorColor = [self separatorColor];
    
    self.chooseFromOneOfThePlansHeaderView.backgroundColor = self.chooseFromOneOfThePlansPROHeaderView.backgroundColor = [self headerBackgroundColor];
    
    [self setupCurrentPlanView];
    
    self.chooseFromOneOfThePlansLabel.textColor = self.chooseFromOneOfThePlansProLabel.textColor = [self secondaryTextColor];
    
    [self setupTableViewHeaderAndFooter];
    self.navigationController.toolbarHidden = NO;
}

- (void)setupCurrentPlanView {
    self.currentPlanLabel.textColor = [self secondaryTextColor];
    self.currentPlanLabelLineView.backgroundColor = [self separatorColor];
    
    self.currentPlanNameLabel.textColor = [self whiteTextColor];
    NSNumber *userProLevelIndexNumber = [self.proLevelsIndexesMutableDictionary objectForKey:[NSNumber numberWithInteger:self.userProLevel]];
    [self.currentPlanDisclosureImageView setHidden:userProLevelIndexNumber == nil];
    
    if (userProLevelIndexNumber) {
        self.currentPlanStorageLabel.attributedText = [self storageAttributedStringForProLevelAtIndex:userProLevelIndexNumber.integerValue];
        self.currentPlanBandwidthLabel.attributedText = [self bandwidthAttributedStringForProLevelAtIndex:userProLevelIndexNumber.integerValue];
    } else {
        [self setCurrentPlanMaxQuotaData];
    }

    self.currentPlanCellView.backgroundColor = [self currentPlanBackgroundColor];
    self.currentPlanBottomLineCellView.backgroundColor = [self separatorColor];
}

- (void)setupTableViewHeaderAndFooter {
    UIColor *separatorColor = [self separatorColor];
    self.chooseFromOneOfThePlansBottomLineView.backgroundColor = separatorColor;
    
    self.chooseFromOneOfThePlansPROBottomLineView.backgroundColor = separatorColor;
    
    self.footerTopLineView.backgroundColor = separatorColor;
    
    self.customPlanLabel.textColor = [self secondaryTextColor];
    NSString *toUpgradeYourCurrentSubscriptionString = LocalizedString(@"To upgrade your current subscription, please contact support for a [A]custom plan[/A].", @"When user is on PRO 3 plan, we will display an extra label to notify user that they can still contact support to have a customised plan.");
    NSString *customPlanString = [toUpgradeYourCurrentSubscriptionString mnz_stringBetweenString:@"[A]" andString:@"[/A]"];
    toUpgradeYourCurrentSubscriptionString = toUpgradeYourCurrentSubscriptionString.mnz_removeWebclientFormatters;
    NSMutableAttributedString *customPlanMutableAttributedString = [NSMutableAttributedString.new initWithString:toUpgradeYourCurrentSubscriptionString attributes:@{NSForegroundColorAttributeName:[self secondaryTextColor]}];
    [customPlanMutableAttributedString setAttributes:@{NSFontAttributeName:[UIFont mnz_preferredFontWithStyle:UIFontTextStyleCaption1 weight:UIFontWeightMedium], NSForegroundColorAttributeName:[self linkColor]} range:[toUpgradeYourCurrentSubscriptionString rangeOfString:customPlanString]];
    self.customPlanLabel.attributedText = customPlanMutableAttributedString;
    
    UIColor *footerTextColor = [self footerTextColor];
    self.twoMonthsFreeLabel.textColor = footerTextColor;
    NSMutableAttributedString *asteriskMutableAttributedString = [NSMutableAttributedString.alloc initWithString:LocalizedString(@"* ", @"") attributes: @{NSFontAttributeName:[UIFont mnz_preferredFontWithStyle:UIFontTextStyleCaption1 weight:UIFontWeightMedium], NSForegroundColorAttributeName:[UIColor mnz_red]}];
    NSAttributedString *twoMonthsFreeAttributedString = [NSAttributedString.alloc initWithString:LocalizedString(@"twoMonthsFree", @"Text shown in the purchase plan view to explain that annual subscription is 17% cheaper than 12 monthly payments") attributes:@{NSFontAttributeName:[UIFont mnz_preferredFontWithStyle:UIFontTextStyleCaption1 weight:UIFontWeightMedium], NSForegroundColorAttributeName:footerTextColor}];
    [asteriskMutableAttributedString appendAttributedString:twoMonthsFreeAttributedString];
    self.twoMonthsFreeLabel.attributedText = asteriskMutableAttributedString;
    self.autorenewableDescriptionLabel.textColor = footerTextColor;
    [self.tableView sizeFooterToFit];
}

- (void)initCurrentPlan {
    self.userProLevel = MEGASdk.shared.mnz_accountDetails.type;
    
    self.currentPlanImageView.image = [self imageForProLevel:self.userProLevel];
    self.currentPlanNameView.backgroundColor = [UIColor mnz_colorWithProLevel:self.userProLevel];
    self.currentPlanNameLabel.text = LocalizedString([MEGAAccountDetails stringForAccountType:self.userProLevel], @"");
    
    if ([MEGASdk.shared mnz_isProAccount]) {
        self.tableView.tableHeaderView = self.chooseFromOneOfThePlansPROHeaderView;
    }
    
    self.proLevelsMutableArray = [NSMutableArray arrayWithArray:[self getAvailableProductPlans]];
    
    switch (self.userProLevel) {
        case MEGAAccountTypeFree:
            if (self.isChoosingTheAccountType) {
                [self.proLevelsMutableArray insertObject:[NSNumber numberWithInteger:MEGAAccountTypeFree] atIndex:0];
            }

            self.currentPlanLabelView.hidden = self.currentPlanCellView.hidden = YES;
            break;
        
        case MEGAAccountTypeLite:
        case MEGAAccountTypeProI:
        case MEGAAccountTypeProII:
            [self removePlanOnAvailablePlans:self.userProLevel];
            break;
            
        case MEGAAccountTypeProIII:
            self.customPlanLabel.hidden = self.customPlanButton.hidden = NO;
            [self removePlanOnAvailablePlans:self.userProLevel];
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
    NSString *storageString = LocalizedString(@"account.storageQuota", @"Text listed that includes the amount of storage that a user gets with a certain package. For example: '2 TB Storage'.");
    NSMutableAttributedString *storageMutableAttributedString = [NSMutableAttributedString.alloc initWithString:storageString attributes:@{NSFontAttributeName:[UIFont mnz_preferredFontWithStyle:UIFontTextStyleCaption1 weight:UIFontWeightMedium], NSForegroundColorAttributeName:[self secondaryTextColor]}];
    
    SKProduct *product = [[MEGAPurchase sharedInstance].products objectOrNilAtIndex:index];
    NSString *storageValueString = [self storageAndUnitsByProduct:product];
    NSMutableAttributedString *storageValueMutableAttributedString = [NSMutableAttributedString.alloc initWithString:storageValueString attributes:@{NSFontAttributeName:[UIFont mnz_preferredFontWithStyle:UIFontTextStyleCaption1 weight:UIFontWeightMedium], NSForegroundColorAttributeName:[self primaryTextColor]}];
    NSRange storageValueRange = [storageString rangeOfString:@"%@"];
    [storageMutableAttributedString replaceCharactersInRange:storageValueRange withAttributedString:storageValueMutableAttributedString];
    
    return storageMutableAttributedString;
}

- (NSAttributedString *)bandwidthAttributedStringForProLevelAtIndex:(NSInteger)index {
    NSString *transferQuotaString = LocalizedString(@"account.transferQuota.perMonth", @"Text listed that includes the amount of transfer quota a user gets per month with a certain package. For example: '8 TB Transfer'.");
    NSMutableAttributedString *transferQuotaMutableAttributedString = [NSMutableAttributedString.alloc initWithString:transferQuotaString attributes:@{NSFontAttributeName:[UIFont mnz_preferredFontWithStyle:UIFontTextStyleCaption1 weight:UIFontWeightMedium], NSForegroundColorAttributeName:[self secondaryTextColor]}];
    
    SKProduct *product = [[MEGAPurchase sharedInstance].products objectOrNilAtIndex:index];
    NSString *transferQuotaValueString = [self transferAndUnitsByProduct:product];
    NSMutableAttributedString *transferQuotaValueMutableAttributedString = [NSMutableAttributedString.alloc initWithString:transferQuotaValueString attributes:@{NSFontAttributeName:[UIFont mnz_preferredFontWithStyle:UIFontTextStyleCaption1 weight:UIFontWeightMedium], NSForegroundColorAttributeName:[self primaryTextColor]}];
    NSRange transferQuotaValueRange = [transferQuotaString rangeOfString:@"%@"];
    [transferQuotaMutableAttributedString replaceCharactersInRange:transferQuotaValueRange withAttributedString:transferQuotaValueMutableAttributedString];
    
    return transferQuotaMutableAttributedString;
}

- (NSAttributedString *)freeStorageAttributedString {
    NSString *freeStorageString = [NSString stringWithFormat:LocalizedString(@"account.storage.freePlan", @"Text listed that includes the amount of storage that a free user gets"), self.accountBaseStorage];
    NSString *freeStorageValueString = [freeStorageString mnz_stringBetweenString:@"[B]" andString:@"[/B]"];
    freeStorageString = freeStorageString.mnz_removeWebclientFormatters;
    NSMutableAttributedString *freeStorageMutableAttributedString = [NSMutableAttributedString.alloc initWithString:freeStorageString attributes:@{NSFontAttributeName:[UIFont mnz_preferredFontWithStyle:UIFontTextStyleCaption1 weight:UIFontWeightMedium], NSForegroundColorAttributeName:[self secondaryTextColor]}];
    
    NSMutableAttributedString *storageMutableAttributedString = [NSMutableAttributedString.alloc initWithString:freeStorageValueString attributes:@{NSFontAttributeName:[UIFont mnz_preferredFontWithStyle:UIFontTextStyleCaption1 weight:UIFontWeightMedium], NSForegroundColorAttributeName:[self primaryTextColor]}];
    NSRange freeStorageValueRange = [freeStorageString rangeOfString:freeStorageValueString];
    [freeStorageMutableAttributedString replaceCharactersInRange:freeStorageValueRange withAttributedString:storageMutableAttributedString];
    
    NSAttributedString *superscriptOneAttributedString = [NSAttributedString.alloc initWithString:LocalizedString(@" ¹", @"") attributes:@{NSFontAttributeName:[UIFont mnz_preferredFontWithStyle:UIFontTextStyleCaption1 weight:UIFontWeightMedium], NSForegroundColorAttributeName:[UIColor mnz_red]}];
    [freeStorageMutableAttributedString appendAttributedString:superscriptOneAttributedString];
    
    return freeStorageMutableAttributedString;
}

- (NSAttributedString *)freeTransferQuotaAttributedString {
    NSString *transferQuotaString = LocalizedString(@"account.transferQuota.freePlan", @"Text listed that explain that a free user gets a limited amount of transfer quota.");
    NSString *limitedString = [transferQuotaString mnz_stringBetweenString:@"[B]" andString:@"[/B]"];
    transferQuotaString = transferQuotaString.mnz_removeWebclientFormatters;
    NSMutableAttributedString *transferQuotaMutableAttributedString = [NSMutableAttributedString.alloc initWithString:transferQuotaString attributes:@{NSFontAttributeName:[UIFont mnz_preferredFontWithStyle:UIFontTextStyleCaption1 weight:UIFontWeightMedium], NSForegroundColorAttributeName:[self secondaryTextColor]}];
    
    NSMutableAttributedString *limitedTransferQuotaMutableAttributedString = [NSMutableAttributedString.alloc initWithString:limitedString attributes:@{NSFontAttributeName:[UIFont mnz_preferredFontWithStyle:UIFontTextStyleCaption1 weight:UIFontWeightMedium], NSForegroundColorAttributeName:[self primaryTextColor]}];
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
    if ([self.proLevelsIndexesMutableDictionary objectForKey:[NSNumber numberWithInteger:self.userProLevel]]) {
        [self pushProductDetailWithAccountType:self.userProLevel];
    }
}

- (IBAction)requestAPlanTouchUpInside:(UIButton *)sender {
    if ([MFMailComposeViewController canSendMail]) {
        MFMailComposeViewController *mailComposeVC = [[MFMailComposeViewController alloc] init];
        mailComposeVC.mailComposeDelegate = self;
        mailComposeVC.toRecipients = @[@"support@mega.nz"];
        
        mailComposeVC.subject = LocalizedString(@"Upgrade to a custom plan", @"Mail title to upgrade to a custom plan");
        [mailComposeVC setMessageBody:LocalizedString(@"Ask us how you can upgrade to a custom plan:", @"Mail subject to upgrade to a custom plan") isHTML:NO];
        
        [self presentViewController:mailComposeVC animated:YES completion:nil];
    } else {
        [SVProgressHUD showImage:[UIImage imageNamed:@"hudWarning"] status:LocalizedString(@"noEmailAccountConfigured", @"Text shown when you want to send feedback of the app and you don't have an email account set up on your device")];
    }
}

- (IBAction)termsAndPoliciesTouchUpInside:(id)sender {
    [self showTermsAndPolicies];
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
        NSMutableAttributedString *superscriptOneAttributedString = [NSMutableAttributedString.alloc initWithString:LocalizedString(@"¹ ", @"") attributes:@{NSFontAttributeName:[UIFont mnz_preferredFontWithStyle:UIFontTextStyleCaption1 weight:UIFontWeightMedium], NSForegroundColorAttributeName:[UIColor mnz_red]}];
        
        NSAttributedString *subjectToYourParticipationAttributedString = [NSAttributedString.alloc initWithString:LocalizedString(@"subjectToYourParticipationInOurAchievementsProgram", @"") attributes:@{NSFontAttributeName:[UIFont mnz_preferredFontWithStyle:UIFontTextStyleCaption1 weight:UIFontWeightMedium], NSForegroundColorAttributeName:[UIColor mnz_primaryGray]}];
        [superscriptOneAttributedString appendAttributedString:subjectToYourParticipationAttributedString];
        
        cell.subjectToYourParticipationLabel.attributedText = superscriptOneAttributedString;
        [cell layoutIfNeeded];
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:@"productCell" forIndexPath:indexPath];
    }
    
    NSNumber *proLevelNumber = [self.proLevelsMutableArray objectOrNilAtIndex:indexPath.row];
    cell.productImageView.image = [self imageForProLevel:proLevelNumber.integerValue];
    cell.productNameLabel.text = LocalizedString([MEGAAccountDetails stringForAccountType:proLevelNumber.integerValue], @"");
    cell.productNameLabel.textColor = [self whiteTextColor];
    cell.productNameView.backgroundColor = [UIColor mnz_colorWithProLevel:proLevelNumber.integerValue];
    cell.productPriceLabel.textColor = [UIColor mnz_colorForPriceLabelWithProLevel:proLevelNumber.integerValue traitCollection:self.traitCollection];
    
    NSNumber *proLevelIndexNumber = [self.proLevelsIndexesMutableDictionary objectForKey:proLevelNumber];
    cell.productStorageLabel.attributedText = (self.isChoosingTheAccountType && indexPath.row == 0) ? [self freeStorageAttributedString] : [self storageAttributedStringForProLevelAtIndex:proLevelIndexNumber.integerValue];
    cell.productBandwidthLabel.attributedText = (self.isChoosingTheAccountType && indexPath.row == 0) ? [self freeTransferQuotaAttributedString] :[self bandwidthAttributedStringForProLevelAtIndex:proLevelIndexNumber.integerValue];
    
    SKProduct *product = [[MEGAPurchase sharedInstance].products objectOrNilAtIndex:proLevelIndexNumber.integerValue];
    
    NSString *productPriceString = [NSString stringWithFormat:LocalizedString(@"productPricePerMonth", @"Price asociated with the MEGA PRO account level you can subscribe"), [self.numberFormatter stringFromNumber:product.price]];
    NSAttributedString *asteriskAttributedString = [NSAttributedString.alloc initWithString:LocalizedString(@" *", @"") attributes:@{NSFontAttributeName:[UIFont mnz_preferredFontWithStyle:UIFontTextStyleCaption1 weight:UIFontWeightMedium], NSForegroundColorAttributeName:[UIColor mnz_red]}];
    NSMutableAttributedString *productPriceMutableAttributedString = [NSMutableAttributedString.alloc initWithString:productPriceString attributes:@{NSFontAttributeName : [UIFont mnz_preferredFontWithStyle:UIFontTextStyleCaption1 weight:UIFontWeightMedium], NSForegroundColorAttributeName : [UIColor mnz_colorWithProLevel:proLevelNumber.integerValue]}];
    [productPriceMutableAttributedString appendAttributedString:asteriskAttributedString];
    cell.productPriceLabel.attributedText = productPriceMutableAttributedString;
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.isChoosingTheAccountType && indexPath.row == 0) {
        [self.viewModel sendAccountPlanTapStats: MEGAAccountTypeFree];
        [self dismissViewControllerAnimated:YES completion:nil];
        return;
    }
    
    NSNumber *accountTypeNumber = [self.proLevelsMutableArray objectOrNilAtIndex:indexPath.row];
    MEGAAccountType accountType = accountTypeNumber.integerValue;
    [self pushProductDetailWithAccountType:accountType];
    [self.viewModel sendAccountPlanTapStats:accountType];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - MEGARestoreDelegate

- (void)successfulRestore:(MEGAPurchase *)megaPurchase {
    if (!self.isPurchased) {
        self.purchased = YES;
        
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:LocalizedString(@"thankYou_title", @"")  message:LocalizedString(@"purchaseRestore_message", @"") preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:LocalizedString(@"ok", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            if (UIApplication.mnz_presentingViewController) {
                [UIApplication.mnz_presentingViewController dismissViewControllerAnimated:YES completion:nil];
            }
        }]];
        
        [self presentViewController:alertController animated:YES completion:nil];
    }
}

- (void)incompleteRestore {
    [SVProgressHUD dismiss];
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:LocalizedString(@"incompleteRestore_title", @"Alert title shown when a restore hasn't been completed correctly")  message:LocalizedString(@"incompleteRestore_message", @"Alert message shown when a restore hasn't been completed correctly") preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:LocalizedString(@"ok", @"") style:UIAlertActionStyleDefault handler:nil]];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)failedRestore:(NSInteger)errorCode message:(NSString *)errorMessage {
    [SVProgressHUD dismiss];
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:LocalizedString(@"failedRestore_title", @"Alert title shown when the restoring process has stopped for some reason")  message:LocalizedString(@"failedRestore_message", @"Alert message shown when the restoring process has stopped for some reason") preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:LocalizedString(@"ok", @"") style:UIAlertActionStyleDefault handler:nil]];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

@end
