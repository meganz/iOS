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

#import "MEGASdkManager.h"
#import "MEGAStore.h"
#import "Helper.h"

#import "AdvancedTableViewController.h"

@interface AdvancedTableViewController () <UIAlertViewDelegate, MEGAGlobalDelegate> {
    NSByteCountFormatter *byteCountFormatter;
}

@end

@implementation AdvancedTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.navigationItem setTitle:AMLocalizedString(@"advanced", nil)];
    
    byteCountFormatter = [[NSByteCountFormatter alloc] init];
    [byteCountFormatter setCountStyle:NSByteCountFormatterCountStyleMemory];
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"AdvancedCell"];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[MEGASdkManager sharedMEGASdk] addMEGAGlobalDelegate:self];
    
    [self.tableView reloadData];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[MEGASdkManager sharedMEGASdk] removeMEGAGlobalDelegate:self];
}

#pragma mark - Private Methods

- (void)deleteFolderContentsInPath:(NSString *)folderPath {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *fileArray = [fileManager contentsOfDirectoryAtPath:folderPath error:nil];
    NSError *error = nil;
    for (NSString *filename in fileArray)  {
        if (![fileManager removeItemAtPath:[folderPath stringByAppendingPathComponent:filename] error:&error] ) {
            MEGALogError(@"Remove item at path: %@", error);
        }
    }
}

- (NSString *)formatStringFromByteCountFormatter:(NSString *)stringFromByteCount {
    NSArray *componentsArray = [stringFromByteCount componentsSeparatedByString:@" "];
    NSString *countString = [componentsArray objectAtIndex:0];
    if ([countString isEqualToString:@"Zero"] || ([countString length] == 0)) {
        countString = @"0";
    }
    return [NSString stringWithFormat:@"%@ %@", countString, [componentsArray objectAtIndex:1]];
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        [[MEGASdkManager sharedMEGASdk] cleanRubbishBin];
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger numberOfRows = 1;
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
    }
    return titleHeader;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    NSString *titleFooter;
    switch (section) {
        case 0: { //Offline
            long long offlineSize = [Helper sizeOfFolderAtPath:[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0]];
            NSString *stringFromByteCount = [byteCountFormatter stringFromByteCount:offlineSize];
            stringFromByteCount = [self formatStringFromByteCountFormatter:stringFromByteCount];
            const char *cString = [stringFromByteCount cStringUsingEncoding:NSUTF8StringEncoding];
            titleFooter = [NSString stringWithFormat:AMLocalizedString(@"currentlyUsing", @"Footer text that explain what amount of space you will free up if 'Clear Offline data', 'Clear cache' or 'Clear Rubbish Bin' is tapped"), cString];
            break;
        }
            
        case 1: { //Cache
            long long thumbnailsSize = [Helper sizeOfFolderAtPath:[[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"thumbnailsV3"]];
            long long previewsSize = [Helper sizeOfFolderAtPath:[[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"previewsV3"]];
            long long cacheSize = thumbnailsSize + previewsSize;
            NSString *stringFromByteCount = [byteCountFormatter stringFromByteCount:cacheSize];
            stringFromByteCount = [self formatStringFromByteCountFormatter:stringFromByteCount];
            const char *cString = [stringFromByteCount cStringUsingEncoding:NSUTF8StringEncoding];
            titleFooter = [NSString stringWithFormat:AMLocalizedString(@"currentlyUsing", @"Footer text that explain what amount of space you will free up if 'Clear Offline data', 'Clear cache' or 'Clear Rubbish Bin' is tapped"), cString];
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
    }
    return titleFooter;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"AdvancedCell" forIndexPath:indexPath];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"AdvancedCell"];
    }
    
    switch (indexPath.section) {
        case 0: { //Offline
            [cell.textLabel setText:AMLocalizedString(@"clearOfflineFiles", @"Section title where you can 'Clear Offline files' of your MEGA app")];
            break;
        }
            
        case 1: { //Cache
            [cell.textLabel setText:AMLocalizedString(@"clearCache", @"Section title where you can 'Clear Cache' of your MEGA app")];
            break;
        }
            
        case 2: { //Rubbish Bin
            [cell.textLabel setText:AMLocalizedString(@"emptyRubbishBin", @"Section title where you can 'Empty Rubbish Bin' of your MEGA account")];
            break;
        }
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case 0: { //Offline
            NSString *offlinePathString = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
            NSError *error = nil;
            if (![[NSFileManager defaultManager] removeItemAtPath:offlinePathString error:&error]) {
                MEGALogError(@"Remove item at path: %@", error);
            }
            [[MEGAStore shareInstance] removeAllOfflineNodes];
            [self.tableView reloadData];
            break;
        }
            
        case 1: { //Cache
            NSString *thumbnailsPathString = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"thumbnailsV3"];
            [self deleteFolderContentsInPath:thumbnailsPathString];
            
             NSString *previewsPathString = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"previewsV3"];
            [self deleteFolderContentsInPath:previewsPathString];
            
            [self.tableView reloadData];
            break;
        }
            
        case 2: { //Rubbish Bin
            UIAlertView *emptyRubbishBinAlertView = [[UIAlertView alloc] initWithTitle:AMLocalizedString(@"emptyRubbishBinAlertTitle", nil)
                                                                          message:nil
                                                                         delegate:self
                                                                cancelButtonTitle:AMLocalizedString(@"cancel", nil)
                                                                otherButtonTitles:AMLocalizedString(@"ok", nil), nil];
            [emptyRubbishBinAlertView setDelegate:self];
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
