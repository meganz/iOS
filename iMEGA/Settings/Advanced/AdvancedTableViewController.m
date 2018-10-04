
#import "AdvancedTableViewController.h"

#import <Photos/Photos.h>

#import "SVProgressHUD.h"

#import "Helper.h"
#import "MEGAMultiFactorAuthCheckRequestDelegate.h"
#import "MEGAReachabilityManager.h"
#import "MEGASdkManager.h"
#import "MEGAStore.h"
#import "NSString+MNZCategory.h"

#import "AwaitingEmailConfirmationView.h"
#import "ChangePasswordViewController.h"
#import "TwoFactorAuthenticationViewController.h"
#import "TwoFactorAuthentication.h"

@interface AdvancedTableViewController () <MEGARequestDelegate>

@property (weak, nonatomic) IBOutlet UILabel *savePhotosLabel;
@property (weak, nonatomic) IBOutlet UILabel *saveVideosLabel;

@property (weak, nonatomic) IBOutlet UISwitch *photosSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *videosSwitch;

@property (weak, nonatomic) IBOutlet UILabel *cancelAccountLabel;

@property (weak, nonatomic) IBOutlet UILabel *dontUseHttpLabel;
@property (weak, nonatomic) IBOutlet UISwitch *useHttpsOnlySwitch;

@property (weak, nonatomic) IBOutlet UILabel *saveMediaInGalleryLabel;
@property (weak, nonatomic) IBOutlet UISwitch *saveMediaInGallerySwitch;

@property (getter=isTwoFactorAuthenticationEnabled) BOOL twoFactorAuthenticationEnabled;

@end

@implementation AdvancedTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.navigationItem setTitle:AMLocalizedString(@"advanced", nil)];
    
     self.cancelAccountLabel.text = AMLocalizedString(@"cancelYourAccount", @"In 'My account', when user want to delete/remove/cancel account will click button named 'Cancel your account'");
    
    [self checkAuthorizationStatus];
    
    MEGAMultiFactorAuthCheckRequestDelegate *delegate = [[MEGAMultiFactorAuthCheckRequestDelegate alloc] initWithCompletion:^(MEGARequest *request, MEGAError *error) {
        self.twoFactorAuthenticationEnabled = request.flag;
    }];
    [[MEGASdkManager sharedMEGASdk] multiFactorAuthCheckWithEmail:[[MEGASdkManager sharedMEGASdk] myEmail] delegate:delegate];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.dontUseHttpLabel setText:AMLocalizedString(@"dontUseHttp", @"Text next to a switch that allows disabling the HTTP protocol for transfers")];
    self.savePhotosLabel.text = AMLocalizedString(@"Save Images in Library", @"Settings section title where you can enable the option to 'Save Images in Library'");
    self.saveVideosLabel.text = AMLocalizedString(@"Save Videos in Library", @"Settings section title where you can enable the option to 'Save Videos in Library'");
    self.saveMediaInGalleryLabel.text = AMLocalizedString(@"Save in Library", @"Settings section title where you can enable the option to 'Save in Library' the images or videos taken from your camera in the MEGA app");
    
    BOOL useHttpsOnly = [[[NSUserDefaults alloc] initWithSuiteName:@"group.mega.ios"] boolForKey:@"useHttpsOnly"];
    [self.useHttpsOnlySwitch setOn:useHttpsOnly];
    
    BOOL isSavePhotoToGalleryEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:@"IsSavePhotoToGalleryEnabled"];
    [self.photosSwitch setOn:isSavePhotoToGalleryEnabled];
    
    BOOL isSaveVideoToGalleryEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:@"IsSaveVideoToGalleryEnabled"];
    [self.videosSwitch setOn:isSaveVideoToGalleryEnabled];
    
    BOOL isSaveMediaCapturedToGalleryEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:@"isSaveMediaCapturedToGalleryEnabled"];
    [self.saveMediaInGallerySwitch setOn:isSaveMediaCapturedToGalleryEnabled];
    
    [self.tableView reloadData];
}

#pragma mark - Private

- (void)checkAuthorizationStatus {
    PHAuthorizationStatus phAuthorizationStatus = [PHPhotoLibrary authorizationStatus];
    switch (phAuthorizationStatus) {
        case PHAuthorizationStatusRestricted:
        case PHAuthorizationStatusDenied: {
            if ([[NSUserDefaults standardUserDefaults] boolForKey:@"isSaveMediaCapturedToGalleryEnabled"]) {
                [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"isSaveMediaCapturedToGalleryEnabled"];
                [[NSUserDefaults standardUserDefaults] synchronize];
            }
            break;
        }
            
        case PHAuthorizationStatusAuthorized:
            if (![[NSUserDefaults standardUserDefaults] objectForKey:@"isSaveMediaCapturedToGalleryEnabled"]) {
                [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"isSaveMediaCapturedToGalleryEnabled"];
                [[NSUserDefaults standardUserDefaults] synchronize];
            }
            break;
            
        default:
            break;
    }
}

- (void)processStarted {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"processStarted" object:nil];
    
    AwaitingEmailConfirmationView *awaitingEmailConfirmationView = [[[NSBundle mainBundle] loadNibNamed:@"AwaitingEmailConfirmationView" owner:self options: nil] firstObject];
    awaitingEmailConfirmationView.titleLabel.text = AMLocalizedString(@"awaitingEmailConfirmation", @"Title shown just after doing some action that requires confirming the action by an email");
    awaitingEmailConfirmationView.descriptionLabel.text = AMLocalizedString(@"ifYouCantAccessYourEmailAccount", @"Account closure, warning message to remind user to contact MEGA support after he confirms that he wants to cancel account.");
    awaitingEmailConfirmationView.frame = self.view.bounds;
    self.view = awaitingEmailConfirmationView;
}

#pragma mark - IBActions

- (IBAction)useHttpsOnlySwitch:(UISwitch *)sender {
    [[[NSUserDefaults alloc] initWithSuiteName:@"group.mega.ios"] setBool:sender.on forKey:@"useHttpsOnly"];
    [[MEGASdkManager sharedMEGASdk] useHttpsOnly:sender.on];
}

- (IBAction)photosSwitchValueChanged:(UISwitch *)sender {
    [[NSUserDefaults standardUserDefaults] setBool:sender.on forKey:@"IsSavePhotoToGalleryEnabled"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (IBAction)videosSwitchValueChanged:(UISwitch *)sender {
    [[NSUserDefaults standardUserDefaults] setBool:sender.on forKey:@"IsSaveVideoToGalleryEnabled"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (IBAction)mediaInGallerySwitchChanged:(UISwitch *)sender {
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        switch (status) {
            case PHAuthorizationStatusNotDetermined:
                break;
            case PHAuthorizationStatusAuthorized: {
                [[NSUserDefaults standardUserDefaults] setBool:self.saveMediaInGallerySwitch.isOn forKey:@"isSaveMediaCapturedToGalleryEnabled"];
                [[NSUserDefaults standardUserDefaults] synchronize];
                break;
            }
            case PHAuthorizationStatusRestricted: {
                break;
            }
            case PHAuthorizationStatusDenied:{
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (self.saveMediaInGallerySwitch.isOn) {
                        UIAlertController *permissionsAlertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"attention", @"Alert title to attract attention") message:AMLocalizedString(@"photoLibraryPermissions", @"Alert message to explain that the MEGA app needs permission to access your device photos") preferredStyle:UIAlertControllerStyleAlert];
                        
                        [permissionsAlertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"cancel", @"Button title to cancel something") style:UIAlertActionStyleCancel handler:nil]];
                        
                        [permissionsAlertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"ok", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
                        }]];
                        
                        [self presentViewController:permissionsAlertController animated:YES completion:nil];
                        
                        [self.saveMediaInGallerySwitch setOn:NO animated:YES];
                    } else {
                        [[NSUserDefaults standardUserDefaults] setBool:sender.on forKey:@"isSaveMediaCapturedToGalleryEnabled"];
                        [[NSUserDefaults standardUserDefaults] synchronize];
                    }
                });
                break;
            }
            default:
                break;
        }
    }];
}

#pragma mark - UITableViewDataSource

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString *titleHeader;
    switch (section) {
        case 0: //Transfers
            titleHeader = AMLocalizedString(@"transfers", @"Title of the Transfers section");
            break;
            
        case 1: //Downloads Options
            titleHeader = AMLocalizedString(@"Download options", @"Title of the dialog displayed the first time that a user want to download a image. Asks if wants to export image files to the photo album after download in future and informs that user can change this option afterwards - (String as short as possible).");
            break;
            
        case 2: //Camera
            titleHeader = AMLocalizedString(@"Camera", @"Setting associated with the 'Camera' of the device");
            break;
    }
    
    return titleHeader;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    NSString *titleFooter;
    switch (section) {
        case 0: { //Transfers
            titleFooter = AMLocalizedString(@"transfersSectionFooter", @"Footer text that explains when disabling the HTTP protocol for transfers may be useful");
            break;
        }
            
        case 1: { //Download options
            titleFooter = AMLocalizedString(@"Images and/or videos downloaded will be stored in the device’s media library instead of the Offline section.", @"Footer text shown under the settings for download options 'Save Images/Videos in Library'");
            break;
        }
            
        case 2: { //Camera
            titleFooter = AMLocalizedString(@"Save a copy of the images and videos taken from the MEGA app in your device’s media library.", @"Footer text shown under the Camera setting to explain the option 'Save in Library'");
            break;
        }
    }
    
    return titleFooter;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case 3: { //Cancel account
            if ([MEGAReachabilityManager isReachableHUDIfNot]) {
                UIAlertController *cancelAccountAlertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"youWillLooseAllData", @"Message that is shown when the user click on 'Cancel your account' to confirm that he's aware that his data will be deleted.") message:nil preferredStyle:UIAlertControllerStyleAlert];
                [cancelAccountAlertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"cancel", nil) style:UIAlertActionStyleCancel handler:nil]];
                [cancelAccountAlertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"ok", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
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
