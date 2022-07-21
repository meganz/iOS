
#import "SettingsTableViewController.h"

#import "CameraUploadManager+Settings.h"
#import "MEGAReachabilityManager.h"
#import "MEGA-Swift.h"
#import "NSURL+MNZCategory.h"

typedef NS_ENUM(NSUInteger, LastSectionRow) {
    LastSectionRowAbout,
    LastSectionRowTermsAndPolicies,
    LastSectionRowCookieSettings
};

@interface SettingsTableViewController () <UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UILabel *cameraUploadsLabel;
@property (weak, nonatomic) IBOutlet UILabel *cameraUploadsDetailLabel;
@property (weak, nonatomic) IBOutlet UILabel *chatLabel;
@property (weak, nonatomic) IBOutlet UILabel *callsLabel;

@property (weak, nonatomic) IBOutlet UILabel *securityLabel;

@property (weak, nonatomic) IBOutlet UILabel *userInterfaceLabel;
@property (weak, nonatomic) IBOutlet UILabel *fileManagementLabel;
@property (weak, nonatomic) IBOutlet UILabel *advancedLabel;

@property (weak, nonatomic) IBOutlet UILabel *helpLabel;

@property (weak, nonatomic) IBOutlet UILabel *aboutLabel;
@property (weak, nonatomic) IBOutlet UILabel *termsAndPoliciesLabel;
@property (weak, nonatomic) IBOutlet UILabel *cookieSettingsLabel;

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

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    
    if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
        [self updateAppearance];
    }
}

#pragma mark - Private

- (void)setupUI {
    self.navigationItem.title = NSLocalizedString(@"settingsTitle", @"Title of the Settings section");
    
    self.cameraUploadsLabel.text = NSLocalizedString(@"cameraUploadsLabel", @"Title of one of the Settings sections where you can set up the 'Camera Uploads' options");
    self.cameraUploadsDetailLabel.text = CameraUploadManager.isCameraUploadEnabled ? NSLocalizedString(@"on", nil) : NSLocalizedString(@"off", nil);
    self.chatLabel.text = NSLocalizedString(@"chat", @"Chat section header");
    self.callsLabel.text = NSLocalizedString(@"settings.section.calls.title", @"Title of the Settings section where you can configure calls options of your MEGA account");

    self.securityLabel.text = NSLocalizedString(@"settings.section.security", @"Title of the Settings section where you can configure security details of your MEGA account");
    
    self.userInterfaceLabel.text = NSLocalizedString(@"settings.section.userInterface", @"Title of one of the Settings sections where you can customise the 'User Interface' of the app.");
    self.fileManagementLabel.text = NSLocalizedString(@"File Management", @"A section header which contains the file management settings. These settings allow users to remove duplicate files etc.");
    self.advancedLabel.text = NSLocalizedString(@"advanced", @"Title of one of the Settings sections where you can configure 'Advanced' options");
    
    self.helpLabel.text = NSLocalizedString(@"help", @"Menu item");
    
    self.aboutLabel.text = NSLocalizedString(@"about", @"Title of one of the Settings sections where you can see things 'About' the app");
    self.termsAndPoliciesLabel.text = NSLocalizedString(@"settings.section.termsAndPolicies", @"Title of one of the Settings sections where you can see the MEGA's 'Terms and Policies'");
    self.cookieSettingsLabel.text = NSLocalizedString(@"general.cookieSettings", @"Title of one of the Settings sections where you can see the MEGA's 'Cookie Settings'");
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
        case 0:
            switch (indexPath.row) {
                case 2:
                    [self presentCallsSettings];
                    break;
                    
                default: //Camera Uploads, Chat
                    break;
            }
        case 1: //Security Options
        case 2: //File management - User Interface - Advanced
        case 3: //Help
            break;
            
        case 4: { //About - Terms and Policies - Cookie Settings
            if ([MEGAReachabilityManager isReachableHUDIfNot]) {
                switch (indexPath.row) {
                    case LastSectionRowTermsAndPolicies:
                        [[TermsAndPoliciesRouter.alloc initWithNavigationController:self.navigationController] start];
                        break;
                    
                    case LastSectionRowCookieSettings:
                        [[CookieSettingsRouter.alloc initWithPresenter:self.navigationController] start];
                        break;
                        
                    default:
                        break;
                }
            }
        }
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
