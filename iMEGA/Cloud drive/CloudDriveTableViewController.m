#import "CloudDriveTableViewController.h"

#import <AVFoundation/AVCaptureDevice.h>
#import <AVFoundation/AVMediaFormat.h>
#import <MobileCoreServices/MobileCoreServices.h>

#import "SVProgressHUD.h"
#import "UIScrollView+EmptyDataSet.h"

#import "NSFileManager+MNZCategory.h"
#import "NSMutableAttributedString+MNZCategory.h"
#import "NSString+MNZCategory.h"
#import "UIAlertAction+MNZCategory.h"

#import "Helper.h"
#import "MEGAAssetsPickerController.h"
#import "MEGACreateFolderRequestDelegate.h"
#import "MEGAImagePickerController.h"
#import "MEGAMoveRequestDelegate.h"
#import "MEGANavigationController.h"
#import "MEGANode+MNZCategory.h"
#import "MEGANodeList+MNZCategory.h"
#import "MEGAPurchase.h"
#import "MEGAReachabilityManager.h"
#import "MEGARemoveRequestDelegate.h"
#import "MEGASdk+MNZCategory.h"
#import "MEGAShareRequestDelegate.h"
#import "MEGAStore.h"
#import "NSMutableArray+MNZCategory.h"

#import "BrowserViewController.h"
#import "ContactsViewController.h"
#import "DetailsNodeInfoViewController.h"
#import "MEGAAVViewController.h"
#import "NodeTableViewCell.h"
#import "PhotosViewController.h"
#import "PreviewDocumentViewController.h"
#import "SortByTableViewController.h"
#import "SharedItemsViewController.h"
#import "UpgradeTableViewController.h"
#import "CustomModalAlertViewController.h"

@interface CloudDriveTableViewController () <UINavigationControllerDelegate, UIDocumentPickerDelegate, UIDocumentMenuDelegate, UISearchBarDelegate, UISearchResultsUpdating, UIViewControllerPreviewingDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, MEGADelegate, MEGARequestDelegate> {
    BOOL allNodesSelected;
    BOOL isSwipeEditing;
    
    MEGAShareType lowShareType; //Control the actions allowed for node/nodes selected
}

@property (weak, nonatomic) IBOutlet UIBarButtonItem *selectAllBarButtonItem;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *moreBarButtonItem;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *sortByBarButtonItem;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *editBarButtonItem;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *negativeSpaceBarButtonItem;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *backBarButtonItem;

@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *downloadBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *shareBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *moveBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *carbonCopyBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *deleteBarButtonItem;

@property (strong, nonatomic) UISearchController *searchController;

@property (nonatomic, strong) MEGANodeList *nodes;
@property (nonatomic, strong) NSArray *nodesArray;
@property (nonatomic, strong) NSMutableArray *searchNodesArray;

@property (nonatomic, strong) NSMutableArray *cloudImages;
@property (nonatomic, strong) NSMutableArray *selectedNodesArray;

@property (nonatomic, strong) NSMutableDictionary *nodesIndexPathMutableDictionary;

@property (nonatomic) id<UIViewControllerPreviewing> previewingContext;

@end

@implementation CloudDriveTableViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.emptyDataSetSource = self;
    self.tableView.emptyDataSetDelegate = self;
    
    self.tableView.estimatedRowHeight = 44.0;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    
    _searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.searchResultsUpdater = self;
    self.searchController.dimsBackgroundDuringPresentation = NO;
    self.searchController.searchBar.delegate = self;
    self.searchController.searchBar.barTintColor = [UIColor colorWithWhite:235.0f / 255.0f alpha:1.0f];
    self.searchController.searchBar.translucent = YES;
    [self.searchController.searchBar sizeToFit];
    
    UITextField *searchTextField = [self.searchController.searchBar valueForKey:@"_searchField"];
    searchTextField.font = [UIFont mnz_SFUIRegularWithSize:14.0f];
    searchTextField.textColor = [UIColor mnz_gray999999];
    
    self.tableView.tableHeaderView = self.searchController.searchBar;
    self.definesPresentationContext = YES;
    
    self.tableView.contentOffset = CGPointMake(0, CGRectGetHeight(self.searchController.searchBar.frame));
    
    [self setNavigationBarButtonItems];
    [self.toolbar setFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.frame), 49)];
    self.toolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth;

    switch (self.displayMode) {
        case DisplayModeCloudDrive: {
            if (!self.parentNode) {
                self.parentNode = [[MEGASdkManager sharedMEGASdk] rootNode];
            }
            break;
        }
            
        case DisplayModeRubbishBin: {
            [self.deleteBarButtonItem setImage:[UIImage imageNamed:@"remove"]];
            break;
        }
            
        default:
            break;
    }
    
    MEGAShareType shareType = [[MEGASdkManager sharedMEGASdk] accessLevelForNode:self.parentNode];
    [self toolbarActionsForShareType:shareType];

    NSString *thumbsDirectory = [Helper pathForSharedSandboxCacheDirectory:@"thumbnailsV3"];
    NSError *error;
    if (![[NSFileManager defaultManager] fileExistsAtPath:thumbsDirectory]) {
        if (![[NSFileManager defaultManager] createDirectoryAtPath:thumbsDirectory withIntermediateDirectories:NO attributes:nil error:&error]) {
            MEGALogError(@"Create directory at path failed with error: %@", error);
        }
    }
    
    NSString *previewsDirectory = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"previewsV3"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:previewsDirectory]) {
        if (![[NSFileManager defaultManager] createDirectoryAtPath:previewsDirectory withIntermediateDirectories:NO attributes:nil error:&error]) {
            MEGALogError(@"Create directory at path failed with error: %@", error);
        }
    }
    
    self.nodesIndexPathMutableDictionary = [[NSMutableDictionary alloc] init];
    
    // Long press to select:
    [self.view addGestureRecognizer:[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)]];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(internetConnectionChanged) name:kReachabilityChangedNotification object:nil];
    
    [[MEGASdkManager sharedMEGASdk] addMEGADelegate:self];
    [[MEGASdkManager sharedMEGASdk] retryPendingConnections];
    
    [self reloadUI];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self encourageToUpgrade];
    
    if (self.homeQuickActionSearch) {
        self.homeQuickActionSearch = NO;
        [self activateSearch];
    }
    
    [self requestReview];
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
    if ([[UIDevice currentDevice] iPhone4X] || [[UIDevice currentDevice] iPhone5X]) {
        return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown;
    }
    
    return UIInterfaceOrientationMaskAll;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self.tableView reloadEmptyDataSet];
    } completion:nil];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    
    if ([self.traitCollection respondsToSelector:@selector(forceTouchCapability)]) {
        if (self.traitCollection.forceTouchCapability == UIForceTouchCapabilityAvailable) {
            if (!self.previewingContext) {
                self.previewingContext = [self registerForPreviewingWithDelegate:self sourceView:self.view];
            }
        } else {
            [self unregisterForPreviewingWithContext:self.previewingContext];
            self.previewingContext = nil;
        }
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger numberOfRows = 0;
    if ([MEGAReachabilityManager isReachable]) {
        if (self.searchController.isActive) {
            numberOfRows = self.searchNodesArray.count;
        } else {
            numberOfRows = [[self.nodes size] integerValue];
        }
    }
    
    if (numberOfRows == 0) {
        [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    } else {
        [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleSingleLine];
    }
    
    return numberOfRows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    MEGANode *node = self.searchController.isActive ? [self.searchNodesArray objectAtIndex:indexPath.row] : [self.nodes nodeAtIndex:indexPath.row];
    
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
        
        if (node.type == MEGANodeTypeFile) {
            MOOfflineNode *offlineNode = [[MEGAStore shareInstance] offlineNodeWithNode:node api:[MEGASdkManager sharedMEGASdk]];
            
            if (offlineNode) {
                isDownloaded = YES;
            }
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
    
    if (@available(iOS 11.0, *)) {
        cell.thumbnailImageView.accessibilityIgnoresInvertColors = YES;
        cell.thumbnailPlayImageView.accessibilityIgnoresInvertColors = YES;
    }
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    MEGANode *node = self.searchController.isActive ? [self.searchNodesArray objectAtIndex:indexPath.row] : [self.nodes nodeAtIndex:indexPath.row];
    
    if (tableView.isEditing) {
        [self.selectedNodesArray addObject:node];
        
        [self updateNavigationBarTitle];
        
        [self toolbarActionsForNodeArray:self.selectedNodesArray];
        
        [self setToolbarActionsEnabled:YES];
        
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
            if (node.name.mnz_isImagePathExtension) {
                NSArray *nodesArray = (self.searchController.isActive ? self.searchNodesArray : [self.nodes mnz_nodesArrayFromNodeList]);
                [node mnz_openImageInNavigationController:self.navigationController withNodes:nodesArray folderLink:NO displayMode:self.displayMode];
            } else {
                [node mnz_openNodeInNavigationController:self.navigationController folderLink:NO];
            }
            break;
        }
            
        default:
            break;
    }
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row > self.nodes.size.integerValue) {
        return;
    }
    MEGANode *node = [self.nodes nodeAtIndex:indexPath.row];
    
    if (tableView.isEditing) {
        
        //tempArray avoid crash: "was mutated while being enumerated."
        NSMutableArray *tempArray = [self.selectedNodesArray copy];
        for (MEGANode *n in tempArray) {
            if (n.handle == node.handle) {
                [self.selectedNodesArray removeObject:n];
            }
        }
        
        [self updateNavigationBarTitle];
        
        [self toolbarActionsForNodeArray:self.selectedNodesArray];
        
        if (self.selectedNodesArray.count == 0) {
            [self setToolbarActionsEnabled:NO];
        }
        
        allNodesSelected = NO;
        
        return;
    }
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    MEGANode *node = self.searchController.isActive ? [self.searchNodesArray objectAtIndex:indexPath.row] : [self.nodes nodeAtIndex:indexPath.row];
    
    if (self.displayMode == DisplayModeCloudDrive && [[MEGASdkManager sharedMEGASdk] accessLevelForNode:node] < MEGAShareTypeAccessFull) {
        return UITableViewCellEditingStyleNone;
    } else {
        self.selectedNodesArray = [NSMutableArray new];
        [self.selectedNodesArray addObject:node];
        
        [self setToolbarActionsEnabled:YES];
        
        isSwipeEditing = YES;
        
        MEGAShareType shareType = [[MEGASdkManager sharedMEGASdk] accessLevelForNode:node];
        [self toolbarActionsForShareType:shareType];
        
        return UITableViewCellEditingStyleDelete;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    MEGANode *node;
    if (self.searchController.isActive) {
        if (indexPath.row > self.searchNodesArray.count || indexPath.row < 0) {
            return @"";
        }
        node = [self.searchNodesArray objectAtIndex:indexPath.row];
    } else {
        if (indexPath.row > self.nodes.size.integerValue || indexPath.row < 0) {
            return @"";
        }
        node = [self.nodes nodeAtIndex:indexPath.row];
    }
    MEGAShareType accessType = [[MEGASdkManager sharedMEGASdk] accessLevelForNode:node];
    if (accessType >= MEGAShareTypeAccessFull) {
        return AMLocalizedString(@"remove", nil);
    }
    
    return @"";
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle==UITableViewCellEditingStyleDelete) {
        MEGANode *node = nil;
        if (self.searchController.isActive) {
            node = [self.searchNodesArray objectAtIndex:indexPath.row];
        } else {
            node = [self.nodes nodeAtIndex:indexPath.row];
        }
        
        void (^completion)(void) = ^{
            [self setEditing:NO animated:YES];
        };
        
        MEGAShareType accessType = [[MEGASdkManager sharedMEGASdk] accessLevelForNode:node];
        if (accessType == MEGAShareTypeAccessOwner) {
            if (self.displayMode == DisplayModeCloudDrive) {
                MEGAMoveRequestDelegate *moveRequestDelegate = [[MEGAMoveRequestDelegate alloc] initToMoveToTheRubbishBinWithFiles:(node.isFile ? 1 : 0) folders:(node.isFolder ? 1 : 0) completion:completion];
                [[MEGASdkManager sharedMEGASdk] moveNode:node newParent:[[MEGASdkManager sharedMEGASdk] rubbishNode] delegate:moveRequestDelegate];
            } else { //DisplayModeRubbishBin (Remove)
                MEGARemoveRequestDelegate *removeRequestDelegate = [[MEGARemoveRequestDelegate alloc] initWithMode:DisplayModeRubbishBin files:(node.isFile ? 1 : 0) folders:(node.isFolder ? 1 : 0) completion:completion];
                [[MEGASdkManager sharedMEGASdk] removeNode:node delegate:removeRequestDelegate];
            }
        } if (accessType == MEGAShareTypeAccessFull) { //DisplayModeSharedItem (Move to the Rubbish Bin)
            MEGAMoveRequestDelegate *moveRequestDelegate = [[MEGAMoveRequestDelegate alloc] initToMoveToTheRubbishBinWithFiles:(node.isFile ? 1 : 0) folders:(node.isFolder ? 1 : 0) completion:completion];
            [[MEGASdkManager sharedMEGASdk] moveNode:node newParent:[[MEGASdkManager sharedMEGASdk] rubbishNode] delegate:moveRequestDelegate];
        }
    }
}

#pragma mark - UIViewControllerPreviewingDelegate

- (UIViewController *)previewingContext:(id<UIViewControllerPreviewing>)previewingContext viewControllerForLocation:(CGPoint)location {
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:location];
    if (!indexPath || ![self.tableView numberOfRowsInSection:indexPath.section]) {
        return nil;
    }
    
    MEGANode *node = self.searchController.isActive ? [self.searchNodesArray objectAtIndex:indexPath.row] : [self.nodes nodeAtIndex:indexPath.row];
    previewingContext.sourceRect = [self.tableView convertRect:[self.tableView cellForRowAtIndexPath:indexPath].frame toView:self.view];
    
    if (self.tableView.isEditing) {
        return nil;
    }
    
    switch (node.type) {
        case MEGANodeTypeFolder: {
            CloudDriveTableViewController *cloudDriveTVC = [self.storyboard instantiateViewControllerWithIdentifier:@"CloudDriveID"];
            cloudDriveTVC.parentNode = node;
            if (self.displayMode == DisplayModeRubbishBin) {
                cloudDriveTVC.displayMode = self.displayMode;
            }
            return cloudDriveTVC;
            break;
        }
            
        case MEGANodeTypeFile: {
            if (node.name.mnz_isImagePathExtension) {
                NSArray *nodesArray = (self.searchController.isActive ? self.searchNodesArray : [self.nodes mnz_nodesArrayFromNodeList]);
                return [node mnz_photoBrowserWithNodes:nodesArray folderLink:NO displayMode:self.displayMode enableMoveToRubbishBin:YES hideControls:YES];
            } else {
                UIViewController *viewController = [node mnz_viewControllerForNodeInFolderLink:NO];
                return viewController;
            }
            break;
        }
            
        default:
            break;
    }

    return nil;
}

- (void)previewingContext:(id<UIViewControllerPreviewing>)previewingContext commitViewController:(UIViewController *)viewControllerToCommit {
    if (viewControllerToCommit.class == CloudDriveTableViewController.class || viewControllerToCommit.class == MWPhotoBrowser.class || viewControllerToCommit.class == PreviewDocumentViewController.class) {
        [self.navigationController pushViewController:viewControllerToCommit animated:YES];
    } else {
        [self.navigationController presentViewController:viewControllerToCommit animated:YES completion:nil];
    }
}

- (NSArray<id<UIPreviewActionItem>> *)previewActions {
    UIViewController *rootViewController = UIApplication.sharedApplication.delegate.window.rootViewController;
    
    UIPreviewAction *saveForOfflineAction =
    [UIPreviewAction actionWithTitle:AMLocalizedString(@"saveForOffline", @"List option shown on the details of a file or folder")
                               style:UIPreviewActionStyleDefault
                             handler:^(UIPreviewAction * _Nonnull action, UIViewController * _Nonnull previewViewController) {
                                 CloudDriveTableViewController *cloudDriveTVC = (CloudDriveTableViewController *)previewViewController;
                                 self.selectedNodesArray = [NSMutableArray new];
                                 [self.selectedNodesArray addObject:cloudDriveTVC.parentNode];
                                 [self downloadAction:nil];
                             }];
    
    UIPreviewAction *copyAction = [UIPreviewAction actionWithTitle:AMLocalizedString(@"copy", @"List option shown on the details of a file or folder")
                                                             style:UIPreviewActionStyleDefault
                                                           handler:^(UIPreviewAction * _Nonnull action, UIViewController * _Nonnull previewViewController) {
                                                               CloudDriveTableViewController *cloudDriveTVC = (CloudDriveTableViewController *)previewViewController;
                                                               MEGANavigationController *navigationController = [self.storyboard instantiateViewControllerWithIdentifier:@"BrowserNavigationControllerID"];
                                                               BrowserViewController *browserVC = navigationController.viewControllers.firstObject;
                                                               browserVC.selectedNodesArray = @[cloudDriveTVC.parentNode];
                                                               browserVC.browserAction = BrowserActionCopy;
                                                               [rootViewController presentViewController:navigationController animated:YES completion:nil];
                                                           }];
    
    NSString *deletePreviewActionTitle;
    UITabBarController *tabBarController = (UITabBarController *)self.presentingViewController;
    UINavigationController *navigationController = tabBarController.selectedViewController;
    if (navigationController.viewControllers.lastObject.class == SharedItemsViewController.class) {
        MEGAShareType shareType = [[MEGASdkManager sharedMEGASdk] accessLevelForNode:self.parentNode];
        if (shareType == MEGAShareTypeAccessOwner) {
            deletePreviewActionTitle = AMLocalizedString(@"removeSharing", @"Alert title shown on the Shared Items section when you want to remove 1 share");
        }
    } else {
        if (self.displayMode == DisplayModeCloudDrive || self.displayMode == DisplayModeSharedItem) {
            deletePreviewActionTitle = AMLocalizedString(@"moveToTheRubbishBin", @"Title for the action that allows you to 'Move to the Rubbish Bin' files or folders");
        } else if (self.displayMode == DisplayModeRubbishBin) {
            deletePreviewActionTitle = AMLocalizedString(@"remove", @"Title for the action that allows to remove a file or folder");
        }
    }
    UIPreviewAction *deleteAction =
    [UIPreviewAction actionWithTitle:deletePreviewActionTitle
                               style:UIPreviewActionStyleDestructive
                             handler:^(UIPreviewAction * _Nonnull action, UIViewController * _Nonnull previewViewController) {
                                 CloudDriveTableViewController *cloudDriveTVC = (CloudDriveTableViewController *)previewViewController;
                                 MEGANode *parentNode = cloudDriveTVC.parentNode;
                                 MEGAShareType accessType = [[MEGASdkManager sharedMEGASdk] accessLevelForNode:parentNode];
                                 if (accessType == MEGAShareTypeAccessOwner) {
                                     if (self.displayMode == DisplayModeCloudDrive) {
                                         if (navigationController.viewControllers.lastObject.class == CloudDriveTableViewController.class) {
                                             MEGAMoveRequestDelegate *moveRequestDelegate = [[MEGAMoveRequestDelegate alloc] initToMoveToTheRubbishBinWithFiles:(self.parentNode.isFile ? 1 : 0) folders:(self.parentNode.isFolder ? 1 : 0) completion:^{
                                                 [self setEditing:NO animated:YES];
                                             }];
                                             
                                             [[MEGASdkManager sharedMEGASdk] moveNode:parentNode newParent:[[MEGASdkManager sharedMEGASdk] rubbishNode] delegate:moveRequestDelegate];
                                         } else if (navigationController.viewControllers.lastObject.class == SharedItemsViewController.class) {
                                             NSMutableArray *outSharesForNodeMutableArray = [[NSMutableArray alloc] init];
                                             MEGAShareList *shareList = [[MEGASdkManager sharedMEGASdk] outSharesForNode:self.parentNode];
                                             NSUInteger outSharesForNodeCount = shareList.size.unsignedIntegerValue;
                                             for (NSInteger i = 0; i < outSharesForNodeCount; i++) {
                                                 MEGAShare *share = [shareList shareAtIndex:i];
                                                 if (share.user != nil) {
                                                     [outSharesForNodeMutableArray addObject:share];
                                                 }
                                             }
                                             
                                             MEGAShareRequestDelegate *shareRequestDelegate = [[MEGAShareRequestDelegate alloc] initToChangePermissionsWithNumberOfRequests:outSharesForNodeMutableArray.count completion:nil];
                                             for (MEGAShare *share in outSharesForNodeMutableArray) {
                                                 [[MEGASdkManager sharedMEGASdk] shareNode:self.parentNode withEmail:share.user level:MEGANodeAccessLevelAccessUnknown delegate:shareRequestDelegate];
                                             }
                                         }
                                     } else { //DisplayModeRubbishBin (Remove)
                                         MEGARemoveRequestDelegate *removeRequestDelegate = [[MEGARemoveRequestDelegate alloc] initWithMode:DisplayModeRubbishBin files:(self.parentNode.isFile ? 1 : 0) folders:(self.parentNode.isFolder ? 1 : 0) completion:^{
                                             [self setEditing:NO animated:YES];
                                         }];
                                         [[MEGASdkManager sharedMEGASdk] removeNode:parentNode delegate:removeRequestDelegate];
                                     }
                                 } if (accessType == MEGAShareTypeAccessFull) { //DisplayModeSharedItem (Move to the Rubbish Bin)
                                     MEGAMoveRequestDelegate *moveRequestDelegate = [[MEGAMoveRequestDelegate alloc] initToMoveToTheRubbishBinWithFiles:(self.parentNode.isFile ? 1 : 0) folders:(self.parentNode.isFolder ? 1 : 0) completion:^{
                                         [self setEditing:NO animated:YES];
                                     }];
                                     
                                     [[MEGASdkManager sharedMEGASdk] moveNode:parentNode newParent:[[MEGASdkManager sharedMEGASdk] rubbishNode] delegate:moveRequestDelegate];
                                 }
                             }];
    
    MEGAShareType shareType = [[MEGASdkManager sharedMEGASdk] accessLevelForNode:self.parentNode];
    NSArray<id<UIPreviewActionItem>> *previewActions;
    switch (shareType) {
        case MEGAShareTypeAccessRead:
        case MEGAShareTypeAccessReadWrite:
        case MEGAShareTypeAccessFull: {
            if (navigationController.viewControllers.lastObject.class == CloudDriveTableViewController.class) {
                previewActions = (shareType == MEGAShareTypeAccessFull) ? @[saveForOfflineAction, copyAction, deleteAction] : @[saveForOfflineAction, copyAction];
            } else if (navigationController.viewControllers.lastObject.class == SharedItemsViewController.class) {
                UIPreviewAction *leaveShareAction = [UIPreviewAction actionWithTitle:AMLocalizedString(@"leave", @"A button label. The button allows the user to leave the group conversation.")
                                                                               style:UIPreviewActionStyleDestructive
                                                                             handler:^(UIPreviewAction * _Nonnull action, UIViewController * _Nonnull previewViewController) {
                                                                                 CloudDriveTableViewController *cloudDriveTVC = (CloudDriveTableViewController *)previewViewController;
                                                                                 
                                                                                 NSString *alertMessage = (cloudDriveTVC.selectedNodesArray.count > 1) ? AMLocalizedString(@"leaveSharesAlertMessage", @"Alert message shown when the user tap on the leave share action selecting multipe inshares") : AMLocalizedString(@"leaveShareAlertMessage", @"Alert message shown when the user tap on the leave share action for one inshare");
                                                                                 UIAlertController *leaveAlertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"leaveFolder", @"Button title of the action that allows to leave a shared folder") message:alertMessage preferredStyle:UIAlertControllerStyleAlert];
                                                                                 [leaveAlertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"cancel", @"Button title to cancel something") style:UIAlertActionStyleCancel handler:nil]];
                                                                                 
                                                                                 [leaveAlertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"ok", @"Button title to cancel something") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                                                                                     MEGARemoveRequestDelegate *removeRequestDelegate = [[MEGARemoveRequestDelegate alloc] initWithMode:DisplayModeSharedItem files:(self.parentNode.isFile ? 1 : 0) folders:(self.parentNode.isFolder ? 1 : 0) completion:^{
                                                                                         [self setEditing:NO animated:YES];
                                                                                     }];
                                                                                     [[MEGASdkManager sharedMEGASdk] removeNode:self.parentNode delegate:removeRequestDelegate];
                                                                                 }]];
                                                                                 
                                                                                 [rootViewController presentViewController:leaveAlertController animated:YES completion:nil];
                                                                             }];
                previewActions = @[saveForOfflineAction, copyAction, leaveShareAction];
            }
            break;
        }
            
        case MEGAShareTypeAccessOwner: {
            UIPreviewAction *shareAction = [UIPreviewAction actionWithTitle:AMLocalizedString(@"share", @"Button title which, if tapped, will trigger the action of sharing with the contact or contacts selected ")
                                                                      style:UIPreviewActionStyleDefault
                                                                    handler:^(UIPreviewAction * _Nonnull action, UIViewController * _Nonnull previewViewController) {
                                                                        CloudDriveTableViewController *cloudDriveTVC = (CloudDriveTableViewController *)previewViewController;
                                                                        UIActivityViewController *activityVC = [Helper activityViewControllerForNodes:@[cloudDriveTVC.parentNode] button:nil];
                                                                        [rootViewController presentViewController:activityVC animated:YES completion:nil];
                                                                    }];
            
            UIPreviewAction *moveAction = [UIPreviewAction actionWithTitle:AMLocalizedString(@"move", @"Title for the action that allows you to move a file or folder")
                                                                     style:UIPreviewActionStyleDefault
                                                                   handler:^(UIPreviewAction * _Nonnull action, UIViewController * _Nonnull previewViewController) {
                                                                       CloudDriveTableViewController *cloudDriveTVC = (CloudDriveTableViewController *)previewViewController;
                                                                       MEGANavigationController *navigationController = [self.storyboard instantiateViewControllerWithIdentifier:@"BrowserNavigationControllerID"];
                                                                       BrowserViewController *browserVC = navigationController.viewControllers.firstObject;
                                                                       browserVC.selectedNodesArray = @[cloudDriveTVC.parentNode];
                                                                       if (lowShareType == MEGAShareTypeAccessOwner) {
                                                                           browserVC.browserAction = BrowserActionMove;
                                                                       }
                                                                       [rootViewController presentViewController:navigationController animated:YES completion:nil];
                                                                   }];
            
            if (self.displayMode == DisplayModeCloudDrive) {
                if (navigationController.viewControllers.lastObject.class == SharedItemsViewController.class) {
                    UIPreviewAction *shareFolderPreviewAction = [UIPreviewAction actionWithTitle:AMLocalizedString(@"shareFolder", @"Button title which, if tapped, will trigger the action of sharing with the contact or contacts selected, the folder you want inside your Cloud Drive")
                                                                                           style:UIPreviewActionStyleDefault
                                                                                         handler:^(UIPreviewAction * _Nonnull action, UIViewController * _Nonnull previewViewController) {
                                                                                             CloudDriveTableViewController *cloudDriveTVC = (CloudDriveTableViewController *)previewViewController;
                                                                                             MEGANavigationController *navigationController = [[UIStoryboard storyboardWithName:@"Contacts" bundle:nil] instantiateViewControllerWithIdentifier:@"ContactsNavigationControllerID"];
                                                                                             ContactsViewController *contactsVC = navigationController.viewControllers.firstObject;
                                                                                             contactsVC.contactsMode = ContactsModeShareFoldersWith;
                                                                                             contactsVC.nodesArray = @[cloudDriveTVC.parentNode];
                                                                                             [rootViewController presentViewController:navigationController animated:YES completion:nil];
                                                                                         }];
                    
                    previewActions = @[shareAction, shareFolderPreviewAction, copyAction, deleteAction];
                } else if (navigationController.viewControllers.lastObject.class == CloudDriveTableViewController.class) {
                    previewActions = @[saveForOfflineAction, shareAction, moveAction, copyAction, deleteAction];
                }
            } else if (self.displayMode == DisplayModeRubbishBin) {
                previewActions = @[saveForOfflineAction, moveAction, copyAction, deleteAction];
            }
            break;
        }
            
        default:
            break;
    }
    
    return previewActions;
}

#pragma mark - UILongPressGestureRecognizer

- (void)longPress:(UILongPressGestureRecognizer *)longPressGestureRecognizer {
    if (longPressGestureRecognizer.state == UIGestureRecognizerStateBegan) {
        CGPoint touchPoint = [longPressGestureRecognizer locationInView:self.tableView];
        NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:touchPoint];
        
        if (!indexPath || ![self.tableView numberOfRowsInSection:indexPath.section]) {
            return;
        }
        
        if (self.isEditing) {
            // Only stop editing if long pressed over a cell that is the only one selected or when selected none
            if (self.selectedNodesArray.count == 0) {
                [self setEditing:NO animated:YES];
            }
            if (self.selectedNodesArray.count == 1) {
                MEGANode *nodeSelected = self.selectedNodesArray.firstObject;
                MEGANode *nodePressed = self.searchController.isActive ? [self.searchNodesArray objectAtIndex:indexPath.row] : [self.nodes nodeAtIndex:indexPath.row];
                if (nodeSelected.handle == nodePressed.handle) {
                    [self setEditing:NO animated:YES];
                }
            }
        } else {
            [self setEditing:YES animated:YES];
            [self tableView:self.tableView didSelectRowAtIndexPath:indexPath];
            [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
        }
    }
}

#pragma mark - DZNEmptyDataSetSource

- (NSAttributedString *)titleForEmptyDataSet:(UIScrollView *)scrollView {
    NSString *text;
    if ([MEGAReachabilityManager isReachable]) {
        if (self.parentNode == nil) {
            return nil;
        }
        
        if (self.searchController.isActive) {
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
    
    NSDictionary *attributes = @{NSFontAttributeName:[UIFont mnz_SFUIRegularWithSize:18.0f], NSForegroundColorAttributeName:[UIColor mnz_gray999999]};
    
    return [[NSAttributedString alloc] initWithString:text attributes:attributes];
}

- (UIImage *)imageForEmptyDataSet:(UIScrollView *)scrollView {
    UIImage *image = nil;
    if ([MEGAReachabilityManager isReachable]) {
        if (self.parentNode == nil) {
            return nil;
        }
        
        if (self.searchController.isActive) {
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
    MEGAShareType parentShareType = [[MEGASdkManager sharedMEGASdk] accessLevelForNode:self.parentNode];
    if (parentShareType == MEGAShareTypeAccessRead) {
        return nil;
    }
    
    NSString *text = @"";
    if ([MEGAReachabilityManager isReachable]) {
        if (self.parentNode == nil) {
            return nil;
        }
        
        switch (self.displayMode) {
            case DisplayModeCloudDrive: {
                if (!self.searchController.isActive) {
                    text = AMLocalizedString(@"addFiles", nil);
                }
                break;
            }
                
            default:
                text = @"";
                break;
        }
        
    }
    
    NSDictionary *attributes = @{NSFontAttributeName:[UIFont mnz_SFUIRegularWithSize:20.0f], NSForegroundColorAttributeName:[UIColor mnz_gray777777]};
    
    return [[NSAttributedString alloc] initWithString:text attributes:attributes];
}

- (UIImage *)buttonBackgroundImageForEmptyDataSet:(UIScrollView *)scrollView forState:(UIControlState)state {
    MEGAShareType parentShareType = [[MEGASdkManager sharedMEGASdk] accessLevelForNode:self.parentNode];
    if (parentShareType == MEGAShareTypeAccessRead) {
        return nil;
    }
    
    UIEdgeInsets capInsets = [Helper capInsetsForEmptyStateButton];
    UIEdgeInsets rectInsets = [Helper rectInsetsForEmptyStateButton];
    
    return [[[UIImage imageNamed:@"buttonBorder"] resizableImageWithCapInsets:capInsets resizingMode:UIImageResizingModeStretch] imageWithAlignmentRectInsets:rectInsets];
}

- (UIColor *)backgroundColorForEmptyDataSet:(UIScrollView *)scrollView {
    return [UIColor whiteColor];
}

- (CGFloat)verticalOffsetForEmptyDataSet:(UIScrollView *)scrollView {
    return [Helper verticalOffsetForEmptyStateWithNavigationBarSize:self.navigationController.navigationBar.frame.size searchBarActive:self.searchController.isActive];
}

- (CGFloat)spaceHeightForEmptyDataSet:(UIScrollView *)scrollView {
    return [Helper spaceHeightForEmptyState];
}

#pragma mark - DZNEmptyDataSetDelegate

- (void)emptyDataSet:(UIScrollView *)scrollView didTapButton:(UIButton *)button {
    switch (self.displayMode) {
        case DisplayModeCloudDrive: {
            [self presentUploadAlertController];
            break;
        }
            
        default:
            break;
    }
}

#pragma mark - Private

- (void)reloadUI {
    switch (self.displayMode) {
        case DisplayModeCloudDrive: {
            if (!self.parentNode) {
                self.parentNode = [[MEGASdkManager sharedMEGASdk] rootNode];
            }
            
            [self updateNavigationBarTitle];
            
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
            [self updateNavigationBarTitle];
            
            self.nodes = [[MEGASdkManager sharedMEGASdk] childrenForParent:self.parentNode];
            
            break;
        }
            
        default:
            break;
    }
    
    if ([[self.nodes size] unsignedIntegerValue] == 0) {
        [self setNavigationBarButtonItemsEnabled:[MEGAReachabilityManager isReachable]];
        
        [self.tableView setTableHeaderView:nil];
    } else {
        [self setNavigationBarButtonItemsEnabled:[MEGAReachabilityManager isReachable]];
        if (!self.tableView.tableHeaderView) {
            self.tableView.tableHeaderView = self.searchController.searchBar;
        }
    }
    
    NSMutableArray *tempArray = [[NSMutableArray alloc] initWithCapacity:self.nodes.size.integerValue];
    for (NSUInteger i = 0; i < self.nodes.size.integerValue ; i++) {
        [tempArray addObject:[self.nodes nodeAtIndex:i]];
    }
    
    self.nodesArray = tempArray;
    
    [self.tableView reloadData];
}

- (void)showImagePickerForSourceType:(UIImagePickerControllerSourceType)sourceType {
    if (sourceType == UIImagePickerControllerSourceTypeCamera) {
        MEGAImagePickerController *imagePickerController = [[MEGAImagePickerController alloc] initToUploadWithParentNode:self.parentNode sourceType:sourceType];
        [self presentViewController:imagePickerController animated:YES completion:nil];
    } else {
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
            dispatch_async(dispatch_get_main_queue(), ^{
                MEGAAssetsPickerController *pickerViewController = [[MEGAAssetsPickerController alloc] initToUploadToCloudDriveWithParentNode:self.parentNode];
                if ([[UIDevice currentDevice] iPadDevice]) {
                    pickerViewController.modalPresentationStyle = UIModalPresentationFormSheet;
                }
                [self presentViewController:pickerViewController animated:YES completion:nil];
            });
        }];
    }
}

- (void)toolbarActionsForShareType:(MEGAShareType )shareType {
    UIBarButtonItem *flexibleItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    lowShareType = shareType;
    
    switch (shareType) {
        case MEGAShareTypeAccessRead:
        case MEGAShareTypeAccessReadWrite: {
            [self.moveBarButtonItem setImage:[UIImage imageNamed:@"copy"]];
            [self.toolbar setItems:@[self.downloadBarButtonItem, flexibleItem, self.moveBarButtonItem]];
            break;
        }
            
        case MEGAShareTypeAccessFull: {
            [self.moveBarButtonItem setImage:[UIImage imageNamed:@"copy"]];
            [self.toolbar setItems:@[self.downloadBarButtonItem, flexibleItem, self.moveBarButtonItem, flexibleItem, self.deleteBarButtonItem]];
            break;
        }
            
        case MEGAShareTypeAccessOwner: {
            if (self.displayMode == DisplayModeCloudDrive) {
                [self.toolbar setItems:@[self.downloadBarButtonItem, flexibleItem, self.shareBarButtonItem, flexibleItem, self.moveBarButtonItem, flexibleItem, self.carbonCopyBarButtonItem, flexibleItem, self.deleteBarButtonItem]];
            } else { //Rubbish Bin
                [self.toolbar setItems:@[self.downloadBarButtonItem, flexibleItem, self.moveBarButtonItem, flexibleItem, self.carbonCopyBarButtonItem, flexibleItem, self.deleteBarButtonItem]];
            }
            
            break;
        }
            
        default:
            break;
    }
}

- (void)setToolbarActionsEnabled:(BOOL)boolValue {
    self.downloadBarButtonItem.enabled = boolValue;
    [self.shareBarButtonItem setEnabled:((self.selectedNodesArray.count < 100) ? boolValue : NO)];
    self.moveBarButtonItem.enabled = boolValue;
    self.carbonCopyBarButtonItem.enabled = boolValue;
    self.deleteBarButtonItem.enabled = boolValue;
}

- (void)toolbarActionsForNodeArray:(NSArray *)nodeArray {
    if (nodeArray.count == 0) {
        return;
    }
    
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

- (void)setNavigationBarButtonItems {
    [self createNegativeSpaceBarButtonItem];
    
    switch (self.displayMode) {
        case DisplayModeCloudDrive: {
            if ([[MEGASdkManager sharedMEGASdk] accessLevelForNode:self.parentNode] == MEGAShareTypeAccessRead) {
                self.navigationItem.rightBarButtonItems = @[self.negativeSpaceBarButtonItem, self.editBarButtonItem, self.sortByBarButtonItem];
            } else {
                self.navigationItem.rightBarButtonItems = @[self.negativeSpaceBarButtonItem, self.moreBarButtonItem];
            }
            break;
        }
            
        case DisplayModeRubbishBin:
            self.navigationItem.rightBarButtonItems = @[self.negativeSpaceBarButtonItem, self.editBarButtonItem, self.sortByBarButtonItem];
            break;
            
        default:
            break;
    }
}

- (void)setNavigationBarButtonItemsEnabled:(BOOL)boolValue {
    switch (self.displayMode) {
        case DisplayModeCloudDrive: {
            self.moreBarButtonItem.enabled = boolValue;
            break;
        }
            
        case DisplayModeRubbishBin: {
            [self.sortByBarButtonItem setEnabled:boolValue];
            [self.editBarButtonItem setEnabled:boolValue];
            break;
        }
            
        default:
            break;
    }
}

- (void)createNegativeSpaceBarButtonItem {
    if (self.negativeSpaceBarButtonItem == nil) {
        self.negativeSpaceBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
        if ([[UIDevice currentDevice] iPadDevice] || [[UIDevice currentDevice] iPhone6XPlus]) {
            self.negativeSpaceBarButtonItem.width = -8.0;
        } else {
            self.negativeSpaceBarButtonItem.width = -4.0;
        }
    }
}

- (void)presentSortByViewController {
    SortByTableViewController *sortByTableViewController = [[UIStoryboard storyboardWithName:@"Cloud" bundle:nil] instantiateViewControllerWithIdentifier:@"sortByTableViewControllerID"];
    sortByTableViewController.offline = NO;
    MEGANavigationController *navigationController = [[MEGANavigationController alloc] initWithRootViewController:sortByTableViewController];
    
    [self presentViewController:navigationController animated:YES completion:nil];
}

- (void)presentFromMoreBarButtonItemTheAlertController:(UIAlertController *)alertController {
    if ([[UIDevice currentDevice] iPadDevice]) {
        alertController.modalPresentationStyle = UIModalPresentationPopover;
        UIPopoverPresentationController *popoverPresentationController = [alertController popoverPresentationController];
        popoverPresentationController.barButtonItem = self.moreBarButtonItem;
        popoverPresentationController.sourceView = self.view;
    }
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)newFolderAlertTextFieldDidChange:(UITextField *)sender {
    UIAlertController *newFolderAlertController = (UIAlertController *)self.presentedViewController;
    if (newFolderAlertController) {
        UITextField *textField = newFolderAlertController.textFields.firstObject;
        UIAlertAction *rightButtonAction = newFolderAlertController.actions.lastObject;
        BOOL enableRightButton = NO;
        if (textField.text.length > 0) {
            enableRightButton = YES;
        }
        rightButtonAction.enabled = enableRightButton;
    }
}

- (void)presentUploadAlertController {
    UIAlertController *uploadAlertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [uploadAlertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"cancel", @"Button title to cancel something") style:UIAlertActionStyleCancel handler:nil]];
    
    UIAlertAction *fromPhotosAlertAction = [UIAlertAction actionWithTitle:AMLocalizedString(@"choosePhotoVideo", @"Menu option from the `Add` section that allows the user to choose a photo or video to upload it to MEGA") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self showImagePickerForSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
    }];
    [fromPhotosAlertAction mnz_setTitleTextColor:[UIColor mnz_black333333]];
    [uploadAlertController addAction:fromPhotosAlertAction];
    
    UIAlertAction *captureAlertAction = [UIAlertAction actionWithTitle:AMLocalizedString(@"capturePhotoVideo", @"Menu option from the `Add` section that allows the user to capture a video or a photo and upload it directly to MEGA.") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        if ([AVCaptureDevice respondsToSelector:@selector(requestAccessForMediaType:completionHandler:)]) {
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL permissionGranted) {
                if (permissionGranted) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self showImagePickerForSourceType:UIImagePickerControllerSourceTypeCamera];
                    });
                } else {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        UIAlertController *permissionsAlertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"attention", @"Alert title to attract attention") message:AMLocalizedString(@"cameraPermissions", @"Alert message to remember that MEGA app needs permission to use the Camera to take a photo or video and it doesn't have it") preferredStyle:UIAlertControllerStyleAlert];
                        
                        [permissionsAlertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"cancel", @"Button title to cancel something") style:UIAlertActionStyleCancel handler:nil]];
                        
                        [permissionsAlertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"ok", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
                        }]];
                        
                        [self presentViewController:permissionsAlertController animated:YES completion:nil];
                    });
                }
            }];
        }
    }];
    [captureAlertAction mnz_setTitleTextColor:[UIColor mnz_black333333]];
    [uploadAlertController addAction:captureAlertAction];
    
    UIAlertAction *importFromAlertAction = [UIAlertAction actionWithTitle:AMLocalizedString(@"uploadFrom", @"Option given on the `Add` section to allow the user upload something from another cloud storage provider.") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        UIDocumentMenuViewController *documentMenuViewController = [[UIDocumentMenuViewController alloc] initWithDocumentTypes:@[(__bridge NSString *) kUTTypeContent, (__bridge NSString *) kUTTypeData,(__bridge NSString *) kUTTypePackage, (@"com.apple.iwork.pages.pages"), (@"com.apple.iwork.numbers.numbers"), (@"com.apple.iwork.keynote.key")] inMode:UIDocumentPickerModeImport];
        documentMenuViewController.delegate = self;
        documentMenuViewController.popoverPresentationController.barButtonItem = self.moreBarButtonItem;
        
        [self presentViewController:documentMenuViewController animated:YES completion:nil];
    }];
    [importFromAlertAction mnz_setTitleTextColor:[UIColor mnz_black333333]];
    [uploadAlertController addAction:importFromAlertAction];
    
    [self presentFromMoreBarButtonItemTheAlertController:uploadAlertController];
}

- (void)updateNavigationBarTitle {
    NSString *navigationTitle;
    if (self.tableView.isEditing) {
        NSNumber *selectedNodesCount = [NSNumber numberWithUnsignedInteger:self.selectedNodesArray.count];
        if (selectedNodesCount.unsignedIntegerValue == 0) {
            navigationTitle = AMLocalizedString(@"selectTitle", @"Title shown on the Camera Uploads section when the edit mode is enabled. On this mode you can select photos");
        } else {
            navigationTitle = (selectedNodesCount.integerValue <= 1) ? [NSString stringWithFormat:AMLocalizedString(@"oneItemSelected", @"Title shown on the Camera Uploads section when the edit mode is enabled and you have selected one photo"), selectedNodesCount.unsignedIntegerValue] : [NSString stringWithFormat:AMLocalizedString(@"itemsSelected", @"Title shown on the Camera Uploads section when the edit mode is enabled and you have selected more than one photo"), selectedNodesCount.unsignedIntegerValue];
        }
    } else {
        switch (self.displayMode) {
            case DisplayModeCloudDrive: {
                if ([self.parentNode type] == MEGANodeTypeRoot) {
                    navigationTitle = AMLocalizedString(@"cloudDrive", @"Title of the Cloud Drive section");
                } else {
                    if (!self.parentNode) {
                        navigationTitle = AMLocalizedString(@"cloudDrive", @"Title of the Cloud Drive section");
                    } else {
                        navigationTitle = [self.parentNode name];
                    }
                }
                break;
            }
                
            case DisplayModeRubbishBin: {
                if ([self.parentNode type] == MEGANodeTypeRubbish) {
                    navigationTitle = AMLocalizedString(@"rubbishBinLabel", @"Title of one of the Settings sections where you can see your MEGA 'Rubbish Bin'");
                } else {
                    navigationTitle = [self.parentNode name];
                }
                break;
            }
                
            default:
                break;
        }
    }
    
    self.navigationItem.title = navigationTitle;
}

- (void)encourageToUpgrade {
    if (self.tabBarController == nil) { //Avoid presenting Upgrade view when peeking
        return;
    }
    
    static BOOL alreadyPresented = NO;
    if (!alreadyPresented && ![[MEGASdkManager sharedMEGASdk] mnz_isProAccount]) {
        MEGAAccountDetails *accountDetails = [[MEGASdkManager sharedMEGASdk] mnz_accountDetails];
        double percentage = accountDetails.storageUsed.doubleValue / accountDetails.storageMax.doubleValue;
        if (accountDetails && percentage > 0.95) { // +95% used storage
            NSString *alertMessage = percentage < 1 ? AMLocalizedString(@"cloudDriveIsAlmostFull", @"Informs the user that they’ve almost reached the full capacity of their Cloud Drive for a Free account. Please leave the [S], [/S], [A], [/A] placeholders as they are.") : AMLocalizedString(@"cloudDriveIsFull", @"A message informing the user that they've reached the full capacity of their accounts. Please leave [S], [/S] as it is which is used to bolden the text.");
            alertMessage = [alertMessage mnz_removeWebclientFormatters];
            NSString *maxStorage = [NSString stringWithFormat:@"%ld", (long)[[MEGAPurchase sharedInstance].pricing storageGBAtProductIndex:7]];
            NSString *maxStorageTB = [NSString stringWithFormat:@"%ld", (long)[[MEGAPurchase sharedInstance].pricing storageGBAtProductIndex:7] / 1024];
            alertMessage = [alertMessage stringByReplacingOccurrencesOfString:@"4096" withString:maxStorage];
            alertMessage = [alertMessage stringByReplacingOccurrencesOfString:@"4" withString:maxStorageTB];
            
            CustomModalAlertViewController *customModalAlertVC = [[CustomModalAlertViewController alloc] init];
            customModalAlertVC.modalPresentationStyle = UIModalPresentationOverCurrentContext;
            customModalAlertVC.image = @"storage_almost_full";
            customModalAlertVC.viewTitle = AMLocalizedString(@"upgradeAccount", @"Button title which triggers the action to upgrade your MEGA account level");
            customModalAlertVC.detail = alertMessage;
            customModalAlertVC.action = AMLocalizedString(@"seePlans", @"Button title to see the available pro plans in MEGA");
            if ([[MEGASdkManager sharedMEGASdk] isAchievementsEnabled]) {
                customModalAlertVC.bonus = AMLocalizedString(@"getBonus", @"Button title to see the available bonus");
            }
            customModalAlertVC.dismiss = AMLocalizedString(@"dismiss", @"Label for any 'Dismiss' button, link, text, title, etc. - (String as short as possible).");
            __weak typeof(CustomModalAlertViewController) *weakCustom = customModalAlertVC;
            customModalAlertVC.completion = ^{
                [weakCustom dismissViewControllerAnimated:YES completion:^{
                    [self showUpgradeTVC];
                }];
            };
            
            [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:customModalAlertVC animated:YES completion:nil];
            
            alreadyPresented = YES;
        } else {
            if (accountDetails && (arc4random_uniform(20) == 0)) { // 5 % of the times
                [self showUpgradeTVC];
                alreadyPresented = YES;
            }
        }
    }
}

- (void)showUpgradeTVC {
    if ([MEGAPurchase sharedInstance].products.count > 0) {
        UpgradeTableViewController *upgradeTVC = [[UIStoryboard storyboardWithName:@"MyAccount" bundle:nil] instantiateViewControllerWithIdentifier:@"UpgradeID"];
        MEGANavigationController *navigationController = [[MEGANavigationController alloc] initWithRootViewController:upgradeTVC];
        
        [self presentViewController:navigationController animated:YES completion:nil];
    }
}

- (void)activateSearch {
    [self.searchController.searchBar becomeFirstResponder];
    self.searchController.active = YES;
}

- (void)requestReview {
    if (@available(iOS 10.3, *)) {
        static BOOL alreadyPresented = NO;
        if (!alreadyPresented && [[MEGASdkManager sharedMEGASdk] mnz_accountDetails] && [[MEGASdkManager sharedMEGASdk] mnz_isProAccount]) {
            alreadyPresented = YES;
            NSUserDefaults *sharedUserDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.mega.ios"];
            NSDate *rateUsDate = [sharedUserDefaults objectForKey:@"rateUsDate"];
            if (rateUsDate) {
                NSInteger months = [[NSCalendar currentCalendar] components:NSCalendarUnitMonth
                                                                   fromDate:rateUsDate
                                                                     toDate:[NSDate date]
                                                                    options:NSCalendarWrapComponents].month;
                if (months < 4) {
                    return;
                }
            }
            [SKStoreReviewController requestReview];
            rateUsDate = [NSDate date];
            [sharedUserDefaults setObject:rateUsDate forKey:@"rateUsDate"];
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
    
    if (self.displayMode == DisplayModeCloudDrive) {
        [self updateNavigationBarTitle];
    }
    
    if (self.selectedNodesArray.count == 0) {
        [self setToolbarActionsEnabled:NO];
    } else if (self.selectedNodesArray.count >= 1) {
        [self setToolbarActionsEnabled:YES];
    }
    
    [self.tableView reloadData];
}

- (IBAction)moreAction:(UIBarButtonItem *)sender {
    UIAlertController *moreAlertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [moreAlertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"cancel", @"Button title to cancel something") style:UIAlertActionStyleCancel handler:nil]];
    
    UIAlertAction *uploadAlertAction = [UIAlertAction actionWithTitle:AMLocalizedString(@"upload", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self presentUploadAlertController];
    }];
    [uploadAlertAction mnz_setTitleTextColor:[UIColor mnz_black333333]];
    [moreAlertController addAction:uploadAlertAction];
    
    UIAlertAction *newFolderAlertAction = [UIAlertAction actionWithTitle:AMLocalizedString(@"newFolder", @"Menu option from the `Add` section that allows you to create a 'New Folder'") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        UIAlertController *newFolderAlertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"newFolder", @"Menu option from the `Add` section that allows you to create a 'New Folder'") message:nil preferredStyle:UIAlertControllerStyleAlert];
        
        [newFolderAlertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            textField.placeholder = AMLocalizedString(@"newFolderMessage", @"Hint text shown on the create folder alert.");
            [textField addTarget:self action:@selector(newFolderAlertTextFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
        }];
        
        [newFolderAlertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"cancel", @"Button title to cancel something") style:UIAlertActionStyleCancel handler:nil]];
        
        UIAlertAction *createFolderAlertAction = [UIAlertAction actionWithTitle:AMLocalizedString(@"createFolderButton", @"Title button for the create folder alert.") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            if ([MEGAReachabilityManager isReachableHUDIfNot]) {
                UITextField *textField = [[newFolderAlertController textFields] firstObject];
                MEGANodeList *childrenNodeList = [[MEGASdkManager sharedMEGASdk] nodeListSearchForNode:self.parentNode searchString:textField.text];
                if ([childrenNodeList mnz_existsFolderWithName:textField.text]) {
                    [SVProgressHUD showErrorWithStatus:AMLocalizedString(@"folderAlreadyExists", @"message when trying to create a folder that already exists")];
                } else {
                    MEGACreateFolderRequestDelegate *createFolderRequestDelegate = [[MEGACreateFolderRequestDelegate alloc] initWithCompletion:nil];
                    [[MEGASdkManager sharedMEGASdk] createFolderWithName:textField.text parent:self.parentNode delegate:createFolderRequestDelegate];
                }
            }
        }];
        createFolderAlertAction.enabled = NO;
        [newFolderAlertController addAction:createFolderAlertAction];
        
        [self presentViewController:newFolderAlertController animated:YES completion:nil];
    }];
    [newFolderAlertAction mnz_setTitleTextColor:[UIColor mnz_black333333]];
    [moreAlertController addAction:newFolderAlertAction];
    
    UIAlertAction *sortByAlertAction = [UIAlertAction actionWithTitle:AMLocalizedString(@"sortTitle", @"Section title of the 'Sort by'") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self presentSortByViewController];
    }];
    [sortByAlertAction mnz_setTitleTextColor:[UIColor mnz_black333333]];
    [moreAlertController addAction:sortByAlertAction];
    
    UIAlertAction *selectAlertAction = [UIAlertAction actionWithTitle:AMLocalizedString(@"select", @"Button that allows you to select a given folder") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        BOOL enableEditing = !self.tableView.isEditing;
        [self setEditing:enableEditing animated:YES];
    }];
    [selectAlertAction mnz_setTitleTextColor:[UIColor mnz_black333333]];
    [moreAlertController addAction:selectAlertAction];
    
    UIAlertAction *rubbishBinAlertAction = [UIAlertAction actionWithTitle:AMLocalizedString(@"rubbishBinLabel", @"Title of one of the Settings sections where you can see your MEGA 'Rubbish Bin'") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        CloudDriveTableViewController *cloudDriveTVC = [[UIStoryboard storyboardWithName:@"Cloud" bundle:nil] instantiateViewControllerWithIdentifier:@"CloudDriveID"];
        cloudDriveTVC.parentNode = [[MEGASdkManager sharedMEGASdk] rubbishNode];
        cloudDriveTVC.displayMode = DisplayModeRubbishBin;
        cloudDriveTVC.title = AMLocalizedString(@"rubbishBinLabel", @"Title of one of the Settings sections where you can see your MEGA 'Rubbish Bin'");
        [self.navigationController pushViewController:cloudDriveTVC animated:YES];
    }];
    [rubbishBinAlertAction mnz_setTitleTextColor:[UIColor mnz_black333333]];
    [moreAlertController addAction:rubbishBinAlertAction];
    
    [self presentFromMoreBarButtonItemTheAlertController:moreAlertController];
}

- (IBAction)editTapped:(UIBarButtonItem *)sender {
    BOOL enableEditing = !self.tableView.isEditing;
    [self setEditing:enableEditing animated:YES];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    
    [self updateNavigationBarTitle];
    
    if (editing) {
        [self.editBarButtonItem setImage:[UIImage imageNamed:@"done"]];
        self.navigationItem.rightBarButtonItems = @[self.negativeSpaceBarButtonItem, self.editBarButtonItem];
        if (!isSwipeEditing) {
            self.navigationItem.leftBarButtonItems = @[self.negativeSpaceBarButtonItem, self.selectAllBarButtonItem];
        }
        
        [self.toolbar setAlpha:0.0];
        [self.tabBarController.tabBar addSubview:self.toolbar];
        [UIView animateWithDuration:0.33f animations:^ {
            [self.toolbar setAlpha:1.0];
        }];
    } else {
        [self.editBarButtonItem setImage:[UIImage imageNamed:@"edit"]];
        
        [self setNavigationBarButtonItems];
        
        allNodesSelected = NO;
        self.selectedNodesArray = nil;
        self.navigationItem.leftBarButtonItems = @[];
        
        [UIView animateWithDuration:0.33f animations:^ {
            [self.toolbar setAlpha:0.0];
        } completion:^(BOOL finished) {
            if (finished) {
                [self.toolbar removeFromSuperview];
            }
        }];
    }
    
    if (!self.selectedNodesArray) {
        self.selectedNodesArray = [NSMutableArray new];
        
        [self setToolbarActionsEnabled:NO];
    }
    
    isSwipeEditing = NO;
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
        [Helper downloadNode:n folderPath:[Helper relativePathForOffline] isFolderLink:NO];
    }
    
    [self setEditing:NO animated:YES];
    
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
    browserVC.selectedNodesArray = [NSArray arrayWithArray:self.selectedNodesArray];
    if (lowShareType == MEGAShareTypeAccessOwner) {
        [browserVC setBrowserAction:BrowserActionMove];
    }
}

- (IBAction)deleteAction:(UIBarButtonItem *)sender {
    NSArray *numberOfFilesAndFoldersArray = self.selectedNodesArray.mnz_numberOfFilesAndFolders;
    NSUInteger numFilesAction = [[numberOfFilesAndFoldersArray objectAtIndex:0] unsignedIntegerValue];
    NSUInteger numFoldersAction = [[numberOfFilesAndFoldersArray objectAtIndex:1] unsignedIntegerValue];
    
    NSString *alertTitle;
    NSString *message;
    void (^handler)(UIAlertAction *action);
    void (^completion)(void) = ^{
        [self setEditing:NO animated:YES];
    };
    if (self.displayMode == DisplayModeCloudDrive) {
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
        
        alertTitle = AMLocalizedString(@"moveToTheRubbishBin", @"Title for the action that allows you to 'Move to the Rubbish Bin' files or folders");
        
        handler = ^(UIAlertAction *action) {
            MEGAMoveRequestDelegate *moveRequestDelegate = [[MEGAMoveRequestDelegate alloc] initToMoveToTheRubbishBinWithFiles:numFilesAction folders:numFoldersAction completion:completion];
            MEGANode *rubbishBinNode = [[MEGASdkManager sharedMEGASdk] rubbishNode];
            for (MEGANode *node in self.selectedNodesArray) {
                [[MEGASdkManager sharedMEGASdk] moveNode:node newParent:rubbishBinNode delegate:moveRequestDelegate];
            }
        };
    } else {
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
        
        alertTitle = AMLocalizedString(@"removeNodeFromRubbishBinTitle", @"Alert title shown on the Rubbish Bin when you want to remove some files and folders of your MEGA account");
        
        handler = ^(UIAlertAction *action) {
            MEGARemoveRequestDelegate *removeRequestDelegate = [[MEGARemoveRequestDelegate alloc] initWithMode:DisplayModeRubbishBin files:numFilesAction folders:numFoldersAction completion:completion];
            for (MEGANode *node in self.selectedNodesArray) {
                [[MEGASdkManager sharedMEGASdk] removeNode:node delegate:removeRequestDelegate];
            }
        };
    }
    
    UIAlertController *removeAlertController = [UIAlertController alertControllerWithTitle:alertTitle message:message preferredStyle:UIAlertControllerStyleAlert];
    [removeAlertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"cancel", @"Button title to cancel something") style:UIAlertActionStyleCancel handler:nil]];
    
    [removeAlertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"ok", @"Button title to cancel something") style:UIAlertActionStyleDefault handler:handler]];
     
     [self presentViewController:removeAlertController animated:YES completion:nil];
}

- (IBAction)copyAction:(UIBarButtonItem *)sender {
    if ([MEGAReachabilityManager isReachableHUDIfNot]) {
        MEGANavigationController *navigationController = [self.storyboard instantiateViewControllerWithIdentifier:@"BrowserNavigationControllerID"];
        [self presentViewController:navigationController animated:YES completion:nil];
        
        BrowserViewController *browserVC = navigationController.viewControllers.firstObject;
        browserVC.selectedNodesArray = self.selectedNodesArray;
        [browserVC setBrowserAction:BrowserActionCopy];
    }
}

- (IBAction)sortByAction:(UIBarButtonItem *)sender {
    [self presentSortByViewController];
}

- (IBAction)infoTouchUpInside:(UIButton *)sender {
    if (self.tableView.isEditing) {
        return;
    }
    
    CGPoint buttonPosition = [sender convertPoint:CGPointZero toView:self.tableView];;
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:buttonPosition];
    
    MEGANode *node = self.searchController.isActive ? [self.searchNodesArray objectAtIndex:indexPath.row] : [self.nodes nodeAtIndex:indexPath.row];
    
    DetailsNodeInfoViewController *detailsNodeInfoVC = [self.storyboard instantiateViewControllerWithIdentifier:@"nodeInfoDetails"];
    [detailsNodeInfoVC setNode:node];
    [detailsNodeInfoVC setDisplayMode:self.displayMode];
    detailsNodeInfoVC.incomingShareChildView = self.isIncomingShareChildView;
    [self.navigationController pushViewController:detailsNodeInfoVC animated:YES];
}

#pragma mark - UISearchBarDelegate

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    self.searchNodesArray = nil;
}

#pragma mark - UISearchResultsUpdating

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    NSString *searchString = searchController.searchBar.text;
    [self.searchNodesArray removeAllObjects];
    if ([searchString isEqualToString:@""]) {
        self.searchNodesArray = [NSMutableArray arrayWithArray:self.nodesArray];
    } else {
        MEGANodeList *allNodeList = [[MEGASdkManager sharedMEGASdk] nodeListSearchForNode:self.parentNode searchString:searchString recursive:YES];
        
        for (NSInteger i = 0; i < [allNodeList.size integerValue]; i++) {
            MEGANode *n = [allNodeList nodeAtIndex:i];
            [self.searchNodesArray addObject:n];
        }
    }
    [self.tableView reloadData];
}

#pragma mark - UIDocumentPickerDelegate

- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentAtURL:(NSURL *)url {
    if (controller.documentPickerMode == UIDocumentPickerModeImport) {
        NSError *error = nil;
        NSString *localFilePath = [[[NSFileManager defaultManager] uploadsDirectory] stringByAppendingPathComponent:url.lastPathComponent];
        if (![[NSFileManager defaultManager] moveItemAtPath:[url path] toPath:localFilePath error:&error]) {
            MEGALogError(@"Move item at path failed with error: %@", error);
        }
        
        NSString *crcLocal = [[MEGASdkManager sharedMEGASdk] CRCForFilePath:localFilePath];
        MEGANode *node = [[MEGASdkManager sharedMEGASdk] nodeByCRC:crcLocal parent:self.parentNode];
        
        // If file doesn't exist in MEGA then upload it
        if (node == nil) {
            [SVProgressHUD showSuccessWithStatus:AMLocalizedString(@"uploadStarted_Message", nil)];
            [[MEGASdkManager sharedMEGASdk] startUploadWithLocalPath:[localFilePath stringByReplacingOccurrencesOfString:[NSHomeDirectory() stringByAppendingString:@"/"] withString:@""] parent:self.parentNode appData:nil isSourceTemporary:YES];
        } else {
            if ([node parentHandle] == [self.parentNode handle]) {
                NSError *error = nil;
                if (![[NSFileManager defaultManager] removeItemAtPath:localFilePath error:&error]) {
                    MEGALogError(@"Remove item at path failed with error: %@", error);
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

#pragma mark - MEGARequestDelegate

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    if ([error type]) {
        if ([error type] == MEGAErrorTypeApiEAccess) {
            if (request.type == MEGARequestTypeUpload) {
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"permissionTitle", @"Error title shown when you are trying to do an action with a file or folder and you don't have the necessary permissions") message:AMLocalizedString(@"permissionMessage", @"Error message shown when you are trying to do an action with a file or folder and you don't have the necessary permissions") preferredStyle:UIAlertControllerStyleActionSheet];
                [self presentViewController:alertController animated:YES completion:nil];
            }
        }
        return;
    }
    
    switch ([request type]) {
        case MEGARequestTypeGetAttrFile: {
            for (NodeTableViewCell *nodeTableViewCell in [self.tableView visibleCells]) {
                if ([request nodeHandle] == [nodeTableViewCell nodeHandle]) {
                    MEGANode *node = [api nodeForHandle:request.nodeHandle];
                    [Helper setThumbnailForNode:node api:api cell:nodeTableViewCell reindexNode:YES];
                }
            }
            break;
        }
            
        case MEGARequestTypeCancelTransfer:
            break;
            
        default:
            break;
    }
}

#pragma mark - MEGAGlobalDelegate

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
            [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
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
            [SVProgressHUD showImage:[UIImage imageNamed:@"hudMinus"] status:AMLocalizedString(@"transferCancelled", nil)];
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
    }
}

@end
