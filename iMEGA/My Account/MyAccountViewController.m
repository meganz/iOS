#import "MyAccountViewController.h"

#import "UIImage+GKContact.h"

#import "Helper.h"
#import "MEGANavigationController.h"
#import "MEGAPurchase.h"
#import "MEGASdk+MNZCategory.h"
#import "MEGAReachabilityManager.h"
#import "MEGASdkManager.h"
#import "NSString+MNZCategory.h"
#import "UpgradeTableViewController.h"

@interface MyAccountViewController () <MEGAPurchasePricingDelegate, MEGARequestDelegate> {
    BOOL isAccountDetailsAvailable;
    
    NSNumber *localSize;
    NSNumber *usedStorage;
    NSNumber *maxStorage;
    
    NSByteCountFormatter *byteCountFormatter;
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
    
    byteCountFormatter = [[NSByteCountFormatter alloc] init];
    [byteCountFormatter setCountStyle:NSByteCountFormatterCountStyleMemory];
    
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
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    long long thumbsSize = [Helper sizeOfFolderAtPath:[Helper pathForSharedSandboxCacheDirectory:@"thumbnailsV3"]];
    long long previewsSize = [Helper sizeOfFolderAtPath:[[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"previewsV3"]];
    long long offlineSize = [Helper sizeOfFolderAtPath:[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0]];
    
    localSize = [NSNumber numberWithLongLong:(thumbsSize + previewsSize + offlineSize)];
    
    NSString *stringFromByteCount = [byteCountFormatter stringFromByteCount:[localSize longLongValue]];
    self.localUsedSpaceLabel.attributedText = [self textForSizeLabels:stringFromByteCount];
    
    [self setupWithAccountDetails];
    
    self.emailLabel.text = [[MEGASdkManager sharedMEGASdk] myEmail];
    
    if (self.presentedViewController == nil) {
        [[MEGASdkManager sharedMEGASdk] addMEGARequestDelegate:self];
    }
    
    self.upgradeAccountButton.enabled = [MEGAPurchase sharedInstance].products.count;
}

- (void)viewWillDisappear:(BOOL)animated {
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
        
        NSString *usedStorageString = [byteCountFormatter stringFromByteCount:[usedStorage longLongValue]];
        long long availableStorage = maxStorage.longLongValue - usedStorage.longLongValue;
        NSString *availableStorageString = [byteCountFormatter stringFromByteCount:(availableStorage < 0) ? 0 : availableStorage];
        
        self.usedSpaceLabel.attributedText = [self textForSizeLabels:usedStorageString];
        self.availableSpaceLabel.attributedText = [self textForSizeLabels:availableStorageString];
        
        NSString *expiresString;
        if (accountDetails.type) {
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            dateFormatter.dateStyle = NSDateFormatterShortStyle;
            dateFormatter.timeStyle = NSDateFormatterNoStyle;
            NSString *currentLanguageID = [[LocalizationSystem sharedLocalSystem] getLanguage];
            dateFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:currentLanguageID];
            
            NSDate *expireDate = [[NSDate alloc] initWithTimeIntervalSince1970:accountDetails.proExpiration];
            expiresString = [NSString stringWithFormat:AMLocalizedString(@"expiresOn", @"Text that shows the expiry date of the account PRO level"), [dateFormatter stringFromDate:expireDate]];
        }
        
        switch (accountDetails.type) {
            case MEGAAccountTypeFree: {
                self.proStatusLabel.text = AMLocalizedString(@"free", @"Text relative to the MEGA account level. UPPER CASE");
                self.proStatusLabel.textColor = [UIColor mnz_green31B500];
                
                self.proExpiryDateLabelHeightLayoutConstraint.constant = 0;
                break;
            }
                
            case MEGAAccountTypeLite: {
                self.proStatusLabel.text = [NSString stringWithFormat:@"PRO LITE"];
                self.proStatusLabel.textColor = [UIColor mnz_orangeFFA500];
                self.proExpiryDateLabel.text = [NSString stringWithFormat:@"%@", expiresString];
                break;
            }
                
            case MEGAAccountTypeProI: {
                self.proStatusLabel.text = [NSString stringWithFormat:@"PRO I"];
                self.proStatusLabel.textColor = [UIColor mnz_redE13339];
                self.proExpiryDateLabel.text = [NSString stringWithFormat:@"%@", expiresString];
                break;
            }
                
            case MEGAAccountTypeProII: {
                self.proStatusLabel.text = [NSString stringWithFormat:@"PRO II"];
                self.proStatusLabel.textColor = [UIColor mnz_redDC191F];
                self.proExpiryDateLabel.text = [NSString stringWithFormat:@"%@", expiresString];
                break;
            }
                
            case MEGAAccountTypeProIII: {
                self.proStatusLabel.text = [NSString stringWithFormat:@"PRO III"];
                self.proStatusLabel.textColor = [UIColor mnz_redD90007];
                self.proExpiryDateLabel.text = [NSString stringWithFormat:@"%@", expiresString];
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
        MEGANavigationController *navigationController = [[MEGANavigationController alloc] initWithRootViewController:upgradeTVC];
        
        [self presentViewController:navigationController animated:YES completion:nil];
    } else {
        [MEGAReachabilityManager isReachableHUDIfNot];
    }
}

- (IBAction)logoutTouchUpInside:(UIButton *)sender {
    if ([MEGAReachabilityManager isReachableHUDIfNot]) {
        NSError *error;
        NSArray *directoryContent = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] error:&error];
        if (error) {
            MEGALogError(@"Contents of directory at path failed with error: %@", error);
        }
        
        BOOL isInboxDirectory = NO;
        for (NSString *directoryElement in directoryContent) {
            if ([directoryElement isEqualToString:@"Inbox"]) {
                NSString *inboxPath = [[Helper pathForOffline] stringByAppendingPathComponent:@"Inbox"];
                [[NSFileManager defaultManager] fileExistsAtPath:inboxPath isDirectory:&isInboxDirectory];
                break;
            }
        }
        
        if (directoryContent.count > 0) {
            if (directoryContent.count == 1 && isInboxDirectory) {
                [[MEGASdkManager sharedMEGASdk] logout];
                return;
            }
            
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"warning", nil) message:AMLocalizedString(@"allFilesSavedForOfflineWillBeDeletedFromYourDevice", @"Alert message shown when the user perform logout and has files in the Offline directory") preferredStyle:UIAlertControllerStyleAlert];
            [alertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"cancel", nil) style:UIAlertActionStyleCancel handler:nil]];
            [alertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"logoutLabel", @"Title of the button which logs out from your account.") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                [[MEGASdkManager sharedMEGASdk] logout];
            }]];
            [self presentViewController:alertController animated:YES completion:nil];
        } else {
            [[MEGASdkManager sharedMEGASdk] logout];
        }
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
