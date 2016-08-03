/**
 * @file AdvancedTableViewController.h
 * @brief View controller that shows advanced options
 *
 * (c) 2013-2016 by Mega Limited, Auckland, New Zealand
 *
 * This file is part of the MEGA SDK - Client Access Engine.
 *
 * Applications using the MEGA API must present a valid application key
 * and comply with the the rules set forth in the Terms of Service.
 *
 * The MEGA SDK is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 *
 * @copyright Simplified (2-clause) BSD License.
 *
 * You should have received a copy of the license along with this
 * program.
 */

#import "AdvancedTableViewController.h"

#import "NSString+MNZCategory.h"
#import "MEGASdkManager.h"
#import "MEGAStore.h"
#import "Helper.h"

#import "SVProgressHUD.h"


@interface AdvancedTableViewController () <UIAlertViewDelegate, MEGAGlobalDelegate> {
    NSByteCountFormatter *byteCountFormatter;
}

@property (weak, nonatomic) IBOutlet UILabel *clearOfflineFilesLabel;
@property (weak, nonatomic) IBOutlet UILabel *clearCacheLabel;
@property (weak, nonatomic) IBOutlet UILabel *emptyRubbishBinLabel;
@property (weak, nonatomic) IBOutlet UILabel *savePhotosLabel;
@property (weak, nonatomic) IBOutlet UILabel *saveVideosLabel;

@property (weak, nonatomic) IBOutlet UISwitch *photosSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *videosSwitch;

@property (nonatomic, copy) NSString *offlineSizeString;
@property (nonatomic, copy) NSString *cacheSizeString;

@end

@implementation AdvancedTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.navigationItem setTitle:AMLocalizedString(@"advanced", nil)];
    
    byteCountFormatter = [[NSByteCountFormatter alloc] init];
    [byteCountFormatter setCountStyle:NSByteCountFormatterCountStyleMemory];
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"AdvancedCell"];
    
    self.offlineSizeString = [[NSString alloc] init];
    self.cacheSizeString = [[NSString alloc] init];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.clearOfflineFilesLabel setText:AMLocalizedString(@"clearOfflineFiles", @"Section title where you can 'Clear Offline files' of your MEGA app")];
    [self.clearCacheLabel setText:AMLocalizedString(@"clearCache", @"Section title where you can 'Clear Cache' of your MEGA app")];
    [self.emptyRubbishBinLabel setText:AMLocalizedString(@"emptyRubbishBin", @"Section title where you can 'Empty Rubbish Bin' of your MEGA account")];
    [self.savePhotosLabel setText:AMLocalizedString(@"saveImagesInGallery", @"Section title where you can enable the option 'Save images in gallery'")];
    [self.saveVideosLabel setText:AMLocalizedString(@"saveVideosInGallery", @"Section title where you can enable the option 'Save videos in gallery'")];
    
    BOOL isSavePhotoToGalleryEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:@"IsSavePhotoToGalleryEnabled"];
    [self.photosSwitch setOn:isSavePhotoToGalleryEnabled];
    
    BOOL isSaveVideoToGalleryEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:@"IsSaveVideoToGalleryEnabled"];
    [self.videosSwitch setOn:isSaveVideoToGalleryEnabled];
    
    [[MEGASdkManager sharedMEGASdk] addMEGAGlobalDelegate:self];
    
    [self reloadUI];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[MEGASdkManager sharedMEGASdk] removeMEGAGlobalDelegate:self];
}

- (void)reloadUI {
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        long long offlineSize = [Helper sizeOfFolderAtPath:[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0]];
        self.offlineSizeString = [byteCountFormatter stringFromByteCount:offlineSize];
        self.offlineSizeString = [self formatStringFromByteCountFormatter:self.offlineSizeString];
        
        long long thumbnailsSize = [Helper sizeOfFolderAtPath:[[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"thumbnailsV3"]];
        long long previewsSize = [Helper sizeOfFolderAtPath:[[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"previewsV3"]];
        long long cacheSize = thumbnailsSize + previewsSize;
        
        self.cacheSizeString = [byteCountFormatter stringFromByteCount:cacheSize];
        self.cacheSizeString = [self formatStringFromByteCountFormatter:self.cacheSizeString];
        
        dispatch_async(dispatch_get_main_queue(), ^(void){
            [self.tableView reloadData];
        });
    });
    
}

#pragma mark - Private Methods

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

#pragma mark - IBActions

- (IBAction)photosSwitchValueChanged:(UISwitch *)sender {
    [[NSUserDefaults standardUserDefaults] setBool:sender.on forKey:@"IsSavePhotoToGalleryEnabled"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (IBAction)videosSwitchValueChanged:(UISwitch *)sender {
    [[NSUserDefaults standardUserDefaults] setBool:sender.on forKey:@"IsSaveVideoToGalleryEnabled"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        [[MEGASdkManager sharedMEGASdk] cleanRubbishBin];
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 9.0) {
        return 3;
    } else {
        return 4;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger numberOfRows = 1;
    if (section == 3) {
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
            
        case 3: //Downloads
            titleHeader = AMLocalizedString(@"imageAndVideoDownloadsHeader", @"Title header that refers to where do you enable the options 'Save images in gallery' and 'Save videos in gallery' inside 'Settings' -> 'Advanced' section");
            break;
    }
    return titleHeader;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    NSString *titleFooter;
    switch (section) {
        case 0: { //Offline
            titleFooter = [NSString stringWithFormat:AMLocalizedString(@"currentlyUsing", @"Footer text that explain what amount of space you will free up if 'Clear Offline data', 'Clear cache' or 'Clear Rubbish Bin' is tapped"), [self.offlineSizeString UTF8String]];
            break;
        }
            
        case 1: { //Cache
            titleFooter = [NSString stringWithFormat:AMLocalizedString(@"currentlyUsing", @"Footer text that explain what amount of space you will free up if 'Clear Offline data', 'Clear cache' or 'Clear Rubbish Bin' is tapped"), [self.cacheSizeString UTF8String]];
            break;
        }
            
        case 2: { //Rubbish Bin
            NSNumber *rubbishBinSizeNumber = [[MEGASdkManager sharedMEGASdk] sizeForNode:[[MEGASdkManager sharedMEGASdk] rubbishNode]];
            NSString *stringFromByteCount = [byteCountFormatter stringFromByteCount:[rubbishBinSizeNumber longLongValue]];
            stringFromByteCount = [self formatStringFromByteCountFormatter:stringFromByteCount];
            const char *cString = [stringFromByteCount cStringUsingEncoding:NSUTF8StringEncoding];
            titleFooter = [NSString stringWithFormat:AMLocalizedString(@"currentlyUsing", @"Footer text that explain what amount of space you will free up if 'Clear Offline data', 'Clear cache' or 'Clear Rubbish Bin' is tapped"), cString];
            break;
        }
            
        case 3: { //Image and videos downloads
            titleFooter = AMLocalizedString(@"imageAndVideoDownloadsFooter", @"Footer text that explain what happen if the options 'Save videos in gallery’ and 'Save images in gallery’ are enabled");
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
            NSString *thumbnailsPathString = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"thumbnailsV3"];
            NSString *previewsPathString = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"previewsV3"];
            
            [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeClear];
            [SVProgressHUD show];
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
                [self deleteFolderContentsInPath:thumbnailsPathString];
                [self deleteFolderContentsInPath:previewsPathString];
                dispatch_async(dispatch_get_main_queue(), ^(void){
                    [SVProgressHUD dismiss];
                    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeNone];
                    [self reloadUI];
                });
            });
            
            break;
        }
            
        case 2: { //Rubbish Bin
            UIAlertView *emptyRubbishBinAlertView = [[UIAlertView alloc] initWithTitle:AMLocalizedString(@"emptyRubbishBinAlertTitle", nil)
                                                                          message:nil
                                                                         delegate:self
                                                                cancelButtonTitle:AMLocalizedString(@"cancel", nil)
                                                                otherButtonTitles:AMLocalizedString(@"ok", nil), nil];
            [emptyRubbishBinAlertView show];
            break;
        }
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - MEGAGlobalDelegate

- (void)onNodesUpdate:(MEGASdk *)api nodeList:(MEGANodeList *)nodeList {
    [self.tableView reloadData];
}

@end
