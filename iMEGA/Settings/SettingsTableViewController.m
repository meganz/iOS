
#import "SettingsTableViewController.h"

#import "LTHPasscodeViewController.h"

#import "CameraUploadManager+Settings.h"
#import "MEGAReachabilityManager.h"
#import "NSURL+MNZCategory.h"

@interface SettingsTableViewController () <UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) NSString *selectedLanguage;

@property (weak, nonatomic) IBOutlet UILabel *cameraUploadsLabel;
@property (weak, nonatomic) IBOutlet UILabel *cameraUploadsDetailLabel;
@property (weak, nonatomic) IBOutlet UILabel *chatLabel;

@property (weak, nonatomic) IBOutlet UILabel *passcodeLabel;
@property (weak, nonatomic) IBOutlet UILabel *passcodeDetailLabel;
@property (weak, nonatomic) IBOutlet UILabel *securityOptionsLabel;

@property (weak, nonatomic) IBOutlet UILabel *fileManagementLabel;
@property (weak, nonatomic) IBOutlet UILabel *appearanceLabel;
@property (weak, nonatomic) IBOutlet UILabel *advancedLabel;

@property (weak, nonatomic) IBOutlet UILabel *aboutLabel;
@property (weak, nonatomic) IBOutlet UILabel *languageLabel;

@property (weak, nonatomic) IBOutlet UILabel *helpLabel;

@property (weak, nonatomic) IBOutlet UILabel *privacyPolicyLabel;
@property (weak, nonatomic) IBOutlet UILabel *termsOfServiceLabel;
@property (weak, nonatomic) IBOutlet UILabel *dataProtectionRegulationLabel;

@end

@implementation SettingsTableViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSString *language = [[LocalizationSystem sharedLocalSystem] getLanguage];
    if (language) {
        self.selectedLanguage = language;
    } else {
        self.selectedLanguage = nil;
    }
    
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
    self.navigationItem.title = AMLocalizedString(@"settingsTitle", @"Title of the Settings section");
    
    self.cameraUploadsLabel.text = AMLocalizedString(@"cameraUploadsLabel", @"Title of one of the Settings sections where you can set up the 'Camera Uploads' options");
    self.cameraUploadsDetailLabel.text = CameraUploadManager.isCameraUploadEnabled ? AMLocalizedString(@"on", nil) : AMLocalizedString(@"off", nil);
    self.chatLabel.text = AMLocalizedString(@"chat", @"Chat section header");
    
    self.passcodeLabel.text = AMLocalizedString(@"passcode", nil);
    self.passcodeDetailLabel.text = ([LTHPasscodeViewController doesPasscodeExist] ? AMLocalizedString(@"on", nil) : AMLocalizedString(@"off", nil));
    self.securityOptionsLabel.text = AMLocalizedString(@"securityOptions", @"Title of the Settings section where you can configure security details of your MEGA account");
    
    self.fileManagementLabel.text = AMLocalizedString(@"File Management", @"A section header which contains the file management settings. These settings allow users to remove duplicate files etc.");
    self.appearanceLabel.text = AMLocalizedString(@"Appearance", @"Title of one of the Settings sections where you can customise the 'Appearance' of the app.");
    self.advancedLabel.text = AMLocalizedString(@"advanced", @"Title of one of the Settings sections where you can configure 'Advanced' options");
    
    self.aboutLabel.text = AMLocalizedString(@"about", @"Title of one of the Settings sections where you can see things 'About' the app");
    self.languageLabel.text = AMLocalizedString(@"language", @"Title of one of the Settings sections where you can set up the 'Language' of the app");
    
    self.helpLabel.text = AMLocalizedString(@"help", @"Menu item");
    
    self.privacyPolicyLabel.text = AMLocalizedString(@"privacyPolicyLabel", @"Title of one of the Settings sections where you can see the MEGA's 'Privacy Policy'");
    self.termsOfServiceLabel.text = AMLocalizedString(@"termsOfServicesLabel", @"Title of one of the Settings sections where you can see the MEGA's 'Terms of Service'");
    self.dataProtectionRegulationLabel.text = AMLocalizedString(@"dataProtectionRegulationLabel", @"Title of one of the Settings sections where you can see the MEGA's 'Data Protection Regulation'");
}

- (void)updateAppearance {
    self.cameraUploadsDetailLabel.textColor = self.passcodeDetailLabel.textColor = [UIColor mnz_secondaryGrayForTraitCollection:self.traitCollection];
    
    self.tableView.separatorColor = [UIColor mnz_separatorColorForTraitCollection:self.traitCollection];
    self.tableView.backgroundColor = [UIColor mnz_settingsBackgroundForTraitCollection:self.traitCollection];
    
    [self.tableView reloadData];
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = [UIColor mnz_secondaryBackgroundForTraitCollection:self.traitCollection];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case 0: //Camera Uploads, Chat
        case 1: //Pascode, Security Options
        case 2: //File management - Appearance - Advanced
        case 3: //About, Language
        case 4: //Help
            break;
            
        case 5: { //Privacy Policy, Terms of Service
            if ([MEGAReachabilityManager isReachableHUDIfNot]) {
                if (indexPath.row == 0) {
                    [[NSURL URLWithString:@"https://mega.nz/privacy"] mnz_presentSafariViewController];
                    break;
                } else if (indexPath.row == 1) {
                    [[NSURL URLWithString:@"https://mega.nz/terms"] mnz_presentSafariViewController];
                    break;
                } else if (indexPath.row == 2) {
                    [[NSURL URLWithString:@"https://mega.nz/gdpr"] mnz_presentSafariViewController];
                    break;
                }
            }
        }
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
