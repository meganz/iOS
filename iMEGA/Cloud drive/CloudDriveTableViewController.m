/**
 * @file CloudDriveTableViewController.m
 * @brief Cloud drive table view controller of the app.
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

#import <AssetsLibrary/AssetsLibrary.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <AVFoundation/AVCaptureDevice.h>
#import <AVFoundation/AVMediaFormat.h>
#import <QuickLook/QuickLook.h>

#import "MWPhotoBrowser.h"
#import "SVProgressHUD.h"
#import "UIScrollView+EmptyDataSet.h"
#import "CTAssetsPickerController.h"

#import "NSMutableAttributedString+MNZCategory.h"
#import "NSString+MNZCategory.h"

#import "Helper.h"
#import "MEGAAVViewController.h"
#import "MEGANavigationController.h"
#import "MEGAPreview.h"
#import "MEGAQLPreviewControllerTransitionAnimator.h"
#import "MEGAReachabilityManager.h"
#import "MEGAStore.h"

#import "BrowserViewController.h"
#import "CloudDriveTableViewController.h"
#import "DetailsNodeInfoViewController.h"
#import "NodeTableViewCell.h"
#import "PhotosViewController.h"
#import "PreviewDocumentViewController.h"

@interface CloudDriveTableViewController () <UIActionSheetDelegate, UIAlertViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate, UISearchDisplayDelegate, UIViewControllerTransitioningDelegate, UIDocumentPickerDelegate, UIDocumentMenuDelegate, QLPreviewControllerDelegate, QLPreviewControllerDataSource, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, MWPhotoBrowserDelegate, MEGADelegate, CTAssetsPickerControllerDelegate> {
    UIAlertView *folderAlertView;
    UIAlertView *removeAlertView;
    UIAlertView *renameAlertView;
    
    NSUInteger remainingOperations;
    
    NSMutableArray *matchSearchNodes;
    
    BOOL allNodesSelected;
    BOOL isSwipeEditing;
    
    MEGAShareType lowShareType; //Control the actions allowed for node/nodes selected
    
    NSString *previewDocumentPath;
    
    NSUInteger numFilesAction, numFoldersAction;
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

@end

@implementation CloudDriveTableViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.emptyDataSetSource = self;
    self.tableView.emptyDataSetDelegate = self;
    
    self.searchDisplayController.searchResultsTableView.emptyDataSetSource = self;
    self.searchDisplayController.searchResultsTableView.emptyDataSetDelegate = self;
    self.searchDisplayController.searchResultsTableView.tableFooterView = [UIView new];
    [self.searchDisplayController setValue:@"" forKey:@"_noResultsMessage"];
    
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
            if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad || iPhone6Plus) {
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
            [self.moveBarButtonItem setImage:[UIImage imageNamed:@"copy"]];
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
            MEGALogError(@"Create directory at path: %@", error);
        }
    }
    
    NSString *previewsDirectory = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"previewsV3"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:previewsDirectory]) {
        if (![[NSFileManager defaultManager] createDirectoryAtPath:previewsDirectory withIntermediateDirectories:NO attributes:nil error:&error]) {
            MEGALogError(@"Create directory at path: %@", error);
        }
    }
    
    self.nodesIndexPathMutableDictionary = [[NSMutableDictionary alloc] init];
    
    matchSearchNodes = [[NSMutableArray alloc] init];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(internetConnectionChanged) name:kReachabilityChangedNotification object:nil];
    
    [[MEGASdkManager sharedMEGASdk] addMEGADelegate:self];
    [[MEGASdkManager sharedMEGASdk] retryPendingConnections];
    
    [self reloadUI];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
    
    [[MEGASdkManager sharedMEGASdk] removeMEGADelegate:self];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    if (self.tableView.isEditing) {
        self.selectedNodesArray = nil;
        [self setEditing:NO animated:NO];
    }
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
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
            [self.searchDisplayController.searchResultsTableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
        } else {
            [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
        }
    } else {
        if (tableView == self.searchDisplayController.searchResultsTableView) {
            [self.searchDisplayController.searchResultsTableView setSeparatorStyle:UITableViewCellSeparatorStyleSingleLine];
        }
        
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
    
    BOOL isDownloaded = NO;
    
    NodeTableViewCell *cell;
    if ([[Helper downloadingNodes] objectForKey:node.base64Handle] != nil) {
        cell = [self.tableView dequeueReusableCellWithIdentifier:@"downloadingNodeCell" forIndexPath:indexPath];
        if (cell == nil) {
            cell = [[NodeTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"downloadingNodeCell"];
        }
        
        [cell.downloadingArrowImageView setImage:[UIImage imageNamed:@"downloadQueued"]];
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
            isDownloaded = YES;
        }
        
        cell.infoLabel.text = [Helper sizeAndDateForNode:node api:[MEGASdkManager sharedMEGASdk]];
    }
    
    if ([node isExported]) {
        if (isDownloaded) {
            [cell.upImageView setImage:[UIImage imageNamed:@"linked"]];
            [cell.middleImageView setImage:nil];
            [cell.downImageView setImage:[Helper downloadedArrowImage]];
        } else {
            [cell.upImageView setImage:nil];
            [cell.middleImageView setImage:[UIImage imageNamed:@"linked"]];
            [cell.downImageView setImage:nil];
        }
    } else {
        [cell.upImageView setImage:nil];
        [cell.downImageView setImage:nil];
        
        if (isDownloaded) {
            [cell.middleImageView setImage:[Helper downloadedArrowImage]];
        } else {
            [cell.middleImageView setImage:nil];
        }
    }
    
    UIView *view = [[UIView alloc] init];
    [view setBackgroundColor:[UIColor mnz_grayF7F7F7]];
    [cell setSelectedBackgroundView:view];
    [cell setSeparatorInset:UIEdgeInsetsMake(0.0, 60.0, 0.0, 0.0)];
    
    cell.nameLabel.text = [node name];
    
    [cell.thumbnailImageView.layer setCornerRadius:4];
    [cell.thumbnailImageView.layer setMasksToBounds:YES];
    
    [cell.thumbnailPlayImageView setHidden:YES];
    
    if ([node type] == MEGANodeTypeFile) {
        if ([node hasThumbnail]) {
            [Helper thumbnailForNode:node api:[MEGASdkManager sharedMEGASdk] cell:cell];
        } else {
            [cell.thumbnailImageView setImage:[Helper imageForNode:node]];
        }
    } else if ([node type] == MEGANodeTypeFolder) {
        [cell.thumbnailImageView setImage:[Helper imageForNode:node]];
        
        cell.infoLabel.text = [Helper filesAndFoldersInFolderNode:node api:[MEGASdkManager sharedMEGASdk]];
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
        [self.shareBarButtonItem setEnabled:((self.selectedNodesArray.count < 100) ? YES : NO)];
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
            CloudDriveTableViewController *cdvc = [self.storyboard instantiateViewControllerWithIdentifier:@"CloudDriveID"];
            [cdvc setParentNode:node];
            
            if (self.displayMode == DisplayModeRubbishBin) {
                [cdvc setDisplayMode:self.displayMode];
            }
            
            [self.navigationController pushViewController:cdvc animated:YES];
            break;
        }
            
        case MEGANodeTypeFile: {
            
            NSString *name = [node name];
            CFStringRef fileUTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef _Nonnull)([name pathExtension]), NULL);
            if (UTTypeConformsTo(fileUTI, kUTTypeImage)) {
                
                int offsetIndex = 0;
                self.cloudImages = [NSMutableArray new];
                
                if (tableView == self.searchDisplayController.searchResultsTableView) {
                    for (NSInteger i = 0; i < matchSearchNodes.count; i++) {
                        MEGANode *n = [matchSearchNodes objectAtIndex:i];
                        
                        if (fileUTI) {
                            CFRelease(fileUTI);
                        }
                        
                        fileUTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef _Nonnull)([n.name pathExtension]), NULL);
                        
                        if (UTTypeConformsTo(fileUTI, kUTTypeImage) && [n type] == MEGANodeTypeFile) {
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
                        
                        if (fileUTI) {
                            CFRelease(fileUTI);
                        }
                        
                        fileUTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef _Nonnull)([n.name pathExtension]), NULL);
                        
                        if (UTTypeConformsTo(fileUTI, kUTTypeImage) && [n type] == MEGANodeTypeFile) {
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
            } else {
                MOOfflineNode *offlineNodeExist = [[MEGAStore shareInstance] fetchOfflineNodeWithFingerprint:[[MEGASdkManager sharedMEGASdk] fingerprintForNode:node]];
                
                if (offlineNodeExist) {
                    if (!isMultimedia(node.name.pathExtension)) {
                        previewDocumentPath = [[Helper pathForOffline] stringByAppendingPathComponent:offlineNodeExist.localPath];
                        
                        QLPreviewController *previewController = [[QLPreviewController alloc] init];
                        [previewController setDelegate:self];
                        [previewController setDataSource:self];
                        [previewController setTransitioningDelegate:self];
                        [previewController setTitle:name];
                        [self presentViewController:previewController animated:YES completion:nil];
                    } else {
                        NSURL *path = [NSURL fileURLWithPath:[[Helper pathForOffline] stringByAppendingString:offlineNodeExist.localPath]];
                        MEGAAVViewController *megaAVViewController = [[MEGAAVViewController alloc] initWithURL:path];
                        [self presentViewController:megaAVViewController animated:YES completion:nil];
                        if (fileUTI) {
                            CFRelease(fileUTI);
                        }
                        return;
                    }
                } else if (UTTypeConformsTo(fileUTI, kUTTypeAudiovisualContent) && [[MEGASdkManager sharedMEGASdk] httpServerStart:YES port:4443]) {
                    MEGAAVViewController *megaAVViewController = [[MEGAAVViewController alloc] initWithNode:node folderLink:NO];
                    [self presentViewController:megaAVViewController animated:YES completion:nil];
                    
                    if (fileUTI) {
                        CFRelease(fileUTI);
                    }
                    return;
                } else {
                    if ([[[[MEGASdkManager sharedMEGASdk] transfers] size] integerValue] > 0) {
                        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:AMLocalizedString(@"documentOpening_alertTitle", nil)
                                                                            message:AMLocalizedString(@"documentOpening_alertMessage", nil)
                                                                           delegate:nil
                                                                  cancelButtonTitle:AMLocalizedString(@"ok", nil)
                                                                  otherButtonTitles:nil, nil];
                        [alertView show];
                    } else {
                        // There isn't enough space in the device for preview the document
                        if (![Helper isFreeSpaceEnoughToDownloadNode:node isFolderLink:NO]) {
                            if (fileUTI) {
                                CFRelease(fileUTI);
                            }
                            return;
                        }
                        
                        PreviewDocumentViewController *previewDocumentVC = [self.storyboard instantiateViewControllerWithIdentifier:@"previewDocumentID"];
                        [previewDocumentVC setNode:node];
                        [previewDocumentVC setApi:[MEGASdkManager sharedMEGASdk]];
                        
                        [self.navigationController pushViewController:previewDocumentVC animated:YES];
                        
                        [tableView deselectRowAtIndexPath:indexPath animated:YES];
                    }
                } 
            }
            
            if (fileUTI) {
                CFRelease(fileUTI);
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
    if (self.displayMode != DisplayModeContact) {
        MEGANode *node;
        if (tableView == self.searchDisplayController.searchResultsTableView) {
            node = [matchSearchNodes objectAtIndex:indexPath.row];
        } else {
            node = [self.nodes nodeAtIndex:indexPath.row];
        }
        MEGAShareType accessType = [[MEGASdkManager sharedMEGASdk] accessLevelForNode:node];
        if (accessType >= MEGAShareTypeAccessFull) {
            return AMLocalizedString(@"remove", nil);
        }
    } else {
        return AMLocalizedString(@"leaveFolder", @"Leave folder");
    }
    
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
        
        if ([node isFolder]) {
            numFoldersAction = 1;
            numFilesAction = 0;
        } else {
            numFilesAction = 1;
            numFoldersAction = 0;
        }
        
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
    NSString *text;
    if ([MEGAReachabilityManager isReachable]) {
        if (self.parentNode == nil) {
            return nil;
        }
        
        if ([self.searchDisplayController isActive]) {
            text = AMLocalizedString(@"noResults", nil);
        } else {
            switch (self.displayMode) {
                case DisplayModeCloudDrive: {
                    if ([self.parentNode type] == MEGANodeTypeRoot) {
                        return [NSMutableAttributedString mnz_darkenSectionTitleInString:AMLocalizedString(@"cloudDriveEmptyState_title", @"Title shown when your Cloud Drive is empty, when you don't have any files.") sectionTitle:AMLocalizedString(@"cloudDrive", @"Title of the Cloud Drive section")];
                    } else {
                        text = AMLocalizedString(@"emptyFolder", @"Title shown when a folder doesn't have any files");
                    }
                    break;
                }
                    
                case DisplayModeContact:
                    text = AMLocalizedString(@"emptyFolder", @"Title shown when a folder doesn't have any files");
                    break;
                    
                case DisplayModeRubbishBin:
                    if ([self.parentNode type] == MEGANodeTypeRubbish) {
                        return [NSMutableAttributedString mnz_darkenSectionTitleInString:AMLocalizedString(@"cloudDriveEmptyState_titleRubbishBin", @"Title shown when your Rubbish Bin is empty.") sectionTitle:AMLocalizedString(@"rubbishBinLabel", @"Title of one of the Settings sections where you can see your MEGA 'Rubbish Bin'")];
                    } else {
                        text = AMLocalizedString(@"emptyFolder", @"Title shown when a folder doesn't have any files");
                    }
                    break;
                    
                default:
                    break;
            }
        }
    } else {
        text = AMLocalizedString(@"noInternetConnection",  @"No Internet Connection");
    }
    
    NSDictionary *attributes = @{NSFontAttributeName:[UIFont fontWithName:kFont size:18.0], NSForegroundColorAttributeName:[UIColor mnz_gray999999]};
    
    return [[NSAttributedString alloc] initWithString:text attributes:attributes];
}

- (UIImage *)imageForEmptyDataSet:(UIScrollView *)scrollView {
    UIImage *image = nil;
    if ([MEGAReachabilityManager isReachable]) {
        if (self.parentNode == nil) {
            return nil;
        }
        
        if ([self.searchDisplayController isActive]) {
            image = [UIImage imageNamed:@"emptySearch"];
        } else {
            switch (self.displayMode) {
                case DisplayModeCloudDrive: {
                    if ([self.parentNode type] == MEGANodeTypeRoot) {
                        image = [UIImage imageNamed:@"emptyCloudDrive"];
                    } else {
                        image = [UIImage imageNamed:@"emptyFolder"];
                    }
                    break;
                }
                    
                case DisplayModeContact:
                    image = [UIImage imageNamed:@"emptyFolder"];
                    break;
                    
                case DisplayModeRubbishBin: {
                    if ([self.parentNode type] == MEGANodeTypeRubbish) {
                        image = [UIImage imageNamed:@"emptyRubbishBin"];
                    } else {
                        image = [UIImage imageNamed:@"emptyFolder"];
                    }
                    break;
                }
                    
                default:
                    break;
            }
        }
    } else {
         image = [UIImage imageNamed:@"noInternetConnection"];
    }
    
    return image;
}

- (NSAttributedString *)buttonTitleForEmptyDataSet:(UIScrollView *)scrollView forState:(UIControlState)state {
    NSString *text = @"";
    if ([MEGAReachabilityManager isReachable]) {
        if (self.parentNode == nil) {
            return nil;
        }
        
        switch (self.displayMode) {
            case DisplayModeCloudDrive: {
                if (![self.searchDisplayController isActive]) {
                    text = AMLocalizedString(@"addFiles", nil);
                }
                break;
            }
                
            default:
                text = @"";
                break;
        }
        
    }
    
    NSDictionary *attributes = @{NSFontAttributeName:[UIFont fontWithName:kFont size:20.0f], NSForegroundColorAttributeName:[UIColor mnz_gray777777]};
    
    return [[NSAttributedString alloc] initWithString:text attributes:attributes];
}

- (UIImage *)buttonBackgroundImageForEmptyDataSet:(UIScrollView *)scrollView forState:(UIControlState)state {
    UIEdgeInsets capInsets = UIEdgeInsetsMake(10.0, 54.0, 12.0, 54.0);
    UIEdgeInsets rectInsets;
    if (iPhone4X || iPhone5X || iPhone6 || iPhone6Plus) {
        rectInsets = UIEdgeInsetsMake(0.0, -20.0, 0.0, -20.0);
    } else  if (iPad) {
        rectInsets = UIEdgeInsetsMake(0.0, -182.0, 0.0, -182.0);
    } else if (iPadPro) {
        rectInsets = UIEdgeInsetsMake(0.0, -310.0, 0.0, -310.0);
    }
    
    return [[[UIImage imageNamed:@"buttonBorder"] resizableImageWithCapInsets:capInsets resizingMode:UIImageResizingModeStretch] imageWithAlignmentRectInsets:rectInsets];
}

- (UIColor *)backgroundColorForEmptyDataSet:(UIScrollView *)scrollView {
    return [UIColor whiteColor];
}

- (CGFloat)verticalOffsetForEmptyDataSet:(UIScrollView *)scrollView {
    if ([self.searchDisplayController isActive]) {
        return -66.0;
    }
    
    return 0.0f;
}

- (CGFloat)spaceHeightForEmptyDataSet:(UIScrollView *)scrollView {
    return 40.0f;
}

#pragma mark - DZNEmptyDataSetDelegate Methods

- (void)emptyDataSet:(UIScrollView *)scrollView didTapButton:(UIButton *)button {
    switch (self.displayMode) {
        case DisplayModeCloudDrive: {
            [self optionAdd:_addBarButtonItem];
            break;
        }
            
        default:
            break;
    }
}

#pragma mark - MWPhotoBrowserDelegate

- (NSUInteger)numberOfPhotosInPhotoBrowser:(MWPhotoBrowser *)photoBrowser {
    return self.cloudImages.count;
}

- (id <MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index {
    if (index < self.cloudImages.count) {
        MEGAPreview *preview = [self.cloudImages objectAtIndex:index];
        preview.isGridMode = NO;
        return preview;
    }
    
    return nil;
}

- (id <MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser thumbPhotoAtIndex:(NSUInteger)index {
    MEGAPreview *thumbnail = [self.cloudImages objectAtIndex:index];
    thumbnail.isGridMode = YES;
    return thumbnail;
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    switch (buttonIndex) {
        //New folder
        case 0:
            folderAlertView = [[UIAlertView alloc] initWithTitle:AMLocalizedString(@"newFolder", @"New Folder")
                                                         message:nil
                                                        delegate:self
                                               cancelButtonTitle:AMLocalizedString(@"cancel", nil)
                                               otherButtonTitles:AMLocalizedString(@"createFolderButton", @"Create"), nil];
            [folderAlertView setAlertViewStyle:UIAlertViewStylePlainTextInput];
            [folderAlertView textFieldAtIndex:0].placeholder = AMLocalizedString(@"newFolderMessage", nil);
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
                if ([documentMenuViewController respondsToSelector:@selector(popoverPresentationController)]) {
                    documentMenuViewController.popoverPresentationController.barButtonItem = self.addBarButtonItem;
                } else {
                    documentMenuViewController.modalPresentationStyle = UIModalPresentationFormSheet;
                }

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
            [button setTitleColor:[UIColor mnz_redD90007] forState:UIControlStateNormal];
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
                if ([MEGAReachabilityManager isReachable]) {
                    UITextField *alertViewTextField = [alertView textFieldAtIndex:0];
                    MEGANode *node = [self.selectedNodesArray objectAtIndex:0];
                    [[MEGASdkManager sharedMEGASdk] renameNode:node newName:[alertViewTextField text]];
                    
                    if ([self.searchDisplayController isActive]) {
                        [self filterContentForSearchText:self.searchDisplayController.searchBar.text];
                        [self.searchDisplayController.searchResultsTableView reloadData];
                    }
                } else {
                    [SVProgressHUD showImage:[UIImage imageNamed:@"hudForbidden"] status:AMLocalizedString(@"noInternetConnection", nil)];
                }
            }
            break;
        }
            
        case 1: {
            if (buttonIndex == 1) {
                if ([MEGAReachabilityManager isReachable]) {
                    [[MEGASdkManager sharedMEGASdk] createFolderWithName:[[folderAlertView textFieldAtIndex:0] text] parent:self.parentNode];
                } else {
                    [SVProgressHUD showImage:[UIImage imageNamed:@"hudForbidden"] status:AMLocalizedString(@"noInternetConnection", nil)];
                }
            }
            break;
        }
            
        case 2: {
            if (buttonIndex == 1) {
                if ([MEGAReachabilityManager isReachable]) {
                    remainingOperations = self.selectedNodesArray.count;
                    for (NSInteger i = 0; i < self.selectedNodesArray.count; i++) {
                        if (self.displayMode == DisplayModeCloudDrive) {
                            [[MEGASdkManager sharedMEGASdk] moveNode:[self.selectedNodesArray objectAtIndex:i] newParent:[[MEGASdkManager sharedMEGASdk] rubbishNode]];
                        } else {
                            [[MEGASdkManager sharedMEGASdk] removeNode:[self.selectedNodesArray objectAtIndex:i]];
                        }
                    }                } else {
                    [SVProgressHUD showImage:[UIImage imageNamed:@"hudForbidden"] status:AMLocalizedString(@"noInternetConnection", nil)];
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

#pragma mark - CTAssetsPickerControllerDelegate

- (void)assetsPickerController:(CTAssetsPickerController *)picker didFinishPickingAssets:(NSArray *)assets {
    if (assets.count==0) {
        [self dismissViewControllerAnimated:YES completion:nil];
        return;
    }
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy'-'MM'-'dd' 'HH'.'mm'.'ss"];
    NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    [formatter setLocale:locale];
    
    [self dismissViewControllerAnimated:YES completion:^{
        NSString *nameExist = nil;
        int numFilesExist = 0;
        BOOL startUpload = NO;
        
        for (ALAsset *asset in assets) {
            NSDate *modificationTime = [asset valueForProperty:ALAssetPropertyDate];
            ALAssetRepresentation *assetRepresentation = [asset defaultRepresentation];
            NSString *extension = [[[[[asset defaultRepresentation] url] absoluteString] mnz_stringBetweenString:@"&ext=" andString:@"\n"] lowercaseString];
            NSString *name = [[formatter stringFromDate:modificationTime] stringByAppendingPathExtension:extension];
            NSString *localFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:name];
            
            NSString *localFingerprint = [[MEGASdkManager sharedMEGASdk] fingerprintForAssetRepresentation:assetRepresentation modificationTime:modificationTime];
            
            MEGANode *node = [[MEGASdkManager sharedMEGASdk] nodeForFingerprint:localFingerprint parent:self.parentNode];
            
            if (node == nil) {
                
                long long asize = assetRepresentation.size;
                long long freeSpace = (long long)[Helper freeDiskSpace];
                
                if (asize > freeSpace) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:AMLocalizedString(@"nodeTooBig", @"Title shown inside an alert if you don't have enough space on your device to download something")
                                                                            message:nil
                                                                           delegate:self
                                                                  cancelButtonTitle:AMLocalizedString(@"ok", nil)
                                                                  otherButtonTitles:nil];
                        [alertView show];
                    });
                    
                    return;
                }
                
                [[NSFileManager defaultManager] createFileAtPath:localFilePath contents:nil attributes:nil];
                NSFileHandle *handle = [NSFileHandle fileHandleForWritingAtPath:localFilePath];
                
                static const NSUInteger kBufferSize = 10 * 1024;
                uint8_t *buffer = calloc(kBufferSize, sizeof(*buffer));
                NSUInteger offset = 0, bytesRead = 0;
                
                do {
                    bytesRead = [assetRepresentation getBytes:buffer fromOffset:offset length:kBufferSize error:nil];
                    [handle writeData:[NSData dataWithBytesNoCopy:buffer length:bytesRead freeWhenDone:NO]];
                    
                    offset += bytesRead;
                    
                } while (bytesRead > 0);
                
                free(buffer);
                [handle closeFile];
                
                NSError *error = nil;
                NSDictionary *attributesDictionary = [NSDictionary dictionaryWithObject:modificationTime forKey:NSFileModificationDate];
                if (![[NSFileManager defaultManager] setAttributes:attributesDictionary ofItemAtPath:localFilePath error:&error]) {
                    MEGALogError(@"Set attributes: %@", error);
                }
                
                [[MEGASdkManager sharedMEGASdk] startUploadWithLocalPath:localFilePath parent:self.parentNode];
                
                if (!startUpload) {
                    startUpload = YES;
                    [SVProgressHUD showSuccessWithStatus:AMLocalizedString(@"uploadStarted_Message", nil)];
                }
                
                
            } else {
                if ([[[MEGASdkManager sharedMEGASdk] parentNodeForNode:node] handle] != [self.parentNode handle]) {
                    [[MEGASdkManager sharedMEGASdk] copyNode:node newParent:self.parentNode newName:name];
                } else {
                    numFilesExist ++;
                    nameExist = node.name;
                }
            }
        }
        
        if (numFilesExist == 1) {
            //Wait 1.5 sec in order to see the "uploadStarted_message" first.
            if (startUpload) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:AMLocalizedString(@"fileAlreadyExistMessage", nil), nameExist]];
                });
            } else {
                [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:AMLocalizedString(@"fileAlreadyExistMessage", nil), nameExist]];
            }
        }
        
        if (numFilesExist > 1) {
            if (startUpload) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:AMLocalizedString(@"filesAlreadyExistMessage", nil), numFilesExist]];
                });
            } else {
                [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:AMLocalizedString(@"filesAlreadyExistMessage", nil), numFilesExist]];
            }
            
        }
    }];
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
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
    [SVProgressHUD showSuccessWithStatus:AMLocalizedString(@"uploadStarted_Message", nil)];
    
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
    
    if ([[self.nodes size] unsignedIntegerValue] == 0) {
        [_editBarButtonItem setEnabled:NO];
    } else {
        [_editBarButtonItem setEnabled:YES];
    }
    
    [self.tableView reloadData];
}

- (void)showImagePickerForSourceType:(UIImagePickerControllerSourceType)sourceType {
    
    if (![UIImagePickerController isSourceTypeAvailable:sourceType]) {
        if (sourceType == UIImagePickerControllerSourceTypeCamera) {
            [SVProgressHUD showImage:[UIImage imageNamed:@"hudNoCamera"] status:AMLocalizedString(@"noCamera", nil)];
        }
        return;
    }
    
    if (sourceType == UIImagePickerControllerSourceTypeCamera) {
        UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
        imagePickerController.modalPresentationStyle = UIModalPresentationCurrentContext;
        imagePickerController.sourceType = sourceType;
        imagePickerController.mediaTypes = [[NSArray alloc] initWithObjects:(NSString *)kUTTypeMovie, (NSString *)kUTTypeImage, nil];
        imagePickerController.videoQuality = UIImagePickerControllerQualityTypeHigh;
        imagePickerController.delegate = self;
        
        self.imagePickerController = imagePickerController;
        
        if (([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) && ([imagePickerController sourceType] == UIImagePickerControllerSourceTypePhotoLibrary)) {
            UIPopoverController *popoverController = [[UIPopoverController alloc] initWithContentViewController:imagePickerController];
            
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                [popoverController presentPopoverFromBarButtonItem:self.addBarButtonItem permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
            }];
        } else {
            [self.tabBarController presentViewController:self.imagePickerController animated:YES completion:nil];
        }
    } else {
        CTAssetsPickerController *picker = [[CTAssetsPickerController alloc] init];
        picker.delegate = self;
        picker.assetsFilter = [ALAssetsFilter allAssets];
        [self presentViewController:picker animated:YES completion:nil];
    }
}

- (void)toolbarActionsForShareType:(MEGAShareType )shareType {
    UIBarButtonItem *flexibleItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    lowShareType = shareType;
    
    switch (shareType) {
        case MEGAShareTypeAccessRead:
        case MEGAShareTypeAccessReadWrite: {
            [self.moveBarButtonItem setImage:[UIImage imageNamed:@"copy"]];
            if (self.displayMode == DisplayModeContact) {
                [self.deleteBarButtonItem setImage:[UIImage imageNamed:@"leaveShare"]];
                [self.toolbar setItems:@[self.downloadBarButtonItem, flexibleItem, self.moveBarButtonItem, flexibleItem, self.deleteBarButtonItem]];
            } else {
                [self.toolbar setItems:@[self.downloadBarButtonItem, flexibleItem, self.moveBarButtonItem]];                
            }
            break;
        }
            
        case MEGAShareTypeAccessFull: {
            [self.moveBarButtonItem setImage:[UIImage imageNamed:@"copy"]];
            if (self.displayMode == DisplayModeContact) {
                [self.deleteBarButtonItem setImage:[UIImage imageNamed:@"leaveShare"]];
                [self.toolbar setItems:@[self.downloadBarButtonItem, flexibleItem, self.moveBarButtonItem, flexibleItem, self.renameBarButtonItem, flexibleItem, self.deleteBarButtonItem]];
            } else {
                [self.toolbar setItems:@[self.downloadBarButtonItem, flexibleItem, self.moveBarButtonItem, flexibleItem, self.renameBarButtonItem, flexibleItem, self.deleteBarButtonItem]];
            }
            break;
        }
            
        case MEGAShareTypeAccessOwner: {
            if (self.displayMode == DisplayModeCloudDrive) {
                [self.toolbar setItems:@[self.downloadBarButtonItem, flexibleItem, self.shareBarButtonItem, flexibleItem, self.moveBarButtonItem, flexibleItem, self.renameBarButtonItem, flexibleItem, self.deleteBarButtonItem]];
            } else { //Rubbish Bin
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

- (void)reloadRowsAtIndexPaths:(NSArray *)indexPathsArray {
    if ([self.searchDisplayController isActive]) {
        [self.searchDisplayController.searchResultsTableView reloadRowsAtIndexPaths:indexPathsArray withRowAnimation:UITableViewRowAnimationNone];
    } else {
        [self.tableView reloadRowsAtIndexPaths:indexPathsArray withRowAnimation:UITableViewRowAnimationNone];
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
        [self.shareBarButtonItem setEnabled:((self.selectedNodesArray.count < 100) ? YES : NO)];
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
                                         otherButtonTitles:AMLocalizedString(@"newFolder", @"New Folder"), AMLocalizedString(@"choosePhotoVideo", @"Choose"), AMLocalizedString(@"capturePhotoVideo", @"Capture"), AMLocalizedString(@"uploadFrom", @"Option given on the `Add` section to allow the user upload something from another cloud storage provider."), nil];
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
    
    [SVProgressHUD showImage:[UIImage imageNamed:@"hudDownload"] status:AMLocalizedString(@"downloadStarted", nil)];
    
    for (MEGANode *n in self.selectedNodesArray) {
        [Helper downloadNode:n folderPath:[Helper pathForOffline] isFolderLink:NO];
    }
    
    [self setEditing:NO animated:YES];
    
    if ([self.searchDisplayController isActive]) {
        [self.searchDisplayController.searchResultsTableView reloadData];
    }
    
    [self.tableView reloadData];
}

- (IBAction)shareAction:(UIBarButtonItem *)sender {
    UIActivityViewController *activityVC = [Helper activityViewControllerForNodes:self.selectedNodesArray button:self.shareBarButtonItem];
    [self presentViewController:activityVC animated:YES completion:nil];
}

- (IBAction)moveAction:(UIBarButtonItem *)sender {
    MEGANavigationController *navigationController = [self.storyboard instantiateViewControllerWithIdentifier:@"BrowserNavigationControllerID"];
    [self presentViewController:navigationController animated:YES completion:nil];
    
    BrowserViewController *browserVC = navigationController.viewControllers.firstObject;
    browserVC.parentNode = [[MEGASdkManager sharedMEGASdk] rootNode];
    browserVC.selectedNodesArray = [NSArray arrayWithArray:self.selectedNodesArray];
    if (lowShareType == MEGAShareTypeAccessOwner) {
        [browserVC setBrowserAction:BrowserActionMove];
    }
    
    if ([self.searchDisplayController isActive]) {
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
        numFilesAction = 0;
        numFoldersAction = 0;
        for (MEGANode *n in self.selectedNodesArray) {
            if ([n type] == MEGANodeTypeFolder) {
                numFoldersAction++;
            } else {
                numFilesAction++;
            }
        }
        
        if (self.displayMode == DisplayModeCloudDrive) {
            NSString *message;
            if (numFilesAction == 0) {
                if (numFoldersAction == 1) {
                    message = AMLocalizedString(@"moveFolderToRubbishBinMessage", nil);
                } else { //folders > 1
                    message = [NSString stringWithFormat:AMLocalizedString(@"moveFoldersToRubbishBinMessage", nil), numFoldersAction];
                }
            } else if (numFilesAction == 1) {
                if (numFoldersAction == 0) {
                    message = AMLocalizedString(@"moveFileToRubbishBinMessage", nil);
                } else if (numFoldersAction == 1) {
                    message = AMLocalizedString(@"moveFileFolderToRubbishBinMessage", nil);
                } else {
                    message = [NSString stringWithFormat:AMLocalizedString(@"moveFileFoldersToRubbishBinMessage", nil), numFoldersAction];
                }
            } else {
                if (numFoldersAction == 0) {
                    message = [NSString stringWithFormat:AMLocalizedString(@"moveFilesToRubbishBinMessage", nil), numFilesAction];
                } else if (numFoldersAction == 1) {
                    message = [NSString stringWithFormat:AMLocalizedString(@"moveFilesFolderToRubbishBinMessage", nil), numFilesAction];
                } else {
                    message = AMLocalizedString(@"moveFilesFoldersToRubbishBinMessage", nil);
                    NSString *filesString = [NSString stringWithFormat:@"%ld", (long)numFilesAction];
                    NSString *foldersString = [NSString stringWithFormat:@"%ld", (long)numFoldersAction];
                    message = [message stringByReplacingOccurrencesOfString:@"[A]" withString:filesString];
                    message = [message stringByReplacingOccurrencesOfString:@"[B]" withString:foldersString];
                }
            }
            
            removeAlertView = [[UIAlertView alloc] initWithTitle:AMLocalizedString(@"moveToTheRubbishBin", nil) message:message delegate:self cancelButtonTitle:AMLocalizedString(@"cancel", nil) otherButtonTitles:AMLocalizedString(@"ok", nil), nil];
        } else {
            NSString *message;
            if (numFilesAction == 0) {
                if (numFoldersAction == 1) {
                    message = AMLocalizedString(@"removeFolderToRubbishBinMessage", nil);
                } else { //folders > 1
                    message = [NSString stringWithFormat:AMLocalizedString(@"removeFoldersToRubbishBinMessage", nil), numFoldersAction];
                }
            } else if (numFilesAction == 1) {
                if (numFoldersAction == 0) {
                    message = AMLocalizedString(@"removeFileToRubbishBinMessage", nil);
                } else if (numFoldersAction == 1) {
                    message = AMLocalizedString(@"removeFileFolderToRubbishBinMessage", nil);
                } else {
                    message = [NSString stringWithFormat:AMLocalizedString(@"removeFileFoldersToRubbishBinMessage", nil), numFoldersAction];
                }
            } else {
                if (numFoldersAction == 0) {
                    message = [NSString stringWithFormat:AMLocalizedString(@"removeFilesToRubbishBinMessage", nil), numFilesAction];
                } else if (numFoldersAction == 1) {
                    message = [NSString stringWithFormat:AMLocalizedString(@"removeFilesFolderToRubbishBinMessage", nil), numFilesAction];
                } else {                    
                    message = AMLocalizedString(@"removeFilesFoldersToRubbishBinMessage", nil);
                    NSString *filesString = [NSString stringWithFormat:@"%ld", (long)numFilesAction];
                    NSString *foldersString = [NSString stringWithFormat:@"%ld", (long)numFoldersAction];
                    message = [message stringByReplacingOccurrencesOfString:@"[A]" withString:filesString];
                    message = [message stringByReplacingOccurrencesOfString:@"[B]" withString:foldersString];
                }
            }
            
            removeAlertView = [[UIAlertView alloc] initWithTitle:AMLocalizedString(@"removeNodeFromRubbishBinTitle", @"Remove node from rubbish bin") message:message delegate:self cancelButtonTitle:AMLocalizedString(@"cancel", nil) otherButtonTitles:AMLocalizedString(@"ok", nil), nil];
        }
        removeAlertView.tag = 2;
        [removeAlertView show];
    }
    
    if ([self.searchDisplayController isActive]) {
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
    CGPoint buttonPosition;
    NSIndexPath *indexPath;
    MEGANode *node = nil;
    if ([self.searchDisplayController isActive]) {
        buttonPosition = [sender convertPoint:CGPointZero toView:self.searchDisplayController.searchResultsTableView];
        indexPath = [self.searchDisplayController.searchResultsTableView indexPathForRowAtPoint:buttonPosition];
        node = [matchSearchNodes objectAtIndex:indexPath.row];
    } else {
        buttonPosition = [sender convertPoint:CGPointZero toView:self.tableView];
        indexPath = [self.tableView indexPathForRowAtPoint:buttonPosition];
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

- (void)searchDisplayControllerWillBeginSearch:(UISearchDisplayController *)controller {
    [self setEditing:NO animated:YES];
}

- (void)searchDisplayControllerDidEndSearch:(UISearchDisplayController *)controller {
    [self.tableView insertSubview:self.searchDisplayController.searchBar aboveSubview:self.tableView];
    [self setEditing:NO animated:NO];
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString {
    [self filterContentForSearchText:searchString];
    
    return YES;
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption {
    [self filterContentForSearchText:self.searchDisplayController.searchBar.text];
    
    return YES;
}


#pragma mark - UIDocumentPickerDelegate

- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentAtURL:(NSURL *)url {
    if (controller.documentPickerMode == UIDocumentPickerModeImport) {
        NSString *localFilePath = [url path];
        
        NSString *crcLocal = [[MEGASdkManager sharedMEGASdk] CRCForFilePath:localFilePath];
        MEGANode *node = [[MEGASdkManager sharedMEGASdk] nodeByCRC:crcLocal parent:self.parentNode];
        
        // If file doesn't exist in MEGA then upload it
        if (node == nil) {
            [SVProgressHUD showSuccessWithStatus:AMLocalizedString(@"uploadStarted_Message", nil)];
            
            [[MEGASdkManager sharedMEGASdk] startUploadWithLocalPath:localFilePath parent:self.parentNode];
        } else {
            if ([node parentHandle] == [self.parentNode handle]) {
                NSError *error = nil;
                if (![[NSFileManager defaultManager] removeItemAtPath:localFilePath error:&error]) {
                    MEGALogError(@"Remove item at path: %@", error);
                }
                
                NSString *alertMessage = AMLocalizedString(@"fileExistAlertController_Message", nil);
                
                NSString *localNameString = [NSString stringWithFormat:@"%@", [url lastPathComponent]];
                NSString *megaNameString = [NSString stringWithFormat:@"%@", [node name]];
                alertMessage = [alertMessage stringByReplacingOccurrencesOfString:@"[A]" withString:localNameString];
                alertMessage = [alertMessage stringByReplacingOccurrencesOfString:@"[B]" withString:megaNameString];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    UIAlertController *alertController = [UIAlertController
                                                          alertControllerWithTitle:nil
                                                          message:alertMessage
                                                          preferredStyle:UIAlertControllerStyleAlert];
                    [alertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"ok", nil) style:UIAlertActionStyleDefault handler:nil]];
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

#pragma mark - UIViewControllerTransitioningDelegate

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source {
    
    if ([presented isKindOfClass:[QLPreviewController class]]) {
        return [[MEGAQLPreviewControllerTransitionAnimator alloc] init];
    }
    
    return nil;
}

#pragma mark - QLPreviewControllerDataSource

- (NSInteger)numberOfPreviewItemsInPreviewController:(QLPreviewController *)controller {
    return 1;
}

- (id <QLPreviewItem>)previewController:(QLPreviewController *)controller previewItemAtIndex:(NSInteger)index {
    return [NSURL fileURLWithPath:previewDocumentPath];
}

#pragma mark - QLPreviewControllerDelegate

- (BOOL)previewController:(QLPreviewController *)controller shouldOpenURL:(NSURL *)url forPreviewItem:(id <QLPreviewItem>)item {
    return YES;
}

#pragma mark - MEGARequestDelegate

- (void)onRequestStart:(MEGASdk *)api request:(MEGARequest *)request {
    
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
            UITableView *tableView = [self.searchDisplayController isActive] ? self.searchDisplayController.searchResultsTableView : self.tableView;
            for (NodeTableViewCell *nodeTableViewCell in [tableView visibleCells]) {
                if ([request nodeHandle] == [nodeTableViewCell nodeHandle]) {
                    MEGANode *node = [api nodeForHandle:request.nodeHandle];
                    [Helper setThumbnailForNode:node api:api cell:nodeTableViewCell];
                }
            }
            break;
        }
            
        case MEGARequestTypeMove: {
            remainingOperations--;
            if (remainingOperations == 0) {
                
                NSString *message;
                if (numFilesAction == 0) {
                    if (numFoldersAction == 1) {
                        message = AMLocalizedString(@"folderMovedToRubbishBinMessage", nil);
                    } else { //folders > 1
                        message = [NSString stringWithFormat:AMLocalizedString(@"foldersMovedToRubbishBinMessage", nil), numFoldersAction];
                    }
                } else if (numFilesAction == 1) {
                    if (numFoldersAction == 0) {
                        message = AMLocalizedString(@"fileMovedToRubbishBinMessage", nil);
                    } else if (numFoldersAction == 1) {
                        message = AMLocalizedString(@"fileFolderMovedToRubbishBinMessage", nil);
                    } else {
                        message = [NSString stringWithFormat:AMLocalizedString(@"fileFoldersMovedToRubbishBinMessage", nil), numFoldersAction];
                    }
                } else {
                    if (numFoldersAction == 0) {
                        message = [NSString stringWithFormat:AMLocalizedString(@"filesMovedToRubbishBinMessage", nil), numFilesAction];
                    } else if (numFoldersAction == 1) {
                        message = [NSString stringWithFormat:AMLocalizedString(@"filesFolderMovedToRubbishBinMessage", nil), numFilesAction];
                    } else {
                        message = AMLocalizedString(@"filesFoldersMovedToRubbishBinMessage", nil);
                        NSString *filesString = [NSString stringWithFormat:@"%ld", (long)numFilesAction];
                        NSString *foldersString = [NSString stringWithFormat:@"%ld", (long)numFoldersAction];
                        message = [message stringByReplacingOccurrencesOfString:@"[A]" withString:filesString];
                        message = [message stringByReplacingOccurrencesOfString:@"[B]" withString:foldersString];
                    }
                }
                
                [SVProgressHUD showImage:[UIImage imageNamed:@"hudRubbishBin"] status:message];
                [self setEditing:NO animated:YES];
            }
            break;
        }
            
        case MEGARequestTypeRemove: {
            remainingOperations--;
            if (remainingOperations == 0) {
                NSString *message;
                if (self.displayMode == DisplayModeCloudDrive || self.displayMode == DisplayModeRubbishBin) {
                    if (numFilesAction == 0) {
                        if (numFoldersAction == 1) {
                            message = AMLocalizedString(@"folderRemovedToRubbishBinMessage", nil);
                        } else { //folders > 1
                            message = [NSString stringWithFormat:AMLocalizedString(@"foldersRemovedToRubbishBinMessage", nil), numFoldersAction];
                        }
                    } else if (numFilesAction == 1) {
                        if (numFoldersAction == 0) {
                            message = AMLocalizedString(@"fileRemovedToRubbishBinMessage", nil);
                        } else if (numFoldersAction == 1) {
                            message = AMLocalizedString(@"fileFolderRemovedToRubbishBinMessage", nil);
                        } else {
                            message = [NSString stringWithFormat:AMLocalizedString(@"fileFoldersRemovedToRubbishBinMessage", nil), numFoldersAction];
                        }
                    } else {
                        if (numFoldersAction == 0) {
                            message = [NSString stringWithFormat:AMLocalizedString(@"filesRemovedToRubbishBinMessage", nil), numFilesAction];
                        } else if (numFoldersAction == 1) {
                            message = [NSString stringWithFormat:AMLocalizedString(@"filesFolderRemovedToRubbishBinMessage", nil), numFilesAction];
                        } else {
                            message = AMLocalizedString(@"filesFoldersRemovedToRubbishBinMessage", nil);
                            NSString *filesString = [NSString stringWithFormat:@"%ld", (long)numFilesAction];
                            NSString *foldersString = [NSString stringWithFormat:@"%ld", (long)numFoldersAction];
                            message = [message stringByReplacingOccurrencesOfString:@"[A]" withString:filesString];
                            message = [message stringByReplacingOccurrencesOfString:@"[B]" withString:foldersString];
                        }
                    }
                } else {
                    message = AMLocalizedString(@"shareFolderLeaved", @"Folder leave");
                }
                [SVProgressHUD showImage:[UIImage imageNamed:@"hudMinus"] status:message];
                [self setEditing:NO animated:YES];
            }
            break;
        }
        
        case MEGARequestTypeRename:
            if ([self.searchDisplayController isActive]) {
                [self filterContentForSearchText:self.searchDisplayController.searchBar.text];
                [self.searchDisplayController.searchResultsTableView reloadData];
            }
            break;
            
        case MEGARequestTypeCancelTransfer:
            break;
            
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
    if (transfer.isStreamingTransfer) {
        return;
    }
    
    if (transfer.type == MEGATransferTypeDownload) {
        NSString *base64Handle = [MEGASdk base64HandleForHandle:transfer.nodeHandle];
        NSIndexPath *indexPath = [self.nodesIndexPathMutableDictionary objectForKey:base64Handle];
        if (indexPath != nil) {
            [self reloadRowsAtIndexPaths:@[indexPath]];
        }
    }
}

- (void)onTransferUpdate:(MEGASdk *)api transfer:(MEGATransfer *)transfer {
    if (transfer.isStreamingTransfer) {
        return;
    }
    
    NSString *base64Handle = [MEGASdk base64HandleForHandle:transfer.nodeHandle];
    
    if (transfer.type == MEGATransferTypeDownload && [[Helper downloadingNodes] objectForKey:base64Handle]) {
        float percentage = ([[transfer transferredBytes] floatValue] / [[transfer totalBytes] floatValue] * 100);
        NSString *percentageCompleted = [NSString stringWithFormat:@"%.f%%", percentage];
        NSString *speed = [NSString stringWithFormat:@"%@/s", [NSByteCountFormatter stringFromByteCount:[[transfer speed] longLongValue]  countStyle:NSByteCountFormatterCountStyleMemory]];
        
        NSIndexPath *indexPath = [self.nodesIndexPathMutableDictionary objectForKey:base64Handle];
        if (indexPath != nil) {
            UITableView *tableView = [self.searchDisplayController isActive] ? self.searchDisplayController.searchResultsTableView : self.tableView;
            NodeTableViewCell *cell = (NodeTableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
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
            [SVProgressHUD showImage:[UIImage imageNamed:@"hudMinus"] status:AMLocalizedString(@"transferCancelled", nil)];
            NSString *base64Handle = [MEGASdk base64HandleForHandle:transfer.nodeHandle];
            NSIndexPath *indexPath = [self.nodesIndexPathMutableDictionary objectForKey:base64Handle];
            if (indexPath != nil) {
                [self reloadRowsAtIndexPaths:@[indexPath]];
            }
        }
        return;
    }
    
    if ([transfer type] == MEGATransferTypeDownload) {
        NSString *base64Handle = [MEGASdk base64HandleForHandle:transfer.nodeHandle];
        NSIndexPath *indexPath = [self.nodesIndexPathMutableDictionary objectForKey:base64Handle];
        if (indexPath != nil) {
            [self reloadRowsAtIndexPaths:@[indexPath]];
        }
    } else if ([transfer type] == MEGATransferTypeUpload) {
        if ([[transfer fileName] isEqualToString:@"capturedvideo.MOV"]) {
            MEGANode *node = [api nodeForHandle:[transfer nodeHandle]];
            
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            [formatter setDateFormat:@"yyyy'-'MM'-'dd' 'HH'.'mm'.'ss"];
            NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
            [formatter setLocale:locale];
            NSString *name = [[formatter stringFromDate:node.modificationTime] stringByAppendingPathExtension:@"mov"];
            [api renameNode:node newName:name];
        } 
    }
}

- (void)onTransferTemporaryError:(MEGASdk *)api transfer:(MEGATransfer *)transfer error:(MEGAError *)error {
}

@end
