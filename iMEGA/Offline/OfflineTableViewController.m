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
#import "MWPhotoBrowser.h"
#import "SVProgressHUD.h"
#import "UIScrollView+EmptyDataSet.h"

#import "MEGASdkManager.h"
#import "MEGAQLPreviewControllerTransitionAnimator.h"
#import "Helper.h"
#import "MEGAReachabilityManager.h"
#import "OfflineTableViewController.h"
#import "OfflineTableViewCell.h"

@interface OfflineTableViewController () <UIViewControllerTransitioningDelegate, QLPreviewControllerDelegate, QLPreviewControllerDataSource, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, MWPhotoBrowserDelegate, MEGATransferDelegate>

@property (nonatomic, strong) NSMutableArray *offlineDocuments;
@property (nonatomic, strong) NSMutableArray *offlineImages;

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
        
        NSString *directoryPathString = [self currentOfflinePath];
        NSArray *nodesHandlesOnFolderArray = [self nodeHandlesOnFolder:directoryPathString];
        
        for (NSString *base64HandleAux in nodesHandlesOnFolderArray) {
            if ([base64HandleAux.lowercaseString.pathExtension isEqualToString:@"mega"]) {
                continue;
            }
            if ([[Helper downloadedNodes] objectForKey:base64HandleAux] == nil) {
                [[Helper downloadedNodes] setObject:base64HandleAux forKey:base64HandleAux];
            }
        }
        
    } else {
        NSString *currentFolderName = [self.folderPathFromOffline lastPathComponent];
        NSArray *itemNameComponentsArray = [currentFolderName componentsSeparatedByString:@"_"];
        NSString *titleString;
        if ([itemNameComponentsArray count] > 2) {
            NSString *handleString = [itemNameComponentsArray objectAtIndex:0];
            titleString = [currentFolderName substringFromIndex:(handleString.length + 1)];
        } else {
            titleString = [itemNameComponentsArray objectAtIndex:1];
        }
        [self.navigationItem setTitle:titleString];
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
    
    self.offlineDocuments = [NSMutableArray new];
    self.offlineImages = [NSMutableArray new];
    
    NSString *directoryPathString = [self currentOfflinePath];
    NSArray *directoryContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:directoryPathString error:NULL];
        
    int offsetIndex = 0;
    for (int i = 0; i < (int)[directoryContents count]; i++) {
        NSString *filePath = [directoryPathString stringByAppendingPathComponent:[directoryContents objectAtIndex:i]];
        NSString *fileName = [NSString stringWithFormat:@"%@", [directoryContents objectAtIndex:i]];
        
        if (![fileName.lowercaseString.pathExtension isEqualToString:@"mega"]) {
            
            NSMutableDictionary *tempDictionary = [NSMutableDictionary new];
            [tempDictionary setValue:fileName forKey:kMEGANode];
            [tempDictionary setValue:[NSNumber numberWithInt:offsetIndex] forKey:kIndex];
            [self.offlineDocuments addObject:tempDictionary];
            
            if (isImage(fileName.pathExtension)) {
                offsetIndex++;
                MWPhoto *photo = [MWPhoto photoWithURL:[NSURL fileURLWithPath:filePath]];
                
                NSString *imageName;
                NSArray *itemNameComponentsArray = [fileName componentsSeparatedByString:@"_"];
                if ([itemNameComponentsArray count] > 2) {
                    NSString *handleString = [itemNameComponentsArray objectAtIndex:0];
                    imageName = [fileName substringFromIndex:(handleString.length + 1)];
                } else {
                    imageName = [itemNameComponentsArray objectAtIndex:1];
                }
                photo.caption = [[MEGASdkManager sharedMEGASdk] unescapeFsIncompatible:imageName];
                [self.offlineImages addObject:photo];
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

- (NSArray *)nodeHandlesOnFolder:(NSString *)path {
    
    NSMutableArray *nodeHandlesOnFolder = [[NSMutableArray alloc] init];
    
    NSArray *directoryContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:nil];
    for (NSString *item in directoryContents) {
        NSDictionary *attributesDictionary = [[NSFileManager defaultManager] attributesOfItemAtPath:[path stringByAppendingPathComponent:item] error:nil];
        if ([attributesDictionary objectForKey:NSFileType] == NSFileTypeDirectory) {
            [nodeHandlesOnFolder addObjectsFromArray:[self nodeHandlesOnFolder:[path stringByAppendingPathComponent:item]]];
        } else {
            NSString *base64Handle = [[item componentsSeparatedByString:@"_"] objectAtIndex:0];
            [nodeHandlesOnFolder addObject:base64Handle];
        }
    }
    
    return nodeHandlesOnFolder;
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
    NSString *directoryPathString = [self currentOfflinePath];
    NSArray *directoryContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:directoryPathString error:nil];
    NSInteger numberOfRows = directoryContents.count;
    if (numberOfRows == 0) {
        [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    } else {
        [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleSingleLine];
    }
    return numberOfRows;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    OfflineTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"offlineTableViewCell" forIndexPath:indexPath];
    
    UIView *view = [[UIView alloc] init];
    [view setBackgroundColor:megaInfoGray];
    [cell setSelectedBackgroundView:view];
    [cell setSeparatorInset:UIEdgeInsetsMake(0.0, 60.0, 0.0, 0.0)];
    
    NSString *directoryPathString = [self currentOfflinePath];
    NSArray *directoryContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:directoryPathString error:nil];
    NSString *pathForItem = [directoryPathString stringByAppendingPathComponent:[directoryContents objectAtIndex:[indexPath row]]];
    
    NSDictionary *filePropertiesDictionary = [[NSFileManager defaultManager] attributesOfItemAtPath:pathForItem error:nil];
    
    struct tm *timeinfo;
    char buffer[80];
    time_t rawtime = [[filePropertiesDictionary valueForKey:NSFileModificationDate] timeIntervalSince1970];
    timeinfo = localtime(&rawtime);
    strftime(buffer, 80, "%d/%m/%y %H:%M", timeinfo);
    NSString *date = [NSString stringWithCString:buffer encoding:NSUTF8StringEncoding];
    
    unsigned long long size;
    
    NSString *itemNameString = [directoryContents objectAtIndex:[indexPath row]];
    [cell setItemNameString:itemNameString];
    
    NSString *handleString;
    NSString *nameString;
    if ([[itemNameString pathExtension] isEqualToString:@"mega"]) {
        nameString = AMLocalizedString(@"downloading", nil);
    } else if ([itemNameString isEqualToString:@"MasterKey.txt"]) {
        nameString = itemNameString;
    } else {
        NSArray *itemNameComponentsArray = [itemNameString componentsSeparatedByString:@"_"];
        handleString = [itemNameComponentsArray objectAtIndex:0];
        if ([itemNameComponentsArray count] > 2) {
            nameString = [itemNameString substringFromIndex:(handleString.length + 1)];
        } else {
            nameString = [itemNameComponentsArray objectAtIndex:1];
        }
    }
    
    BOOL isDirectory;
    [[NSFileManager defaultManager] fileExistsAtPath:pathForItem isDirectory:&isDirectory];
    if (isDirectory) {
        [cell.thumbnailImageView setImage:[Helper folderImage]];
        
        size = [Helper sizeOfFolderAtPath:pathForItem];
    } else {
        NSString *extension = [[nameString pathExtension] lowercaseString];
        NSString *fileTypeIconString = [Helper fileTypeIconForExtension:extension];
        
        if (isImage(nameString.pathExtension)) {
            [cell.thumbnailImageView.layer setCornerRadius:4];
            [cell.thumbnailImageView.layer setMasksToBounds:YES];
            
            NSString *thumbnailFilePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
            thumbnailFilePath = [thumbnailFilePath stringByAppendingPathComponent:@"thumbs"];
            thumbnailFilePath = [thumbnailFilePath stringByAppendingPathComponent:handleString];
            
            UIImage *thumbnailImage = [UIImage imageWithContentsOfFile:thumbnailFilePath];
            if (thumbnailImage == nil) {
                thumbnailImage = [Helper defaultPhotoImage];
            }
            [cell.thumbnailImageView setImage:thumbnailImage];
        } else {
            UIImage *iconImage = [UIImage imageNamed:fileTypeIconString];
            [cell.thumbnailImageView setImage:iconImage];
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
        NSArray *nodesHandlesOnFolderArray;
        NSString *base64Handle;
        
        BOOL isDirectory;
        [[NSFileManager defaultManager] fileExistsAtPath:itemPath isDirectory:&isDirectory];
        if (isDirectory) {
            if ([[[[MEGASdkManager sharedMEGASdk] transfers] size] integerValue] != 0) {
                [self cancelPendingTransfersOnFolder:itemPath folderLink:NO];
            }
            if ([[[[MEGASdkManager sharedMEGASdkFolder] transfers] size] integerValue] != 0) {
                [self cancelPendingTransfersOnFolder:itemPath folderLink:YES];
            }
            nodesHandlesOnFolderArray = [self nodeHandlesOnFolder:itemPath];
            
        } else {
            base64Handle = [[[cell itemNameString] componentsSeparatedByString:@"_"] objectAtIndex:0];
            NSNumber *transferTag = [[Helper downloadingNodes] objectForKey:base64Handle];
            if (transferTag != nil) {
                [[MEGASdkManager sharedMEGASdk] cancelTransferByTag:transferTag.integerValue];
            }
        }
        
        NSError *error = nil;
        BOOL success = [ [NSFileManager defaultManager] removeItemAtPath:itemPath error:&error];
        if (!success || error) {
            [SVProgressHUD showErrorWithStatus:AMLocalizedString(@"itemDeletingError", @"Error at deleting")];
            return;
        } else {
            if (isDirectory) {
                for (NSString *base64HandleAux in nodesHandlesOnFolderArray) {
                    [[Helper downloadedNodes] removeObjectForKey:base64HandleAux];
                }
            } else {
                [[Helper downloadedNodes] removeObjectForKey:base64Handle];
            }
            [self.tableView reloadData];
        }
    }
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    OfflineTableViewCell *cell = (OfflineTableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
    NSString *itemNameString = [cell itemNameString];
    if ([[itemNameString pathExtension] isEqualToString:@"mega"]) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        return;
    }
    NSString *itemPath = [[self currentOfflinePath] stringByAppendingPathComponent:itemNameString];
    
    NSString *filename;
    NSArray *itemNameComponentsArray = [itemNameString componentsSeparatedByString:@"_"];
    if ([itemNameComponentsArray count] > 2) {
        NSString *handleString = [itemNameComponentsArray objectAtIndex:0];
        filename = [itemNameString substringFromIndex:(handleString.length + 1)];
    } else {
        filename = [itemNameComponentsArray objectAtIndex:1];
    }
    
    BOOL isDirectory;
    [[NSFileManager defaultManager] fileExistsAtPath:itemPath isDirectory:&isDirectory];
    if (isDirectory) {
        NSString *folderPathFromOffline = [self folderPathFromOffline:itemPath folder:[cell itemNameString]];
        
        OfflineTableViewController *offlineTVC = [self.storyboard instantiateViewControllerWithIdentifier:@"OfflineTableViewControllerID"];
        [offlineTVC setFolderPathFromOffline:folderPathFromOffline];
        [self.navigationController pushViewController:offlineTVC animated:YES];
    } else {
        if (isImage(itemNameString.pathExtension)) {
            MWPhotoBrowser *browser = [[MWPhotoBrowser alloc] initWithDelegate:self];
            
            browser.displayActionButton = YES;
            browser.displayNavArrows = YES;
            browser.displaySelectionButtons = NO;
            browser.zoomPhotosToFill = YES;
            browser.alwaysShowControls = NO;
            browser.enableGrid = YES;
            browser.startOnGrid = NO;
            
            // Optionally set the current visible photo before displaying
            //    [browser setCurrentPhotoIndex:1];
            
            [self.navigationController pushViewController:browser animated:YES];
            
            [browser showNextPhotoAnimated:YES];
            [browser showPreviousPhotoAnimated:YES];
            NSInteger selectedIndexPhoto = [[[self.offlineDocuments objectAtIndex:indexPath.row] objectForKey:kIndex] integerValue];
            [browser setCurrentPhotoIndex:selectedIndexPhoto];
            
        } else if (isVideo(itemNameString.pathExtension)) {
            NSURL *fileURL = [NSURL fileURLWithPath:itemPath];
            
            MPMoviePlayerViewController *moviePlayerViewController = [[MPMoviePlayerViewController alloc] initWithContentURL:fileURL];
            [[NSNotificationCenter defaultCenter] removeObserver:moviePlayerViewController name:UIApplicationDidEnterBackgroundNotification object:nil];
            [self presentMoviePlayerViewControllerAnimated:moviePlayerViewController];
            [moviePlayerViewController.moviePlayer play];
        } else {
            [Helper setPathForPreviewDocument:itemPath];
            
            //Copy the node to tmp without handle_
            NSArray *itemNameComponentsArray = [itemNameString componentsSeparatedByString:@"_"];
            NSString *handleString = [itemNameComponentsArray objectAtIndex:0];
            NSString *nameString;
            if ([itemNameComponentsArray count] > 2) {
                nameString = [itemNameString substringFromIndex:(handleString.length + 1)];
            } else {
                nameString = [itemNameComponentsArray objectAtIndex:1];
            }
            
            NSArray *pathElements = [itemPath componentsSeparatedByString:@"/"];
            
            NSString *pathWihtoutName = @"/";
            for (NSInteger i = 0; i < pathElements.count - 1; i++) {
                pathWihtoutName = [pathWihtoutName stringByAppendingPathComponent:[pathElements objectAtIndex:i]];
            }
            
            [Helper setRenamePathForPreviewDocument:[pathWihtoutName stringByAppendingPathComponent:nameString]];
            
            NSError *error = nil;
            BOOL success = [[NSFileManager defaultManager] moveItemAtPath:itemPath toPath:[Helper renamePathForPreviewDocument] error:&error];
            if (!success || error) {
                [MEGASdk logWithLevel:MEGALogLevelError message:[NSString stringWithFormat:@"Move file error %@", error]];
            }
            
            QLPreviewController *previewController = [[QLPreviewController alloc]init];
            previewController.delegate=self;
            previewController.dataSource=self;
            [previewController setTransitioningDelegate:self];
            [previewController setTitle:filename];
            [self presentViewController:previewController animated:YES completion:nil];
        }
        
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
            text = AMLocalizedString(@"offlineEmptyState_textForEmptyFolder", @"When you downloaded this folder it was empty.");
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

#pragma mark - MWPhotoBrowserDelegate

- (NSUInteger)numberOfPhotosInPhotoBrowser:(MWPhotoBrowser *)photoBrowser {
    return self.offlineImages.count;
}

- (id <MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index {
    if (index < self.offlineImages.count)
        return [self.offlineImages objectAtIndex:index];
    return nil;
}

#pragma mark - QLPreviewControllerDataSource

- (NSInteger)numberOfPreviewItemsInPreviewController:(QLPreviewController *)controller {
    return 1;
}

- (id <QLPreviewItem>)previewController:(QLPreviewController *)controller previewItemAtIndex:(NSInteger)index {
    return [NSURL fileURLWithPath:[Helper renamePathForPreviewDocument]];
}

#pragma mark - QLPreviewControllerDelegate

- (BOOL)previewController:(QLPreviewController *)controller shouldOpenURL:(NSURL *)url forPreviewItem:(id <QLPreviewItem>)item {
    return YES;
}

- (void)previewControllerWillDismiss:(QLPreviewController *)controller {
    NSError *error = nil;
    BOOL success = [[NSFileManager defaultManager] moveItemAtPath:[Helper renamePathForPreviewDocument] toPath:[Helper pathForPreviewDocument] error:&error];
    if (!success || error) {
        [MEGASdk logWithLevel:MEGALogLevelError message:[NSString stringWithFormat:@"Move file error %@", error]];
    }
    
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
