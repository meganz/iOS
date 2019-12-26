#import "MyAccountViewController.h"

#import "UIImage+GKContact.h"

#import "Helper.h"
#import "MEGAPurchase.h"
#import "MEGASdk+MNZCategory.h"
#import "MEGAReachabilityManager.h"
#import "MEGASdkManager.h"
#import "MEGAShowPasswordReminderRequestDelegate.h"
#import "NSFileManager+MNZCategory.h"
#import "NSString+MNZCategory.h"
#import "UpgradeTableViewController.h"

@interface MyAccountViewController () <MEGAPurchasePricingDelegate, MEGARequestDelegate> {
    BOOL isAccountDetailsAvailable;
    
    NSNumber *localSize;
    NSNumber *usedStorage;
    NSNumber *maxStorage;
}

@property (weak, nonatomic) IBOutlet UIBarButtonItem *editBarButtonItem;

@property (weak, nonatomic) IBOutlet UILabel *emailLabel;

@property (weak, nonatomic) IBOutlet UILabel *localLabel;
@property (weak, nonatomic) IBOutlet UILabel *localUsedSpaceLabel;

@property (weak, nonatomic) IBOutlet UILabel *usedLabel;
@property (weak, nonatomic) IBOutlet UILabel *usedSpaceLabel;

@property (weak, nonatomic) IBOutlet UILabel *availableLabel;
@property (weak, nonatomic) IBOutlet UILabel *availableSpaceLabel;

@property (weak, nonatomic) IBOutlet UILabel *accountTypeLabel;

@property (weak, nonatomic) IBOutlet UIView *proView;
@property (weak, nonatomic) IBOutlet UILabel *proStatusLabel;
@property (weak, nonatomic) IBOutlet UILabel *proExpiryDateLabel;
@property (weak, nonatomic) IBOutlet UIButton *upgradeAccountButton;

@property (weak, nonatomic) IBOutlet UIImageView *logoutButtonTopImageView;
@property (weak, nonatomic) IBOutlet UIButton *logoutButton;
@property (weak, nonatomic) IBOutlet UIImageView *logoutButtonBottomImageView;

@property (nonatomic) MEGAAccountType megaAccountType;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *usedLabelTopLayoutConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *accountTypeLabelTopLayoutConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *proViewTopLayoutConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *proExpiryDateLabelHeightLayoutConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *upgradeAccountTopLayoutConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *logoutButtonTopLayoutConstraint;

@property (nonatomic) NSDateFormatter *dateFormatter;

@end

@implementation MyAccountViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = AMLocalizedString(@"profile", @"Label for any 'Profile' button, link, text, title, etc. - (String as short as possible).");
    
    self.editBarButtonItem.title = AMLocalizedString(@"edit", @"Caption of a button to edit the files that are selected");
    
    [self.localLabel setText:AMLocalizedString(@"localLabel", @"Local")];
    [self.usedLabel setText:AMLocalizedString(@"usedSpaceLabel", @"Used")];
    [self.availableLabel setText:AMLocalizedString(@"availableLabel", @"Available")];
    
    NSString *accountTypeString = [AMLocalizedString(@"accountType", @"title of the My Account screen") stringByReplacingOccurrencesOfString:@":" withString:@""];
    self.accountTypeLabel.text = accountTypeString;
    
    [self.upgradeAccountButton setTitle:AMLocalizedString(@"upgradeAccount", @"Button title which triggers the action to upgrade your MEGA account level") forState:UIControlStateNormal];
    
    [self.logoutButton setTitle:AMLocalizedString(@"logoutLabel", @"Title of the button which logs out from your account.") forState:UIControlStateNormal];
    
    if ([[UIDevice currentDevice] iPhone4X]) {
        float constant = ([[MEGASdkManager sharedMEGASdk] mnz_isProAccount]) ? 4.0f : 8.0f;
        self.usedLabelTopLayoutConstraint.constant = constant;
        self.accountTypeLabelTopLayoutConstraint.constant = constant + 1;
        self.proViewTopLayoutConstraint.constant = constant;
        self.upgradeAccountTopLayoutConstraint.constant = constant;
        self.logoutButtonTopLayoutConstraint.constant = 0.0f;
        self.logoutButtonTopImageView.backgroundColor = nil;
        self.logoutButtonBottomImageView.backgroundColor = nil;
    }
    
    [[MEGAPurchase sharedInstance] setPricingsDelegate:self];
    
    self.dateFormatter = NSDateFormatter.alloc.init;
    self.dateFormatter.dateStyle = NSDateFormatterShortStyle;
    self.dateFormatter.timeStyle = NSDateFormatterNoStyle;
    self.dateFormatter.locale = NSLocale.autoupdatingCurrentLocale;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    unsigned long long thumbsSize = [NSFileManager.defaultManager mnz_sizeOfFolderAtPath:[Helper pathForSharedSandboxCacheDirectory:@"thumbnailsV3"]];
    unsigned long long previewsSize = [NSFileManager.defaultManager mnz_sizeOfFolderAtPath:[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject stringByAppendingPathComponent:@"previewsV3"]];
    unsigned long long offlineSize = [NSFileManager.defaultManager mnz_sizeOfFolderAtPath:NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject];
    
    localSize = @(thumbsSize + previewsSize + offlineSize + [NSFileManager.defaultManager mnz_groupSharedDirectorySize]);
    
    NSString *stringFromByteCount = [Helper memoryStyleStringFromByteCount:localSize.unsignedLongLongValue];
    self.localUsedSpaceLabel.attributedText = [self textForSizeLabels:stringFromByteCount];
    
    [self setupWithAccountDetails];
    
    self.emailLabel.text = [[MEGASdkManager sharedMEGASdk] myEmail];
    
    if (self.presentedViewController == nil) {
        [[MEGASdkManager sharedMEGASdk] addMEGARequestDelegate:self];
    }
    
    self.upgradeAccountButton.enabled = [MEGAPurchase sharedInstance].products.count;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    if (self.presentedViewController == nil) {
        [[MEGASdkManager sharedMEGASdk] removeMEGARequestDelegate:self];
    }
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

#pragma mark - Private

- (NSMutableAttributedString *)textForSizeLabels:(NSString *)stringFromByteCount {
    NSArray *componentsSeparatedByStringArray = [stringFromByteCount componentsSeparatedByString:@" "];
    NSString *firstPartString = [[NSString mnz_stringWithoutUnitOfComponents:componentsSeparatedByStringArray] stringByAppendingString:@" "];
    NSMutableAttributedString *firstPartMutableAttributedString = [[NSMutableAttributedString alloc] initWithString:firstPartString];
    
    NSRange firstPartRange = [firstPartString rangeOfString:firstPartString];
    [firstPartMutableAttributedString addAttribute:NSFontAttributeName
                                             value:[UIFont mnz_SFUILightWithSize:18.0f]
                                             range:firstPartRange];
    
    if (componentsSeparatedByStringArray.count > 1) {
        NSString *secondPartString = [componentsSeparatedByStringArray objectAtIndex:1];
        NSRange secondPartRange = [secondPartString rangeOfString:secondPartString];
        NSMutableAttributedString *secondPartMutableAttributedString = [[NSMutableAttributedString alloc] initWithString:secondPartString];
        
        [secondPartMutableAttributedString addAttribute:NSFontAttributeName
                                                  value:[UIFont mnz_SFUILightWithSize:12.0f]
                                                  range:secondPartRange];
        
        [firstPartMutableAttributedString appendAttributedString:secondPartMutableAttributedString];
    }
    
    return firstPartMutableAttributedString;
}

- (void)setupWithAccountDetails {
    if ([[MEGASdkManager sharedMEGASdk] mnz_accountDetails]) {
        MEGAAccountDetails *accountDetails = [[MEGASdkManager sharedMEGASdk] mnz_accountDetails];
        
        self.megaAccountType = accountDetails.type;
        
        usedStorage = accountDetails.storageUsed;
        maxStorage = accountDetails.storageMax;
        
        NSString *usedStorageString = [Helper memoryStyleStringFromByteCount:usedStorage.longLongValue];
        long long availableStorage = maxStorage.longLongValue - usedStorage.longLongValue;
        NSString *availableStorageString = [Helper memoryStyleStringFromByteCount:((availableStorage < 0) ? 0 : availableStorage)];
        
        self.usedSpaceLabel.attributedText = [self textForSizeLabels:usedStorageString];
        self.availableSpaceLabel.attributedText = [self textForSizeLabels:availableStorageString];
        
        NSString *renewsExpiresString;
        if (accountDetails.type) {
            if (accountDetails.subscriptionRenewTime > 0) {
                NSDate *renewDate = [[NSDate alloc] initWithTimeIntervalSince1970:accountDetails.subscriptionRenewTime];
                renewsExpiresString = [NSString stringWithFormat:@"%@ %@", AMLocalizedString(@"Renews on", @"Label for the ‘Renews on’ text into the my account page, indicating the renewal date of a subscription - (String as short as possible)."), [self.dateFormatter stringFromDate:renewDate]];
            } else if (accountDetails.proExpiration > 0) {
                NSDate *expireDate = [[NSDate alloc] initWithTimeIntervalSince1970:accountDetails.proExpiration];
                renewsExpiresString = [NSString stringWithFormat:AMLocalizedString(@"expiresOn", @"Text that shows the expiry date of the account PRO level"), [self.dateFormatter stringFromDate:expireDate]];
            } else {                
                self.proExpiryDateLabel.hidden = YES;
                self.proExpiryDateLabelHeightLayoutConstraint.constant = 0;
            }
        }
        
        switch (accountDetails.type) {
            case MEGAAccountTypeFree: {
                self.proStatusLabel.text = AMLocalizedString(@"Free", @"Text relative to the MEGA account level. UPPER CASE");
                self.proStatusLabel.textColor = [UIColor mnz_green31B500];
                
                self.proExpiryDateLabelHeightLayoutConstraint.constant = 0;
                break;
            }
                
            case MEGAAccountTypeLite: {
                self.proStatusLabel.text = [NSString stringWithFormat:@"PRO LITE"];
                self.proStatusLabel.textColor = [UIColor mnz_orangeFFA500];
                self.proExpiryDateLabel.text = renewsExpiresString;
                break;
            }
                
            case MEGAAccountTypeProI: {
                self.proStatusLabel.text = [NSString stringWithFormat:@"PRO I"];
                self.proStatusLabel.textColor = UIColor.mnz_redProI;
                self.proExpiryDateLabel.text = renewsExpiresString;
                break;
            }
                
            case MEGAAccountTypeProII: {
                self.proStatusLabel.text = [NSString stringWithFormat:@"PRO II"];
                self.proStatusLabel.textColor = UIColor.mnz_redProII;
                self.proExpiryDateLabel.text = renewsExpiresString;
                break;
            }
                
            case MEGAAccountTypeProIII: {
                self.proStatusLabel.text = [NSString stringWithFormat:@"PRO III"];
                self.proStatusLabel.textColor = UIColor.mnz_redProIII;
                self.proExpiryDateLabel.text = renewsExpiresString;
                break;
            }
                
            default:
                break;
        }
    } else {
        MEGALogError(@"Account details unavailable");
    }
}

#pragma mark - IBActions

- (IBAction)editTouchUpInside:(UIBarButtonItem *)sender {
    [super presentEditProfileAlertController];
}

- (IBAction)buyPROTouchUpInside:(UIButton *)sender {
    if ([[MEGASdkManager sharedMEGASdk] mnz_accountDetails]) {
        UpgradeTableViewController *upgradeTVC = [[UIStoryboard storyboardWithName:@"MyAccount" bundle:nil] instantiateViewControllerWithIdentifier:@"UpgradeID"];
        upgradeTVC.hideSkipButton = YES;
        
        [self.navigationController pushViewController:upgradeTVC animated:YES];
    } else {
        [MEGAReachabilityManager isReachableHUDIfNot];
    }
}

- (IBAction)logoutTouchUpInside:(UIButton *)sender {
    if ([MEGAReachabilityManager isReachableHUDIfNot]) {
        MEGAShowPasswordReminderRequestDelegate *showPasswordReminderDelegate = [[MEGAShowPasswordReminderRequestDelegate alloc] initToLogout:YES];
        [[MEGASdkManager sharedMEGASdk] shouldShowPasswordReminderDialogAtLogout:YES delegate:showPasswordReminderDelegate];
    }
}

#pragma mark - MEGAPurchasePricingDelegate

- (void)pricingsReady {
    self.upgradeAccountButton.enabled = YES;
}

#pragma mark - MEGARequestDelegate

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    [super onRequestFinish:api request:request error:error];
    
    if ([error type]) {
        return;
    }
    
    switch ([request type]) {
        case MEGARequestTypeAccountDetails: {
            [self setupWithAccountDetails];
            break;
        }
            
        default:
            break;
    }
}

@end
