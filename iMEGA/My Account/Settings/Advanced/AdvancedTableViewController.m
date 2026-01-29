#import "AdvancedTableViewController.h"

#import <Photos/Photos.h>

#import "Helper.h"
#import "MEGA-Swift.h"
#import "NSString+MNZCategory.h"

#import "LocalizationHelper.h"

@interface AdvancedTableViewController () <MEGARequestDelegate>

@end

@implementation AdvancedTableViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

    [self.navigationItem setTitle:LocalizedString(@"advanced", @"")];

    [self checkAuthorizationStatus];

    [self setupColors];
    
    [self setupForLiquidGlass];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    self.savePhotosLabel.text = LocalizedString(@"Save Images in Photos", @"Settings section title where you can enable the option to 'Save Images in Photos'");
    self.saveVideosLabel.text = LocalizedString(@"Save Videos in Photos", @"Settings section title where you can enable the option to 'Save Videos in Photos'");
    self.saveMediaInGalleryLabel.text = LocalizedString(@"Save in Photos", @"Settings section title where you can enable the option to 'Save in Photos' the images or videos taken from your camera in the MEGA app");
    BOOL isSavePhotoToGalleryEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:AdvancedTableViewController.savePhotoToGalleryKey];
    [self.saveImagesSwitch setOn:isSavePhotoToGalleryEnabled];

    BOOL isSaveVideoToGalleryEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:AdvancedTableViewController.saveVideoToGalleryKey];
    [self.saveVideosSwitch setOn:isSaveVideoToGalleryEnabled];

    [self.saveMediaInGallerySwitch setOn:[self getIsSaveMediaCapturedToGalleryEnabled]];
    
    [self configureLabelAppearance];

    [self.tableView reloadData];
}

#pragma mark - Private

- (void)setupColors {
    self.tableView.separatorColor = [UIColor borderStrong];
    self.tableView.backgroundColor = [UIColor pageBackgroundColor];
}

- (void)checkAuthorizationStatus {
    PHAuthorizationStatus phAuthorizationStatus = [PHPhotoLibrary authorizationStatus];
    switch (phAuthorizationStatus) {
        case PHAuthorizationStatusRestricted:
        case PHAuthorizationStatusDenied: {
            //If the app doesn't have access to Photos (Or the permission has been revoked), update the settings associated with Photos accordingly.
            [NSUserDefaults.standardUserDefaults setBool:NO forKey:AdvancedTableViewController.savePhotoToGalleryKey];
            [NSUserDefaults.standardUserDefaults setBool:NO forKey:AdvancedTableViewController.saveVideoToGalleryKey];
            if ([self getIsSaveMediaCapturedToGalleryEnabled]) {
                [self setIsSaveMediaCapturedToGalleryEnabled:NO];
            }
            break;
        }

        case PHAuthorizationStatusAuthorized: {
            //If the app has 'Read and Write' access to Photos and the user didn't configure the setting to save the media captured from the MEGA app in Photos, enable it by default.
            if (![self hasSetIsSaveMediaCapturedToGalleryEnabled]) {
                [self setIsSaveMediaCapturedToGalleryEnabled:YES];
            }
            break;
        }

        default:
            break;
    }
}

- (void)checkPhotosPermissionForUserDefaultSetting:(NSString *)userDefaultSetting settingSwitch:(UISwitch *)settingSwitch {
    DevicePermissionsHandlerObjC *handler = [[DevicePermissionsHandlerObjC alloc] init];
    [handler requestPhotoAlbumAccessPermissionsWithHandler:^(BOOL granted) {
        if (granted) {
            [settingSwitch setOn:!settingSwitch.isOn animated:YES];
        } else {
            [settingSwitch setOn:NO animated:YES];
            [handler alertPhotosPermission];
        }

        [NSUserDefaults.standardUserDefaults setBool:settingSwitch.isOn forKey:userDefaultSetting];
    }];
}

- (void)checkPhotosPermissionForSettingSwitch:(UISwitch *)settingSwitch completion:(void (^)(void))completionHandler {
    DevicePermissionsHandlerObjC *handler = [[DevicePermissionsHandlerObjC alloc] init];
    [handler requestPhotoAlbumAccessPermissionsWithHandler:^(BOOL granted) {
        if (granted) {
            [settingSwitch setOn:!settingSwitch.isOn animated:YES];
        } else {
            [settingSwitch setOn:NO animated:YES];
            [handler alertPhotosPermission];
        }

        completionHandler();
    }];
}

- (void)tableView:(UITableView *)tableView willDisplayFooterView:(UIView *)view forSection:(NSInteger)section {
    if ([view isKindOfClass:[UITableViewHeaderFooterView class]]) {
        UITableViewHeaderFooterView *headerFooterView = (UITableViewHeaderFooterView *) view;
        headerFooterView.textLabel.textColor = [UIColor mnz_secondaryTextColor];
    }
}

#pragma mark - IBActions

- (IBAction)downloadOptionsSaveImagesSwitchTouchUpInside:(UIButton *)sender {
    [self checkPhotosPermissionForUserDefaultSetting:AdvancedTableViewController.savePhotoToGalleryKey settingSwitch:self.saveImagesSwitch];
}

- (IBAction)downloadOptionsSaveVideosSwitchTouchUpInside:(UIButton *)sender {
    [self checkPhotosPermissionForUserDefaultSetting:AdvancedTableViewController.saveVideoToGalleryKey settingSwitch:self.saveVideosSwitch];
}

- (IBAction)saveInLibrarySwitchTouchUpInside:(UIButton *)sender {
    [self checkPhotosPermissionForSettingSwitch:self.saveMediaInGallerySwitch completion:^{
        [self setIsSaveMediaCapturedToGalleryEnabled:self.saveMediaInGallerySwitch.isOn];
    }];
}

@end
