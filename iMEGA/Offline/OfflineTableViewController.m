/**
 * @file OfflineTableViewController.m
 * @brief View controller that show offline files
 *
 * (c) 2013-2015 by Mega Limited, Auckland, New Zealand
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

#import <MediaPlayer/MediaPlayer.h>
#import <QuickLook/QuickLook.h>
#import <MobileCoreServices/MobileCoreServices.h>

#import "SVProgressHUD.h"
#import "UIScrollView+EmptyDataSet.h"

#import "MEGASdkManager.h"
#import "MEGAQLPreviewControllerTransitionAnimator.h"
#import "Helper.h"
#import "MEGAReachabilityManager.h"
#import "OfflineTableViewController.h"
#import "OfflineTableViewCell.h"

#import "MEGAStore.h"

@interface OfflineTableViewController () <UIViewControllerTransitioningDelegate, QLPreviewControllerDelegate, QLPreviewControllerDataSource, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, MEGATransferDelegate> {
    NSString *previewDocumentPath;
}

@property (nonatomic, strong) NSMutableArray *offlineFilesAndFolders;
@property (nonatomic, strong) NSMutableArray *offlineFiles;

@property (nonatomic, strong) NSString *folderPathFromOffline;

@end

@implementation OfflineTableViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.emptyDataSetSource = self;
    self.tableView.emptyDataSetDelegate = self;
    
    if (self.folderPathFromOffline == nil) {
        [self.navigationItem setTitle:AMLocalizedString(@"offline", @"Offline")];
    } else {
        NSString *currentFolderName = [self.folderPathFromOffline lastPathComponent];
        [self.navigationItem setTitle:currentFolderName];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self.tableView selector:@selector(reloadEmptyDataSet) name:kReachabilityChangedNotification object:nil];
    
    [[MEGASdkManager sharedMEGASdk] addMEGATransferDelegate:self];
    [[MEGASdkManager sharedMEGASdk] retryPendingConnections];
    [[MEGASdkManager sharedMEGASdkFolder] addMEGATransferDelegate:self];
    [[MEGASdkManager sharedMEGASdkFolder] retryPendingConnections];
    [self reloadUI];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self.tableView name:kReachabilityChangedNotification object:nil];
    
    [[MEGASdkManager sharedMEGASdk] removeMEGATransferDelegate:self];
    [[MEGASdkManager sharedMEGASdkFolder] removeMEGATransferDelegate:self];
}

- (void)dealloc {
    self.tableView.emptyDataSetSource = nil;
    self.tableView.emptyDataSetDelegate = nil;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationPortrait;
}

#pragma mark - Private methods

- (void)reloadUI {
    
    self.offlineFilesAndFolders = [NSMutableArray new];
    self.offlineFiles = [NSMutableArray new];
    
    NSString *directoryPathString = [self currentOfflinePath];
    NSArray *directoryContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:directoryPathString error:NULL];
        
    int offsetIndex = 0;
    for (int i = 0; i < (int)[directoryContents count]; i++) {
        NSString *filePath = [directoryPathString stringByAppendingPathComponent:[directoryContents objectAtIndex:i]];
        NSString *fileName = [NSString stringWithFormat:@"%@", [directoryContents objectAtIndex:i]];
        
        // Inbox folder in documents folder is created by the system. Don't show it
        if ([[[Helper pathForOffline] stringByAppendingPathComponent:@"Inbox"] isEqualToString:filePath]) {
            continue;
        }
        
        if (![fileName.lowercaseString.pathExtension isEqualToString:@"mega"]) {
            
            NSMutableDictionary *tempDictionary = [NSMutableDictionary new];
            [tempDictionary setValue:fileName forKey:kMEGANode];
            [tempDictionary setValue:[NSNumber numberWithInt:offsetIndex] forKey:kIndex];
            [self.offlineFilesAndFolders addObject:tempDictionary];
            
            BOOL isDirectory;
            [[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:&isDirectory];
            if (!isDirectory) {
                offsetIndex++;
                [self.offlineFiles addObject:filePath];
            }
        }
    }
    
    [self.tableView reloadData];
}

- (NSString *)currentOfflinePath {
    NSString *pathString = [Helper pathForOffline];
    if (self.folderPathFromOffline != nil) {
        pathString = [pathString stringByAppendingPathComponent:self.folderPathFromOffline];
    }
    return pathString;
}

- (NSString *)folderPathFromOffline:(NSString *)absolutePath folder:(NSString *)folderName {
    
    NSArray *directoryPathComponents = [absolutePath pathComponents];
    NSUInteger directoryPathComponentsCount = directoryPathComponents.count;
    
    NSString *documentDirectory = [[Helper pathForOffline] lastPathComponent];
    NSUInteger documentsDirectoryPosition = 0;
    for (NSUInteger i = 0; i < directoryPathComponentsCount; i++) {
        NSString *folderString = [directoryPathComponents objectAtIndex:i];
        if ([folderString isEqualToString:documentDirectory]) {
            documentsDirectoryPosition = i;
            break;
        }
    }
    
    NSUInteger numberOfChildFolders = (directoryPathComponentsCount - (documentsDirectoryPosition + 1));
    NSIndexSet *indexSet = [[NSIndexSet alloc] initWithIndexesInRange:NSMakeRange((documentsDirectoryPosition + 1), numberOfChildFolders)];
    NSArray *childFoldersArray = [directoryPathComponents objectsAtIndexes:indexSet];
    
    NSString *pathFromOffline = @"";
    if (childFoldersArray.count > 1) {
        for (NSString *folderString in childFoldersArray) {
            pathFromOffline = [pathFromOffline stringByAppendingPathComponent:folderString];
        }
    } else {
        pathFromOffline = folderName;
    }
    
    return pathFromOffline;
}

- (unsigned long long)sizeOfFolderAtPath:(NSString *)path {
    unsigned long long folderSize = 0;
    
    NSArray *directoryContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:nil];
    
    for (NSString *item in directoryContents) {
        NSDictionary *attributesDictionary = [[NSFileManager defaultManager] attributesOfItemAtPath:[path stringByAppendingPathComponent:item] error:nil];
        if ([attributesDictionary objectForKey:NSFileType] == NSFileTypeDirectory) {
            folderSize += [self sizeOfFolderAtPath:[path stringByAppendingPathComponent:item]];
        } else {
            folderSize += [[attributesDictionary objectForKey:NSFileSize] unsignedLongLongValue];
        }
    }
    
    return folderSize;
}

- (NSArray *)offlinePathOnFolder:(NSString *)path {
    NSString *relativePath = [Helper pathRelativeToOfflineDirectory:path];
    NSMutableArray *offlinePathsOnFolder = [[NSMutableArray alloc] init];
    
    NSArray *directoryContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:nil];
    for (NSString *item in directoryContents) {
        NSDictionary *attributesDictionary = [[NSFileManager defaultManager] attributesOfItemAtPath:[path stringByAppendingPathComponent:item] error:nil];
        if ([attributesDictionary objectForKey:NSFileType] == NSFileTypeDirectory) {
            [offlinePathsOnFolder addObject:[relativePath stringByAppendingPathComponent:item]];
            [offlinePathsOnFolder addObjectsFromArray:[self offlinePathOnFolder:[path stringByAppendingPathComponent:item]]];
        } else {
            [offlinePathsOnFolder addObject:[relativePath stringByAppendingPathComponent:item]];
        }
    }
    
    return offlinePathsOnFolder;
}

- (void)cancelPendingTransfersOnFolder:(NSString *)folderPath folderLink:(BOOL)isFolderLink {
    MEGATransferList *transferList;
    NSInteger transferListSize;
    if (isFolderLink) {
        transferList = [[MEGASdkManager sharedMEGASdkFolder] transfers];
        transferListSize = [transferList.size integerValue];
    } else {
        transferList = [[MEGASdkManager sharedMEGASdk] transfers];
        transferListSize = [transferList.size integerValue];
    }
    
    for (NSInteger i = 0; i < transferListSize; i++) {
        MEGATransfer *transfer = [transferList transferAtIndex:i];
        if (transfer.type == MEGATransferTypeUpload) {
            continue;
        }
        
        if ([transfer.parentPath isEqualToString:[folderPath stringByAppendingString:@"/"]]) {
             if (isFolderLink) {
                 [[MEGASdkManager sharedMEGASdkFolder] cancelTransferByTag:transfer.tag];
             } else {
                 [[MEGASdkManager sharedMEGASdk] cancelTransferByTag:transfer.tag];
             }
        } else {
            NSString *lastPathComponent = [folderPath lastPathComponent];
            NSArray *pathComponentsArray = [transfer.parentPath pathComponents];
            NSUInteger pathComponentsArrayCount = [pathComponentsArray count];
            for (NSUInteger j = 0; j < pathComponentsArrayCount; j++) {
                NSString *folderString = [pathComponentsArray objectAtIndex:j];
                if ([folderString isEqualToString:lastPathComponent]) {
                    if (isFolderLink) {
                        [[MEGASdkManager sharedMEGASdkFolder] cancelTransferByTag:transfer.tag];
                    } else {
                        [[MEGASdkManager sharedMEGASdk] cancelTransferByTag:transfer.tag];
                    }
                    break;
                }
            }
        }
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.offlineFilesAndFolders.count == 0) {
        [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    } else {
        [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleSingleLine];
    }
    return self.offlineFilesAndFolders.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    OfflineTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"offlineTableViewCell" forIndexPath:indexPath];
    
    UIView *view = [[UIView alloc] init];
    [view setBackgroundColor:megaInfoGray];
    [cell setSelectedBackgroundView:view];
    [cell setSeparatorInset:UIEdgeInsetsMake(0.0, 60.0, 0.0, 0.0)];
    
    NSString *directoryPathString = [self currentOfflinePath];
    NSString *nameString = [[self.offlineFilesAndFolders objectAtIndex:indexPath.row] objectForKey:kMEGANode];
    NSString *pathForItem = [directoryPathString stringByAppendingPathComponent:nameString];
    
    NSDictionary *filePropertiesDictionary = [[NSFileManager defaultManager] attributesOfItemAtPath:pathForItem error:nil];
    
    struct tm *timeinfo;
    char buffer[80];
    time_t rawtime = [[filePropertiesDictionary valueForKey:NSFileModificationDate] timeIntervalSince1970];
    timeinfo = localtime(&rawtime);
    strftime(buffer, 80, "%d/%m/%y %H:%M", timeinfo);
    NSString *date = [NSString stringWithCString:buffer encoding:NSUTF8StringEncoding];
    
    unsigned long long size;
    
    [cell setItemNameString:nameString];
    
    MOOfflineNode *offNode = [[MEGAStore shareInstance] fetchOfflineNodeWithPath:[Helper pathRelativeToOfflineDirectory:pathForItem]];
    NSString *handleString = [offNode base64Handle];
    
    BOOL isDirectory;
    [[NSFileManager defaultManager] fileExistsAtPath:pathForItem isDirectory:&isDirectory];
    if (isDirectory) {
        [cell.thumbnailImageView setImage:[Helper folderImage]];
        
        size = [Helper sizeOfFolderAtPath:pathForItem];
    } else {
        NSString *extension = [[nameString pathExtension] lowercaseString];
        NSString *fileTypeIconString = [Helper fileTypeIconForExtension:extension];
        
        if (!handleString) {
            NSString *fpLocal = [[MEGASdkManager sharedMEGASdk] fingerprintForFilePath:pathForItem];
            if (fpLocal) {
                MEGANode *node = [[MEGASdkManager sharedMEGASdk] nodeForFingerprint:fpLocal];
                if (node) {
                    handleString = [node base64Handle];
                    [[MEGAStore shareInstance] insertOfflineNode:node api:[MEGASdkManager sharedMEGASdk] path:[[Helper pathRelativeToOfflineDirectory:pathForItem] decomposedStringWithCanonicalMapping]];
                }
            }
        }
        
        CFStringRef fileUTI = [Helper fileUTI:[nameString pathExtension]];
        if (UTTypeConformsTo(fileUTI, kUTTypeImage)) {
            [cell.thumbnailImageView.layer setCornerRadius:4];
            [cell.thumbnailImageView.layer setMasksToBounds:YES];
            
            NSString *thumbnailFilePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
            thumbnailFilePath = [thumbnailFilePath stringByAppendingPathComponent:@"thumbnailsV3"];
            thumbnailFilePath = [thumbnailFilePath stringByAppendingPathComponent:handleString];
            
            if (![[NSFileManager defaultManager] fileExistsAtPath:thumbnailFilePath]) {
                [[MEGASdkManager sharedMEGASdk] createThumbnail:pathForItem destinatioPath:thumbnailFilePath];
            }
            
            UIImage *thumbnailImage = [UIImage imageWithContentsOfFile:thumbnailFilePath];
            if (thumbnailImage == nil) {
                thumbnailImage = [Helper defaultPhotoImage];
            }
            [cell.thumbnailImageView setImage:thumbnailImage];
        } else {
            UIImage *iconImage = [UIImage imageNamed:fileTypeIconString];
            [cell.thumbnailImageView setImage:iconImage];
        }
        if (fileUTI) {
            CFRelease(fileUTI);
        }
        
        size = [[[NSFileManager defaultManager] attributesOfItemAtPath:pathForItem error:nil] fileSize];
    }
    [cell.nameLabel setText:[[MEGASdkManager sharedMEGASdk] unescapeFsIncompatible:nameString]];
    
    NSString *sizeString = [NSByteCountFormatter stringFromByteCount:size countStyle:NSByteCountFormatterCountStyleMemory];
    NSString *sizeAndDate = [NSString stringWithFormat:@"%@ • %@", sizeString, date];
    [cell.infoLabel setText:sizeAndDate];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle==UITableViewCellEditingStyleDelete) {
        OfflineTableViewCell *cell = (OfflineTableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
        NSString *itemPath = [[self currentOfflinePath] stringByAppendingPathComponent:[cell itemNameString]];
        NSArray *offlinePathsOnFolderArray;
        MOOfflineNode *offlineNode;
        
        BOOL isDirectory;
        [[NSFileManager defaultManager] fileExistsAtPath:itemPath isDirectory:&isDirectory];
        if (isDirectory) {
            if ([[[[MEGASdkManager sharedMEGASdk] transfers] size] integerValue] != 0) {
                [self cancelPendingTransfersOnFolder:itemPath folderLink:NO];
            }
            if ([[[[MEGASdkManager sharedMEGASdkFolder] transfers] size] integerValue] != 0) {
                [self cancelPendingTransfersOnFolder:itemPath folderLink:YES];
            }
            offlinePathsOnFolderArray = [self offlinePathOnFolder:itemPath];
        }
        
        NSError *error = nil;
        BOOL success = [ [NSFileManager defaultManager] removeItemAtPath:itemPath error:&error];
        offlineNode = [[MEGAStore shareInstance] fetchOfflineNodeWithPath:[Helper pathRelativeToOfflineDirectory:itemPath]];
        if (!success || error) {
            [SVProgressHUD showErrorWithStatus:@""];
            return;
        } else {
            if (isDirectory) {
                for (NSString *localPathAux in offlinePathsOnFolderArray) {
                    offlineNode = [[MEGAStore shareInstance] fetchOfflineNodeWithPath:localPathAux];
                    if (offlineNode) {
                        [[MEGAStore shareInstance] removeOfflineNode:offlineNode];
                    }
                }
            } else {
                if (offlineNode) {
                    [[MEGAStore shareInstance] removeOfflineNode:offlineNode];
                }
            }
            [self reloadUI];
        }
    }
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    OfflineTableViewCell *cell = (OfflineTableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
    NSString *itemNameString = [cell itemNameString];
    previewDocumentPath = [[self currentOfflinePath] stringByAppendingPathComponent:itemNameString];
    
    BOOL isDirectory;
    [[NSFileManager defaultManager] fileExistsAtPath:previewDocumentPath isDirectory:&isDirectory];
    if (isDirectory) {
        NSString *folderPathFromOffline = [self folderPathFromOffline:previewDocumentPath folder:[cell itemNameString]];
        
        OfflineTableViewController *offlineTVC = [self.storyboard instantiateViewControllerWithIdentifier:@"OfflineTableViewControllerID"];
        [offlineTVC setFolderPathFromOffline:folderPathFromOffline];
        [self.navigationController pushViewController:offlineTVC animated:YES];
    } else {
        QLPreviewController *previewController = [[QLPreviewController alloc]init];
        previewController.delegate = self;
        previewController.dataSource = self;
        
        NSInteger selectedIndexFile = [[[self.offlineFilesAndFolders objectAtIndex:indexPath.row] objectForKey:kIndex] integerValue];
        
        [previewController setCurrentPreviewItemIndex:selectedIndexFile];
        [previewController setTransitioningDelegate:self];
        [self presentViewController:previewController animated:YES completion:nil];
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleDelete;
}

#pragma mark - UIViewControllerTransitioningDelegate

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source {
    
    if ([presented isKindOfClass:[QLPreviewController class]]) {
        return [[MEGAQLPreviewControllerTransitionAnimator alloc] init];
    }
    
    return nil;
}

#pragma mark - DZNEmptyDataSetSource

- (NSAttributedString *)titleForEmptyDataSet:(UIScrollView *)scrollView {
    
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    
    NSString *text;
    if ([MEGAReachabilityManager isReachable]) {
        if (self.folderPathFromOffline == nil) {
            text = AMLocalizedString(@"offlineEmptyState_title", @"No files saved for Offline");
        } else {
            text = AMLocalizedString(@"emptyFolder", @"Title shown when a folder doesn't have any files");
        }
    } else {
        text = AMLocalizedString(@"noInternetConnection",  @"No Internet Connection");
    }
    
    NSDictionary *attributes = @{NSFontAttributeName:[UIFont fontWithName:kFont size:18.0], NSForegroundColorAttributeName:megaBlack};
    
    return [[NSAttributedString alloc] initWithString:text attributes:attributes];
}

- (NSAttributedString *)descriptionForEmptyDataSet:(UIScrollView *)scrollView {
    
    NSString *text;
    if ([MEGAReachabilityManager isReachable]) {
        if (self.folderPathFromOffline == nil) {
            text = AMLocalizedString(@"offlineEmptyState_text",  @"You can download files to this section to be able to use them when you don't have internet connection.");
        } else {
            text = AMLocalizedString(@"emptyFolder", nil);
        }
    } else {
        text = @"";
    }
    
    NSMutableParagraphStyle *paragraph = [NSMutableParagraphStyle new];
    paragraph.lineBreakMode = NSLineBreakByWordWrapping;
    paragraph.alignment = NSTextAlignmentCenter;
    
    NSDictionary *attributes = @{NSFontAttributeName:[UIFont fontWithName:kFont size:14.0],
                                 NSForegroundColorAttributeName:megaGray,
                                 NSParagraphStyleAttributeName:paragraph};
    
    return [[NSAttributedString alloc] initWithString:text attributes:attributes];
}

- (UIImage *)imageForEmptyDataSet:(UIScrollView *)scrollView {
    UIImage *image;
    if ([MEGAReachabilityManager isReachable]) {
        if (self.folderPathFromOffline == nil) {
            image = [UIImage imageNamed:@"emptyOffline"];
        } else {
            image = [UIImage imageNamed:@"emptyFolder"];
        }
    } else {
        image = [UIImage imageNamed:@"noInternetConnection"];
    }
    return image;
}

- (UIColor *)backgroundColorForEmptyDataSet:(UIScrollView *)scrollView {
    return [UIColor whiteColor];
}

#pragma mark - QLPreviewControllerDataSource

- (NSInteger)numberOfPreviewItemsInPreviewController:(QLPreviewController *)controller {
    return self.offlineFiles.count;
}

- (id <QLPreviewItem>)previewController:(QLPreviewController *)controller previewItemAtIndex:(NSInteger)index {
    previewDocumentPath = [self.offlineFiles objectAtIndex:index];
    return [NSURL fileURLWithPath:previewDocumentPath];
}

#pragma mark - QLPreviewControllerDelegate

- (BOOL)previewController:(QLPreviewController *)controller shouldOpenURL:(NSURL *)url forPreviewItem:(id <QLPreviewItem>)item {
    return YES;
}

#pragma mark - MEGATransferDelegate

- (void)onTransferStart:(MEGASdk *)api transfer:(MEGATransfer *)transfer {
}

- (void)onTransferUpdate:(MEGASdk *)api transfer:(MEGATransfer *)transfer {
}

- (void)onTransferFinish:(MEGASdk *)api transfer:(MEGATransfer *)transfer error:(MEGAError *)error {
    if ([error type]) {
        return;
    }
    
    if ([transfer type] == MEGATransferTypeDownload) {
        [self reloadUI];
    }
}

-(void)onTransferTemporaryError:(MEGASdk *)api transfer:(MEGATransfer *)transfer error:(MEGAError *)error {
}

@end
