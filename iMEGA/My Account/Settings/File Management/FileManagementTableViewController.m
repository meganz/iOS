#import "FileManagementTableViewController.h"

#import "SVProgressHUD.h"

#import "Helper.h"
#import "MEGAReachabilityManager.h"
#import "MEGASdk+MNZCategory.h"
#import "MEGAStore.h"
#import "MEGA-Swift.h"
#import "NSFileManager+MNZCategory.h"
#import "NSString+MNZCategory.h"

@import MEGAL10nObjc;
@import MEGASDKRepo;

typedef NS_ENUM(NSUInteger, FileManagementTableSection) {
    FileManagementTableSectionMobileData = 0,
    FileManagementTableSectionOnYourDevice,
    FileManagementTableSectionClearCache,
    FileManagementTableSectionOnMEGA,
    FileManagementTableSectionFileVersioning
};

@interface FileManagementTableViewController () <MEGAGlobalDelegate, MEGARequestDelegate>

@property (nonatomic, copy) NSString *offlineSizeString;
@property (nonatomic, copy) NSString *cacheSizeString;
@property (nonatomic) BOOL isOfflineSizeEmpty;
@property (nonatomic) BOOL isCacheSizeEmpty;

@property (nonatomic, getter=isFileVersioningEnabled) BOOL fileVersioningEnabled;

@end

@implementation FileManagementTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    NSString *title = LocalizedString(@"File Management", @"A section header which contains the file management settings. These settings allow users to remove duplicate files etc.");
    self.navigationItem.title = title;
    [self setMenuCapableBackButtonWithMenuTitle: title];

    _offlineSizeString = @"...";
    _cacheSizeString = @"...";

    [self updateAppearance];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    self.clearOfflineFilesLabel.text = LocalizedString(@"clearOfflineFiles", @"Section title where you can 'Clear Offline files' of your MEGA app");
    self.clearCacheLabel.text = LocalizedString(@"clearCache", @"Section title where you can 'Clear Cache' of your MEGA app");

    self.rubbishBinLabel.text = LocalizedString(@"rubbishBinLabel", @"Title of one of the Settings sections where you can see your MEGA 'Rubbish Bin'");

    self.fileVersioningLabel.text = LocalizedString(@"File versioning", @"Title of the option to enable or disable file versioning on Settings section");
    [MEGASdk.shared getFileVersionsOptionWithDelegate:self];

    self.useMobileDataLabel.text = LocalizedString(@"useMobileData", @"Title next to a switch button (On-Off) to allow using mobile data (Roaming) for a feature.");
    self.useMobileDataSwitch.on = [NSUserDefaults.standardUserDefaults boolForKey:MEGAUseMobileDataForPreviewingOriginalPhoto];

    [MEGASdk.shared addMEGAGlobalDelegate:self];

    [self reloadUI];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [MEGASdk.shared removeMEGAGlobalDelegate:self];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[TransfersWidgetViewController sharedTransferViewController].progressView showWidgetIfNeeded];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [TransfersWidgetViewController.sharedTransferViewController.progressView hideWidget];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];

    if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
        [self updateAppearance];
    }
}

#pragma mark - Private

- (void)updateAppearance {
    self.tableView.separatorColor = [UIColor mnz_separator];
    self.tableView.backgroundColor = [UIColor pageBackgroundColor];

    [self updateLabelAppearance];

    [self.tableView reloadData];
}

- (void)reloadUI {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        unsigned long long offlineSize = [NSFileManager.defaultManager mnz_sizeOfFolderAtPath:NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject];
        self.offlineSizeString = [NSString memoryStyleStringFromByteCount:offlineSize];
        self.offlineSizeString = [NSString mnz_formatStringFromByteCountFormatter:self.offlineSizeString];
        self.isOfflineSizeEmpty = [NSString mnz_isByteCountEmpty:self.offlineSizeString];

        unsigned long long cachesFolderSize = [NSFileManager.defaultManager mnz_sizeOfFolderAtPath:[Helper pathForSharedSandboxCacheDirectory:@""]];

        unsigned long long temporaryDirectory = [NSFileManager.defaultManager mnz_sizeOfFolderAtPath:NSTemporaryDirectory()];
        unsigned long long groupDirectory = [NSFileManager.defaultManager mnz_groupSharedDirectorySize];
        unsigned long long cacheSize = cachesFolderSize + temporaryDirectory + groupDirectory;

        self.cacheSizeString = [NSString memoryStyleStringFromByteCount:cacheSize];
        self.cacheSizeString = [NSString mnz_formatStringFromByteCountFormatter:self.cacheSizeString];
        self.isCacheSizeEmpty = [NSString mnz_isByteCountEmpty:self.cacheSizeString];

        dispatch_async(dispatch_get_main_queue(), ^(void){
            [self.tableView reloadData];
        });
    });
}

- (void)removeGroupSharedDirectoryContents {
    //Remove only the contents of some folders located inside of the group shared directory. The 'GroupSupport' directory contents are not deleted because is where the SDK databases are located.
    NSString *groupSharedDirectoryPath = [NSFileManager.defaultManager containerURLForSecurityApplicationGroupIdentifier:MEGAGroupIdentifier].path;
    [NSFileManager.defaultManager mnz_removeFolderContentsAtPath:[groupSharedDirectoryPath stringByAppendingPathComponent:MEGAExtensionLogsFolder]];
    [NSFileManager.defaultManager mnz_removeFolderContentsAtPath:[groupSharedDirectoryPath stringByAppendingPathComponent:MEGAFileExtensionStorageFolder]];
    [NSFileManager.defaultManager mnz_removeFolderContentsAtPath:[groupSharedDirectoryPath stringByAppendingPathComponent:MEGAShareExtensionStorageFolder]];
}

- (void)showClearAllOfflineFilesActionSheet:(UIView *)sender {
    UIAlertController *clearAllOfflineFilesAlertController = [UIAlertController alertControllerWithTitle:LocalizedString(@"settings.fileManagement.alert.clearAllOfflineFiles", @"Question shown after you tap on 'Settings' - 'File Management' - 'Clear Offline files' to confirm the action") message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [clearAllOfflineFilesAlertController addAction:[UIAlertAction actionWithTitle:LocalizedString(@"cancel", @"Button title to cancel something") style:UIAlertActionStyleCancel handler:nil]];

    UIAlertAction *clearAlertAction = [UIAlertAction actionWithTitle:LocalizedString(@"clear", @"Button title to clear something") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self clearOfflineFiles];
    }];
    [clearAllOfflineFilesAlertController addAction:clearAlertAction];

    clearAllOfflineFilesAlertController.popoverPresentationController.sourceRect = sender.frame;
    clearAllOfflineFilesAlertController.popoverPresentationController.sourceView = sender.superview;

    [self presentViewController:clearAllOfflineFilesAlertController animated:YES completion:nil];
}

- (void)clearOfflineFiles {
    NSString *offlinePathString = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeClear];
    [SVProgressHUD show];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        [NSFileManager.defaultManager mnz_removeFolderContentsAtPath:offlinePathString];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [SVProgressHUD dismiss];
            [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeNone];
            [[MEGAStore shareInstance] removeAllOfflineNodes];
            [QuickAccessWidgetManager reloadWidgetContentOfKindWithKind:MEGAOfflineQuickAccessWidget];
            [self reloadUI];
        });
    });
}

#pragma mark - IBAction

- (IBAction)useMobileDataSwitchChanged:(UISwitch *)sender {
    [NSUserDefaults.standardUserDefaults setBool:sender.on forKey:MEGAUseMobileDataForPreviewingOriginalPhoto];
}

#pragma mark - UITableViewDataSource

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString *titleHeader;
    switch (section) {
        case FileManagementTableSectionMobileData:
            titleHeader = LocalizedString(@"settings.fileManagement.useMobileData.header", @"Header of a Use Mobile Data setting to load preview of images in hight resolution");
            break;
        case FileManagementTableSectionOnYourDevice:
            titleHeader = LocalizedString(@"onYourDevice", @"Title header that refers to where do you do the actions 'Clear Offlines files' and 'Clear cache' inside 'Settings' -> 'Advanced' section");
            break;

        case FileManagementTableSectionOnMEGA:
            titleHeader = LocalizedString(@"onMEGA", @"Title header that refers to where do you do the action 'Empty Rubbish Bin' inside 'Settings' -> 'Advanced' section");
            break;
    }

    return titleHeader;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    NSString *titleFooter;
    switch (section) {
        case FileManagementTableSectionMobileData: {
            titleFooter = LocalizedString(@"settings.fileManagement.useMobileData.footer", @"Footer explaning how Use Mobile Data setting to load preview of images in hight resolution works");
            break;
        }
        case FileManagementTableSectionOnYourDevice: {
            NSString *currentlyUsingString = LocalizedString(@"currentlyUsing", @"Footer text that explain what amount of space you will free up if 'Clear Offline data', 'Clear cache' or 'Clear Rubbish Bin' is tapped");
            currentlyUsingString = [currentlyUsingString stringByReplacingOccurrencesOfString:@"%s" withString:self.offlineSizeString];
            titleFooter = currentlyUsingString;
            break;
        }

        case FileManagementTableSectionClearCache: {
            NSString *currentlyUsingString = LocalizedString(@"currentlyUsing", @"Footer text that explain what amount of space you will free up if 'Clear Offline data', 'Clear cache' or 'Clear Rubbish Bin' is tapped");
            currentlyUsingString = [currentlyUsingString stringByReplacingOccurrencesOfString:@"%s" withString:self.cacheSizeString];
            titleFooter = currentlyUsingString;
            break;
        }

        case FileManagementTableSectionOnMEGA: {
            NSNumber *rubbishBinSizeNumber = [MEGASdk.shared sizeForNode:[MEGASdk.shared rubbishNode]];
            NSString *stringFromByteCount = [NSString memoryStyleStringFromByteCount:rubbishBinSizeNumber.unsignedLongLongValue];
            stringFromByteCount = [NSString mnz_formatStringFromByteCountFormatter:stringFromByteCount];
            NSString *currentlyUsingString = LocalizedString(@"currentlyUsing", @"Footer text that explain what amount of space you will free up if 'Clear Offline data', 'Clear cache' or 'Clear Rubbish Bin' is tapped");
            currentlyUsingString = [currentlyUsingString stringByReplacingOccurrencesOfString:@"%s" withString:stringFromByteCount];
            titleFooter = currentlyUsingString;
            break;
        }
    }

    return titleFooter;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = [UIColor pageBackgroundColor];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case FileManagementTableSectionOnYourDevice: {
            if (_isOfflineSizeEmpty) {
                break;
            }

            [self showClearAllOfflineFilesActionSheet:[tableView cellForRowAtIndexPath:indexPath].contentView];
            break;
        }

        case FileManagementTableSectionClearCache: {
            if (_isCacheSizeEmpty) {
                break;
            }

            [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeClear];
            [SVProgressHUD show];
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
                [NSFileManager.defaultManager mnz_removeFolderContentsAtPath:NSTemporaryDirectory()];
                [NSFileManager.defaultManager mnz_removeFolderContentsAtPath:[Helper pathForSharedSandboxCacheDirectory:@""]];
                [self removeGroupSharedDirectoryContents];

                if (MEGASdk.shared.downloadTransfers.size == 0) {
                    [NSFileManager.defaultManager mnz_removeFolderContentsRecursivelyAtPath:[Helper pathForOffline] forItemsExtension:@"mega"];
                    [NSFileManager.defaultManager mnz_removeItemAtPath:[NSFileManager.defaultManager downloadsDirectory]];
                }
                if (MEGASdk.shared.uploadTransfers.size == 0) {
                    [NSFileManager.defaultManager mnz_removeItemAtPath:[NSFileManager.defaultManager uploadsDirectory]];
                }

                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [SVProgressHUD dismiss];
                    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeNone];
                    [self reloadUI];
                });
            });
            break;
        }

        case FileManagementTableSectionOnMEGA:
            break;
        case FileManagementTableSectionFileVersioning:
            [[FileVersioningViewRouter.alloc initWithNavigationController:self.navigationController] start];

        default:
            break;
    }

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - MEGAGlobalDelegate

- (void)onNodesUpdate:(MEGASdk *)api nodeList:(MEGANodeList *)nodeList {
    [self.tableView reloadData];
}

- (void)onUsersUpdate:(MEGASdk *)api userList:(MEGAUserList *)userList {
    NSInteger userListCount = userList.size;
    for (NSInteger i = 0 ; i < userListCount; i++) {
        MEGAUser *user = [userList userAtIndex:i];

        if (user.handle == MEGASdk.currentUserHandle.unsignedLongLongValue && [user hasChangedType:MEGAUserChangeTypeDisableVersions] && user.isOwnChange == 0) {
            [api getFileVersionsOptionWithDelegate:self];
        }
    }
}

#pragma mark - MEGARequestDelegate

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    if ((request.type == MEGARequestTypeGetAttrUser) && (request.paramType == MEGAUserAttributeDisableVersions)) {
        if (!error.type || error.type == MEGAErrorTypeApiENoent) {
            self.fileVersioningDetail.text = !request.flag ? LocalizedString(@"on", @"") : LocalizedString(@"off", @"");
        }
    }
}

@end
