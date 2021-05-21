
#import "CloudDriveViewController.h"

#import <AVFoundation/AVCaptureDevice.h>
#import <AVFoundation/AVMediaFormat.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <VisionKit/VisionKit.h>
#import <PDFKit/PDFKit.h>

#import "SVProgressHUD.h"
#import "UIScrollView+EmptyDataSet.h"

#import "NSFileManager+MNZCategory.h"
#import "NSString+MNZCategory.h"
#import "UIActivityViewController+MNZCategory.h"
#import "UIApplication+MNZCategory.h"
#import "UIImageView+MNZCategory.h"

#import "DevicePermissionsHelper.h"
#import "Helper.h"
#import "MEGACreateFolderRequestDelegate.h"
#import "MEGAMoveRequestDelegate.h"
#import "MEGANode+MNZCategory.h"
#import "NSDate+MNZCategory.h"
#import "MEGANodeList+MNZCategory.h"
#import "MEGAPurchase.h"
#import "MEGAReachabilityManager.h"
#import "MEGARemoveRequestDelegate.h"
#import "MEGASdkManager.h"
#import "MEGASdk+MNZCategory.h"
#import "MEGAShareRequestDelegate.h"
#import "MEGAStore.h"
#import "MEGA-Swift.h"
#import "NSArray+MNZCategory.h"
#import "NSURL+MNZCategory.h"
#import "UITextField+MNZCategory.h"

#import "BrowserViewController.h"
#import "CloudDriveTableViewController.h"
#import "CloudDriveCollectionViewController.h"
#import "ContactsViewController.h"
#import "CopyrightWarningViewController.h"
#import "EmptyStateView.h"
#import "CustomModalAlertViewController.h"
#import "MEGAImagePickerController.h"
#import "MEGANavigationController.h"
#import "MEGAPhotoBrowserViewController.h"
#import "NodeTableViewCell.h"
#import "PhotosViewController.h"
#import "PreviewDocumentViewController.h"
#import "SearchOperation.h"
#import "SharedItemsViewController.h"
#import "UIViewController+MNZCategory.h"

@import Photos;

static const NSTimeInterval kSearchTimeDelay = .5;
static const NSUInteger kMinDaysToEncourageToUpgrade = 3;

@interface CloudDriveViewController () <UINavigationControllerDelegate, UIDocumentPickerDelegate, UIDocumentMenuDelegate, UISearchBarDelegate, UISearchResultsUpdating, UIViewControllerPreviewingDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, MEGADelegate, MEGARequestDelegate, NodeActionViewControllerDelegate, NodeInfoViewControllerDelegate, UITextFieldDelegate, UISearchControllerDelegate, VNDocumentCameraViewControllerDelegate, RecentNodeActionDelegate, AudioPlayerPresenterProtocol, BrowserViewControllerDelegate, TextFileEditable> {
    
    MEGAShareType lowShareType; //Control the actions allowed for node/nodes selected
}

@property (weak, nonatomic) IBOutlet UIView *containerView;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *selectAllBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *moreBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *moreMinimizedBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *editBarButtonItem;

@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *downloadBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *shareBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *moveBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *carbonCopyBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *deleteBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *restoreBarButtonItem;

@property (nonatomic, strong) NSArray *nodesArray;

@property (nonatomic, strong) NSMutableArray *cloudImages;

@property (nonatomic, strong) CloudDriveTableViewController *cdTableView;
@property (nonatomic, strong) CloudDriveCollectionViewController *cdCollectionView;

@property (nonatomic, assign) ViewModePreference viewModePreference;
@property (nonatomic, assign) BOOL shouldDetermineViewMode;
@property (strong, nonatomic) NSOperationQueue *searchQueue;
@property (strong, nonatomic) MEGACancelToken *cancelToken;

@property (strong, nonatomic) Throttler *throttler;

@end

@implementation CloudDriveViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = self.containerView.backgroundColor = UIColor.mnz_background;
    
    self.definesPresentationContext = YES;
    
    switch (self.displayMode) {
        case DisplayModeCloudDrive: {
            if (!self.parentNode) {
                self.parentNode = [[MEGASdkManager sharedMEGASdk] rootNode];
            }
            break;
        }
            
        case DisplayModeRubbishBin: {
            [self.deleteBarButtonItem setImage:[UIImage imageNamed:@"rubbishBin"]];
            break;
        }
            
        default:
            break;
    }
    
    [self determineViewMode];
    
    if (self.displayMode != DisplayModeCloudDrive || (([MEGASdkManager.sharedMEGASdk accessLevelForNode:self.parentNode] != MEGAShareTypeAccessOwner) && MEGAReachabilityManager.isReachable)) {
    }
    
    [self setNavigationBarButtonItems];
    
    MEGAShareType shareType = [[MEGASdkManager sharedMEGASdk] accessLevelForNode:self.parentNode];
    [self toolbarActionsForShareType:shareType];
    
    NSString *thumbsDirectory = [Helper pathForSharedSandboxCacheDirectory:@"thumbnailsV3"];
    NSError *error;
    if (![[NSFileManager defaultManager] fileExistsAtPath:thumbsDirectory]) {
        if (![[NSFileManager defaultManager] createDirectoryAtPath:thumbsDirectory withIntermediateDirectories:NO attributes:nil error:&error]) {
            MEGALogError(@"Create directory at path failed with error: %@", error);
        }
    }
    
    NSString *previewsDirectory = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject stringByAppendingPathComponent:@"previewsV3"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:previewsDirectory]) {
        if (![[NSFileManager defaultManager] createDirectoryAtPath:previewsDirectory withIntermediateDirectories:NO attributes:nil error:&error]) {
            MEGALogError(@"Create directory at path failed with error: %@", error);
        }
    }
    
    self.nodesIndexPathMutableDictionary = [[NSMutableDictionary alloc] init];
    
    [self.view addGestureRecognizer:[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)]];
    
    self.moreBarButtonItem.accessibilityLabel = NSLocalizedString(@"more", @"Top menu option which opens more menu options in a context menu.");
    
    _searchQueue = NSOperationQueue.new;
    self.searchQueue.name = @"searchQueue";
    self.searchQueue.qualityOfService = NSQualityOfServiceUserInteractive;
    self.searchQueue.maxConcurrentOperationCount = 1;
    
    if (@available(iOS 13.0, *)) {
        [self configPreviewingRegistration];
    }
    
    StorageFullModalAlertViewController *warningVC = StorageFullModalAlertViewController.alloc.init;
    [warningVC showStorageAlertIfNeeded];
    
    self.searchController = [Helper customSearchControllerWithSearchResultsUpdaterDelegate:self searchBarDelegate:self];
    self.searchController.hidesNavigationBarDuringPresentation = NO;
    self.searchController.delegate = self;
    
    self.navigationController.delegate = self;
    self.throttler = [Throttler.alloc initWithTimeInterval:.1 dispatchQueue:dispatch_get_main_queue()];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(internetConnectionChanged) name:kReachabilityChangedNotification object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(reloadUI) name:MEGASortingPreference object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(determineViewMode) name:MEGAViewModePreference object:nil];
    
    [[MEGASdkManager sharedMEGASdk] addMEGADelegate:self];
    [[MEGAReachabilityManager sharedManager] retryPendingConnections];
    
    [self reloadUI];
    
    if (self.displayMode != DisplayModeRecents) {
        self.shouldRemovePlayerDelegate = YES;
    }
    
    if (self.myAvatarManager != nil) {
        [self refreshMyAvatar];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[TransfersWidgetViewController sharedTransferViewController].progressView showWidgetIfNeeded];

    [self encourageToUpgrade];
    
    [self requestReview];
    
    [AudioPlayerManager.shared addDelegate:self];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
    
    [[MEGASdkManager sharedMEGASdk] removeMEGADelegate:self];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    if (self.cdTableView.tableView.isEditing || self.cdCollectionView.collectionView.allowsMultipleSelection) {
        self.selectedNodesArray = nil;
        [self setEditMode:NO];
    }
    
    if (self.shouldRemovePlayerDelegate) {
        [AudioPlayerManager.shared removeDelegate:self];
    }
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self.cdTableView.tableView reloadEmptyDataSet];
    } completion:nil];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    
    if (@available(iOS 13.0, *)) {
        if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
            [AppearanceManager forceNavigationBarUpdate:self.navigationController.navigationBar traitCollection:self.traitCollection];
            [AppearanceManager forceToolbarUpdate:self.toolbar traitCollection:self.traitCollection];
            [AppearanceManager forceSearchBarUpdate:self.searchController.searchBar traitCollection:self.traitCollection];
            
            [self reloadData];
        }
    }
    
    [self configPreviewingRegistration];
}

#pragma mark - Layout

- (void)determineViewMode {
    ViewModePreference viewModePreference = [NSUserDefaults.standardUserDefaults integerForKey:MEGAViewModePreference];
    switch (viewModePreference) {
        case ViewModePreferencePerFolder:
            //Check Core Data or determine according to the number of nodes with or without thumbnail
            break;
            
        case ViewModePreferenceList:
            [self initTable];
            self.shouldDetermineViewMode = NO;
            return;
            
        case ViewModePreferenceThumbnail:
            [self initCollection];
            self.shouldDetermineViewMode = NO;
            return;
    }
    
    CloudAppearancePreference *cloudAppearancePreference = [MEGAStore.shareInstance fetchCloudAppearancePreferenceWithHandle:self.parentNode.handle];
    if (cloudAppearancePreference) {
        switch (cloudAppearancePreference.viewMode.integerValue) {
            case ViewModePreferenceList:
                [self initTable];
                break;
                
            case ViewModePreferenceThumbnail:
                [self initCollection];
                break;
                
            default:
                [self initTable];
                break;
        }
    } else {
        MEGANodeList *nodes = [[MEGASdkManager sharedMEGASdk] childrenForParent:self.parentNode];
        NSInteger nodesWithThumbnail = 0;
        NSInteger nodesWithoutThumbnail = 0;
        
        for (int i = 0; i < nodes.size.intValue; i++) {
            MEGANode *node = [nodes nodeAtIndex:i];
            if (node.hasThumbnail) {
                nodesWithThumbnail = nodesWithThumbnail + 1;
            } else {
                nodesWithoutThumbnail = nodesWithoutThumbnail + 1;
            }
        }
        
        if (nodesWithThumbnail > nodesWithoutThumbnail) {
            [self initCollection];
        } else {
            [self initTable];
        }
    }
    
    self.shouldDetermineViewMode = NO;
}

- (void)initTable {
    [self.cdCollectionView willMoveToParentViewController:nil];
    [self.cdCollectionView.view removeFromSuperview];
    [self.cdCollectionView removeFromParentViewController];
    self.cdCollectionView = nil;
    
    self.viewModePreference = ViewModePreferenceList;
    
    self.cdTableView = [self.storyboard instantiateViewControllerWithIdentifier:@"CloudDriveTableID"];
    [self addChildViewController:self.cdTableView];
    self.cdTableView.view.frame = self.containerView.bounds;
    [self.containerView addSubview:self.cdTableView.view];
    [self.cdTableView didMoveToParentViewController:self];
    
    self.cdTableView.cloudDrive = self;
    self.cdTableView.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    self.cdTableView.tableView.emptyDataSetDelegate = self;
    self.cdTableView.tableView.emptyDataSetSource = self;
}

- (void)initCollection {
    [self.cdTableView willMoveToParentViewController:nil];
    [self.cdTableView.view removeFromSuperview];
    [self.cdTableView removeFromParentViewController];
    self.cdTableView = nil;
    
    self.viewModePreference = ViewModePreferenceThumbnail;
    
    self.cdCollectionView = [self.storyboard instantiateViewControllerWithIdentifier:@"CloudDriveCollectionID"];
    self.cdCollectionView.cloudDrive = self;
    [self addChildViewController:self.cdCollectionView];
    self.cdCollectionView.view.frame = self.containerView.bounds;
    [self.containerView addSubview:self.cdCollectionView.view];
    [self.cdCollectionView didMoveToParentViewController:self];
    
    self.cdCollectionView.collectionView.emptyDataSetDelegate = self;
    self.cdCollectionView.collectionView.emptyDataSetSource = self;
}

- (void)changeViewModePreference {
    self.viewModePreference = (self.viewModePreference == ViewModePreferenceList) ? ViewModePreferenceThumbnail : ViewModePreferenceList;
    if ([NSUserDefaults.standardUserDefaults integerForKey:MEGAViewModePreference] == ViewModePreferencePerFolder) {
        [MEGAStore.shareInstance insertOrUpdateCloudViewModeWithHandle:self.parentNode.handle viewMode:self.viewModePreference];
    } else {
        [NSUserDefaults.standardUserDefaults setInteger:self.viewModePreference forKey:MEGAViewModePreference];
    }
    
    [NSNotificationCenter.defaultCenter postNotificationName:MEGAViewModePreference object:self userInfo:@{MEGAViewModePreference : @(self.viewModePreference)}];
}

#pragma mark - UIViewControllerPreviewingDelegate

- (UIViewController *)previewingContext:(id<UIViewControllerPreviewing>)previewingContext viewControllerForLocation:(CGPoint)location {
    
    if (self.cdTableView.tableView.isEditing || self.cdCollectionView.collectionView.allowsMultipleSelection) {
        return nil;
    }
    
    NSIndexPath *indexPath;
    if (self.viewModePreference == ViewModePreferenceList) {
        CGPoint cellPoint = [self.view convertPoint:location toView:self.cdTableView.tableView];
        indexPath = [self.cdTableView.tableView indexPathForRowAtPoint:cellPoint];
        if (!indexPath || ![self.cdTableView.tableView numberOfRowsInSection:indexPath.section]) {
            return nil;
        }
    } else {
        CGPoint cellPoint = [self.view convertPoint:location toView:self.cdCollectionView.collectionView];
        indexPath = [self.cdCollectionView.collectionView indexPathForItemAtPoint:cellPoint];
        if (!indexPath || ![self.cdCollectionView.collectionView numberOfItemsInSection:indexPath.section]) {
            return nil;
        }
    }
    
    MEGANode *node = [self nodeAtIndexPath:indexPath];
    if (node == nil) {
        return nil;
    }
    
    previewingContext.sourceRect = (self.viewModePreference == ViewModePreferenceList) ? [self.cdTableView.tableView convertRect:[self.cdTableView.tableView cellForRowAtIndexPath:indexPath].frame toView:self.view] : [self.cdCollectionView.collectionView convertRect:[self.cdCollectionView.collectionView cellForItemAtIndexPath:indexPath].frame toView:self.view];
    
    switch (node.type) {
        case MEGANodeTypeFolder: {
            CloudDriveViewController *cloudDriveVC = [self.storyboard instantiateViewControllerWithIdentifier:@"CloudDriveID"];
            cloudDriveVC.parentNode = node;
            if (self.displayMode == DisplayModeRubbishBin) {
                cloudDriveVC.displayMode = self.displayMode;
            }
            return cloudDriveVC;
            break;
        }
            
        case MEGANodeTypeFile: {
            if (node.name.mnz_isImagePathExtension || node.name.mnz_isVideoPathExtension) {
                return [self photoBrowserForMediaNode:node];
            } else {
                if (!node.mnz_isPlayable || (node.mnz_isPlayable && node.name.mnz_isVideoPathExtension)) {
                    UIViewController *viewController = [node mnz_viewControllerForNodeInFolderLink:NO fileLink:nil inViewController:self];
                    return viewController;
                }
            }
            break;
        }
            
        default:
            break;
    }
    
    return nil;
}

- (void)previewingContext:(id<UIViewControllerPreviewing>)previewingContext commitViewController:(UIViewController *)viewControllerToCommit {
    if (viewControllerToCommit.class == CloudDriveViewController.class) {
        [self.navigationController pushViewController:viewControllerToCommit animated:YES];
    } else if (viewControllerToCommit.class == PreviewDocumentViewController.class) {
        MEGANavigationController *navigationController = [[MEGANavigationController alloc] initWithRootViewController:viewControllerToCommit];
        [self.navigationController presentViewController:navigationController animated:YES completion:nil];
    } else {
        if (viewControllerToCommit.isBeingPresented || viewControllerToCommit.presentingViewController != nil) {
            return;
        }
        [self.navigationController presentViewController:viewControllerToCommit animated:YES completion:nil];
    }
}

- (NSArray<id<UIPreviewActionItem>> *)previewActions {
    UIViewController *rootViewController = UIApplication.sharedApplication.delegate.window.rootViewController;
    
    UIPreviewAction *saveForOfflineAction =
    [UIPreviewAction actionWithTitle:NSLocalizedString(@"saveForOffline", @"List option shown on the details of a file or folder")
                               style:UIPreviewActionStyleDefault
                             handler:^(UIPreviewAction * _Nonnull action, UIViewController * _Nonnull previewViewController) {
                                 CloudDriveViewController *cloudDriveVC = (CloudDriveViewController *)previewViewController;
                                 self.selectedNodesArray = [NSMutableArray new];
                                 [self.selectedNodesArray addObject:cloudDriveVC.parentNode];
                                 [self downloadAction:nil];
                             }];
    
    UIPreviewAction *copyAction = [UIPreviewAction actionWithTitle:NSLocalizedString(@"copy", @"List option shown on the details of a file or folder")
                                                             style:UIPreviewActionStyleDefault
                                                           handler:^(UIPreviewAction * _Nonnull action, UIViewController * _Nonnull previewViewController) {
                                                               CloudDriveViewController *cloudDriveVC = (CloudDriveViewController *)previewViewController;
                                                               [cloudDriveVC.parentNode mnz_copyInViewController:rootViewController];
                                                           }];
    
    NSString *deletePreviewActionTitle;
    UITabBarController *tabBarController = (UITabBarController *)self.presentingViewController;
    UINavigationController *navigationController = tabBarController.selectedViewController;
    if (navigationController.viewControllers.lastObject.class == SharedItemsViewController.class) {
        MEGAShareType shareType = [[MEGASdkManager sharedMEGASdk] accessLevelForNode:self.parentNode];
        if (shareType == MEGAShareTypeAccessOwner) {
            deletePreviewActionTitle = NSLocalizedString(@"removeSharing", @"Alert title shown on the Shared Items section when you want to remove 1 share");
        }
    } else {
        if (self.displayMode == DisplayModeCloudDrive || self.displayMode == DisplayModeSharedItem) {
            deletePreviewActionTitle = NSLocalizedString(@"moveToTheRubbishBin", @"Title for the action that allows you to 'Move to the Rubbish Bin' files or folders");
        } else if (self.displayMode == DisplayModeRubbishBin) {
            deletePreviewActionTitle = NSLocalizedString(@"remove", @"Title for the action that allows to remove a file or folder");
        }
    }
    UIPreviewAction *deleteAction =
    [UIPreviewAction actionWithTitle:deletePreviewActionTitle
                               style:UIPreviewActionStyleDestructive
                             handler:^(UIPreviewAction * _Nonnull action, UIViewController * _Nonnull previewViewController) {
                                 CloudDriveViewController *cloudDriveVC = (CloudDriveViewController *)previewViewController;
                                 MEGANode *parentNode = cloudDriveVC.parentNode;
                                 MEGAShareType accessType = [[MEGASdkManager sharedMEGASdk] accessLevelForNode:parentNode];
                                 if (accessType == MEGAShareTypeAccessOwner) {
                                     if (self.displayMode == DisplayModeCloudDrive) {
                                         if (navigationController.viewControllers.lastObject.class == CloudDriveViewController.class) {
                                             [parentNode mnz_moveToTheRubbishBinWithCompletion:^{
                                                 [self setEditMode:NO];
                                             }];
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
                                             [MEGAStore.shareInstance deleteCloudAppearancePreferenceWithHandle:parentNode.handle];
                                             
                                             [self setEditMode:NO];
                                         }];
                                         [[MEGASdkManager sharedMEGASdk] removeNode:parentNode delegate:removeRequestDelegate];
                                     }
                                 } if (accessType == MEGAShareTypeAccessFull) { //DisplayModeSharedItem (Move to the Rubbish Bin)
                                     [parentNode mnz_moveToTheRubbishBinWithCompletion:^{
                                         [self setEditMode:NO];
                                     }];
                                 }
    }];
    
    MEGAShareType shareType = [[MEGASdkManager sharedMEGASdk] accessLevelForNode:self.parentNode];
    NSArray<id<UIPreviewActionItem>> *previewActions;
    switch (shareType) {
        case MEGAShareTypeAccessRead:
        case MEGAShareTypeAccessReadWrite:
        case MEGAShareTypeAccessFull: {
            if (navigationController.viewControllers.lastObject.class == CloudDriveViewController.class) {
                previewActions = (shareType == MEGAShareTypeAccessFull) ? @[saveForOfflineAction, copyAction, deleteAction] : @[saveForOfflineAction, copyAction];
            } else if (navigationController.viewControllers.lastObject.class == SharedItemsViewController.class) {
                UIPreviewAction *leaveShareAction = [UIPreviewAction actionWithTitle:NSLocalizedString(@"leave", @"A button label. The button allows the user to leave the group conversation.")
                                                                               style:UIPreviewActionStyleDestructive
                                                                             handler:^(UIPreviewAction * _Nonnull action, UIViewController * _Nonnull previewViewController) {
                                                                                 CloudDriveViewController *cloudDriveVC = (CloudDriveViewController *)previewViewController;
                                                                                 
                                                                                 NSString *alertMessage = (cloudDriveVC.selectedNodesArray.count > 1) ? NSLocalizedString(@"leaveSharesAlertMessage", @"Alert message shown when the user tap on the leave share action selecting multipe inshares") : NSLocalizedString(@"leaveShareAlertMessage", @"Alert message shown when the user tap on the leave share action for one inshare");
                                                                                 UIAlertController *leaveAlertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"leaveFolder", @"Button title of the action that allows to leave a shared folder") message:alertMessage preferredStyle:UIAlertControllerStyleAlert];
                                                                                 [leaveAlertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"cancel", @"Button title to cancel something") style:UIAlertActionStyleCancel handler:nil]];
                                                                                 
                                                                                 [leaveAlertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"ok", @"Button title to cancel something") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                                                                                     MEGARemoveRequestDelegate *removeRequestDelegate = [[MEGARemoveRequestDelegate alloc] initWithMode:DisplayModeSharedItem files:(self.parentNode.isFile ? 1 : 0) folders:(self.parentNode.isFolder ? 1 : 0) completion:^{
                                                                                         [self setEditMode:NO];
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
            UIPreviewAction *shareAction = [UIPreviewAction actionWithTitle:NSLocalizedString(@"share", @"Button title which, if tapped, will trigger the action of sharing with the contact or contacts selected ")
                                                                      style:UIPreviewActionStyleDefault
                                                                    handler:^(UIPreviewAction * _Nonnull action, UIViewController * _Nonnull previewViewController) {
                                                                        CloudDriveViewController *cloudDriveVC = (CloudDriveViewController *)previewViewController;
                                                                        UIActivityViewController *activityVC = [UIActivityViewController activityViewControllerForNodes:@[cloudDriveVC.parentNode] sender:nil];
                                                                        [rootViewController presentViewController:activityVC animated:YES completion:nil];
                                                                    }];
            
            UIPreviewAction *moveAction = [UIPreviewAction actionWithTitle:NSLocalizedString(@"move", @"Title for the action that allows you to move a file or folder")
                                                                     style:UIPreviewActionStyleDefault
                                                                   handler:^(UIPreviewAction * _Nonnull action, UIViewController * _Nonnull previewViewController) {
                                                                       CloudDriveViewController *cloudDriveVC = (CloudDriveViewController *)previewViewController;
                                                                       [cloudDriveVC.parentNode mnz_moveInViewController:rootViewController];
                                                                   }];
            
            if (self.displayMode == DisplayModeCloudDrive) {
                if (navigationController.viewControllers.lastObject.class == SharedItemsViewController.class) {
                    UIPreviewAction *shareFolderPreviewAction = [UIPreviewAction actionWithTitle:NSLocalizedString(@"shareFolder", @"Button title which, if tapped, will trigger the action of sharing with the contact or contacts selected, the folder you want inside your Cloud Drive")
                                                                                           style:UIPreviewActionStyleDefault
                                                                                         handler:^(UIPreviewAction * _Nonnull action, UIViewController * _Nonnull previewViewController) {
                                                                                             CloudDriveViewController *cloudDriveVC = (CloudDriveViewController *)previewViewController;
                                                                                             MEGANavigationController *navigationController = [[UIStoryboard storyboardWithName:@"Contacts" bundle:nil] instantiateViewControllerWithIdentifier:@"ContactsNavigationControllerID"];
                                                                                             ContactsViewController *contactsVC = navigationController.viewControllers.firstObject;
                                                                                             contactsVC.contactsMode = ContactsModeShareFoldersWith;
                                                                                             contactsVC.nodesArray = @[cloudDriveVC.parentNode];
                                                                                             [rootViewController presentViewController:navigationController animated:YES completion:nil];
                                                                                         }];
                    
                    previewActions = @[shareAction, shareFolderPreviewAction, copyAction, deleteAction];
                } else if (navigationController.viewControllers.lastObject.class == CloudDriveViewController.class) {
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
    UIView *view = self.cdTableView ? self.cdTableView.tableView : self.cdCollectionView.collectionView;
    CGPoint touchPoint = [longPressGestureRecognizer locationInView:view];
    
    NSIndexPath *indexPath;
    
    if (self.viewModePreference == ViewModePreferenceList) {
        indexPath = [self.cdTableView.tableView indexPathForRowAtPoint:touchPoint];
        if (!indexPath || ![self.cdTableView.tableView numberOfRowsInSection:indexPath.section]) {
            return;
        }
    } else {
        indexPath = [self.cdCollectionView.collectionView indexPathForItemAtPoint:touchPoint];
        if (!indexPath || ![self.cdCollectionView.collectionView numberOfItemsInSection:indexPath.section]) {
            return;
        }
    }
    
    if (longPressGestureRecognizer.state == UIGestureRecognizerStateBegan) {
        BOOL editing = self.cdTableView ? self.cdTableView.tableView.isEditing : self.cdCollectionView.collectionView.allowsMultipleSelection;
        if (editing) {
            // Only stop editing if long pressed over a cell that is the only one selected or when selected none
            if (self.selectedNodesArray.count == 0) {
                [self setEditMode:NO];
            }
            if (self.selectedNodesArray.count == 1) {
                MEGANode *nodeSelected = self.selectedNodesArray.firstObject;
                MEGANode *nodePressed = [self nodeAtIndexPath:indexPath];
                if (nodeSelected.handle == nodePressed.handle) {
                    [self setEditMode:NO];
                }
            }
        } else {
            [self setEditMode:YES];
            [self selectIndexPath:indexPath];
        }
    }
    
    if (longPressGestureRecognizer.state == UIGestureRecognizerStateEnded) {
        [self.cdTableView.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
    }
}

#pragma mark - DZNEmptyDataSetSource

- (nullable UIView *)customViewForEmptyDataSet:(UIScrollView *)scrollView {
    EmptyStateView *emptyStateView = [EmptyStateView.alloc initWithImage:[self imageForEmptyState] title:[self titleForEmptyState] description:[self descriptionForEmptyState] buttonTitle:[self buttonTitleForEmptyState]];
    [emptyStateView.button addTarget:self action:@selector(buttonTouchUpInsideEmptyState) forControlEvents:UIControlEventTouchUpInside];
    
    return emptyStateView;
}

#pragma mark - Empty State

- (NSString *)titleForEmptyState {
    NSString *text;
    if ([MEGAReachabilityManager isReachable]) {
        if (self.parentNode == nil) {
            return nil;
        }

        if (self.searchController.isActive) {
            text = NSLocalizedString(@"noResults", nil);
        } else {
            switch (self.displayMode) {
                case DisplayModeCloudDrive: {
                    if ([self.parentNode type] == MEGANodeTypeRoot) {
                        text = NSLocalizedString(@"cloudDriveEmptyState_title", @"Title shown when your Cloud Drive is empty, when you don't have any files.");
                    } else {
                        text = NSLocalizedString(@"emptyFolder", @"Title shown when a folder doesn't have any files");
                    }
                    break;
                }

                case DisplayModeRubbishBin:
                    if ([self.parentNode type] == MEGANodeTypeRubbish) {
                        text = NSLocalizedString(@"cloudDriveEmptyState_titleRubbishBin", @"Title shown when your Rubbish Bin is empty.");
                    } else {
                        text = NSLocalizedString(@"emptyFolder", @"Title shown when a folder doesn't have any files");
                    }
                    break;

                default:
                    break;
            }
        }
    } else {
        text = NSLocalizedString(@"noInternetConnection",  @"No Internet Connection");
    }

    return text;
}

- (NSString *)descriptionForEmptyState {
    NSString *text = @"";
    if (!MEGAReachabilityManager.isReachable && !MEGAReachabilityManager.sharedManager.isMobileDataEnabled) {
        text = NSLocalizedString(@"Mobile Data is turned off", @"Information shown when the user has disabled the 'Mobile Data' setting for MEGA in the iOS Settings.");
    }

    return text;
}

- (UIImage *)imageForEmptyState {
    UIImage *image = nil;
    if ([MEGAReachabilityManager isReachable]) {
        if (self.parentNode == nil) {
            return nil;
        }

        if (self.searchController.isActive) {
            image = [UIImage imageNamed:@"searchEmptyState"];
        } else {
            switch (self.displayMode) {
                case DisplayModeCloudDrive: {
                    if ([self.parentNode type] == MEGANodeTypeRoot) {
                        image = [UIImage imageNamed:@"cloudEmptyState"];
                    } else {
                        image = [UIImage imageNamed:@"folderEmptyState"];
                    }
                    break;
                }

                case DisplayModeRubbishBin: {
                    if ([self.parentNode type] == MEGANodeTypeRubbish) {
                        image = [UIImage imageNamed:@"rubbishEmptyState"];
                    } else {
                        image = [UIImage imageNamed:@"folderEmptyState"];
                    }
                    break;
                }

                default:
                    break;
            }
        }
    } else {
        image = [UIImage imageNamed:@"noInternetEmptyState"];
    }

    return image;
}

- (NSString *)buttonTitleForEmptyState {
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
                    text = NSLocalizedString(@"addFiles", nil);
                }
                break;
            }

            default:
                text = @"";
                break;
        }
    } else {
        if (!MEGAReachabilityManager.sharedManager.isMobileDataEnabled) {
            text = NSLocalizedString(@"Turn Mobile Data on", @"Button title to go to the iOS Settings to enable 'Mobile Data' for the MEGA app.");
        }
    }

    return text;
}

- (void)buttonTouchUpInsideEmptyState {
    if (MEGAReachabilityManager.isReachable) {
        switch (self.displayMode) {
            case DisplayModeCloudDrive: {
                [self presentUploadAlertController];
                break;
            }
                
            default:
                break;
        }
    } else {
        if (!MEGAReachabilityManager.sharedManager.isMobileDataEnabled) {
            [UIApplication.sharedApplication openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString] options:@{} completionHandler:nil];
        }
    }
}

#pragma mark - Public

- (void)didSelectNode:(MEGANode *)node {
    if (node.isTakenDown) {
        NSString *alertMessage = node.isFolder ? NSLocalizedString(@"This folder has been the subject of a takedown notice.", @"Popup notification text on mouse-over taken down folder.") : NSLocalizedString(@"This file has been the subject of a takedown notice.", @"Popup notification text on mouse-over of taken down file.");
        
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:alertMessage preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"openButton", @"Button title to trigger the action of opening the file without downloading or opening it.") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            node.isFolder ? [self openFolderNode:node] : [self openFileNode:node];
        }]];
        [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Dispute Takedown", @"File Manager -> Context menu item for taken down file or folder, for dispute takedown.") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [[NSURL URLWithString:MEGADisputeURL] mnz_presentSafariViewController];
        }]];
        [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"cancel", @"Button title to cancel something") style:UIAlertActionStyleCancel handler:nil]];
        
        [self presentViewController:alertController animated:YES completion:nil];
    } else {
        node.isFolder ? [self openFolderNode:node] : [self openFileNode:node];
    }
}

- (nullable MEGANode *)nodeAtIndexPath:(NSIndexPath *)indexPath {
    BOOL isInSearch = self.searchController.searchBar.text.length >= kMinimumLettersToStartTheSearch;
    MEGANode *node;
    if (self.viewModePreference == ViewModePreferenceList) {
        node = isInSearch ? [self.searchNodesArray objectOrNilAtIndex:indexPath.row] : [self.nodes nodeAtIndex:indexPath.row];
    } else {
        node = [self.cdCollectionView thumbnailNodeAtIndexPath:indexPath];
    }
    
    return node;
}

#pragma mark - Private

- (void)reloadUI {
    switch (self.displayMode) {
        case DisplayModeCloudDrive: {
            if (!self.parentNode) {
                self.parentNode = [[MEGASdkManager sharedMEGASdk] rootNode];
            }
            [self updateNavigationBarTitle];
            self.nodes = [MEGASdkManager.sharedMEGASdk childrenForParent:self.parentNode order:[Helper sortTypeFor:self.parentNode]];

            break;
        }
            
        case DisplayModeRubbishBin: {
            [self updateNavigationBarTitle];
            self.nodes = [MEGASdkManager.sharedMEGASdk childrenForParent:self.parentNode order:[Helper sortTypeFor:self.parentNode]];
            self.moreMinimizedBarButtonItem.enabled = self.nodes.size.integerValue > 0;
            
            break;
        }
            
        case DisplayModeRecents: {
            [self updateNavigationBarTitle];
            break;
        }
            
        default:
            break;
    }
    
    [self setNavigationBarButtonItemsEnabled:MEGAReachabilityManager.isReachable];
    self.navigationItem.searchController = self.searchController;
    self.navigationItem.hidesSearchBarWhenScrolling = NO;
    
    NSMutableArray *tempArray = [[NSMutableArray alloc] initWithCapacity:self.nodes.size.integerValue];
    for (NSUInteger i = 0; i < self.nodes.size.integerValue ; i++) {
        [tempArray addObject:[self.nodes nodeAtIndex:i]];
    }
    
    self.nodesArray = tempArray;
    
    if (self.shouldDetermineViewMode) {
        [self determineViewMode];
    }
    
    [self reloadData];
}

- (void)loadPhotoAlbumBrowser {
    AlbumsTableViewController *albumTableViewController = [AlbumsTableViewController.alloc initWithSelectionActionText:NSLocalizedString(@"Upload (%d)", @"Used in Photos app browser view to send the photos from the view to the cloud.") selectionActionDisabledText:NSLocalizedString(@"upload", @"Used in Photos app browser view as a disabled action when there is no assets selected") completionBlock:^(NSArray<PHAsset *> * _Nonnull assets) {
        if (assets.count > 0) {
            for (PHAsset *asset in assets) {
                [MEGAStore.shareInstance insertUploadTransferWithLocalIdentifier:asset.localIdentifier parentNodeHandle:self.parentNode.handle];
            }
            
            [Helper startPendingUploadTransferIfNeeded];
        }
    }];
    MEGANavigationController *navigationController = [MEGANavigationController.alloc initWithRootViewController:albumTableViewController];
    [self presentViewController:navigationController animated:YES completion:nil];
}

- (void)showImagePickerForSourceType:(UIImagePickerControllerSourceType)sourceType {
    if (sourceType == UIImagePickerControllerSourceTypeCamera) {
        MEGAImagePickerController *imagePickerController = [[MEGAImagePickerController alloc] initToUploadWithParentNode:self.parentNode sourceType:sourceType];
        [self presentViewController:imagePickerController animated:YES completion:nil];
    } else {
        [DevicePermissionsHelper photosPermissionWithCompletionHandler:^(BOOL granted) {
            if (granted) {
                [self loadPhotoAlbumBrowser];
            } else {
                [DevicePermissionsHelper alertPhotosPermission];
            }
        }];
    }
}

- (void)toolbarActionsForShareType:(MEGAShareType )shareType {
    UIBarButtonItem *flexibleItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    lowShareType = shareType;
    
    switch (shareType) {
        case MEGAShareTypeAccessRead:
        case MEGAShareTypeAccessReadWrite: {
            self.toolbar.items = @[self.downloadBarButtonItem, flexibleItem, self.carbonCopyBarButtonItem];
            break;
        }
            
        case MEGAShareTypeAccessFull: {
            self.toolbar.items = @[self.downloadBarButtonItem, flexibleItem, self.carbonCopyBarButtonItem, flexibleItem, self.moveBarButtonItem, flexibleItem, self.deleteBarButtonItem];
            break;
        }
            
        case MEGAShareTypeAccessOwner: {
            if (self.displayMode == DisplayModeCloudDrive) {
                [self.toolbar setItems:@[self.downloadBarButtonItem, flexibleItem, self.shareBarButtonItem, flexibleItem, self.moveBarButtonItem, flexibleItem, self.carbonCopyBarButtonItem, flexibleItem, self.deleteBarButtonItem]];
            } else { //Rubbish Bin
                [self.toolbar setItems:@[self.restoreBarButtonItem, flexibleItem, self.moveBarButtonItem, flexibleItem, self.carbonCopyBarButtonItem, flexibleItem, self.deleteBarButtonItem]];
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
    self.restoreBarButtonItem.enabled = boolValue;
    
    if ((self.displayMode == DisplayModeRubbishBin) && boolValue) {
        for (MEGANode *n in self.selectedNodesArray) {
            if (!n.mnz_isRestorable) {
                self.restoreBarButtonItem.enabled = NO;
                break;
            }
        }
    }
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
    [self reloadUI];
}

- (void)setNavigationBarButtonItems {
    switch (self.displayMode) {
        case DisplayModeCloudDrive: {
            if ([[MEGASdkManager sharedMEGASdk] accessLevelForNode:self.parentNode] == MEGAShareTypeAccessRead) {
                self.navigationItem.rightBarButtonItems = @[self.moreMinimizedBarButtonItem];
            } else {
                self.navigationItem.rightBarButtonItems = @[self.moreBarButtonItem];
            }
            break;
        }
            
        case DisplayModeRubbishBin:
            self.navigationItem.rightBarButtonItems = @[self.moreMinimizedBarButtonItem];
            break;
            
        case DisplayModeRecents:
            self.navigationItem.rightBarButtonItems = @[];
            self.navigationItem.leftBarButtonItem =[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"close", @"A button label.")
                                                                                    style:UIBarButtonItemStylePlain
                                                                                   target:self
                                                                                   action:@selector(dismissSelf)];
            break;
            
        default:
            break;
    }
}

- (void)dismissSelf {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)setNavigationBarButtonItemsEnabled:(BOOL)boolValue {
    
    switch (self.displayMode) {
        case DisplayModeCloudDrive: {
            self.moreMinimizedBarButtonItem.enabled = boolValue;
            self.moreBarButtonItem.enabled = boolValue;
            break;
        }
            
        case DisplayModeRubbishBin: {
            self.editBarButtonItem.enabled = boolValue;
            break;
        }
            
        case DisplayModeRecents: {
            break;
        }
            
        default:
            break;
    }
}

- (void)presentSortByActionSheet {
    MEGASortOrderType sortType = [Helper sortTypeFor:self.parentNode];
    
    UIImageView *checkmarkImageView = [UIImageView.alloc initWithImage:[UIImage imageNamed:@"turquoise_checkmark"]];
    
    NSMutableArray<ActionSheetAction *> *actions = NSMutableArray.new;
    [actions addObject:[ActionSheetAction.alloc initWithTitle:NSLocalizedString(@"nameAscending", nil) detail:nil accessoryView:sortType == MEGASortOrderTypeDefaultAsc ? checkmarkImageView : nil image:[UIImage imageNamed:@"ascending"] style:UIAlertActionStyleDefault actionHandler:^{
        [Helper saveSortOrder:MEGASortOrderTypeDefaultAsc for:self.parentNode];
        [self reloadUI];
    }]];
    [actions addObject:[ActionSheetAction.alloc initWithTitle:NSLocalizedString(@"nameDescending", nil) detail:nil accessoryView:sortType == MEGASortOrderTypeDefaultDesc ? checkmarkImageView : nil image:[UIImage imageNamed:@"descending"] style:UIAlertActionStyleDefault actionHandler:^{
        [Helper saveSortOrder:MEGASortOrderTypeDefaultDesc for:self.parentNode];
        [self reloadUI];
    }]];
    [actions addObject:[ActionSheetAction.alloc initWithTitle:NSLocalizedString(@"largest", nil) detail:nil accessoryView:sortType == MEGASortOrderTypeSizeDesc ? checkmarkImageView : nil image:[UIImage imageNamed:@"largest"] style:UIAlertActionStyleDefault actionHandler:^{
        [Helper saveSortOrder:MEGASortOrderTypeSizeDesc for:self.parentNode];
        [self reloadUI];
    }]];
    [actions addObject:[ActionSheetAction.alloc initWithTitle:NSLocalizedString(@"smallest", nil) detail:nil accessoryView:sortType == MEGASortOrderTypeSizeAsc ? checkmarkImageView : nil image:[UIImage imageNamed:@"smallest"] style:UIAlertActionStyleDefault actionHandler:^{
        [Helper saveSortOrder:MEGASortOrderTypeSizeAsc for:self.parentNode];
        [self reloadUI];
    }]];
    [actions addObject:[ActionSheetAction.alloc initWithTitle:NSLocalizedString(@"newest", nil) detail:nil accessoryView:sortType == MEGASortOrderTypeModificationDesc ? checkmarkImageView : nil image:[UIImage imageNamed:@"newest"] style:UIAlertActionStyleDefault actionHandler:^{
        [Helper saveSortOrder:MEGASortOrderTypeModificationDesc for:self.parentNode];
        [self reloadUI];
    }]];
    [actions addObject:[ActionSheetAction.alloc initWithTitle:NSLocalizedString(@"oldest", nil) detail:nil accessoryView:sortType == MEGASortOrderTypeModificationAsc ? checkmarkImageView : nil image:[UIImage imageNamed:@"oldest"] style:UIAlertActionStyleDefault actionHandler:^{
        [Helper saveSortOrder:MEGASortOrderTypeModificationAsc for:self.parentNode];
        [self reloadUI];
    }]];
    
    [actions addObject:[ActionSheetAction.alloc initWithTitle:NSLocalizedString(@"Label", @"A menu item in the left panel drop down menu to allow sorting by label.") detail:nil accessoryView:sortType == MEGASortOrderTypeLabelAsc ? checkmarkImageView : nil image:[UIImage imageNamed:@"label"] style:UIAlertActionStyleDefault actionHandler:^{
        [Helper saveSortOrder:MEGASortOrderTypeLabelAsc for:self.parentNode];
        [self reloadUI];
    }]];
    
    [actions addObject:[ActionSheetAction.alloc initWithTitle:NSLocalizedString(@"Favourite", @"Context menu item. Allows user to add file/folder to favourites") detail:nil accessoryView:sortType == MEGASortOrderTypeFavouriteAsc ? checkmarkImageView : nil image:[UIImage imageNamed:@"favourite"] style:UIAlertActionStyleDefault actionHandler:^{
        [Helper saveSortOrder:MEGASortOrderTypeFavouriteAsc for:self.parentNode];
        [self reloadUI];
    }]];
    
    ActionSheetViewController *sortByActionSheet = [ActionSheetViewController.alloc initWithActions:actions headerTitle:nil dismissCompletion:nil sender:self.navigationItem.rightBarButtonItems.firstObject];
    [self presentViewController:sortByActionSheet animated:YES completion:nil];
}

- (void)newFolderAlertTextFieldDidChange:(UITextField *)textField {
    UIAlertController *newFolderAlertController = (UIAlertController *)self.presentedViewController;
    if ([newFolderAlertController isKindOfClass:UIAlertController.class]) {
        UIAlertAction *rightButtonAction = newFolderAlertController.actions.lastObject;
        BOOL containsInvalidChars = textField.text.mnz_containsInvalidChars;
        textField.textColor = containsInvalidChars ? UIColor.mnz_redError : UIColor.mnz_label;
        rightButtonAction.enabled = (!textField.text.mnz_isEmpty && !containsInvalidChars);
    }
}

- (void)presentUploadAlertController {
    NSMutableArray<ActionSheetAction *> *actions = NSMutableArray.new;
    [actions addObject:[ActionSheetAction.alloc initWithTitle:NSLocalizedString(@"choosePhotoVideo", @"Menu option from the `Add` section that allows the user to choose a photo or video to upload it to MEGA") detail:nil image:[UIImage imageNamed:@"saveToPhotos"] style:UIAlertActionStyleDefault actionHandler:^{
        [self showImagePickerForSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
    }]];
    [actions addObject:[ActionSheetAction.alloc initWithTitle:NSLocalizedString(@"capturePhotoVideo", @"Menu option from the `Add` section that allows the user to capture a video or a photo and upload it directly to MEGA.") detail:nil image:[UIImage imageNamed:@"capture"] style:UIAlertActionStyleDefault actionHandler:^{
        [DevicePermissionsHelper videoPermissionWithCompletionHandler:^(BOOL granted) {
            if (granted) {
                [DevicePermissionsHelper photosPermissionWithCompletionHandler:^(BOOL granted) {
                    if (granted) {
                        [self showImagePickerForSourceType:UIImagePickerControllerSourceTypeCamera];
                    } else {
                        [NSUserDefaults.standardUserDefaults setBool:NO forKey:@"isSaveMediaCapturedToGalleryEnabled"];
                        [self showImagePickerForSourceType:UIImagePickerControllerSourceTypeCamera];
                    }
                }];
            } else {
                [DevicePermissionsHelper alertVideoPermissionWithCompletionHandler:nil];
            }
        }];
    }]];
    [actions addObject:[ActionSheetAction.alloc initWithTitle:NSLocalizedString(@"uploadFrom", @"Option given on the `Add` section to allow the user upload something from another cloud storage provider.") detail:nil image:[UIImage imageNamed:@"import"] style:UIAlertActionStyleDefault actionHandler:^{
        UIDocumentMenuViewController *documentMenuViewController = [[UIDocumentMenuViewController alloc] initWithDocumentTypes:@[(__bridge NSString *) kUTTypeContent, (__bridge NSString *) kUTTypeData,(__bridge NSString *) kUTTypePackage, (@"com.apple.iwork.pages.pages"), (@"com.apple.iwork.numbers.numbers"), (@"com.apple.iwork.keynote.key")] inMode:UIDocumentPickerModeImport];
        documentMenuViewController.delegate = self;
        documentMenuViewController.popoverPresentationController.barButtonItem = self.moreBarButtonItem;
        
        [self presentViewController:documentMenuViewController animated:YES completion:nil];
    }]];
    
    ActionSheetViewController *uploadActions =[ActionSheetViewController.alloc initWithActions:actions headerTitle:nil dismissCompletion:nil sender:self.navigationItem.rightBarButtonItems.firstObject];
    [self presentViewController:uploadActions animated:YES completion:nil];
}

- (void)presentScanDocument {
    if (@available(iOS 13.0, *)) {
        if (!VNDocumentCameraViewController.isSupported) {
            [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Document scanning is not available", @"A tooltip message which is shown when device does not support document scanning")];
            return;
        }
        
        [self presentViewController:({
            VNDocumentCameraViewController *scanVC = [VNDocumentCameraViewController.alloc init];
            scanVC.delegate = self;
            scanVC;
        }) animated:YES completion:nil];
    }
}

- (void)updateNavigationBarTitle {
    NSString *navigationTitle;
    if (self.cdTableView.tableView.isEditing || self.cdCollectionView.collectionView.allowsMultipleSelection) {
        if (self.selectedNodesArray.count == 0) {
            navigationTitle = NSLocalizedString(@"selectTitle", @"Title shown on the Camera Uploads section when the edit mode is enabled. On this mode you can select photos");
        } else {
            navigationTitle = (self.selectedNodesArray.count == 1) ? [NSString stringWithFormat:NSLocalizedString(@"oneItemSelected", @"Title shown on the Camera Uploads section when the edit mode is enabled and you have selected one photo"), self.selectedNodesArray.count] : [NSString stringWithFormat:NSLocalizedString(@"itemsSelected", @"Title shown on the Camera Uploads section when the edit mode is enabled and you have selected more than one photo"), self.selectedNodesArray.count];
        }
    } else {
        switch (self.displayMode) {
            case DisplayModeCloudDrive: {
                if (!self.parentNode || self.parentNode.type == MEGANodeTypeRoot) {
                    navigationTitle = NSLocalizedString(@"cloudDrive", @"Title of the Cloud Drive section");
                } else {
                    navigationTitle = [self.parentNode name];
                }
                break;
            }
                
            case DisplayModeRubbishBin: {
                if ([self.parentNode type] == MEGANodeTypeRubbish) {
                    navigationTitle = NSLocalizedString(@"rubbishBinLabel", @"Title of one of the Settings sections where you can see your MEGA 'Rubbish Bin'");
                } else {
                    navigationTitle = [self.parentNode name];
                }
                break;
            }
                
            case DisplayModeRecents: {
                navigationTitle = [NSString stringWithFormat:NSLocalizedString(@"%1$d items", @"Plural of items which contains a folder. 2 items"), self.nodes.size.intValue];
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
    
    NSDate *accountCreationDate = MEGASdkManager.sharedMEGASdk.accountCreationDate;
    NSInteger days = [NSCalendar.currentCalendar components:NSCalendarUnitDay
                                                   fromDate:accountCreationDate
                                                     toDate:NSDate.date
                                                    options:NSCalendarWrapComponents].day;
    
    if (!alreadyPresented && ![[MEGASdkManager sharedMEGASdk] mnz_isProAccount] && days > kMinDaysToEncourageToUpgrade) {
        NSDate *lastEncourageUpgradeDate = [[NSUserDefaults standardUserDefaults] objectForKey:@"lastEncourageUpgradeDate"];
        if (lastEncourageUpgradeDate) {
            NSInteger week = [[NSCalendar currentCalendar] components:NSCalendarUnitWeekOfYear
                                                             fromDate:lastEncourageUpgradeDate
                                                               toDate:[NSDate date]
                                                              options:NSCalendarWrapComponents].weekOfYear;
            if (week < 1) {
                return;
            }
        }
        MEGAAccountDetails *accountDetails = [[MEGASdkManager sharedMEGASdk] mnz_accountDetails];
        if (accountDetails && (arc4random_uniform(20) == 0)) { // 5 % of the times
            [UpgradeAccountRouter.new presentUpgradeTVC];
            [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:@"lastEncourageUpgradeDate"];
            alreadyPresented = YES;
        }
    }
}

- (void)requestReview {
    static BOOL alreadyPresented = NO;
    if (!alreadyPresented && [[MEGASdkManager sharedMEGASdk] mnz_accountDetails] && [[MEGASdkManager sharedMEGASdk] mnz_isProAccount]) {
        alreadyPresented = YES;
        NSUserDefaults *sharedUserDefaults = [NSUserDefaults.alloc initWithSuiteName:MEGAGroupIdentifier];
        NSDate *rateUsDate = [sharedUserDefaults objectForKey:@"rateUsDate"];
        if (rateUsDate) {
            NSInteger weeks = [[NSCalendar currentCalendar] components:NSCalendarUnitWeekOfYear
                                                              fromDate:rateUsDate
                                                                toDate:[NSDate date]
                                                               options:NSCalendarWrapComponents].weekOfYear;
            if (weeks < 17) {
                return;
            }
        } else {
            NSTimeInterval sixteenWeeksAgo = -16 * 7 * 24 * 60 * 60;
            rateUsDate = [NSDate dateWithTimeIntervalSinceNow:sixteenWeeksAgo];
            [sharedUserDefaults setObject:rateUsDate forKey:@"rateUsDate"];
            return;
        }
        [SKStoreReviewController requestReview];
        rateUsDate = [NSDate date];
        [sharedUserDefaults setObject:rateUsDate forKey:@"rateUsDate"];
    }
}

- (void)showNodeInfo:(MEGANode *)node {
    MEGANavigationController *nodeInfoNavigation = [NodeInfoViewController instantiateWithNode:node delegate:self];
    [self presentViewController:nodeInfoNavigation animated:YES completion:nil];
}

- (MEGAPhotoBrowserViewController *)photoBrowserForMediaNode:(MEGANode *)node {
    NSArray *nodesArray = (self.searchController.isActive && !self.searchController.searchBar.text.mnz_isEmpty) ? self.searchNodesArray : [self.nodes mnz_nodesArrayFromNodeList];
    NSMutableArray<MEGANode *> *mediaNodesArray = [[NSMutableArray alloc] initWithCapacity:nodesArray.count];
    for (MEGANode *n in nodesArray) {
        if (n.name.mnz_isImagePathExtension || n.name.mnz_isVideoPathExtension) {
            [mediaNodesArray addObject:n];
        }
    }
    
    DisplayMode displayMode = [[MEGASdkManager sharedMEGASdk] accessLevelForNode:node] == MEGAShareTypeAccessOwner ? self.displayMode : DisplayModeSharedItem;
    MEGAPhotoBrowserViewController *photoBrowserVC = [MEGAPhotoBrowserViewController photoBrowserWithMediaNodes:mediaNodesArray api:[MEGASdkManager sharedMEGASdk] displayMode:displayMode presentingNode:node preferredIndex:0];
    
    return photoBrowserVC;
}

- (void)showNode:(MEGANode *)node {
    [self.navigationController presentViewController:[self photoBrowserForMediaNode:node] animated:YES completion:nil];
}

- (void)reloadData {
    if (self.viewModePreference == ViewModePreferenceList) {
        [self.cdTableView.tableView reloadData];
    } else {
        [self.cdCollectionView reloadData];
    }
}

- (void)setEditMode:(BOOL)editMode {
    if (self.viewModePreference == ViewModePreferenceList) {
        [self.cdTableView setTableViewEditing:editMode animated:YES];
    } else {
        [self.cdCollectionView setCollectionViewEditing:editMode animated:YES];
    }
}

- (void)selectIndexPath:(NSIndexPath *)indexPath {
    if (self.viewModePreference == ViewModePreferenceList) {
        [self.cdTableView tableViewSelectIndexPath:indexPath];
        [self.cdTableView.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
    } else {
        [self.cdCollectionView collectionViewSelectIndexPath:indexPath];
        [self.cdCollectionView.collectionView selectItemAtIndexPath:indexPath animated:YES scrollPosition:UICollectionViewScrollPositionNone];
    }
}

- (NSInteger)numberOfRows {
    NSInteger numberOfRows = 0;
    if (self.viewModePreference == ViewModePreferenceList) {
        numberOfRows = [self.cdTableView.tableView numberOfRowsInSection:0];
    } else {
        numberOfRows = [self.cdCollectionView.collectionView mnz_totalRows];
    }
    
    return numberOfRows;
}

- (void)search {
    if (self.searchController.searchBar.text.length >= kMinimumLettersToStartTheSearch) {
        NSString *text = self.searchController.searchBar.text;
        [SVProgressHUD show];
        [self.searchNodesArray removeAllObjects];
        self.cancelToken = MEGACancelToken.alloc.init;
        SearchOperation *searchOperation = [SearchOperation.alloc initWithParentNode:self.parentNode text:text cancelToken:self.cancelToken completion:^(NSArray <MEGANode *> *nodesFound, BOOL isCancelled) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.searchNodesArray = [NSMutableArray arrayWithArray:nodesFound];
                [SVProgressHUD dismiss];
                [self reloadData];
                self.cancelToken = nil;
            });
        }];
        [self.searchQueue addOperation:searchOperation];
    } else {
        [self reloadData];
    }
}

- (void)cancelSearchIfNeeded {
    if (self.searchQueue.operationCount) {
        [self.cancelToken cancelWithNewValue:YES];
        [self.searchQueue cancelAllOperations];
    }
}

- (void)openFileNode:(MEGANode *)node {
    if (node.name.mnz_isImagePathExtension || node.name.mnz_isVideoPathExtension) {
        [self showNode:node];
    } else {
        [node mnz_openNodeInNavigationController:self.navigationController folderLink:NO fileLink:nil];
    }
}

- (void)openFolderNode:(MEGANode *)node {
    CloudDriveViewController *cloudDriveVC = [self.storyboard instantiateViewControllerWithIdentifier:@"CloudDriveID"];
    cloudDriveVC.parentNode = node;
    
    if (self.displayMode == DisplayModeRubbishBin) {
        cloudDriveVC.displayMode = self.displayMode;
    }
    
    [self.navigationController pushViewController:cloudDriveVC animated:YES];
}

- (void)confirmDeleteActionFiles:(NSUInteger)numFilesAction andFolders:(NSUInteger)numFoldersAction {
    NSString *alertTitle;
    NSString *message;
    if (numFilesAction == 0) {
        if (numFoldersAction == 1) {
            message = NSLocalizedString(@"removeFolderToRubbishBinMessage", nil);
        } else { //folders > 1
            message = [NSString stringWithFormat:NSLocalizedString(@"removeFoldersToRubbishBinMessage", nil), numFoldersAction];
        }
    } else if (numFilesAction == 1) {
        if (numFoldersAction == 0) {
            message = NSLocalizedString(@"removeFileToRubbishBinMessage", nil);
        } else if (numFoldersAction == 1) {
            message = NSLocalizedString(@"removeFileFolderToRubbishBinMessage", nil);
        } else {
            message = [NSString stringWithFormat:NSLocalizedString(@"removeFileFoldersToRubbishBinMessage", nil), numFoldersAction];
        }
    } else {
        if (numFoldersAction == 0) {
            message = [NSString stringWithFormat:NSLocalizedString(@"removeFilesToRubbishBinMessage", nil), numFilesAction];
        } else if (numFoldersAction == 1) {
            message = [NSString stringWithFormat:NSLocalizedString(@"removeFilesFolderToRubbishBinMessage", nil), numFilesAction];
        } else {
            message = NSLocalizedString(@"removeFilesFoldersToRubbishBinMessage", nil);
            NSString *filesString = [NSString stringWithFormat:@"%ld", (long)numFilesAction];
            NSString *foldersString = [NSString stringWithFormat:@"%ld", (long)numFoldersAction];
            message = [message stringByReplacingOccurrencesOfString:@"[A]" withString:filesString];
            message = [message stringByReplacingOccurrencesOfString:@"[B]" withString:foldersString];
        }
        alertTitle = NSLocalizedString(@"removeNodeFromRubbishBinTitle", @"Alert title shown on the Rubbish Bin when you want to remove some files and folders of your MEGA account");
    }
    
    UIAlertController *removeAlertController = [UIAlertController alertControllerWithTitle:alertTitle message:message preferredStyle:UIAlertControllerStyleAlert];
    [removeAlertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"cancel", @"Button title to cancel something") style:UIAlertActionStyleCancel handler:nil]];
    
    [removeAlertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"ok", @"Button title to cancel something") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        MEGARemoveRequestDelegate *removeRequestDelegate = [MEGARemoveRequestDelegate.alloc initWithMode:DisplayModeRubbishBin files:numFilesAction folders:numFoldersAction completion:^{
            [self setEditMode:NO];
        }];
        for (MEGANode *node in self.selectedNodesArray) {
            [MEGASdkManager.sharedMEGASdk removeNode:node delegate:removeRequestDelegate];
        }
    }]];
    
    [self presentViewController:removeAlertController animated:YES completion:nil];
}

#pragma mark - IBActions

- (IBAction)selectAllAction:(UIBarButtonItem *)sender {
    [self.selectedNodesArray removeAllObjects];
    
    if (!self.allNodesSelected) {
        NSArray *nodesArray = (self.searchController.isActive && !self.searchController.searchBar.text.mnz_isEmpty) ? self.searchNodesArray : [self.nodes mnz_nodesArrayFromNodeList];
        
        self.selectedNodesArray = nodesArray.mutableCopy;
        
        self.allNodesSelected = YES;
        
        [self toolbarActionsForNodeArray:self.selectedNodesArray];
    } else {
        self.allNodesSelected = NO;
    }
    
    if (self.displayMode == DisplayModeCloudDrive || self.displayMode == DisplayModeRubbishBin) {
        [self updateNavigationBarTitle];
    }
    
    if (self.selectedNodesArray.count == 0) {
        [self setToolbarActionsEnabled:NO];
    } else if (self.selectedNodesArray.count >= 1) {
        [self setToolbarActionsEnabled:YES];
    }
    
    [self reloadData];
}

- (IBAction)moreAction:(UIBarButtonItem *)sender {
    __weak __typeof__(self) weakSelf = self;

    NSMutableArray<ActionSheetAction *> *actions = NSMutableArray.new;
    [actions addObject:[ActionSheetAction.alloc initWithTitle:NSLocalizedString(@"upload", @"") detail:nil image:[UIImage imageNamed:@"upload"] style:UIAlertActionStyleDefault actionHandler:^{
        [weakSelf presentUploadAlertController];
    }]];
    
    if (@available(iOS 13.0, *)) {
        [actions addObject:[ActionSheetAction.alloc initWithTitle:NSLocalizedString(@"Scan Document", @"Menu option from the `Add` section that allows the user to scan document and upload it directly to MEGA") detail:nil image:[UIImage imageNamed:@"scanDocument"] style:UIAlertActionStyleDefault actionHandler:^{
            [self presentScanDocument];
        }]];
    }
    
    [actions addObject:[ActionSheetAction.alloc initWithTitle:NSLocalizedString(@"newFolder", @"Menu option from the `Add` section that allows you to create a 'New Folder'") detail:nil image:[UIImage imageNamed:@"newFolder"] style:UIAlertActionStyleDefault actionHandler:^{
        UIAlertController *newFolderAlertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"newFolder", @"Menu option from the `Add` section that allows you to create a 'New Folder'") message:nil preferredStyle:UIAlertControllerStyleAlert];
        
        [newFolderAlertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            textField.placeholder = NSLocalizedString(@"newFolderMessage", @"Hint text shown on the create folder alert.");
            [textField addTarget:weakSelf action:@selector(newFolderAlertTextFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
            textField.shouldReturnCompletion = ^BOOL(UITextField *textField) {
                return (!textField.text.mnz_isEmpty && !textField.text.mnz_containsInvalidChars);
            };
        }];
        
        [newFolderAlertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"cancel", @"Button title to cancel something") style:UIAlertActionStyleCancel handler:nil]];
        
        UIAlertAction *createFolderAlertAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"createFolderButton", @"Title button for the create folder alert.") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            if ([MEGAReachabilityManager isReachableHUDIfNot]) {
                UITextField *textField = [[newFolderAlertController textFields] firstObject];
                MEGANodeList *childrenNodeList = [[MEGASdkManager sharedMEGASdk] nodeListSearchForNode:weakSelf.parentNode searchString:textField.text recursive:NO];
                if ([childrenNodeList mnz_existsFolderWithName:textField.text]) {
                    [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"There is already a folder with the same name", @"A tooltip message which is shown when a folder name is duplicated during renaming or creation.")];
                } else {
                    MEGACreateFolderRequestDelegate *createFolderRequestDelegate = [[MEGACreateFolderRequestDelegate alloc] initWithCompletion:^(MEGARequest *request) {
                        MEGANode *newFolderNode = [[MEGASdkManager sharedMEGASdk] nodeForHandle:request.nodeHandle];
                        [self didSelectNode:newFolderNode];
                    }];
                    [[MEGASdkManager sharedMEGASdk] createFolderWithName:textField.text parent:weakSelf.parentNode delegate:createFolderRequestDelegate];
                }
            }
        }];
        createFolderAlertAction.enabled = NO;
        [newFolderAlertController addAction:createFolderAlertAction];
        
        [weakSelf presentViewController:newFolderAlertController animated:YES completion:nil];
    }]];
    
    [actions addObject:[ActionSheetAction.alloc initWithTitle:NSLocalizedString(@"new_text_file", @"Menu option from the `Add` section that allows the user to create a new text file and upload it directly to MEGA") detail:nil image:[UIImage imageNamed:@"textfile"] style:UIAlertActionStyleDefault actionHandler:^{
        [[CreateTextFileAlertViewRouter.alloc initWithPresenter:self.navigationController parentHandle:self.parentNode.handle] start];
    }]];
    
    if ([self numberOfRows]) {
        NSString *title = (self.viewModePreference == ViewModePreferenceList) ? NSLocalizedString(@"Thumbnail View", @"Text shown for switching from list view to thumbnail view.") : NSLocalizedString(@"List View", @"Text shown for switching from thumbnail view to list view.");
        UIImage *image = (self.viewModePreference == ViewModePreferenceList) ? [UIImage imageNamed:@"thumbnailsThin"] : [UIImage imageNamed:@"gridThin"];
        [actions addObject:[ActionSheetAction.alloc initWithTitle:title detail:nil image:image style:UIAlertActionStyleDefault actionHandler:^{
            [weakSelf changeViewModePreference];
        }]];
        [actions addObject:[ActionSheetAction.alloc initWithTitle:NSLocalizedString(@"sortTitle", @"Section title of the 'Sort by'") detail:[NSString localizedSortOrderType:[Helper sortTypeFor:self.parentNode]] image:[UIImage imageNamed:@"sort"] style:UIAlertActionStyleDefault actionHandler:^{
            [weakSelf presentSortByActionSheet];
        }]];
        [actions addObject:[ActionSheetAction.alloc initWithTitle:NSLocalizedString(@"select", @"Button that allows you to select a given folder") detail:nil image:[UIImage imageNamed:@"select"] style:UIAlertActionStyleDefault actionHandler:^{
            BOOL enableEditing = weakSelf.cdTableView ? !weakSelf.cdTableView.tableView.isEditing : !weakSelf.cdCollectionView.collectionView.allowsMultipleSelection;
            [weakSelf setEditMode:enableEditing];
            
        }]];
    }
    
    [actions addObject:[ActionSheetAction.alloc initWithTitle:NSLocalizedString(@"rubbishBinLabel", @"Title of one of the Settings sections where you can see your MEGA 'Rubbish Bin'") detail:[Helper sizeForNode:MEGASdkManager.sharedMEGASdk.rubbishNode api:MEGASdkManager.sharedMEGASdk] image:[UIImage imageNamed:@"rubbishBin"] style:UIAlertActionStyleDefault actionHandler:^{
        CloudDriveViewController *cloudDriveVC = [[UIStoryboard storyboardWithName:@"Cloud" bundle:nil] instantiateViewControllerWithIdentifier:@"CloudDriveID"];
        cloudDriveVC.parentNode = [[MEGASdkManager sharedMEGASdk] rubbishNode];
        cloudDriveVC.displayMode = DisplayModeRubbishBin;
        cloudDriveVC.title = NSLocalizedString(@"rubbishBinLabel", @"Title of one of the Settings sections where you can see your MEGA 'Rubbish Bin'");
        [weakSelf.navigationController pushViewController:cloudDriveVC animated:YES];
    }]];
    
    ActionSheetViewController *moreActionSheet = [ActionSheetViewController.alloc initWithActions:actions headerTitle:nil dismissCompletion:nil sender:self.navigationItem.rightBarButtonItems.firstObject];
    [self presentViewController:moreActionSheet animated:YES completion:nil];
}

- (IBAction)moreMinimizedAction:(UIBarButtonItem *)sender {
    __weak __typeof__(self) weakSelf = self;
    
    NSMutableArray<ActionSheetAction *> *actions = NSMutableArray.new;
    if ([self numberOfRows]) {
        NSString *title = (self.viewModePreference == ViewModePreferenceList) ? NSLocalizedString(@"Thumbnail View", @"Text shown for switching from list view to thumbnail view.") : NSLocalizedString(@"List View", @"Text shown for switching from thumbnail view to list view.");
        UIImage *image = (self.viewModePreference == ViewModePreferenceList) ? [UIImage imageNamed:@"thumbnailsThin"] : [UIImage imageNamed:@"gridThin"];
        [actions addObject:[ActionSheetAction.alloc initWithTitle:title detail:nil image:image style:UIAlertActionStyleDefault actionHandler:^{
            [weakSelf changeViewModePreference];
        }]];
    }
    
    [actions addObject:[ActionSheetAction.alloc initWithTitle:NSLocalizedString(@"sortTitle", @"Section title of the 'Sort by'") detail:[NSString localizedSortOrderType:[Helper sortTypeFor:self.parentNode]] image:[UIImage imageNamed:@"sort"] style:UIAlertActionStyleDefault actionHandler:^{
        [weakSelf presentSortByActionSheet];
    }]];
    
    [actions addObject:[ActionSheetAction.alloc initWithTitle:NSLocalizedString(@"select", @"Button that allows you to select a given folder") detail:nil image:[UIImage imageNamed:@"select"] style:UIAlertActionStyleDefault actionHandler:^{
        BOOL enableEditing = weakSelf.cdTableView ? !weakSelf.cdTableView.tableView.isEditing : !weakSelf.cdCollectionView.collectionView.allowsMultipleSelection;
        [weakSelf setEditMode:enableEditing];
    }]];
    
    if (self.displayMode == DisplayModeRubbishBin) {
        [actions addObject:[ActionSheetAction.alloc initWithTitle:NSLocalizedString(@"emptyRubbishBin", @"Section title where you can 'Empty Rubbish Bin' of your MEGA account") detail:nil image:[UIImage imageNamed:@"rubbishBin"] style:UIAlertActionStyleDefault actionHandler:^{
            if ([MEGAReachabilityManager isReachableHUDIfNot]) {
                UIAlertController *clearRubbishBinAlertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"emptyRubbishBinAlertTitle", @"Alert title shown when you tap 'Empty Rubbish Bin'") message:nil preferredStyle:UIAlertControllerStyleAlert];
                [clearRubbishBinAlertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"cancel", nil) style:UIAlertActionStyleCancel handler:nil]];
                [clearRubbishBinAlertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"ok", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    [MEGASdkManager.sharedMEGASdk cleanRubbishBin];
                }]];
                
                [UIApplication.mnz_visibleViewController presentViewController:clearRubbishBinAlertController animated:YES completion:nil];
            }
        }]];
    }
    ActionSheetViewController *moreMinimizedActionSheet = [ActionSheetViewController.alloc initWithActions:actions headerTitle:nil dismissCompletion:nil sender:self.navigationItem.rightBarButtonItems.firstObject];
    [self presentViewController:moreMinimizedActionSheet animated:YES completion:nil];
}

- (IBAction)editTapped:(UIBarButtonItem *)sender {
    BOOL enableEditing = self.cdTableView ? !self.cdTableView.tableView.isEditing : !self.cdCollectionView.collectionView.allowsMultipleSelection;
    [self setEditMode:enableEditing];
}

- (void)setViewEditing:(BOOL)editing {
    [self updateNavigationBarTitle];
    
    if (editing) {
        self.editBarButtonItem.title = NSLocalizedString(@"cancel", @"Button title to cancel something");
        self.navigationItem.rightBarButtonItems = @[self.editBarButtonItem];
        self.navigationItem.leftBarButtonItems = @[self.selectAllBarButtonItem];
        
        UITabBar *tabBar = self.tabBarController.tabBar;
        if (tabBar == nil) {
            return;
        }
        
        if (![self.tabBarController.view.subviews containsObject:self.toolbar]) {
            [self.toolbar setAlpha:0.0];
            [self.tabBarController.view addSubview:self.toolbar];
            self.toolbar.translatesAutoresizingMaskIntoConstraints = NO;
            [self.toolbar setBackgroundColor:[UIColor mnz_mainBarsForTraitCollection:self.traitCollection]];
            
            NSLayoutAnchor *bottomAnchor = tabBar.safeAreaLayoutGuide.bottomAnchor;
            
            [NSLayoutConstraint activateConstraints:@[[self.toolbar.topAnchor constraintEqualToAnchor:tabBar.topAnchor constant:0],
                                                      [self.toolbar.leadingAnchor constraintEqualToAnchor:tabBar.leadingAnchor constant:0],
                                                      [self.toolbar.trailingAnchor constraintEqualToAnchor:tabBar.trailingAnchor constant:0],
                                                      [self.toolbar.bottomAnchor constraintEqualToAnchor:bottomAnchor constant:0]]];
            
            [UIView animateWithDuration:0.33f animations:^ {
                [self.toolbar setAlpha:1.0];
            }];
        }
    } else {
        [self setNavigationBarButtonItems];
        self.allNodesSelected = NO;
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
    
    if ([AudioPlayerManager.shared isPlayerAlive]) {
        [AudioPlayerManager.shared playerHidden:editing presenter:self];
    }
}

- (IBAction)downloadAction:(UIBarButtonItem *)sender {
    [SVProgressHUD showImage:[UIImage imageNamed:@"hudDownload"] status:NSLocalizedString(@"downloadStarted", nil)];
    
    for (MEGANode *node in self.selectedNodesArray) {
        if ([node mnz_downloadNode]) {
            [self.cdTableView.tableView reloadData];
        } else {
            return;
        }
    }
    
    [self setEditMode:NO];
    
    [self reloadData];
}

- (IBAction)shareAction:(UIBarButtonItem *)sender {
    UIActivityViewController *activityVC = [UIActivityViewController activityViewControllerForNodes:self.selectedNodesArray sender:self.shareBarButtonItem];
    __weak __typeof__(self) weakSelf = self;
    activityVC.completionWithItemsHandler = ^(UIActivityType  _Nullable activityType, BOOL completed, NSArray * _Nullable returnedItems, NSError * _Nullable activityError) {
        if (completed && !activityError) {
            [weakSelf setEditMode:NO];
        }
    };
    [self presentViewController:activityVC animated:YES completion:nil];
}

- (IBAction)moveAction:(UIBarButtonItem *)sender {
    MEGANavigationController *navigationController = [self.storyboard instantiateViewControllerWithIdentifier:@"BrowserNavigationControllerID"];
    [self presentViewController:navigationController animated:YES completion:nil];
    
    BrowserViewController *browserVC = navigationController.viewControllers.firstObject;
    browserVC.browserViewControllerDelegate = self;
    browserVC.selectedNodesArray = self.selectedNodesArray.copy;
    browserVC.browserAction = BrowserActionMove;
}

- (IBAction)copyAction:(UIBarButtonItem *)sender {
    MEGANavigationController *navigationController = [self.storyboard instantiateViewControllerWithIdentifier:@"BrowserNavigationControllerID"];
    [self presentViewController:navigationController animated:YES completion:nil];
    
    BrowserViewController *browserVC = navigationController.viewControllers.firstObject;
    browserVC.browserViewControllerDelegate = self;
    browserVC.selectedNodesArray = self.selectedNodesArray.copy;
    browserVC.browserAction = BrowserActionCopy;
}

- (IBAction)sortByAction:(UIBarButtonItem *)sender {
    [self presentSortByActionSheet];
}

- (void)showCustomActionsForNode:(MEGANode *)node sender:(UIButton *)sender {
    NodeActionViewController *nodeActions = [NodeActionViewController.alloc initWithNode:node delegate:self displayMode:self.displayMode isIncoming:self.isIncomingShareChildView sender:sender];
    [self presentViewController:nodeActions animated:YES completion:nil];
}

- (IBAction)restoreTouchUpInside:(UIBarButtonItem *)sender {
    for (MEGANode *node in self.selectedNodesArray) {
        [node mnz_restore];
    }
    [self setEditMode:NO];
}

#pragma mark - UISearchBarDelegate

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    self.searchNodesArray = nil;
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    if (self.viewModePreference == ViewModePreferenceThumbnail) {
        self.cdCollectionView.collectionView.clipsToBounds = YES;
    }
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
    if (self.viewModePreference == ViewModePreferenceThumbnail) {
        self.cdCollectionView.collectionView.clipsToBounds = NO;
    }
}

#pragma mark - UISearchControllerDelegate

- (void)didPresentSearchController:(UISearchController *)searchController {
    if (UIDevice.currentDevice.iPhoneDevice && UIInterfaceOrientationIsLandscape(UIApplication.sharedApplication.statusBarOrientation)) {
        [Helper resetFrameForSearchController:searchController];
    }
}

#pragma mark - UISearchResultsUpdating

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    if (self.searchController.searchBar.text.length >= kMinimumLettersToStartTheSearch) {
        [self cancelSearchIfNeeded];
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(search) object:nil];
        [self performSelector:@selector(search) withObject:nil afterDelay:kSearchTimeDelay];
    } else {
        [self reloadData];
    }
}

#pragma mark - UIDocumentPickerDelegate

- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentAtURL:(NSURL *)url {
    if (controller.documentPickerMode == UIDocumentPickerModeImport) {
        NSError *error = nil;
        NSString *localFilePath = [[[NSFileManager defaultManager] uploadsDirectory] stringByAppendingPathComponent:url.lastPathComponent];
        if (![[NSFileManager defaultManager] moveItemAtPath:[url path] toPath:localFilePath error:&error]) {
            MEGALogError(@"Move item at path failed with error: %@", error);
        }
        
        NSString *fingerprint = [[MEGASdkManager sharedMEGASdk] fingerprintForFilePath:localFilePath];
        MEGANode *node = [[MEGASdkManager sharedMEGASdk] nodeForFingerprint:fingerprint parent:self.parentNode];
        
        // If file doesn't exist in MEGA then upload it
        if (node == nil) {
            [SVProgressHUD showSuccessWithStatus:NSLocalizedString(@"uploadStarted_Message", nil)];
            
            NSString *appData = [[NSString new] mnz_appDataToSaveCoordinates:localFilePath.mnz_coordinatesOfPhotoOrVideo];
            [[MEGASdkManager sharedMEGASdk] startUploadWithLocalPath:localFilePath.mnz_relativeLocalPath parent:self.parentNode appData:appData isSourceTemporary:NO];
        } else {
            if (node.parentHandle == self.parentNode.handle) {
                [NSFileManager.defaultManager mnz_removeItemAtPath:localFilePath];
                
                NSString *alertMessage = NSLocalizedString(@"fileExistAlertController_Message", nil);
                
                NSString *localNameString = [NSString stringWithFormat:@"%@", [url lastPathComponent]];
                NSString *megaNameString = [NSString stringWithFormat:@"%@", node.name];
                alertMessage = [alertMessage stringByReplacingOccurrencesOfString:@"[A]" withString:localNameString];
                alertMessage = [alertMessage stringByReplacingOccurrencesOfString:@"[B]" withString:megaNameString];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    UIAlertController *alertController = [UIAlertController
                                                          alertControllerWithTitle:nil
                                                          message:alertMessage
                                                          preferredStyle:UIAlertControllerStyleAlert];
                    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"ok", nil) style:UIAlertActionStyleDefault handler:nil]];
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
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"permissionTitle", @"Error title shown when you are trying to do an action with a file or folder and you don't have the necessary permissions") message:NSLocalizedString(@"permissionMessage", @"Error message shown when you are trying to do an action with a file or folder and you don't have the necessary permissions") preferredStyle:UIAlertControllerStyleAlert];
                [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"ok", nil) style:UIAlertActionStyleCancel handler:nil]];
                [self presentViewController:alertController animated:YES completion:nil];
            }
        }
        return;
    }
    
    switch ([request type]) {
        case MEGARequestTypeGetAttrFile: {
            for (NodeTableViewCell *nodeTableViewCell in self.cdTableView.tableView.visibleCells) {
                if (request.nodeHandle == nodeTableViewCell.node.handle) {
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
    BOOL shouldProcessOnNodesUpdate = [nodeList mnz_shouldProcessOnNodesUpdateForParentNode:self.parentNode childNodesArray:self.nodes.mnz_nodesArrayFromNodeList];
    
    if (shouldProcessOnNodesUpdate) {
        if (self.nodes.size.unsignedIntegerValue == 0) {
            self.shouldDetermineViewMode = YES;
        }
        [self.nodesIndexPathMutableDictionary removeAllObjects];
        [self reloadUI];
    }
}

#pragma mark - MEGATransferDelegate

- (void)onTransferStart:(MEGASdk *)api transfer:(MEGATransfer *)transfer {
    if (transfer.isStreamingTransfer) {
        return;
    }
    
    if (transfer.type == MEGATransferTypeDownload && self.viewModePreference == ViewModePreferenceList) {
        [self.cdTableView.tableView reloadData];
    }
}

- (void)onTransferUpdate:(MEGASdk *)api transfer:(MEGATransfer *)transfer {
    if (transfer.isStreamingTransfer) {
        return;
    }
    
    [self.throttler startWithAction:^{
        NSString *base64Handle = [MEGASdk base64HandleForHandle:transfer.nodeHandle];
        
        if (transfer.type == MEGATransferTypeDownload && [Helper.downloadingNodes objectForKey:base64Handle] && self.viewModePreference == ViewModePreferenceList) {
            float percentage = ([[transfer transferredBytes] floatValue] / [[transfer totalBytes] floatValue] * 100);
            NSString *percentageCompleted = [NSString stringWithFormat:@"%.f%%", percentage];
            NSString *speed = [NSString stringWithFormat:@"%@/s", [Helper memoryStyleStringFromByteCount:transfer.speed.longLongValue]];
            
            NSIndexPath *indexPath = [self.nodesIndexPathMutableDictionary objectForKey:base64Handle];
            if (indexPath != nil) {
                NodeTableViewCell *cell = (NodeTableViewCell *)[self.cdTableView.tableView cellForRowAtIndexPath:indexPath];
                [cell.infoLabel setText:[NSString stringWithFormat:@"%@ • %@", percentageCompleted, speed]];
                cell.downloadProgressView.progress = [[transfer transferredBytes] floatValue] / [[transfer totalBytes] floatValue];
            }
        }
    }];
}

- (void)onTransferFinish:(MEGASdk *)api transfer:(MEGATransfer *)transfer error:(MEGAError *)error {
    if (transfer.isStreamingTransfer) {
        return;
    }
    
    if ([error type]) {
        if ([error type] == MEGAErrorTypeApiEAccess) {
            if ([transfer type] ==  MEGATransferTypeUpload) {
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"permissionTitle", nil) message:NSLocalizedString(@"permissionMessage", nil) preferredStyle:UIAlertControllerStyleAlert];
                [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"ok", nil) style:UIAlertActionStyleCancel handler:nil]];
                [self presentViewController:alertController animated:YES completion:nil];
            }
        } else if ([error type] == MEGAErrorTypeApiEIncomplete) {
            [SVProgressHUD showImage:[UIImage imageNamed:@"hudMinus"] status:NSLocalizedString(@"transferCancelled", nil)];
        }
    }
    
    if (transfer.type == MEGATransferTypeDownload) {
        switch (self.viewModePreference) {
            case ViewModePreferenceList:
                [self.cdTableView.tableView reloadData];
                break;
            case ViewModePreferenceThumbnail:
                if (transfer.publicNode.isFile) {
                    [self.cdCollectionView reloadFileItem:transfer.nodeHandle];
                } else {
                    [self.cdCollectionView reloadFolderItem:transfer.nodeHandle];
                }
                break;
            default:
                break;
        }
    }
}

#pragma mark - VNDocumentCameraViewControllerDelegate

- (void)documentCameraViewController:(VNDocumentCameraViewController *)controller didFinishWithScan:(VNDocumentCameraScan *)scan  API_AVAILABLE(ios(13.0)){
    [controller dismissViewControllerAnimated:YES completion:^{
        
        DocScannerSaveSettingTableViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"DocScannerSaveSettingTableViewController"];
        vc.parentNode = self.parentNode;
        NSMutableArray *docs = NSMutableArray.new;
        
        for (NSUInteger idx = 0; idx < scan.pageCount; idx ++) {
            UIImage *doc = [scan imageOfPageAtIndex:idx];
            [docs addObject:doc];
        }
        vc.docs = docs.copy;
        [self presentViewController:({
            MEGANavigationController *nav = [MEGANavigationController.alloc initWithRootViewController:vc];
            [nav addLeftDismissButtonWithText:NSLocalizedString(@"cancel", nil)];
            nav.modalPresentationStyle = UIModalPresentationFullScreen;
            nav;
        }) animated:YES completion:nil];
    }];
}

#pragma mark - NodeActionViewControllerDelegate

- (void)nodeAction:(NodeActionViewController *)nodeAction didSelect:(MegaNodeActionType)action for:(MEGANode *)node from:(id)sender {
    switch (action) {
        case MegaNodeActionTypeDownload:
            [SVProgressHUD showImage:[UIImage imageNamed:@"hudDownload"] status:NSLocalizedString(@"downloadStarted", @"Message shown when a download starts")];
            if ([node mnz_downloadNode]) {
                [self.cdTableView.tableView reloadData];
            }
            break;
            
        case MegaNodeActionTypeCopy:
            self.selectedNodesArray = [[NSMutableArray alloc] initWithObjects:node, nil];
            [self copyAction:nil];
            break;
            
        case MegaNodeActionTypeMove:
            self.selectedNodesArray = [[NSMutableArray alloc] initWithObjects:node, nil];
            [self moveAction:nil];
            break;
            
        case MegaNodeActionTypeRename:
            [node mnz_renameNodeInViewController:self];
            break;
            
        case MegaNodeActionTypeShare: {
            UIActivityViewController *activityVC = [UIActivityViewController activityViewControllerForNodes:@[node] sender:sender];
            [self presentViewController:activityVC animated:YES completion:nil];
        }
            break;
            
        case MegaNodeActionTypeShareFolder: {
            MEGANavigationController *navigationController = [[UIStoryboard storyboardWithName:@"Contacts" bundle:nil] instantiateViewControllerWithIdentifier:@"ContactsNavigationControllerID"];
            ContactsViewController *contactsVC = navigationController.viewControllers.firstObject;
            contactsVC.nodesArray = @[node];
            contactsVC.contactsMode = ContactsModeShareFoldersWith;
            [self presentViewController:navigationController animated:YES completion:nil];
            break;
        }
            
        case MegaNodeActionTypeManageShare: {
            ContactsViewController *contactsVC = [[UIStoryboard storyboardWithName:@"Contacts" bundle:nil] instantiateViewControllerWithIdentifier:@"ContactsViewControllerID"];
            contactsVC.node = node;
            contactsVC.contactsMode = ContactsModeFolderSharedWith;
            [self.navigationController pushViewController:contactsVC animated:YES];
            break;
        }
            
        case MegaNodeActionTypeInfo:
            [self showNodeInfo:node];
            break;
            
        case MegaNodeActionTypeFavourite: {
            if (@available(iOS 14.0, *)) {
                MEGAGenericRequestDelegate *delegate = [MEGAGenericRequestDelegate.alloc initWithCompletion:^(MEGARequest * _Nonnull request, MEGAError * _Nonnull error) {
                    if (error.type == MEGAErrorTypeApiOk) {
                        if (request.numDetails == 1) {
                            [[QuickAccessWidgetManager.alloc init] insertFavouriteItemFor:node];
                        } else {
                            [[QuickAccessWidgetManager.alloc init] deleteFavouriteItemFor:node];
                        }
                    }
                }];
                [MEGASdkManager.sharedMEGASdk setNodeFavourite:node favourite:!node.isFavourite delegate:delegate];
            } else {
                [MEGASdkManager.sharedMEGASdk setNodeFavourite:node favourite:!node.isFavourite];
            }
            break;
        }
            
        case MegaNodeActionTypeLabel:
            [node mnz_labelActionSheetInViewController:self];
            break;
            
        case MegaNodeActionTypeLeaveSharing:
            [node mnz_leaveSharingInViewController:self];
            break;
            
        case MegaNodeActionTypeGetLink:
        case MegaNodeActionTypeManageLink: {
            if (MEGAReachabilityManager.isReachableHUDIfNot) {
                [CopyrightWarningViewController presentGetLinkViewControllerForNodes:@[node] inViewController:UIApplication.mnz_presentingViewController];
            }
            break;
        }
            
        case MegaNodeActionTypeRemoveLink: {
            [node mnz_removeLink];
            break;
        }
            
        case MegaNodeActionTypeMoveToRubbishBin:
            [self moveToRubbishBinFor:node];
            break;
            
        case MegaNodeActionTypeRemove:
            [node mnz_removeInViewController:self];
            break;
            
        case MegaNodeActionTypeRemoveSharing:
            [node mnz_removeSharing];
            break;
            
        case MegaNodeActionTypeRestore:
            [node mnz_restore];
            break;
            
        case MegaNodeActionTypeSaveToPhotos:
            [node mnz_saveToPhotosWithApi:[MEGASdkManager sharedMEGASdk]];
            break;
            
        case MegaNodeActionTypeSendToChat:
            [node mnz_sendToChatInViewController:self];
            break;
            
        default:
            break;
    }
}

#pragma mark - NodeInfoViewControllerDelegate

- (void)nodeInfoViewController:(NodeInfoViewController *)nodeInfoViewController presentParentNode:(MEGANode *)node {
    [node navigateToParentAndPresent];
}

#pragma mark - RecentNodeActionDelegate

- (void)showCustomActionsForNode:(MEGANode *)node fromSender:(id)sender {
    NodeActionViewController *nodeActions = [NodeActionViewController.alloc initWithNode:node delegate:self displayMode:self.displayMode isIncoming:self.isIncomingShareChildView sender:sender];
    [self presentViewController:nodeActions animated:YES completion:nil];
}

- (void)showSelectedNodeInViewController:(UIViewController *)viewController {
    [self.navigationController presentViewController:viewController animated:YES completion:nil];
}

#pragma mark - AudioPlayerPresenterProtocol

- (void)updateContentView:(CGFloat)height {
    if (self.viewModePreference == ViewModePreferenceList) {
        self.cdTableView.tableView.contentInset = UIEdgeInsetsMake(0, 0, height, 0);
    } else {
        self.cdCollectionView.collectionView.contentInset = UIEdgeInsetsMake(0, 0, height, 0);
    }
}

#pragma mark - UINavigationControllerDelegate
- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    if([AudioPlayerManager.shared isPlayerAlive] && navigationController.viewControllers.count > 1) {
        self.shouldRemovePlayerDelegate = ![viewController conformsToProtocol:@protocol(AudioPlayerPresenterProtocol)];
    }
}

- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    if (self.displayMode != DisplayModeRecents) {
        self.shouldRemovePlayerDelegate = YES;
    }
}

#pragma mark - BrowserViewControllerDelegate

- (void)nodeEditCompleted:(BOOL)complete {
    [self setEditMode:!complete];
}

@end
