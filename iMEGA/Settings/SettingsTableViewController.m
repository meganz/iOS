
#import "SettingsTableViewController.h"

#import "CameraUploadManager+Settings.h"
#import "MEGAReachabilityManager.h"
#import "MEGA-Swift.h"
#import "NSURL+MNZCategory.h"

typedef NS_ENUM(NSUInteger, RegulationSectionRows) {
    RegulationSectionPrivacyPolicy,
    RegulationSectionCookiePolicy,
    RegulationSectionCookieSettings,
    RegulationSectionTermsOfService,
    RegulationSectionDataProtectionRegulation,
};

@interface SettingsTableViewController () <UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UILabel *cameraUploadsLabel;
@property (weak, nonatomic) IBOutlet UILabel *cameraUploadsDetailLabel;
@property (weak, nonatomic) IBOutlet UILabel *chatLabel;

@property (weak, nonatomic) IBOutlet UILabel *securityOptionsLabel;

@property (weak, nonatomic) IBOutlet UILabel *fileManagementLabel;
@property (weak, nonatomic) IBOutlet UILabel *appearanceLabel;
@property (weak, nonatomic) IBOutlet UILabel *advancedLabel;

@property (weak, nonatomic) IBOutlet UILabel *aboutLabel;

@property (weak, nonatomic) IBOutlet UILabel *helpLabel;

@property (weak, nonatomic) IBOutlet UILabel *privacyPolicyLabel;
@property (weak, nonatomic) IBOutlet UILabel *cookiePolicyLabel;
@property (weak, nonatomic) IBOutlet UILabel *cookieSettingsLabel;
@property (weak, nonatomic) IBOutlet UILabel *termsOfServiceLabel;
@property (weak, nonatomic) IBOutlet UILabel *dataProtectionRegulationLabel;

@end

@implementation SettingsTableViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self updateAppearance];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self setupUI];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    
    if (@available(iOS 13.0, *)) {
        if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
            [self updateAppearance];
        }
    }
}

#pragma mark - Private

- (void)setupUI {
    self.navigationItem.title = NSLocalizedString(@"settingsTitle", @"Title of the Settings section");
    
    self.cameraUploadsLabel.text = NSLocalizedString(@"cameraUploadsLabel", @"Title of one of the Settings sections where you can set up the 'Camera Uploads' options");
    self.cameraUploadsDetailLabel.text = CameraUploadManager.isCameraUploadEnabled ? NSLocalizedString(@"on", nil) : NSLocalizedString(@"off", nil);
    self.chatLabel.text = NSLocalizedString(@"chat", @"Chat section header");
    
    self.securityOptionsLabel.text = NSLocalizedString(@"securityOptions", @"Title of the Settings section where you can configure security details of your MEGA account");
    
    self.fileManagementLabel.text = NSLocalizedString(@"File Management", @"A section header which contains the file management settings. These settings allow users to remove duplicate files etc.");
    self.appearanceLabel.text = NSLocalizedString(@"Appearance", @"Title of one of the Settings sections where you can customise the 'Appearance' of the app.");
    self.advancedLabel.text = NSLocalizedString(@"advanced", @"Title of one of the Settings sections where you can configure 'Advanced' options");
    
    self.aboutLabel.text = NSLocalizedString(@"about", @"Title of one of the Settings sections where you can see things 'About' the app");
    
    self.helpLabel.text = NSLocalizedString(@"help", @"Menu item");
    
    self.privacyPolicyLabel.text = NSLocalizedString(@"privacyPolicyLabel", @"Title of one of the Settings sections where you can see the MEGA's 'Privacy Policy'");
    self.cookiePolicyLabel.text = NSLocalizedString(@"Cookie Policy", @"Title of one of the Settings sections where you can see the MEGA's 'Cookie Policy'");
    self.cookieSettingsLabel.text = NSLocalizedString(@"Cookie Settings", @"Title of one of the Settings sections where you can see the MEGA's 'Cookie Settings'");
    self.termsOfServiceLabel.text = NSLocalizedString(@"termsOfServicesLabel", @"Title of one of the Settings sections where you can see the MEGA's 'Terms of Service'");
    self.dataProtectionRegulationLabel.text = NSLocalizedString(@"dataProtectionRegulationLabel", @"Title of one of the Settings sections where you can see the MEGA's 'Data Protection Regulation'");
}

- (void)updateAppearance {
    self.cameraUploadsDetailLabel.textColor = UIColor.mnz_secondaryLabel;
    
    self.tableView.separatorColor = [UIColor mnz_separatorForTraitCollection:self.traitCollection];
    self.tableView.backgroundColor = [UIColor mnz_backgroundGroupedForTraitCollection:self.traitCollection];
    
    [self.tableView reloadData];
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = [UIColor mnz_secondaryBackgroundGrouped:self.traitCollection];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case 0: //Camera Uploads, Chat
        case 1: //Pascode, Security Options
        case 2: //File management - Appearance - Advanced
        case 3: //About, Language
        case 4: //Help
            break;
            
        case 5: {
            if ([MEGAReachabilityManager isReachableHUDIfNot]) {
                switch (indexPath.row) {
                    case RegulationSectionPrivacyPolicy:
                        [[NSURL URLWithString:@"https://mega.nz/privacy"] mnz_presentSafariViewController];
                        break;
                        
                    case RegulationSectionCookiePolicy:
                        [[NSURL URLWithString:@"https://mega.nz/cookie"] mnz_presentSafariViewController];
                        break;
                        
                    case RegulationSectionCookieSettings:
                        [self.navigationController presentViewController:[CookieSettingsFactory.new createCookieSettingsNC] animated:YES completion:nil];
                        break;
                        
                    case RegulationSectionTermsOfService:
                        [[NSURL URLWithString:@"https://mega.nz/terms"] mnz_presentSafariViewController];
                        break;
                        
                    case RegulationSectionDataProtectionRegulation:
                        [[NSURL URLWithString:@"https://mega.nz/gdpr"] mnz_presentSafariViewController];
                        break;
                }
            }
        }
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
