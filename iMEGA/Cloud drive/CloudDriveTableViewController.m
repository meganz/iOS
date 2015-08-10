/**
 * @file CloudDriveTableViewController.m
 * @brief Cloud drive table view controller of the app.
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

#import <AssetsLibrary/AssetsLibrary.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <MediaPlayer/MPMoviePlayerViewController.h>
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVCaptureDevice.h>
#import <AVFoundation/AVMediaFormat.h>

#import "MWPhotoBrowser.h"
#import "SVProgressHUD.h"
#import "NSString+MNZCategory.h"
#import "UIScrollView+EmptyDataSet.h"

#import "Helper.h"

#import "CloudDriveTableViewController.h"
#import "NodeTableViewCell.h"
#import "LoginViewController.h"
#import "DetailsNodeInfoViewController.h"
#import "MEGAPreview.h"
#import "MEGANavigationController.h"
#import "MEGAReachabilityManager.h"
#import "BrowserViewController.h"
#import "CameraUploads.h"
#import "PhotosViewController.h"
#import "SortByTableViewController.h"

#import "AppDelegate.h"
#import "MEGAProxyServer.h"

#import "MEGAStore.h"

@interface CloudDriveTableViewController () <UIActionSheetDelegate, UIAlertViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate, UISearchDisplayDelegate, UIDocumentPickerDelegate, UIDocumentMenuDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, MWPhotoBrowserDelegate, MEGADelegate> {
    UIAlertView *folderAlertView;
    UIAlertView *removeAlertView;
    UIAlertView *renameAlertView;
    
    NSInteger indexNodeSelected;
    NSUInteger remainingOperations;
    
    NSMutableArray *exportLinks;
    
    NSMutableArray *matchSearchNodes;
    
    BOOL allNodesSelected;
    BOOL isSwipeEditing;
    BOOL isSearchTableViewDisplay; //YES if the search table view is displayed, NO otherwise
    
    MEGAShareType lowShareType; //Control the actions allowed for node/nodes selected
}

@property (weak, nonatomic) IBOutlet UIBarButtonItem *addBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *selectAllBarButtonItem;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *sortByBarButtonItem;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *editBarButtonItem;

@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *downloadBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *shareBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *moveBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *renameBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *deleteBarButtonItem;

@property (nonatomic, strong) MEGANodeList *nodes;

@property (nonatomic, strong) NSMutableArray *cloudImages;
@property (nonatomic, strong) NSMutableArray *selectedNodesArray;

@property (nonatomic) UIImagePickerController *imagePickerController;

@property (nonatomic, strong) NSMutableDictionary *nodesIndexPathMutableDictionary;

@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@property (nonatomic, strong) ALAssetsLibrary *library;

@end

@implementation CloudDriveTableViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.emptyDataSetSource = self;
    self.tableView.emptyDataSetDelegate = self;
    
    [self.tableView setTableHeaderView:self.searchDisplayController.searchBar];
    [self.tableView setContentOffset:CGPointMake(0, CGRectGetHeight(self.searchDisplayController.searchBar.frame))];
    
    [self.toolbar setFrame:CGRectMake(0, 49, CGRectGetWidth(self.view.frame), 49)];
    
    UIBarButtonItem *flexibleItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    switch (self.displayMode) {
        case DisplayModeCloudDrive: {
            if (!self.parentNode) {
                self.parentNode = [[MEGASdkManager sharedMEGASdk] rootNode];
            }
            
            MEGAShareType accessType = [[MEGASdkManager sharedMEGASdk] accessLevelForNode:self.parentNode];
            
            
            UIBarButtonItem *negativeSpaceBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
            if (([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)) {
                [negativeSpaceBarButtonItem setWidth:-8.0];
            } else {
                [negativeSpaceBarButtonItem setWidth:-4.0];
            }

            
            switch (accessType) {
                case MEGAShareTypeAccessRead: {
                    self.navigationItem.rightBarButtonItems = @[negativeSpaceBarButtonItem, self.editBarButtonItem, self.sortByBarButtonItem];
                    break;
                }
                    
                default: {
                    self.navigationItem.rightBarButtonItems = @[negativeSpaceBarButtonItem, self.editBarButtonItem, self.addBarButtonItem, self.sortByBarButtonItem];
                    break;
                }
            }
            
            break;
        }
            
        case DisplayModeContact:
            self.navigationItem.rightBarButtonItems = nil;
            [self.toolbar setItems:@[self.downloadBarButtonItem, flexibleItem, self.moveBarButtonItem, flexibleItem, self.renameBarButtonItem, flexibleItem, self.deleteBarButtonItem]];
            break;
        
            
        case DisplayModeRubbishBin:
            self.navigationItem.rightBarButtonItems = @[self.editBarButtonItem, self.sortByBarButtonItem];
            [self.deleteBarButtonItem setImage:[UIImage imageNamed:@"remove"]];
            [self.toolbar setItems:@[self.downloadBarButtonItem, flexibleItem, self.moveBarButtonItem, flexibleItem, self.renameBarButtonItem, flexibleItem, self.deleteBarButtonItem]];
            break;
        
        default:
            break;
    }
    
    
    MEGAShareType shareType = [[MEGASdkManager sharedMEGASdk] accessLevelForNode:self.parentNode];
    
    [self toolbarActionsForShareType:shareType];

    NSString *thumbsDirectory = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"thumbnailsV3"];
    NSError *error;
    if (![[NSFileManager defaultManager] fileExistsAtPath:thumbsDirectory]) {
        if (![[NSFileManager defaultManager] createDirectoryAtPath:thumbsDirectory withIntermediateDirectories:NO attributes:nil error:&error]) {
            [MEGASdk logWithLevel:MEGALogLevelError message:[NSString stringWithFormat:@"Create directory error %@", error]];
        }
    }
    
    NSString *previewsDirectory = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"previewsV3"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:previewsDirectory]) {
        if (![[NSFileManager defaultManager] createDirectoryAtPath:previewsDirectory withIntermediateDirectories:NO attributes:nil error:&error]) {
            [MEGASdk logWithLevel:MEGALogLevelError message:[NSString stringWithFormat:@"Create directory error %@", error]];
        }
    }
    
    [self.searchDisplayController.searchResultsTableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    
    self.nodesIndexPathMutableDictionary = [[NSMutableDictionary alloc] init];
    
    
    self.dateFormatter = [[NSDateFormatter alloc] init];
    [self.dateFormatter setDateFormat:@"yyyy'-'MM'-'dd' 'HH'.'mm'.'ss"];
    NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    [self.dateFormatter setLocale:locale];
    
    self.library = [[ALAssetsLibrary alloc] init];
    
    matchSearchNodes = [[NSMutableArray alloc] init];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(internetConnectionChanged) name:kReachabilityChangedNotification object:nil];
    
    [[MEGASdkManager sharedMEGASdk] addMEGADelegate:self];
    [[MEGASdkManager sharedMEGASdk] retryPendingConnections];
    
    [self reloadUI];
    
    [self setNavigationBarButtonItemsEnabled:[MEGAReachabilityManager isReachable]];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
    
    if (self.tableView.isEditing) {
        self.selectedNodesArray = nil;
        [self setEditing:NO animated:NO];
    }
    
    [[MEGASdkManager sharedMEGASdk] removeMEGADelegate:self];
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

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger numberOfRows = 0;
    if ([MEGAReachabilityManager isReachable]) {
        if (tableView == self.searchDisplayController.searchResultsTableView) {
            numberOfRows = [matchSearchNodes count];
        } else {
            numberOfRows = [[self.nodes size] integerValue];
        }
    }
    
    if (numberOfRows == 0) {
        if (tableView == self.searchDisplayController.searchResultsTableView) {
            [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleSingleLine];
        } else {
            [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
        }
    } else {
        [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleSingleLine];
    }
    
    return numberOfRows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    MEGANode *node = nil;
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        node = [matchSearchNodes objectAtIndex:indexPath.row];
    } else {
        node = [self.nodes nodeAtIndex:indexPath.row];
    }
    
    [self.nodesIndexPathMutableDictionary setObject:indexPath forKey:node.base64Handle];
    
    NodeTableViewCell *cell;
    if ([[Helper downloadingNodes] objectForKey:node.base64Handle] != nil) {
        cell = [self.tableView dequeueReusableCellWithIdentifier:@"downloadingNodeCell" forIndexPath:indexPath];
        if (cell == nil) {
            cell = [[NodeTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"downloadingNodeCell"];
        }
        
        [cell.downloadedImageView setImage:[Helper downloadingArrowImage]];
        [cell.infoLabel setText:AMLocalizedString(@"queued", @"Queued")];
    } else {
        cell = [self.tableView dequeueReusableCellWithIdentifier:@"nodeCell" forIndexPath:indexPath];
        if (cell == nil) {
            cell = [[NodeTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"nodeCell"];
        }
        
        NSString *fingerprint = [[MEGASdkManager sharedMEGASdk] fingerprintForNode:node];
        MOOfflineNode *offlineNode = [[MEGAStore shareInstance] fetchOfflineNodeWithFingerprint:fingerprint];
        
        // Check fingerprint, if we download a file with NULL fingerprint, all folders are marked as downloaded because the fingerprinf for folders are NULL
        if (offlineNode && fingerprint) {
            [cell.downloadedImageView setImage:[Helper downloadedArrowImage]];
        } else {
            [cell.downloadedImageView setImage:nil];
        }
        
        struct tm *timeinfo;
        char buffer[80];
        
        time_t rawtime = [[node modificationTime] timeIntervalSince1970];
        timeinfo = localtime(&rawtime);
        
        strftime(buffer, 80, "%d %B %Y %I:%M %p", timeinfo);
        
        NSString *date = [NSString stringWithCString:buffer encoding:NSUTF8StringEncoding];
        NSString *size = [NSByteCountFormatter stringFromByteCount:node.size.longLongValue countStyle:NSByteCountFormatterCountStyleMemory];
        NSString *sizeAndDate = [NSString stringWithFormat:@"%@ • %@", size, date];
        
        cell.infoLabel.text = sizeAndDate;
    }
    
    UIView *view = [[UIView alloc] init];
    [view setBackgroundColor:megaInfoGray];
    [cell setSelectedBackgroundView:view];
    [cell setSeparatorInset:UIEdgeInsetsMake(0.0, 60.0, 0.0, 0.0)];
    
    cell.nameLabel.text = [node name];
    
    if ([node type] == MEGANodeTypeFile) {
        
        // check if the thumbnail exist in the cache directory
        NSString *thumbnailFilePath = [Helper pathForNode:node searchPath:NSCachesDirectory directory:@"thumbnailsV3"];
        BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:thumbnailFilePath];
        
        if (!fileExists) {
            [[MEGASdkManager sharedMEGASdk] getThumbnailNode:node destinationFilePath:thumbnailFilePath];
            [cell.thumbnailImageView setImage:[Helper imageForNode:node]];
        } else {
            [cell.thumbnailImageView.layer setCornerRadius:4];
            [cell.thumbnailImageView.layer setMasksToBounds:YES];
            
            [cell.thumbnailImageView setImage:[UIImage imageWithContentsOfFile:thumbnailFilePath]];
        }
        
    } else if ([node type] == MEGANodeTypeFolder) {
        [cell.thumbnailImageView setImage:[Helper imageForNode:node]];
        
        NSInteger files = [[MEGASdkManager sharedMEGASdk] numberChildFilesForParent:node];
        NSInteger folders = [[MEGASdkManager sharedMEGASdk] numberChildFoldersForParent:node];
        
        NSString *filesAndFolders = [self stringByFiles:files andFolders:folders];
        cell.infoLabel.text = filesAndFolders;
    }
    
    cell.nodeHandle = [node handle];
    
    if (self.isEditing) {
        // Check if selectedNodesArray contains the current node in the tableView
        for (MEGANode *n in self.selectedNodesArray) {
            if ([n handle] == [node handle]) {
                [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
            }
        }
    }
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    MEGANode *node = nil;
    
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        node = [matchSearchNodes objectAtIndex:indexPath.row];
    } else {
        node = [self.nodes nodeAtIndex:indexPath.row];
    }
    
    if (tableView.isEditing) {
        [self.selectedNodesArray addObject:node];
        
        [self toolbarActionsForNodeArray:self.selectedNodesArray];
        
        [self.downloadBarButtonItem setEnabled:YES];
        [self.shareBarButtonItem setEnabled:YES];
        [self.moveBarButtonItem setEnabled:YES];
        [self.deleteBarButtonItem setEnabled:YES];
        
        if (self.selectedNodesArray.count == 1) {
            [self.renameBarButtonItem setEnabled:YES];
        } else {
            [self.renameBarButtonItem setEnabled:NO];
        }
        
        if (self.selectedNodesArray.count == self.nodes.size.integerValue) {
            allNodesSelected = YES;
        } else {
            allNodesSelected = NO;
        }
        
        return;
    }
    
    switch ([node type]) {
        case MEGANodeTypeFolder: {
            if ([node.name isEqualToString:@"Camera Uploads"]) {
                [Helper changeToViewController:[PhotosViewController class] onTabBarController:self.tabBarController];
            } else {
                CloudDriveTableViewController *cdvc = [self.storyboard instantiateViewControllerWithIdentifier:@"CloudDriveID"];
                [cdvc setParentNode:node];
                
                if (self.displayMode == DisplayModeRubbishBin) {
                    [cdvc setDisplayMode:self.displayMode];
                }
                
                [self.navigationController pushViewController:cdvc animated:YES];
            }
            break;
        }
            
        case MEGANodeTypeFile: {
            NSString *name = [node name];
            if (isImage(name.pathExtension)) {
                
                int offsetIndex = 0;
                self.cloudImages = [NSMutableArray new];
                
                if (tableView == self.searchDisplayController.searchResultsTableView) {
                    for (NSInteger i = 0; i < matchSearchNodes.count; i++) {
                        MEGANode *n = [matchSearchNodes objectAtIndex:i];
                        
                        if (isImage([n name].pathExtension) && [n type] == MEGANodeTypeFile) {
                            MEGAPreview *photo = [MEGAPreview photoWithNode:n];
                            photo.caption = [n name];
                            [self.cloudImages addObject:photo];
                            if ([n handle] == [node handle]) {
                                offsetIndex = (int)[self.cloudImages count] - 1;
                            }
                        }
                    }
                } else {
                    for (NSInteger i = 0; i < [[self.nodes size] integerValue]; i++) {
                        MEGANode *n = [self.nodes nodeAtIndex:i];
                        
                        if (isImage([n name].pathExtension) && [n type] == MEGANodeTypeFile) {
                            MEGAPreview *photo = [MEGAPreview photoWithNode:n];
                            photo.caption = [n name];
                            [self.cloudImages addObject:photo];
                            if ([n handle] == [node handle]) {
                                offsetIndex = (int)[self.cloudImages count] - 1;
                            }
                        }
                    }
                }
                
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
                [browser setCurrentPhotoIndex:offsetIndex];
            } else if (isMultimedia(name.pathExtension)) {
                NSURL *link = [NSURL URLWithString:[NSString stringWithFormat:@"http://127.0.0.1:%llu/%lld.%@", [[MEGAProxyServer sharedInstance] port], node.handle, node.name.pathExtension.lowercaseString]];
                if (link) {
                    MPMoviePlayerViewController *moviePlayerViewController = [[MPMoviePlayerViewController alloc] initWithContentURL:link];
                    // Remove the movie player view controller from the "playback did finish" notification observers
                    [[NSNotificationCenter defaultCenter] removeObserver:moviePlayerViewController
                                                                    name:MPMoviePlayerPlaybackDidFinishNotification
                                                                  object:moviePlayerViewController.moviePlayer];
                    
                    // Register this class as an observer instead
                    [[NSNotificationCenter defaultCenter] addObserver:self
                                                             selector:@selector(movieFinishedCallback:)
                                                                 name:MPMoviePlayerPlaybackDidFinishNotification
                                                               object:moviePlayerViewController.moviePlayer];
                    
                    [[NSNotificationCenter defaultCenter] removeObserver:moviePlayerViewController name:UIApplicationDidEnterBackgroundNotification object:nil];
                    
                    [self presentMoviePlayerViewControllerAnimated:moviePlayerViewController];
                    
                    [moviePlayerViewController.moviePlayer prepareToPlay];
                    [moviePlayerViewController.moviePlayer play];
                    
                    return;
                }
                
            } else {
                MEGANode *node = nil;
                
                if (tableView == self.searchDisplayController.searchResultsTableView) {
                    node = [matchSearchNodes objectAtIndex:indexPath.row];
                } else {
                    node = [self.nodes nodeAtIndex:indexPath.row];
                }
                
                DetailsNodeInfoViewController *detailsNodeInfoVC = [self.storyboard instantiateViewControllerWithIdentifier:@"nodeInfoDetails"];
                [detailsNodeInfoVC setNode:node];
                
                [self.navigationController pushViewController:detailsNodeInfoVC animated:YES];
                
                [tableView deselectRowAtIndexPath:indexPath animated:YES];
            }
            break;
        }
            
        default:
            break;
    }
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    MEGANode *node = [self.nodes nodeAtIndex:indexPath.row];
    
    if (tableView.isEditing) {
        
        //tempArray avoid crash: "was mutated while being enumerated."
        NSMutableArray *tempArray = [self.selectedNodesArray copy];
        for (MEGANode *n in tempArray) {
            if (n.handle == node.handle) {
                [self.selectedNodesArray removeObject:n];
            }
        }
        
        [self toolbarActionsForNodeArray:self.selectedNodesArray];
        
        if (self.selectedNodesArray.count == 0) {
            [self.downloadBarButtonItem setEnabled:NO];
            [self.shareBarButtonItem setEnabled:NO];
            [self.moveBarButtonItem setEnabled:NO];
            [self.renameBarButtonItem setEnabled:NO];
            [self.deleteBarButtonItem setEnabled:NO];
        } else if (self.selectedNodesArray.count == 1) {
            [self.renameBarButtonItem setEnabled:YES];
        }
        
        allNodesSelected = NO;
        
        return;
    }
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    MEGANode *node = nil;
    
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        node = [matchSearchNodes objectAtIndex:indexPath.row];
    } else {
        node = [self.nodes nodeAtIndex:indexPath.row];
    }
//    MEGANode *n = [self.nodes nodeAtIndex:indexPath.row];
    
    if (self.displayMode == DisplayModeCloudDrive && [[MEGASdkManager sharedMEGASdk] accessLevelForNode:node] < MEGAShareTypeAccessFull) {
        return UITableViewCellEditingStyleNone;
    } else {
        self.selectedNodesArray = [NSMutableArray new];
        [self.selectedNodesArray addObject:node];
        [self.downloadBarButtonItem setEnabled:YES];
        [self.shareBarButtonItem setEnabled:YES];
        [self.moveBarButtonItem setEnabled:YES];
        [self.renameBarButtonItem setEnabled:YES];
        [self.deleteBarButtonItem setEnabled:YES];
        
        isSwipeEditing = YES;
        
        MEGAShareType shareType = [[MEGASdkManager sharedMEGASdk] accessLevelForNode:node];
        [self toolbarActionsForShareType:shareType];
        
        return UITableViewCellEditingStyleDelete;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    MEGANode *node = [self.nodes nodeAtIndex:indexPath.row];
    MEGAShareType accessType = [[MEGASdkManager sharedMEGASdk] accessLevelForNode:node];
    
    if (self.displayMode != DisplayModeContact) {
        if (accessType >= MEGAShareTypeAccessFull) {
            return AMLocalizedString(@"remove", nil);
        }
    } else {
        return AMLocalizedString(@"leaveFolder", @"Leave folder");
    }
    
    //editingStyleForRowAtIndexPath return -> UITableViewCellEditingStyleNone
    return @"";
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle==UITableViewCellEditingStyleDelete) {
        MEGANode *node = nil;
        
        if (tableView == self.searchDisplayController.searchResultsTableView) {
            node = [matchSearchNodes objectAtIndex:indexPath.row];
        } else {
            node = [self.nodes nodeAtIndex:indexPath.row];
        }
        remainingOperations = 1;
        
        MEGAShareType accessType = [[MEGASdkManager sharedMEGASdk] accessLevelForNode:node];
    
        if (accessType == MEGAShareTypeAccessOwner) {
            if (self.displayMode == DisplayModeCloudDrive) {
                [[MEGASdkManager sharedMEGASdk] moveNode:node newParent:[[MEGASdkManager sharedMEGASdk] rubbishNode]];
            } else {
                [[MEGASdkManager sharedMEGASdk] removeNode:node];
            }
        } else {
            //Leave share folder
            [[MEGASdkManager sharedMEGASdk] removeNode:node];
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (([[[UIDevice currentDevice] systemVersion] compare:@"8.0" options:NSNumericSearch] == NSOrderedAscending)) {
        return 44.0;
    }
    else {
        return UITableViewAutomaticDimension;
    }
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (([[[UIDevice currentDevice] systemVersion] compare:@"8.0" options:NSNumericSearch] == NSOrderedAscending)) {
        return 44.0;
    }
    else {
        return UITableViewAutomaticDimension;
    }
}
- (IBAction)editTapped:(UIBarButtonItem *)sender {
    BOOL value = [self.editBarButtonItem.image isEqual:[UIImage imageNamed:@"edit"]];
    [self setEditing:value animated:YES];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    
    if (editing) {
        [self.editBarButtonItem setImage:[UIImage imageNamed:@"done"]];
        [self.addBarButtonItem setEnabled:NO];
        [self.sortByBarButtonItem setEnabled:NO];
        if (!isSwipeEditing) {
            self.navigationItem.leftBarButtonItems = @[self.selectAllBarButtonItem];
        }
    } else {
        [self.editBarButtonItem setImage:[UIImage imageNamed:@"edit"]];
        allNodesSelected = NO;
        self.selectedNodesArray = nil;
        [self.addBarButtonItem setEnabled:YES];
        [self.sortByBarButtonItem setEnabled:YES];
        self.navigationItem.leftBarButtonItems = @[];
    }
    
    if (!self.selectedNodesArray) {
        self.selectedNodesArray = [NSMutableArray new];
        
        [self.downloadBarButtonItem setEnabled:NO];
        [self.shareBarButtonItem setEnabled:NO];
        [self.moveBarButtonItem setEnabled:NO];
        [self.renameBarButtonItem setEnabled:NO];
        [self.deleteBarButtonItem setEnabled:NO];
    }
    
    [self.tabBarController.tabBar addSubview:self.toolbar];
    
    [UIView animateWithDuration:animated ? .33 : 0 animations:^{
        self.toolbar.frame = CGRectMake(0, editing ? 0 : 49 , CGRectGetWidth(self.view.frame), 49);
    }];
    
    isSwipeEditing = NO;
}

#pragma mark - DZNEmptyDataSetSource

- (NSAttributedString *)titleForEmptyDataSet:(UIScrollView *)scrollView {
    
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    
    NSString *text;
    if ([MEGAReachabilityManager isReachable]) {
        if (self.parentNode == nil) {
            return nil;
        }
        
        switch (self.displayMode) {
            case DisplayModeCloudDrive: {
                if ([self.parentNode type] == MEGANodeTypeRoot) {
                    text = AMLocalizedString(@"cloudDriveEmptyState_title", @"No files in your Cloud Drive");
                } else {
                    text = AMLocalizedString(@"emptyFolder", @"Title shown when a folder doesn't have any files");
                }
                break;
            }
                
            case DisplayModeContact:
                text = AMLocalizedString(@"cloudDriveEmptyState_titleContact", @"No files in this shared folder");
                break;
                
            case DisplayModeRubbishBin:
                if ([self.parentNode type] == MEGANodeTypeRubbish) {
                    text = AMLocalizedString(@"cloudDriveEmptyState_titleRubbishBin", @"Empty rubbish bin");
                } else {
                    text = AMLocalizedString(@"emptyFolder", @"Title shown when a folder doesn't have any files");
                }
                break;
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
        if (self.parentNode == nil) {
            return nil;
        }
        
        switch (self.displayMode) {
            case DisplayModeCloudDrive:
                text = AMLocalizedString(@"cloudDriveEmptyState_text",  @"Add new files using the upper button.");
                break;
                
            case DisplayModeContact:
                text = AMLocalizedString(@"cloudDriveEmptyState_textContact",  @"Share something!");
                break;
                
            case DisplayModeRubbishBin:
                if ([self.parentNode type] == MEGANodeTypeRubbish) {
                    text = AMLocalizedString(@"cloudDriveEmptyState_textRubbishBin",  @"Awesome!");
                } else {
                    text = @"";
                }
                break;
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
    
    if ([MEGAReachabilityManager isReachable]) {
        if (self.parentNode == nil) {
            return nil;
        }
        
        switch (self.displayMode) {
            case DisplayModeCloudDrive: {
                if ([self.parentNode type] == MEGANodeTypeRoot) {
                    return [UIImage imageNamed:@"emptyCloudDrive"];
                } else {
                    return [UIImage imageNamed:@"emptyFolder"];
                }
                break;
            }
                
            case DisplayModeContact:
                return [UIImage imageNamed:@"emptyFolder"];
                break;
                
            case DisplayModeRubbishBin:
                if ([self.parentNode type] == MEGANodeTypeRubbish) {
                    return [UIImage imageNamed:@"emptyRubbishBin"];
                } else {
                    return [UIImage imageNamed:@"emptyFolder"];
                }
                break;
        }
    } else {
         return [UIImage imageNamed:@"noInternetConnection"];
    }
}

- (UIColor *)backgroundColorForEmptyDataSet:(UIScrollView *)scrollView {
    return [UIColor whiteColor];
}

#pragma mark - MWPhotoBrowserDelegate

- (NSUInteger)numberOfPhotosInPhotoBrowser:(MWPhotoBrowser *)photoBrowser {
    return self.cloudImages.count;
}

- (id <MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index {
    if (index < self.cloudImages.count) {
        return [self.cloudImages objectAtIndex:index];
    }
    
    return nil;
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    switch (buttonIndex) {
        //New folder
        case 0:
            folderAlertView = [[UIAlertView alloc] initWithTitle:AMLocalizedString(@"newFolder", @"New Folder")
                                                         message:AMLocalizedString(@"newFolderMessage", @"Name for the new folder")
                                                        delegate:self
                                               cancelButtonTitle:AMLocalizedString(@"cancel", nil)
                                               otherButtonTitles:AMLocalizedString(@"createFolderButton", @"Create"), nil];
            [folderAlertView setAlertViewStyle:UIAlertViewStylePlainTextInput];
            [folderAlertView textFieldAtIndex:0].text = @"";
            folderAlertView.tag = 1;
            [folderAlertView show];
            break;
            
        //Choose
        case 1:
            [self showImagePickerForSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
            break;
          
        //Capture
        case 2:
            if ([AVCaptureDevice respondsToSelector:@selector(requestAccessForMediaType: completionHandler:)]) {
                [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                    // Will get here on both iOS 7 & 8 even though camera permissions weren't required
                    // until iOS 8. So for iOS 7 permission will always be granted.
                    if (granted) {
                        // Permission has been granted. Use dispatch_async for any UI updating
                        // code because this block may be executed in a thread.
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self showImagePickerForSourceType:UIImagePickerControllerSourceTypeCamera];
                        });
                    } else {
                        // Permission has been denied.
                        dispatch_async(dispatch_get_main_queue(), ^{
                            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:AMLocalizedString(@"attention", @"Attention")
                                                                            message:AMLocalizedString(@"cameraPermissions", @"Please give MEGA app permission to access your Camera in your settings app!")
                                                                           delegate:self cancelButtonTitle:(&UIApplicationOpenSettingsURLString ? AMLocalizedString(@"cancel", nil) : AMLocalizedString(@"ok", nil))
                                                                  otherButtonTitles:(&UIApplicationOpenSettingsURLString ? AMLocalizedString(@"ok", nil) : nil), nil];
                            alert.tag = 3;
                            [alert show];
                        });
                    }
                }];
            }

            break;
          
        // Upload a file iOS 8+
        case 3: {
            if (([[[UIDevice currentDevice] systemVersion] compare:@"8.0" options:NSNumericSearch] != NSOrderedAscending)) {
                UIDocumentMenuViewController *documentMenuViewController = [[UIDocumentMenuViewController alloc] initWithDocumentTypes:@[(__bridge NSString *) kUTTypeContent,
                                                                                                                                 (__bridge NSString *) kUTTypeData,
                                                                                                                                 (__bridge NSString *) kUTTypePackage,
                                                                                                                                 (@"com.apple.iwork.pages.pages"),
                                                                                                                                 (@"com.apple.iwork.numbers.numbers"),
                                                                                                                                 (@"com.apple.iwork.keynote.key")]
                                                                                                                        inMode:UIDocumentPickerModeImport];
                documentMenuViewController.delegate = self;
                documentMenuViewController.modalPresentationStyle = UIModalPresentationFormSheet;
                [self presentViewController:documentMenuViewController animated:YES completion:nil];
            }
            break;
        }
            
        default:
            break;
    }
}

//For iOS 7 UIActionSheet color
- (void)willPresentActionSheet:(UIActionSheet *)actionSheet {
    for (UIView *subview in actionSheet.subviews) {
        if ([subview isKindOfClass:[UIButton class]]) {
            UIButton *button = (UIButton *)subview;
            [button setTitleColor:megaRed forState:UIControlStateNormal];
        }
    }
}

#pragma mark - UIAlertViewDelegate

- (BOOL)alertViewShouldEnableFirstOtherButton:(UIAlertView *)alertView {
    BOOL shouldEnable;
    if ([alertView tag] == 0) {
        UITextField *textField = [alertView textFieldAtIndex:0];
        NSString *newName = [textField text];
        NSString *newNameExtension = [newName pathExtension];
        NSString *newNameWithoutExtension = [newName stringByDeletingPathExtension];
        
        MEGANode *node = [self.selectedNodesArray objectAtIndex:0];
        NSString *nodeNameString = [node name];
        NSString *nodeNameExtension = [NSString stringWithFormat:@".%@", [nodeNameString pathExtension]];
        
        switch ([node type]) {
            case MEGANodeTypeFile: {
                if ([newName isEqualToString:@""] ||
                    [newName isEqualToString:nodeNameString] ||
                    [newName isEqualToString:nodeNameExtension] ||
                    ![[NSString stringWithFormat:@".%@", newNameExtension] isEqualToString:nodeNameExtension] || //Particular case, for example: (.jp == .jpg)
                    [newNameWithoutExtension isEqualToString:nodeNameExtension]) {
                    shouldEnable = NO;
                } else {
                    shouldEnable = YES;
                }
                break;
            }
                
            case MEGANodeTypeFolder: {
                if ([newName isEqualToString:@""] || [newName isEqualToString:nodeNameString]) {
                    shouldEnable = NO;
                } else {
                    shouldEnable = YES;
                }
                break;
            }
                
            default:
                shouldEnable = NO;
                break;
        }
    } else {
        shouldEnable = YES;
    }
    
    return shouldEnable;
}

- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex {
    if ([alertView tag] == 0) {
        UITextField *textField = [alertView textFieldAtIndex:0];
        [textField setSelectedTextRange:nil];
    }
}


- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    
    switch ([alertView tag]) {
        case 0: {
            if (buttonIndex == 1) {
                UITextField *alertViewTextField = [alertView textFieldAtIndex:0];
                MEGANode *node = [self.selectedNodesArray objectAtIndex:0];
                [[MEGASdkManager sharedMEGASdk] renameNode:node newName:[alertViewTextField text]];
                
                if (isSearchTableViewDisplay) {
                    [self filterContentForSearchText:self.searchDisplayController.searchBar.text];
                    [self.searchDisplayController.searchResultsTableView reloadData];
                }
            }
            break;
        }
            
        case 1: {
            if (buttonIndex == 1) {
                [[MEGASdkManager sharedMEGASdk] createFolderWithName:[[folderAlertView textFieldAtIndex:0] text] parent:self.parentNode];
            }
            break;
        }
            
        case 2: {
            if (buttonIndex == 1) {
                remainingOperations = self.selectedNodesArray.count;
                for (NSInteger i = 0; i < self.selectedNodesArray.count; i++) {
                    if (self.displayMode == DisplayModeCloudDrive) {
                        [[MEGASdkManager sharedMEGASdk] moveNode:[self.selectedNodesArray objectAtIndex:i] newParent:[[MEGASdkManager sharedMEGASdk] rubbishNode]];
                    } else {
                        [[MEGASdkManager sharedMEGASdk] removeNode:[self.selectedNodesArray objectAtIndex:i]];
                    }
                }
            }
            break;
        }
        
        // Check camera permissions
        case 3: {
            if (buttonIndex == 1) {
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
            }
        }
            
        default:
            break;
    }
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    NSURL *assetURL = [info objectForKey:UIImagePickerControllerReferenceURL];
    
    // if assetURL != nil then is picked from camera roll else is a capture from camera.
    if (assetURL) {
        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
        [library assetForURL:assetURL resultBlock:^(ALAsset *asset)  {
            
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            [formatter setDateFormat:@"yyyy'-'MM'-'dd' 'HH'.'mm'.'ss"];
            NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
            [formatter setLocale:locale];
            
            NSDate *modificationTime = [asset valueForProperty:ALAssetPropertyDate];
            NSString *extension = [[[[[asset defaultRepresentation] url] absoluteString] stringBetweenString:@"&ext=" andString:@"\n"] lowercaseString];
            NSString *name = [[formatter stringFromDate:modificationTime] stringByAppendingPathExtension:extension];
            NSString *localFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:name];
            
            ALAssetRepresentation *assetRepresentation = [asset defaultRepresentation];
            
            if (!assetRepresentation) {
                return;
            }
            
            Byte *buffer = (Byte *)malloc(assetRepresentation.size);
            NSUInteger buffered = [assetRepresentation getBytes:buffer fromOffset:0 length:assetRepresentation.size error:nil];
            
            NSData *data = [NSData dataWithBytesNoCopy:buffer length:buffered freeWhenDone:YES];
            [data writeToFile:localFilePath atomically:YES];
            
            NSError *error = nil;
            NSDictionary *attributesDictionary = [NSDictionary dictionaryWithObject:modificationTime forKey:NSFileModificationDate];
            [[NSFileManager defaultManager] setAttributes:attributesDictionary ofItemAtPath:localFilePath error:&error];
            if (error) {
                [MEGASdk logWithLevel:MEGALogLevelError message:[NSString stringWithFormat:@"Error change modification date for file %@", error]];
            }
            
            [[MEGASdkManager sharedMEGASdk] startUploadWithLocalPath:localFilePath parent:self.parentNode];
        } failureBlock:nil];
    } else {
        NSString *mediaType = [info objectForKey: UIImagePickerControllerMediaType];
        
        if ([mediaType isEqualToString:(__bridge NSString *)kUTTypeMovie]) {
            NSURL *videoUrl=(NSURL*)[info objectForKey:UIImagePickerControllerMediaURL];
            NSString *moviePath = [videoUrl path];
            
            if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum (moviePath)) {
                UISaveVideoAtPathToSavedPhotosAlbum (moviePath, nil, nil, nil);
            }
            
            [[MEGASdkManager sharedMEGASdk] startUploadWithLocalPath:moviePath parent:self.parentNode];
            
        } else if ([mediaType isEqualToString:(__bridge NSString *)kUTTypeImage]) {
            
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            [formatter setDateFormat:@"yyyy'-'MM'-'dd' 'HH'.'mm'.'ss"];
            NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
            [formatter setLocale:locale];
            
            NSString *filename = [NSString stringWithFormat:@"%@.jpg",[formatter stringFromDate:[NSDate date]]];
            NSString *imagePath = [NSTemporaryDirectory() stringByAppendingPathComponent:filename];
            UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
            NSData *imageData = UIImageJPEGRepresentation(image, 1);
            [imageData writeToFile:imagePath atomically:YES];
            
            [[MEGASdkManager sharedMEGASdk] startUploadWithLocalPath:imagePath parent:self.parentNode];
        }
    }
    
    [self dismissViewControllerAnimated:YES completion:NULL];
    self.imagePickerController = nil;
}


- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    MEGANode *node = [self.selectedNodesArray objectAtIndex:0];
    NSString *nodeName = [textField text];
    UITextPosition *beginning = textField.beginningOfDocument;
    UITextRange *textRange;
    
    switch ([node type]) {
        case MEGANodeTypeFile: {
            if ([[nodeName pathExtension] isEqualToString:@""] && [nodeName isEqualToString:[nodeName stringByDeletingPathExtension]]) { //File without extension
                UITextPosition *end = textField.endOfDocument;
                textRange = [textField textRangeFromPosition:beginning  toPosition:end];
            } else {
                NSRange filenameRange = [nodeName rangeOfString:@"." options:NSBackwardsSearch];
                UITextPosition *beforeExtension = [textField positionFromPosition:beginning offset:filenameRange.location];
                textRange = [textField textRangeFromPosition:beginning  toPosition:beforeExtension];
            }
            [textField setSelectedTextRange:textRange];
            break;
        }
            
        case MEGANodeTypeFolder: {
            UITextPosition *end = textField.endOfDocument;
            textRange = [textField textRangeFromPosition:beginning  toPosition:end];
            [textField setSelectedTextRange:textRange];
            break;
        }
            
        default:
            break;
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    BOOL shouldChangeCharacters = YES;
    MEGANode *node = [self.selectedNodesArray objectAtIndex:0];
    switch ([node type]) {
        case MEGANodeTypeFile: {
            NSString *textFieldString = [textField text];
            NSString *newName = [textFieldString stringByReplacingCharactersInRange:range withString:string];
            NSString *newNameExtension = [newName pathExtension];
            NSString *newNameWithoutExtension = [newName stringByDeletingPathExtension];
            
            NSString *nodeNameString = [node name];
            NSString *nodeNameExtension = [NSString stringWithFormat:@".%@", [nodeNameString pathExtension]];
            
            NSRange nodeWithoutExtensionRange = [[textFieldString stringByDeletingPathExtension] rangeOfString:[textFieldString stringByDeletingPathExtension]];
            NSRange nodeExtensionStartRange = [textFieldString rangeOfString:@"." options:NSBackwardsSearch];
            
            if ((range.location > nodeExtensionStartRange.location) ||
                (range.length > nodeWithoutExtensionRange.length) ||
                ([newName isEqualToString:newNameExtension] && [newNameWithoutExtension isEqualToString:nodeNameExtension]) ||
                ((range.location == nodeExtensionStartRange.location) && [string isEqualToString:@""])) {
                
                UITextPosition *beginning = textField.beginningOfDocument;
                UITextPosition *beforeExtension = [textField positionFromPosition:beginning offset:nodeExtensionStartRange.location];
                [textField setSelectedTextRange:[textField textRangeFromPosition:beginning toPosition:beforeExtension]];
                shouldChangeCharacters = NO;
            } else if (range.location < nodeExtensionStartRange.location) {
                shouldChangeCharacters = YES;
            }
            break;
        }
            
        case MEGANodeTypeFolder:
            shouldChangeCharacters = YES;
            break;
            
        default:
            shouldChangeCharacters = NO;
            break;
    }
    
    return shouldChangeCharacters;
}

#pragma mark - Private methods

- (void)reloadUI {
    switch (self.displayMode) {
        case DisplayModeCloudDrive: {
            if (!self.parentNode) {
                self.parentNode = [[MEGASdkManager sharedMEGASdk] rootNode];
            }
            
            if ([self.parentNode type] == MEGANodeTypeRoot) {
                [self.navigationItem setTitle:AMLocalizedString(@"cloudDrive", @"Cloud drive")];
            } else {
                if (!self.parentNode) {
                    [self.navigationItem setTitle:AMLocalizedString(@"cloudDrive", @"Cloud drive")];
                } else {
                    [self.navigationItem setTitle:[self.parentNode name]];
                }
            }
            
            //Sort configuration by default is "default ascending"
            if (![[NSUserDefaults standardUserDefaults] integerForKey:@"SortOrderType"]) {
                [[NSUserDefaults standardUserDefaults] setInteger:1 forKey:@"SortOrderType"];
                [[NSUserDefaults standardUserDefaults] synchronize];
            }
            
            MEGASortOrderType sortOrderType = [[NSUserDefaults standardUserDefaults] integerForKey:@"SortOrderType"];
            
            self.nodes = [[MEGASdkManager sharedMEGASdk] childrenForParent:self.parentNode order:sortOrderType];
            
            break;
        }
            
        case DisplayModeRubbishBin: {
            if ([self.parentNode type] == MEGANodeTypeRubbish) {
                [self.navigationItem setTitle:AMLocalizedString(@"rubbishBinLabel", @"Rubbish bin")];
            } else {
                [self.navigationItem setTitle:[self.parentNode name]];
            }
            
            self.nodes = [[MEGASdkManager sharedMEGASdk] childrenForParent:self.parentNode];
            
            break;
        }
            
        case DisplayModeContact: {
            self.nodes = [[MEGASdkManager sharedMEGASdk] inSharesForUser:self.user];
            [self.tableView setContentOffset:CGPointMake(0, 0)];
            [self.searchDisplayController.searchBar setFrame:CGRectMake(0, 0, 0, 0)];
            break;
        }
            
        default:
            break;
    }
    
    [self.tableView reloadData];
}

- (void)showImagePickerForSourceType:(UIImagePickerControllerSourceType)sourceType {
    
    if (![UIImagePickerController isSourceTypeAvailable:sourceType]) {
        if (sourceType == UIImagePickerControllerSourceTypeCamera) {
            [SVProgressHUD showErrorWithStatus:AMLocalizedString(@"noCamera", @"No camera available")];
        }
        return;
    }
    
    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
    imagePickerController.modalPresentationStyle = UIModalPresentationCurrentContext;
    imagePickerController.sourceType = sourceType;
    imagePickerController.mediaTypes = [[NSArray alloc] initWithObjects:(NSString *)kUTTypeMovie, (NSString *)kUTTypeImage, nil];
    imagePickerController.delegate = self;
    
    self.imagePickerController = imagePickerController;
    
    if (([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) && ([imagePickerController sourceType] == UIImagePickerControllerSourceTypePhotoLibrary)) {
        UIPopoverController *popoverController = [[UIPopoverController alloc] initWithContentViewController:self.imagePickerController];
        [popoverController presentPopoverFromBarButtonItem:self.addBarButtonItem permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    } else {
        [self.tabBarController presentViewController:self.imagePickerController animated:YES completion:nil];
    }
}

- (NSString *)stringByFiles:(NSInteger)files andFolders:(NSInteger)folders {
    if (files > 1 && folders > 1) {
        return [NSString stringWithFormat:AMLocalizedString(@"foldersAndFiles", @"Folders, files"), (int)folders, (int)files];
    }
    
    if (files > 1 && folders == 1) {
        return [NSString stringWithFormat:AMLocalizedString(@"folderAndFiles", @"Folder, files"), (int)folders, (int)files];
    }
    
    if (files > 1 && !folders) {
        return [NSString stringWithFormat:AMLocalizedString(@"files", @"Files"), (int)files];
    }
    
    if (files == 1 && folders > 1) {
        return [NSString stringWithFormat:AMLocalizedString(@"foldersAndFile", @"Folders, file"), (int)folders, (int)files];
    }
    
    if (files == 1 && folders == 1) {
        return [NSString stringWithFormat:AMLocalizedString(@"folderAndFile", @"Folder, file"), (int)folders, (int)files];
    }
    
    if (files == 1 && !folders) {
        return [NSString stringWithFormat:AMLocalizedString(@"oneFile", @"File"), (int)files];
    }
    
    if (!files && folders > 1) {
        return [NSString stringWithFormat:AMLocalizedString(@"folders", @"Folders"), (int)folders];
    }
    
    if (!files && folders == 1) {
        return [NSString stringWithFormat:AMLocalizedString(@"oneFolder", @"Folder"), (int)folders];
    }
    
    return AMLocalizedString(@"emptyFolder", @"Title shown when a folder doesn't have any files");
}

- (void)toolbarActionsForShareType:(MEGAShareType )shareType {
    UIBarButtonItem *flexibleItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    lowShareType = shareType;
    
    switch (shareType) {
        case MEGAShareTypeAccessRead:
        case MEGAShareTypeAccessReadWrite: {
            if (self.displayMode == DisplayModeContact) {
                [self.toolbar setItems:@[self.downloadBarButtonItem, flexibleItem, self.moveBarButtonItem, flexibleItem, self.deleteBarButtonItem]];
            } else {
                [self.toolbar setItems:@[self.downloadBarButtonItem, flexibleItem, self.moveBarButtonItem]];                
            }
            break;
        }
            
        case MEGAShareTypeAccessFull: {
                [self.toolbar setItems:@[self.downloadBarButtonItem, flexibleItem, self.moveBarButtonItem, flexibleItem, self.renameBarButtonItem, flexibleItem, self.deleteBarButtonItem]];
            break;
        }
            
        case MEGAShareTypeAccessOwner: {
            if (self.displayMode == DisplayModeCloudDrive) {
                [self.toolbar setItems:@[self.downloadBarButtonItem, flexibleItem, self.shareBarButtonItem, flexibleItem, self.moveBarButtonItem, flexibleItem, self.renameBarButtonItem, flexibleItem, self.deleteBarButtonItem]];
            } else {
                [self.toolbar setItems:@[self.downloadBarButtonItem, flexibleItem, self.moveBarButtonItem, flexibleItem, self.renameBarButtonItem, flexibleItem, self.deleteBarButtonItem]];
            }
            
            break;
        }
            
        default:
            break;
    }
}

- (void)toolbarActionsForNodeArray:(NSArray *)nodeArray {
    MEGAShareType shareType;
    lowShareType = MEGAShareTypeAccessOwner;
    
    for (MEGANode *n in nodeArray) {
        shareType = [[MEGASdkManager sharedMEGASdk] accessLevelForNode:n];
        
        if (shareType == MEGAShareTypeAccessRead  && shareType < lowShareType) {
            lowShareType = shareType;
            break;
        }
        
        if (shareType == MEGAShareTypeAccessReadWrite && shareType < lowShareType) {
            lowShareType = shareType;
        }
        
        if (shareType == MEGAShareTypeAccessFull && shareType < lowShareType) {
            lowShareType = shareType;
            
        }
    }
    
    [self toolbarActionsForShareType:lowShareType];
}

- (void)internetConnectionChanged {
    BOOL boolValue = [MEGAReachabilityManager isReachable];
    [self setNavigationBarButtonItemsEnabled:boolValue];
    
    [self.tableView reloadData];
}

- (void)setNavigationBarButtonItemsEnabled:(BOOL)boolValue {
    switch (self.displayMode) {
        case DisplayModeCloudDrive: {
            [self.sortByBarButtonItem setEnabled:boolValue];
            [self.addBarButtonItem setEnabled:boolValue];
            [self.editBarButtonItem setEnabled:boolValue];
            break;
        }
            
        case DisplayModeContact:
            break;
            
        case DisplayModeRubbishBin: {
            [self.sortByBarButtonItem setEnabled:boolValue];
            [self.editBarButtonItem setEnabled:boolValue];
            break;
        }
    }
}

#pragma mark - IBActions

- (IBAction)selectAllAction:(UIBarButtonItem *)sender {
    [self.selectedNodesArray removeAllObjects];
    
    if (!allNodesSelected) {
        MEGANode *n = nil;
        NSInteger nodeListSize = [[self.nodes size] integerValue];
        
        for (NSInteger i = 0; i < nodeListSize; i++) {
            n = [self.nodes nodeAtIndex:i];
            [self.selectedNodesArray addObject:n];
        }
        
        allNodesSelected = YES;
        
        [self toolbarActionsForNodeArray:self.selectedNodesArray];
    } else {
        allNodesSelected = NO;
    }
    
    if (self.selectedNodesArray.count == 0) {
        [self.downloadBarButtonItem setEnabled:NO];
        [self.shareBarButtonItem setEnabled:NO];
        [self.moveBarButtonItem setEnabled:NO];
        [self.deleteBarButtonItem setEnabled:NO];
        [self.renameBarButtonItem setEnabled:NO];
        
    } else if (self.selectedNodesArray.count >= 1 ) {
        [self.downloadBarButtonItem setEnabled:YES];
        [self.shareBarButtonItem setEnabled:YES];
        [self.moveBarButtonItem setEnabled:YES];
        [self.deleteBarButtonItem setEnabled:YES];
        
        if (self.selectedNodesArray.count == 1) {
            [self.renameBarButtonItem setEnabled:YES];
        } else {
            [self.renameBarButtonItem setEnabled:NO];
        }
    }
    
    [self.tableView reloadData];
}

- (IBAction)optionAdd:(id)sender {
    UIActionSheet *actionSheet;
    
    //iOS 8+
    if (([[[UIDevice currentDevice] systemVersion] compare:@"8.0" options:NSNumericSearch] != NSOrderedAscending)) {
        actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                  delegate:self
                                         cancelButtonTitle:AMLocalizedString(@"cancel", nil)
                                    destructiveButtonTitle:nil
                                         otherButtonTitles:AMLocalizedString(@"newFolder", @"New Folder"), AMLocalizedString(@"choosePhotoVideo", @"Choose"), AMLocalizedString(@"capturePhotoVideo", @"Capture"), @"Upload a file", nil];
    
    } else {
        actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                  delegate:self
                                         cancelButtonTitle:AMLocalizedString(@"cancel", nil)
                                    destructiveButtonTitle:nil
                                         otherButtonTitles:AMLocalizedString(@"newFolder", @"New Folder"), AMLocalizedString(@"choosePhotoVideo", @"Choose"), AMLocalizedString(@"capturePhotoVideo", @"Capture"), nil];
    }
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        [actionSheet showFromBarButtonItem:self.addBarButtonItem animated:YES];
    } else {
        [actionSheet showFromTabBar:self.tabBarController.tabBar];
    }
}

- (IBAction)downloadAction:(UIBarButtonItem *)sender {
    for (MEGANode *n in self.selectedNodesArray) {
        if (![Helper isFreeSpaceEnoughToDownloadNode:n isFolderLink:NO]) {
            [self setEditing:NO animated:YES];
            return;
        }
    }
    
    [SVProgressHUD showSuccessWithStatus:AMLocalizedString(@"downloadStarted", nil)];
    
    for (MEGANode *n in self.selectedNodesArray) {
        [Helper downloadNode:n folderPath:[Helper pathForOffline] isFolderLink:NO];
    }
    
    [self setEditing:NO animated:YES];
    
    if (isSearchTableViewDisplay) {
        [self.searchDisplayController.searchResultsTableView reloadData];
    }
    
    [self.tableView reloadData];
}

- (IBAction)shareLinkAction:(UIBarButtonItem *)sender {
    exportLinks = [NSMutableArray new];
    remainingOperations = self.selectedNodesArray.count;
    
    for (MEGANode *n in self.selectedNodesArray) {
        [[MEGASdkManager sharedMEGASdk] exportNode:n];
    }
    
    if (isSearchTableViewDisplay) {
        [self filterContentForSearchText:self.searchDisplayController.searchBar.text];
        [self.searchDisplayController.searchResultsTableView reloadData];
    }
}

- (IBAction)moveCopyAction:(UIBarButtonItem *)sender {
    MEGANavigationController *navigationController = [self.storyboard instantiateViewControllerWithIdentifier:@"BrowserNavigationControllerID"];
    [self presentViewController:navigationController animated:YES completion:nil];
    
    BrowserViewController *browserVC = navigationController.viewControllers.firstObject;
    browserVC.parentNode = [[MEGASdkManager sharedMEGASdk] rootNode];
    browserVC.selectedNodesArray = [NSArray arrayWithArray:self.selectedNodesArray];
    if (lowShareType == MEGAShareTypeAccessOwner) {
        [browserVC setBrowserAction:BrowserActionMove];
    }
    
    if (isSearchTableViewDisplay) {
        [self.searchDisplayController.searchResultsTableView reloadData];
    }
}

- (IBAction)deleteAction:(UIBarButtonItem *)sender {
    if (lowShareType == MEGAShareTypeAccessFull) {
        //Leave folder or remove folder in a incoming shares
        for (NSInteger i = 0; i < self.selectedNodesArray.count; i++) {
            [[MEGASdkManager sharedMEGASdk] removeNode:[self.selectedNodesArray objectAtIndex:i]];
        }
    } else {
        NSInteger files = 0;
        NSInteger folders = 0;
        for (MEGANode *n in self.selectedNodesArray) {
            if ([n type] == MEGANodeTypeFolder) {
                folders++;
            } else {
                files++;
            }
        }
        
        if (self.displayMode == DisplayModeCloudDrive) {
            NSString *message;
            if (files == 0) {
                if (folders == 1) {
                    message = AMLocalizedString(@"moveFolderToRubbishBinMessage", nil);
                } else { //folders > 1
                    message = [NSString stringWithFormat:AMLocalizedString(@"moveFoldersToRubbishBinMessage", nil), folders];
                }
            } else if (files == 1) {
                if (folders == 0) {
                    message = AMLocalizedString(@"moveFileToRubbishBinMessage", nil);
                } else if (folders == 1) {
                    message = AMLocalizedString(@"moveFileFolderToRubbishBinMessage", nil);
                } else {
                    message = [NSString stringWithFormat:AMLocalizedString(@"moveFileFoldersToRubbishBinMessage", nil), folders];
                }
            } else {
                if (folders == 0) {
                    message = [NSString stringWithFormat:AMLocalizedString(@"moveFilesToRubbishBinMessage", nil), files];
                } else if (folders == 1) {
                    message = [NSString stringWithFormat:AMLocalizedString(@"moveFilesFolderToRubbishBinMessage", nil), files];
                } else {
                    message = [NSString stringWithFormat:AMLocalizedString(@"moveFilesFoldersToRubbishBinMessage", nil), files, folders];
                }
            }
            
            removeAlertView = [[UIAlertView alloc] initWithTitle:AMLocalizedString(@"moveNodeToRubbishBinTitle", @"Remove node from rubbish bin") message:message delegate:self cancelButtonTitle:AMLocalizedString(@"cancel", nil) otherButtonTitles:AMLocalizedString(@"ok", nil), nil];
        } else {
            NSString *message;
            if (files == 0) {
                if (folders == 1) {
                    message = AMLocalizedString(@"removeFolderToRubbishBinMessage", nil);
                } else { //folders > 1
                    message = [NSString stringWithFormat:AMLocalizedString(@"removeFoldersToRubbishBinMessage", nil), folders];
                }
            } else if (files == 1) {
                if (folders == 0) {
                    message = AMLocalizedString(@"removeFileToRubbishBinMessage", nil);
                } else if (folders == 1) {
                    message = AMLocalizedString(@"removeFileFolderToRubbishBinMessage", nil);
                } else {
                    message = [NSString stringWithFormat:AMLocalizedString(@"removeFileFoldersToRubbishBinMessage", nil), folders];
                }
            } else {
                if (folders == 0) {
                    message = [NSString stringWithFormat:AMLocalizedString(@"removeFilesToRubbishBinMessage", nil), files];
                } else if (folders == 1) {
                    message = [NSString stringWithFormat:AMLocalizedString(@"removeFilesFolderToRubbishBinMessage", nil), files];
                } else {
                    message = [NSString stringWithFormat:AMLocalizedString(@"removeFilesFoldersToRubbishBinMessage", nil), files, folders];
                }
            }
            
            removeAlertView = [[UIAlertView alloc] initWithTitle:AMLocalizedString(@"removeNodeFromRubbishBinTitle", @"Remove node from rubbish bin") message:message delegate:self cancelButtonTitle:AMLocalizedString(@"cancel", nil) otherButtonTitles:AMLocalizedString(@"ok", nil), nil];
        }
        removeAlertView.tag = 2;
        [removeAlertView show];
    }
    
    if (isSearchTableViewDisplay) {
        [self.searchDisplayController.searchResultsTableView reloadData];
    }
}

- (IBAction)renameAction:(UIBarButtonItem *)sender {
    if (!renameAlertView) {
        renameAlertView = [[UIAlertView alloc] initWithTitle:AMLocalizedString(@"rename", nil) message:AMLocalizedString(@"renameNodeMessage", @"Enter the new name") delegate:self cancelButtonTitle:AMLocalizedString(@"cancel", nil) otherButtonTitles:AMLocalizedString(@"rename", nil), nil];
    }
    
    [renameAlertView setAlertViewStyle:UIAlertViewStylePlainTextInput];
    [renameAlertView setTag:0];
    
    UITextField *textField = [renameAlertView textFieldAtIndex:0];
    [textField setDelegate:self];
    MEGANode *node = [self.selectedNodesArray objectAtIndex:0];
    [textField setText:[node name]];
    
    [renameAlertView show];
}

- (IBAction)sortByAction:(UIBarButtonItem *)sender {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Cloud" bundle:nil];
    MEGANavigationController *sortByNavigationControllerID = [storyboard instantiateViewControllerWithIdentifier:@"sortByNavigationControllerID"];
    
    [self presentViewController:sortByNavigationControllerID animated:YES completion:nil];
    
}

- (IBAction)infoTouchUpInside:(UIButton *)sender {
    MEGANode *node = nil;
    
    CGPoint buttonPosition = [sender convertPoint:CGPointZero toView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:buttonPosition];
    
    if (isSearchTableViewDisplay) {
        node = [matchSearchNodes objectAtIndex:indexPath.row];
    } else {
        node = [self.nodes nodeAtIndex:indexPath.row];
    }
    
    DetailsNodeInfoViewController *detailsNodeInfoVC = [self.storyboard instantiateViewControllerWithIdentifier:@"nodeInfoDetails"];
    [detailsNodeInfoVC setNode:node];
    [detailsNodeInfoVC setDisplayMode:self.displayMode];
    
    [self.navigationController pushViewController:detailsNodeInfoVC animated:YES];
}

#pragma mark - Content Filtering

- (void)filterContentForSearchText:(NSString*)searchText {
    [matchSearchNodes removeAllObjects];
    MEGANodeList *allNodeList = nil;
    
    allNodeList = [[MEGASdkManager sharedMEGASdk] nodeListSearchForNode:self.parentNode searchString:searchText recursive:YES];
    
    for (NSInteger i = 0; i < [allNodeList.size integerValue]; i++) {
        MEGANode *n = [allNodeList nodeAtIndex:i];
        [matchSearchNodes addObject:n];
    }
    
}

#pragma mark - UISearchDisplayDelegate

- (void)searchDisplayControllerDidEndSearch:(UISearchDisplayController *)controller {
    [self.tableView insertSubview:self.searchDisplayController.searchBar aboveSubview:self.tableView];
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleSingleLine];
}

- (void)searchDisplayController:(UISearchDisplayController *)controller willShowSearchResultsTableView:(UITableView *)tableView {
    isSearchTableViewDisplay = YES;
}

- (void)searchDisplayController:(UISearchDisplayController *)controller willHideSearchResultsTableView:(UITableView *)tableView {
    isSearchTableViewDisplay = NO;
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString {
    [self filterContentForSearchText:searchString];
    
    return YES;
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption {
    [self filterContentForSearchText:self.searchDisplayController.searchBar.text];
    
    return YES;
}

#pragma mark - Movie player

- (void)movieFinishedCallback:(NSNotification*)aNotification {
    MPMoviePlayerController *moviePlayer = [aNotification object];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:MPMoviePlayerPlaybackDidFinishNotification
                                                  object:moviePlayer];
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UIDocumentPickerDelegate

- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentAtURL:(NSURL *)url {
    if (controller.documentPickerMode == UIDocumentPickerModeImport) {
        NSString *localFilePath = [url path];
        
        NSString *crcLocal = [[MEGASdkManager sharedMEGASdk] CRCForFilePath:localFilePath];
        MEGANode *node = [[MEGASdkManager sharedMEGASdk] nodeByCRC:crcLocal parent:self.parentNode];
        
        // If file doesn't exist in MEGA then upload it
        if (node == nil) {
            UIAlertView *toastAlertView = [[UIAlertView alloc] initWithTitle:nil
                                                                     message:AMLocalizedString(@"uploadStarted_Message", @"Message shown when the user select upload a file")
                                                                    delegate:nil
                                                           cancelButtonTitle:nil
                                                           otherButtonTitles:nil, nil];
            [toastAlertView show];
            
            int duration = 1; // duration in seconds
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, duration * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                [toastAlertView dismissWithClickedButtonIndex:0 animated:YES];
            });
            [[MEGASdkManager sharedMEGASdk] startUploadWithLocalPath:localFilePath parent:self.parentNode];
        } else {
            if ([node.name isEqualToString:url.lastPathComponent]) {
                NSError *error = nil;
                BOOL success = [[NSFileManager defaultManager] removeItemAtPath:localFilePath error:&error];
                if (!success || error) {
                    [MEGASdk logWithLevel:MEGALogLevelError message:[NSString stringWithFormat:@"Remove file error %@", error]];
                }
                
                NSString *alertMessage = [NSString stringWithFormat:AMLocalizedString(@"fileExistAlertController_Message", nil), [url lastPathComponent]];
                dispatch_async(dispatch_get_main_queue(), ^{
                    UIAlertController *alertController = [UIAlertController
                                                          alertControllerWithTitle:nil
                                                          message:alertMessage
                                                          preferredStyle:UIAlertControllerStyleAlert];
                    [alertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"OK", @"Ok") style:UIAlertActionStyleDefault handler:nil]];
                    [self presentViewController:alertController animated:YES completion:nil];
                });
            } else {
                [[MEGASdkManager sharedMEGASdk] copyNode:node newParent:self.parentNode newName:url.lastPathComponent];
            }
        }
    }
}

#pragma mark - UIDocumentMenuDelegate

- (void)documentMenu:(UIDocumentMenuViewController *)documentMenu didPickDocumentPicker:(UIDocumentPickerViewController *)documentPicker {
    documentPicker.delegate = self;
    [self presentViewController:documentPicker animated:YES completion:nil];
}

#pragma mark - MEGARequestDelegate

- (void)onRequestStart:(MEGASdk *)api request:(MEGARequest *)request {
    switch ([request type]) {
        case MEGARequestTypeExport:
            [SVProgressHUD showWithStatus:AMLocalizedString(@"generatingLink", @"Generating link...")];
            break;
            
        default:
            break;
    }
}

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    if ([error type]) {
        if ([error type] == MEGAErrorTypeApiEAccess) {
            if ([request type] == MEGARequestTypeCreateFolder || [request type] == MEGARequestTypeUpload) {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:AMLocalizedString(@"permissionTitle", nil) message:AMLocalizedString(@"permissionMessage", nil) delegate:self cancelButtonTitle:AMLocalizedString(@"ok", nil) otherButtonTitles:nil, nil];
                [alertView show];
            }
        }
        return;
    }
    
    switch ([request type]) {
            
        case MEGARequestTypeGetAttrFile: {
            for (NodeTableViewCell *ntvc in [self.tableView visibleCells]) {
                if ([request nodeHandle] == [ntvc nodeHandle]) {
                    MEGANode *node = [[MEGASdkManager sharedMEGASdk] nodeForHandle:[request nodeHandle]];
                    NSString *thumbnailFilePath = [Helper pathForNode:node searchPath:NSCachesDirectory directory:@"thumbnailsV3"];
                    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:thumbnailFilePath];
                    if (fileExists) {
                        [ntvc.thumbnailImageView setImage:[UIImage imageWithContentsOfFile:thumbnailFilePath]];
                    }
                }
            }
            
            for (NodeTableViewCell *ntvc in [self.searchDisplayController.searchResultsTableView visibleCells]) {
                if ([request nodeHandle] == [ntvc nodeHandle]) {
                    MEGANode *node = [[MEGASdkManager sharedMEGASdk] nodeForHandle:[request nodeHandle]];
                    NSString *thumbnailFilePath = [Helper pathForNode:node searchPath:NSCachesDirectory directory:@"thumbnailsV3"];
                    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:thumbnailFilePath];
                    if (fileExists) {
                        [ntvc.thumbnailImageView setImage:[UIImage imageWithContentsOfFile:thumbnailFilePath]];
                    }
                }
            }
            
            break;
        }
            
        case MEGARequestTypeMove: {
            remainingOperations--;
            if (remainingOperations == 0) {
                NSString *message = (self.selectedNodesArray.count <= 1 ) ? AMLocalizedString(@"fileMovedToRubbishBin", nil) : [NSString stringWithFormat:AMLocalizedString(@"filesMovedToRubbishBin", nil), self.selectedNodesArray.count];
                [SVProgressHUD showSuccessWithStatus:message];
                [self setEditing:NO animated:NO];
            }
            break;
        }
            
        case MEGARequestTypeRemove: {
            remainingOperations--;
            if (remainingOperations == 0) {
                NSString *message;
                if (self.displayMode == DisplayModeCloudDrive || self.displayMode == DisplayModeRubbishBin) {
                    message = (self.selectedNodesArray.count <= 1 ) ? AMLocalizedString(@"fileRemovedFromRubbishBin", nil) : [NSString stringWithFormat:AMLocalizedString(@"filesRemovedFromRubbishBin", nil), self.selectedNodesArray.count];
                } else {
                    message = AMLocalizedString(@"shareFolderLeaved", @"Folder leave!");
                }
                [SVProgressHUD showSuccessWithStatus:message];
                [self setEditing:NO animated:NO];
            }
            break;
        }
            
        case MEGARequestTypeExport: {
            remainingOperations--;
            
            MEGANode *n = [[MEGASdkManager sharedMEGASdk] nodeForHandle:request.nodeHandle];
            
            NSString *name = [NSString stringWithFormat:@"%@: %@", AMLocalizedString(@"name", nil), n.name];
            
            NSString *size = [NSString stringWithFormat:@"%@: %@", AMLocalizedString(@"size", nil), n.isFile ? [NSByteCountFormatter stringFromByteCount:[[n size] longLongValue]  countStyle:NSByteCountFormatterCountStyleMemory] : AMLocalizedString(@"folder", nil)];
            
            NSString *link = [request link];
            
            NSArray *tempArray = [NSArray arrayWithObjects:[NSString stringWithFormat:@"%@ \n %@ \n %@\n", name, size, link], nil];
            [exportLinks addObjectsFromArray:tempArray];
            
            if (remainingOperations == 0) {
                [SVProgressHUD dismiss];
                UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:exportLinks applicationActivities:nil];
                activityVC.excludedActivityTypes = @[UIActivityTypePrint, UIActivityTypeAssignToContact, UIActivityTypeSaveToCameraRoll];
                
                if ([activityVC respondsToSelector:@selector(popoverPresentationController)]) {
                    activityVC.popoverPresentationController.barButtonItem = self.moveBarButtonItem;
                }
                
                [self presentViewController:activityVC animated:YES completion:nil ];
                [self setEditing:NO animated:NO];
            }
            break;
        }
            
        case MEGARequestTypeRename:
            if (isSearchTableViewDisplay) {
                [self filterContentForSearchText:self.searchDisplayController.searchBar.text];
                [self.searchDisplayController.searchResultsTableView reloadData];
            }
            
        default:
            break;
    }
}

- (void)onRequestTemporaryError:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
}

#pragma mark - MEGAGlobalDelegate

- (void)onReloadNeeded:(MEGASdk *)api {
}

- (void)onNodesUpdate:(MEGASdk *)api nodeList:(MEGANodeList *)nodeList {
    [self.nodesIndexPathMutableDictionary removeAllObjects];
    [self reloadUI];
}


#pragma mark - MEGATransferDelegate

- (void)onTransferStart:(MEGASdk *)api transfer:(MEGATransfer *)transfer {
    if (transfer.type == MEGATransferTypeDownload && !transfer.isStreamingTransfer) {
        NSString *base64Handle = [MEGASdk base64HandleForHandle:transfer.nodeHandle];
        NSIndexPath *indexPath = [self.nodesIndexPathMutableDictionary objectForKey:base64Handle];
        if (indexPath != nil) {
            [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
        }
    }
}

- (void)onTransferUpdate:(MEGASdk *)api transfer:(MEGATransfer *)transfer {
    NSString *base64Handle = [MEGASdk base64HandleForHandle:transfer.nodeHandle];
    
    if (transfer.type == MEGATransferTypeDownload  && !transfer.isStreamingTransfer && [[Helper downloadingNodes] objectForKey:base64Handle]) {
        float percentage = ([[transfer transferredBytes] floatValue] / [[transfer totalBytes] floatValue] * 100);
        NSString *percentageCompleted = [NSString stringWithFormat:@"%.f%%", percentage];
        NSString *speed = [NSString stringWithFormat:@"%@/s", [NSByteCountFormatter stringFromByteCount:[[transfer speed] longLongValue]  countStyle:NSByteCountFormatterCountStyleMemory]];
        
        NSIndexPath *indexPath = [self.nodesIndexPathMutableDictionary objectForKey:base64Handle];
        if (indexPath != nil) {
            NodeTableViewCell *cell = (NodeTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
            [cell.infoLabel setText:[NSString stringWithFormat:@"%@ • %@", percentageCompleted, speed]];
        }
    }
}

- (void)onTransferFinish:(MEGASdk *)api transfer:(MEGATransfer *)transfer error:(MEGAError *)error {
    if (transfer.isStreamingTransfer) {
        return;
    }
    
    if ([error type]) {
        if ([error type] == MEGAErrorTypeApiEAccess) {
            if ([transfer type] ==  MEGATransferTypeUpload) {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:AMLocalizedString(@"permissionTitle", nil) message:AMLocalizedString(@"permissionMessage", nil) delegate:self cancelButtonTitle:AMLocalizedString(@"ok", nil) otherButtonTitles:nil, nil];
                [alertView show];
            }
        } else if ([error type] == MEGAErrorTypeApiEIncomplete) {
            [SVProgressHUD showSuccessWithStatus:AMLocalizedString(@"transferCanceled", @"Transfer canceled")];
            NSString *base64Handle = [MEGASdk base64HandleForHandle:transfer.nodeHandle];
            NSIndexPath *indexPath = [self.nodesIndexPathMutableDictionary objectForKey:base64Handle];
            if (indexPath != nil) {
                [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
            }
        }
        return;
    }
    
    if ([transfer type] == MEGATransferTypeDownload) {
        NSString *base64Handle = [MEGASdk base64HandleForHandle:transfer.nodeHandle];
        NSIndexPath *indexPath = [self.nodesIndexPathMutableDictionary objectForKey:base64Handle];
        if (indexPath != nil) {
            [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
        }
    } else if ([transfer type] == MEGATransferTypeUpload) {
        if ([[transfer fileName] isEqualToString:@"capturedvideo.MOV"]) {
            MEGANode *node = [[MEGASdkManager sharedMEGASdk] nodeForHandle:[transfer nodeHandle]];
            
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            [formatter setDateFormat:@"yyyy'-'MM'-'dd' 'HH'.'mm'.'ss"];
            NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
            [formatter setLocale:locale];
            NSString *name = [[formatter stringFromDate:node.modificationTime] stringByAppendingPathExtension:@"MOV"];
            [[MEGASdkManager sharedMEGASdk] renameNode:node newName:name];
        } 
    }
}

- (void)onTransferTemporaryError:(MEGASdk *)api transfer:(MEGATransfer *)transfer error:(MEGAError *)error {
}

@end
