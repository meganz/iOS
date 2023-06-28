
#import "AdvancedTableViewController.h"

#import <Photos/Photos.h>


#import "Helper.h"
#import "MEGASdkManager.h"
#import "MEGA-Swift.h"
#import "NSString+MNZCategory.h"

@interface AdvancedTableViewController () <MEGARequestDelegate>

@property (weak, nonatomic) IBOutlet UILabel *savePhotosLabel;
@property (weak, nonatomic) IBOutlet UILabel *saveVideosLabel;

@property (weak, nonatomic) IBOutlet UISwitch *saveImagesSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *saveVideosSwitch;

@property (weak, nonatomic) IBOutlet UILabel *dontUseHttpLabel;
@property (weak, nonatomic) IBOutlet UISwitch *useHttpsOnlySwitch;

@property (weak, nonatomic) IBOutlet UILabel *saveMediaInGalleryLabel;
@property (weak, nonatomic) IBOutlet UISwitch *saveMediaInGallerySwitch;

@end

@implementation AdvancedTableViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.navigationItem setTitle:NSLocalizedString(@"advanced", nil)];
    
    [self checkAuthorizationStatus];
    
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

- (void)checkPhotosPermissionForUserDefaultSetting:(NSString *)userDefaultSetting settingSwitch:(UISwitch *)settingSwitch {
    DevicePermissionsHandlerObjC *handler = [[DevicePermissionsHandlerObjC alloc] init];
    [handler requstPhotoAlbumAccessPermissionsWithHandler:^(BOOL granted) {
        if (granted) {
            [settingSwitch setOn:!settingSwitch.isOn animated:YES];
        } else {
            [settingSwitch setOn:NO animated:YES];
            [handler alertPhotosPermission];
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
    return 3;
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
            titleHeader = NSLocalizedString(@"Camera", @"Header title of Camera section on MEGA Settings > Advanced screen.");
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

@end
