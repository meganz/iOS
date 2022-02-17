
#import "AdvancedTableViewController.h"

#import <Photos/Photos.h>

#import "DevicePermissionsHelper.h"
#import "Helper.h"
#import "MEGAMultiFactorAuthCheckRequestDelegate.h"
#import "MEGAReachabilityManager.h"
#import "MEGASdkManager.h"
#import "MEGA-Swift.h"
#import "NSString+MNZCategory.h"

#import "AwaitingEmailConfirmationView.h"
#import "TwoFactorAuthenticationViewController.h"

@interface AdvancedTableViewController () <MEGARequestDelegate>

@property (weak, nonatomic) IBOutlet UILabel *savePhotosLabel;
@property (weak, nonatomic) IBOutlet UILabel *saveVideosLabel;

@property (weak, nonatomic) IBOutlet UISwitch *saveImagesSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *saveVideosSwitch;

@property (weak, nonatomic) IBOutlet UILabel *cancelAccountLabel;

@property (weak, nonatomic) IBOutlet UILabel *dontUseHttpLabel;
@property (weak, nonatomic) IBOutlet UISwitch *useHttpsOnlySwitch;

@property (weak, nonatomic) IBOutlet UILabel *saveMediaInGalleryLabel;
@property (weak, nonatomic) IBOutlet UISwitch *saveMediaInGallerySwitch;

@property (getter=isTwoFactorAuthenticationEnabled) BOOL twoFactorAuthenticationEnabled;

@end

@implementation AdvancedTableViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.navigationItem setTitle:NSLocalizedString(@"advanced", nil)];
    
     self.cancelAccountLabel.text = NSLocalizedString(@"cancelYourAccount", @"In 'My account', when user want to delete/remove/cancel account will click button named 'Cancel your account'");
    
    [self checkAuthorizationStatus];
    
    MEGAMultiFactorAuthCheckRequestDelegate *delegate = [[MEGAMultiFactorAuthCheckRequestDelegate alloc] initWithCompletion:^(MEGARequest *request, MEGAError *error) {
        self.twoFactorAuthenticationEnabled = request.flag;
    }];
    [[MEGASdkManager sharedMEGASdk] multiFactorAuthCheckWithEmail:[[MEGASdkManager sharedMEGASdk] myEmail] delegate:delegate];
    
    [self updateAppearance];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.dontUseHttpLabel setText:NSLocalizedString(@"dontUseHttp", @"Text next to a switch that allows disabling the HTTP protocol for transfers")];
    self.savePhotosLabel.text = NSLocalizedString(@"Save Images in Photos", @"Settings section title where you can enable the option to 'Save Images in Photos'");
    self.saveVideosLabel.text = NSLocalizedString(@"Save Videos in Photos", @"Settings section title where you can enable the option to 'Save Videos in Photos'");
    self.saveMediaInGalleryLabel.text = NSLocalizedString(@"Save in Photos", @"Settings section title where you can enable the option to 'Save in Photos' the images or videos taken from your camera in the MEGA app");
    BOOL useHttpsOnly = [[NSUserDefaults.alloc initWithSuiteName:MEGAGroupIdentifier] boolForKey:@"useHttpsOnly"];
    [self.useHttpsOnlySwitch setOn:useHttpsOnly];
    
    BOOL isSavePhotoToGalleryEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:@"IsSavePhotoToGalleryEnabled"];
    [self.saveImagesSwitch setOn:isSavePhotoToGalleryEnabled];
    
    BOOL isSaveVideoToGalleryEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:@"IsSaveVideoToGalleryEnabled"];
    [self.saveVideosSwitch setOn:isSaveVideoToGalleryEnabled];
    
    BOOL isSaveMediaCapturedToGalleryEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:@"isSaveMediaCapturedToGalleryEnabled"];
    [self.saveMediaInGallerySwitch setOn:isSaveMediaCapturedToGalleryEnabled];
    
    [self.tableView reloadData];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    
    if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
        [self updateAppearance];
    }
}

#pragma mark - Private

- (void)updateAppearance {
    self.cancelAccountLabel.textColor = [UIColor mnz_redForTraitCollection:self.traitCollection];
    
    self.tableView.separatorColor = [UIColor mnz_separatorForTraitCollection:self.traitCollection];
    self.tableView.backgroundColor = [UIColor mnz_backgroundGroupedForTraitCollection:self.traitCollection];
    
    [self.tableView reloadData];
}

- (void)checkAuthorizationStatus {
    PHAuthorizationStatus phAuthorizationStatus = [PHPhotoLibrary authorizationStatus];
    switch (phAuthorizationStatus) {
        case PHAuthorizationStatusRestricted:
        case PHAuthorizationStatusDenied: {
            //If the app doesn't have access to Photos (Or the permission has been revoked), update the settings associated with Photos accordingly.
            [NSUserDefaults.standardUserDefaults setBool:NO forKey:@"IsSavePhotoToGalleryEnabled"];
            [NSUserDefaults.standardUserDefaults setBool:NO forKey:@"IsSaveVideoToGalleryEnabled"];
            if ([[NSUserDefaults standardUserDefaults] boolForKey:@"isSaveMediaCapturedToGalleryEnabled"]) {
                [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"isSaveMediaCapturedToGalleryEnabled"];
            }
            break;
        }
            
        case PHAuthorizationStatusAuthorized: {
            //If the app has 'Read and Write' access to Photos and the user didn't configure the setting to save the media captured from the MEGA app in Photos, enable it by default.
            if (![[NSUserDefaults standardUserDefaults] objectForKey:@"isSaveMediaCapturedToGalleryEnabled"]) {
                [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"isSaveMediaCapturedToGalleryEnabled"];
            }
            break;
        }
            
        default:
            break;
    }
}

- (void)processStarted {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"processStarted" object:nil];
    
    AwaitingEmailConfirmationView *awaitingEmailConfirmationView = [[[NSBundle mainBundle] loadNibNamed:@"AwaitingEmailConfirmationView" owner:self options: nil] firstObject];
    awaitingEmailConfirmationView.titleLabel.text = NSLocalizedString(@"awaitingEmailConfirmation", @"Title shown just after doing some action that requires confirming the action by an email");
    awaitingEmailConfirmationView.descriptionLabel.text = NSLocalizedString(@"ifYouCantAccessYourEmailAccount", @"Account closure, warning message to remind user to contact MEGA support after he confirms that he wants to cancel account.");
    awaitingEmailConfirmationView.frame = self.view.bounds;
    self.view = awaitingEmailConfirmationView;
}

- (void)checkPhotosPermissionForUserDefaultSetting:(NSString *)userDefaultSetting settingSwitch:(UISwitch *)settingSwitch {
    [DevicePermissionsHelper photosPermissionWithCompletionHandler:^(BOOL granted) {
        if (granted) {
            [settingSwitch setOn:!settingSwitch.isOn animated:YES];
        } else {
            [settingSwitch setOn:NO animated:YES];
            [DevicePermissionsHelper alertPhotosPermission];
        }
        
        [NSUserDefaults.standardUserDefaults setBool:settingSwitch.isOn forKey:userDefaultSetting];
    }];
}

#pragma mark - IBActions

- (IBAction)useHttpsOnlySwitch:(UISwitch *)sender {
    [[NSUserDefaults.alloc initWithSuiteName:MEGAGroupIdentifier] setBool:sender.on forKey:@"useHttpsOnly"];
    [[MEGASdkManager sharedMEGASdk] useHttpsOnly:sender.on];
}

- (IBAction)downloadOptionsSaveImagesSwitchTouchUpInside:(UIButton *)sender {
    [self checkPhotosPermissionForUserDefaultSetting:@"IsSavePhotoToGalleryEnabled" settingSwitch:self.saveImagesSwitch];
}

- (IBAction)downloadOptionsSaveVideosSwitchTouchUpInside:(UIButton *)sender {
    [self checkPhotosPermissionForUserDefaultSetting:@"IsSaveVideoToGalleryEnabled" settingSwitch:self.saveVideosSwitch];
}

- (IBAction)saveInLibrarySwitchTouchUpInside:(UIButton *)sender {
    [self checkPhotosPermissionForUserDefaultSetting:@"isSaveMediaCapturedToGalleryEnabled" settingSwitch:self.saveMediaInGallerySwitch];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (MEGASdkManager.sharedMEGASdk.isBusinessAccount && !MEGASdkManager.sharedMEGASdk.isMasterBusinessAccount) {
        return 3;
    }
    
    return 4;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString *titleHeader;
    switch (section) {
        case 0: //Transfers
            titleHeader = NSLocalizedString(@"transfers", @"Title of the Transfers section");
            break;
            
        case 1: //Downloads Options
            titleHeader = NSLocalizedString(@"Download options", @"Title of the dialog displayed the first time that a user want to download a image. Asks if wants to export image files to the photo album after download in future and informs that user can change this option afterwards - (String as short as possible).");
            break;
            
        case 2: //Camera
            titleHeader = NSLocalizedString(@"Camera", @"Setting associated with the 'Camera' of the device");
            break;
        
    }
    
    return titleHeader;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    NSString *titleFooter;
    switch (section) {
        case 0: { //Transfers
            titleFooter = NSLocalizedString(@"transfersSectionFooter", @"Footer text that explains when disabling the HTTP protocol for transfers may be useful");
            break;
        }
            
        case 1: { //Download options
            titleFooter = NSLocalizedString(@"Images and/or videos downloaded will be stored in the device’s media library instead of the Offline section.", @"Footer text shown under the settings for download options 'Save Images/Videos in Library'");
            break;
        }
            
        case 2: { //Camera
            titleFooter = NSLocalizedString(@"Save a copy of the images and videos taken from the MEGA app in your device’s media library.", @"Footer text shown under the Camera setting to explain the option 'Save in Photos'");
            break;
        }
    }
    
    return titleFooter;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = [UIColor mnz_secondaryBackgroundGrouped:self.traitCollection];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case 4: { //Cancel account
            if ([MEGAReachabilityManager isReachableHUDIfNot]) {
                UIAlertController *cancelAccountAlertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"youWillLooseAllData", @"Message that is shown when the user click on 'Cancel your account' to confirm that he's aware that his data will be deleted.") message:nil preferredStyle:UIAlertControllerStyleAlert];
                [cancelAccountAlertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"cancel", nil) style:UIAlertActionStyleCancel handler:nil]];
                [cancelAccountAlertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"ok", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    if (self.isTwoFactorAuthenticationEnabled) {
                        TwoFactorAuthenticationViewController *twoFactorAuthenticationVC = [[UIStoryboard storyboardWithName:@"TwoFactorAuthentication" bundle:nil] instantiateViewControllerWithIdentifier:@"TwoFactorAuthenticationViewControllerID"];
                        twoFactorAuthenticationVC.twoFAMode = TwoFactorAuthenticationCancelAccount;
                        
                        [self.navigationController pushViewController:twoFactorAuthenticationVC animated:YES];
                        
                        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(processStarted) name:@"processStarted" object:nil];
                    } else {
                        [[MEGASdkManager sharedMEGASdk] cancelAccountWithDelegate:self];
                    }
                }]];
                [self presentViewController:cancelAccountAlertController animated:YES completion:nil];
            }
            break;
        }
            
        default:
            break;
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - MEGARequestDelegate

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    if (error.type) {
        return;
    }
    
    switch (request.type) {
        case MEGARequestTypeGetCancelLink: {
            [self processStarted];
            break;
        }
            
        default:
            break;
    }
}

@end
