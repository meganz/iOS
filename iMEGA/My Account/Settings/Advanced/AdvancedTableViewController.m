
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

@end
