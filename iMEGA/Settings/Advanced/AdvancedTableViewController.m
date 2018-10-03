
#import "AdvancedTableViewController.h"

#import <Photos/Photos.h>

#import "SVProgressHUD.h"

#import "DevicePermissionsHelper.h"
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

@interface AdvancedTableViewController () <MEGAGlobalDelegate, MEGARequestDelegate> {
    NSByteCountFormatter *byteCountFormatter;
}

@property (weak, nonatomic) IBOutlet UILabel *clearOfflineFilesLabel;
@property (weak, nonatomic) IBOutlet UILabel *clearCacheLabel;
@property (weak, nonatomic) IBOutlet UILabel *emptyRubbishBinLabel;

@property (weak, nonatomic) IBOutlet UILabel *savePhotosLabel;
@property (weak, nonatomic) IBOutlet UILabel *saveVideosLabel;

@property (weak, nonatomic) IBOutlet UISwitch *photosSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *videosSwitch;

@property (weak, nonatomic) IBOutlet UILabel *cancelAccountLabel;

@property (weak, nonatomic) IBOutlet UILabel *dontUseHttpLabel;
@property (weak, nonatomic) IBOutlet UISwitch *useHttpsOnlySwitch;

// Photos taken and videos recorded from within the app
@property (weak, nonatomic) IBOutlet UILabel *saveMediaInGalleryLabel;
@property (weak, nonatomic) IBOutlet UISwitch *saveMediaInGallerySwitch;

@property (nonatomic, copy) NSString *offlineSizeString;
@property (nonatomic, copy) NSString *cacheSizeString;

@property (getter=isTwoFactorAuthenticationEnabled) BOOL twoFactorAuthenticationEnabled;

@end

@implementation AdvancedTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.navigationItem setTitle:AMLocalizedString(@"advanced", nil)];
    
    byteCountFormatter = [[NSByteCountFormatter alloc] init];
    [byteCountFormatter setCountStyle:NSByteCountFormatterCountStyleMemory];
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"AdvancedCell"];
    
    self.cancelAccountLabel.text = AMLocalizedString(@"cancelYourAccount", @"In 'My account', when user want to delete/remove/cancel account will click button named 'Cancel your account'");
    
    _offlineSizeString = @"...";
    _cacheSizeString = @"...";
    
    [self checkAuthorizationStatus];
    
    MEGAMultiFactorAuthCheckRequestDelegate *delegate = [[MEGAMultiFactorAuthCheckRequestDelegate alloc] initWithCompletion:^(MEGARequest *request, MEGAError *error) {
        self.twoFactorAuthenticationEnabled = request.flag;
    }];
    [[MEGASdkManager sharedMEGASdk] multiFactorAuthCheckWithEmail:[[MEGASdkManager sharedMEGASdk] myEmail] delegate:delegate];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.clearOfflineFilesLabel setText:AMLocalizedString(@"clearOfflineFiles", @"Section title where you can 'Clear Offline files' of your MEGA app")];
    [self.clearCacheLabel setText:AMLocalizedString(@"clearCache", @"Section title where you can 'Clear Cache' of your MEGA app")];
    [self.emptyRubbishBinLabel setText:AMLocalizedString(@"emptyRubbishBin", @"Section title where you can 'Empty Rubbish Bin' of your MEGA account")];
    [self.dontUseHttpLabel setText:AMLocalizedString(@"dontUseHttp", @"Text next to a switch that allows disabling the HTTP protocol for transfers")];
    [self.savePhotosLabel setText:AMLocalizedString(@"saveImagesInGallery", @"Section title where you can enable the option 'Save images in gallery'")];
    [self.saveVideosLabel setText:AMLocalizedString(@"saveVideosInGallery", @"Section title where you can enable the option 'Save videos in gallery'")];
    [self.saveMediaInGalleryLabel setText:AMLocalizedString(@"saveMediaInGallery", @"Section title where you can enable the option 'Save media in gallery'")];
    
    BOOL useHttpsOnly = [[[NSUserDefaults alloc] initWithSuiteName:@"group.mega.ios"] boolForKey:@"useHttpsOnly"];
    [self.useHttpsOnlySwitch setOn:useHttpsOnly];
    
    BOOL isSavePhotoToGalleryEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:@"IsSavePhotoToGalleryEnabled"];
    [self.photosSwitch setOn:isSavePhotoToGalleryEnabled];
    
    BOOL isSaveVideoToGalleryEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:@"IsSaveVideoToGalleryEnabled"];
    [self.videosSwitch setOn:isSaveVideoToGalleryEnabled];
    
    BOOL isSaveMediaCapturedToGalleryEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:@"isSaveMediaCapturedToGalleryEnabled"];
    [self.saveMediaInGallerySwitch setOn:isSaveMediaCapturedToGalleryEnabled];
    
    [[MEGASdkManager sharedMEGASdk] addMEGAGlobalDelegate:self];
    
    [self reloadUI];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[MEGASdkManager sharedMEGASdk] removeMEGAGlobalDelegate:self];
}

- (void)reloadUI {
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        unsigned long long offlineSize = [Helper sizeOfFolderAtPath:[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0]];
        self.offlineSizeString = [byteCountFormatter stringFromByteCount:offlineSize];
        self.offlineSizeString = [self formatStringFromByteCountFormatter:self.offlineSizeString];
        
        unsigned long long thumbnailsSize = [Helper sizeOfFolderAtPath:[Helper pathForSharedSandboxCacheDirectory:@"thumbnailsV3"]];
        unsigned long long previewsSize = [Helper sizeOfFolderAtPath:[[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"previewsV3"]];
        unsigned long long temporaryDirectory = [Helper sizeOfFolderAtPath:NSTemporaryDirectory()];
        unsigned long long cacheSize = thumbnailsSize + previewsSize + temporaryDirectory;
        
        self.cacheSizeString = [byteCountFormatter stringFromByteCount:cacheSize];
        self.cacheSizeString = [self formatStringFromByteCountFormatter:self.cacheSizeString];
        
        dispatch_async(dispatch_get_main_queue(), ^(void){
            [self.tableView reloadData];
        });
    });
    
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

- (void)deleteFolderContentsInPath:(NSString *)folderPath {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *fileArray = [fileManager contentsOfDirectoryAtPath:folderPath error:nil];
    NSError *error = nil;
    for (NSString *filename in fileArray)  {
        if (![fileManager removeItemAtPath:[folderPath stringByAppendingPathComponent:filename] error:&error] ) {
            MEGALogError(@"Remove item at path failed with error: %@", error);
        }
    }
}

- (NSString *)formatStringFromByteCountFormatter:(NSString *)stringFromByteCount {
    NSArray *componentsSeparatedByStringArray = [stringFromByteCount componentsSeparatedByString:@" "];
    NSString *countString = [NSString mnz_stringWithoutUnitOfComponents:componentsSeparatedByStringArray];
    NSString *unitString = [NSString mnz_stringWithoutCountOfComponents:componentsSeparatedByStringArray];
    
    return [NSString stringWithFormat:@"%@ %@", countString, unitString];
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
    [DevicePermissionsHelper photosPermissionWithCompletionHandler:^(BOOL granted) {
        if (granted) {
            [[NSUserDefaults standardUserDefaults] setBool:sender.on forKey:@"isSaveMediaCapturedToGalleryEnabled"];
            [[NSUserDefaults standardUserDefaults] synchronize];
        } else {
            if (self.saveMediaInGallerySwitch.isOn) {
                [DevicePermissionsHelper warnAboutPhotosPermission];
                [self.saveMediaInGallerySwitch setOn:NO animated:YES];
            } else {
                [[NSUserDefaults standardUserDefaults] setBool:sender.on forKey:@"isSaveMediaCapturedToGalleryEnabled"];
                [[NSUserDefaults standardUserDefaults] synchronize];
            }
        }
    }];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 7;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger numberOfRows = 1;
    if (section == 4) {
        numberOfRows = 2;
    }
    return numberOfRows;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString *titleHeader;
    switch (section) {
        case 0: //On your device
            titleHeader = AMLocalizedString(@"onYourDevice", @"Title header that refers to where do you do the actions 'Clear Offlines files' and 'Clear cache' inside 'Settings' -> 'Advanced' section");
            break;
            
        case 2: //On MEGA
            titleHeader = AMLocalizedString(@"onMEGA", @"Title header that refers to where do you do the action 'Empty Rubbish Bin' inside 'Settings' -> 'Advanced' section");
            break;
            
        case 3: //TRANSFERS
            titleHeader = AMLocalizedString(@"transfers", @"Title of the Transfers section");
            break;
            
        case 4: //Downloads
            titleHeader = AMLocalizedString(@"imageAndVideoDownloadsHeader", @"Title header that refers to where do you enable the options 'Save images in gallery' and 'Save videos in gallery' inside 'Settings' -> 'Advanced' section");
            break;
            
        case 5: //Photos taken and video recorded from within the app
            titleHeader = AMLocalizedString(@"photosTakenAndVideoRecordedFromWithinTheAppHeader", @"Title header that refers to where do you enable the options 'Save media in gallery -> 'Advanced' section");
            break;
    }
    return titleHeader;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    NSString *titleFooter;
    switch (section) {
        case 0: { //Offline
            NSString *currentlyUsingString = AMLocalizedString(@"currentlyUsing", @"Footer text that explain what amount of space you will free up if 'Clear Offline data', 'Clear cache' or 'Clear Rubbish Bin' is tapped");
            currentlyUsingString = [currentlyUsingString stringByReplacingOccurrencesOfString:@"%s" withString:self.offlineSizeString];
            titleFooter = currentlyUsingString;
            break;
        }
            
        case 1: { //Cache
            NSString *currentlyUsingString = AMLocalizedString(@"currentlyUsing", @"Footer text that explain what amount of space you will free up if 'Clear Offline data', 'Clear cache' or 'Clear Rubbish Bin' is tapped");
            currentlyUsingString = [currentlyUsingString stringByReplacingOccurrencesOfString:@"%s" withString:self.cacheSizeString];
            titleFooter = currentlyUsingString;
            break;
        }
            
        case 2: { //Rubbish Bin
            NSNumber *rubbishBinSizeNumber = [[MEGASdkManager sharedMEGASdk] sizeForNode:[[MEGASdkManager sharedMEGASdk] rubbishNode]];
            NSString *stringFromByteCount = [byteCountFormatter stringFromByteCount:rubbishBinSizeNumber.unsignedLongLongValue];
            stringFromByteCount = [self formatStringFromByteCountFormatter:stringFromByteCount];
            NSString *currentlyUsingString = AMLocalizedString(@"currentlyUsing", @"Footer text that explain what amount of space you will free up if 'Clear Offline data', 'Clear cache' or 'Clear Rubbish Bin' is tapped");
            currentlyUsingString = [currentlyUsingString stringByReplacingOccurrencesOfString:@"%s" withString:stringFromByteCount];
            titleFooter = currentlyUsingString;
            break;
        }
            
        case 3: { //TRANSFERS
            titleFooter = AMLocalizedString(@"transfersSectionFooter", @"Footer text that explains when disabling the HTTP protocol for transfers may be useful");
            break;
        }
            
        case 4: { //Image and videos downloads
            titleFooter = AMLocalizedString(@"imageAndVideoDownloadsFooter", @"Footer text that explain what happen if the options 'Save videos in gallery’ and 'Save images in gallery’ are enabled");
            break;
        }
            
        case 5: { //Photos taken and video recorded from within the app
            titleFooter = AMLocalizedString(@"photosTakenAndVideoRecordedFromWithinTheAppFooter", @"Footer text that explain what happen if the options 'Save media in gallery’ is enabled");
            break;
        }
    }
    return titleFooter;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case 0: { //Offline
            NSString *offlinePathString = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
            [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeClear];
            [SVProgressHUD show];
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
                [self deleteFolderContentsInPath:offlinePathString];
                dispatch_async(dispatch_get_main_queue(), ^(void){
                    [SVProgressHUD dismiss];
                    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeNone];
                    [[MEGAStore shareInstance] removeAllOfflineNodes];
                    [self reloadUI];
                });
            });
            break;
        }
            
        case 1: { //Cache
            NSString *thumbnailsPathString = [Helper pathForSharedSandboxCacheDirectory:@"thumbnailsV3"];
            NSString *previewsPathString = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"previewsV3"];
            
            [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeClear];
            [SVProgressHUD show];
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
                [self deleteFolderContentsInPath:thumbnailsPathString];
                [self deleteFolderContentsInPath:previewsPathString];
                [self deleteFolderContentsInPath:NSTemporaryDirectory()];
                dispatch_async(dispatch_get_main_queue(), ^(void){
                    [SVProgressHUD dismiss];
                    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeNone];
                    [self reloadUI];
                });
            });
            
            break;
        }
            
        case 2: { //Rubbish Bin
            if ([MEGAReachabilityManager isReachableHUDIfNot]) {
                UIAlertController *emptyRubbishBinAlertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"emptyRubbishBinAlertTitle", nil) message:nil preferredStyle:UIAlertControllerStyleAlert];
                [emptyRubbishBinAlertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"cancel", nil) style:UIAlertActionStyleCancel handler:nil]];
                [emptyRubbishBinAlertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"ok", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    [[MEGASdkManager sharedMEGASdk] cleanRubbishBin];
                }]];
                [self presentViewController:emptyRubbishBinAlertController animated:YES completion:nil];
            }
            break;
        }
            
        case 6: { //Cancel account
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

#pragma mark - MEGAGlobalDelegate

- (void)onNodesUpdate:(MEGASdk *)api nodeList:(MEGANodeList *)nodeList {
    [self.tableView reloadData];
}

@end
