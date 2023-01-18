
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
#import "MEGAStore.h"
#import "MEGA-Swift.h"
#import "NSArray+MNZCategory.h"
#import "NSURL+MNZCategory.h"
#import "UITextField+MNZCategory.h"

#import "BrowserViewController.h"
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
static const NSTimeInterval kHUDDismissDelay = .3;
static const NSUInteger kMinDaysToEncourageToUpgrade = 3;

@interface CloudDriveViewController () <UINavigationControllerDelegate, UISearchBarDelegate, UISearchResultsUpdating, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, MEGADelegate, MEGARequestDelegate, NodeActionViewControllerDelegate, NodeInfoViewControllerDelegate, UITextFieldDelegate, UISearchControllerDelegate, VNDocumentCameraViewControllerDelegate, RecentNodeActionDelegate, AudioPlayerPresenterProtocol, TextFileEditable> {
    
    MEGAShareType lowShareType; //Control the actions allowed for node/nodes selected
}
@property (weak, nonatomic) IBOutlet UIView *containerView;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *selectAllBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *moreBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *moreMinimizedBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *editBarButtonItem;

@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *downloadBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *shareLinkBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *moveBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *carbonCopyBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *deleteBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *restoreBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *actionsBarButtonItem;

@property (nonatomic, strong) NSArray *nodesArray;

@property (nonatomic, strong) NSMutableArray *cloudImages;

@property (nonatomic, assign) ViewModePreference viewModePreference;
@property (nonatomic, assign) BOOL shouldDetermineViewMode;
@property (strong, nonatomic) NSOperationQueue *searchQueue;
@property (strong, nonatomic) MEGACancelToken *cancelToken;

@property (nonatomic, assign) BOOL onlyUploadOptions;

@end

@implementation CloudDriveViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = self.containerView.backgroundColor = UIColor.mnz_background;
    
    self.definesPresentationContext = YES;
    
    [self configureContextMenuManager];
    
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
    
    if (self.displayMode == DisplayModeBackup) {
        [self toolbarActionsForNode:self.parentNode];
    } else {
        MEGAShareType shareType = [[MEGASdkManager sharedMEGASdk] accessLevelForNode:self.parentNode];
        [self toolbarActionsForShareType:shareType isBackupNode:false];
    }
    
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
    
    self.moreBarButtonItem.accessibilityLabel = NSLocalizedString(@"more", @"Top menu option which opens more menu options in a context menu.");
    
    _searchQueue = NSOperationQueue.new;
    self.searchQueue.name = @"searchQueue";
    self.searchQueue.qualityOfService = NSQualityOfServiceUserInteractive;
    self.searchQueue.maxConcurrentOperationCount = 1;
    
    StorageFullModalAlertViewController *warningVC = StorageFullModalAlertViewController.alloc.init;
    [warningVC showStorageAlertIfNeeded];
    
    self.searchController = [Helper customSearchControllerWithSearchResultsUpdaterDelegate:self searchBarDelegate:self];
    self.searchController.hidesNavigationBarDuringPresentation = NO;
    self.searchController.delegate = self;
    
    self.navigationController.delegate = self;
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
    
    if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
        [AppearanceManager forceNavigationBarUpdate:self.navigationController.navigationBar traitCollection:self.traitCollection];
        [AppearanceManager forceToolbarUpdate:self.toolbar traitCollection:self.traitCollection];
        [AppearanceManager forceSearchBarUpdate:self.searchController.searchBar traitCollection:self.traitCollection];
        
        [self reloadData];
    }
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

- (void)moveNode:(MEGANode * _Nonnull)node {
    self.selectedNodesArray = [[NSMutableArray alloc] initWithObjects:node, nil];
    [self moveAction:nil];
}

- (BOOL)isListViewModeSelected {
    return self.viewModePreference == ViewModePreferenceList;
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

- (void)nodesSortTypeHasChanged {
    [self reloadUI];
    
    if (self.searchController.isActive) {
        NSArray *sortedSearchedNodes = [self sortNodes:self.searchNodesArray
                                                sortBy:[Helper sortTypeFor:self.parentNode]];
        self.searchNodesArray = [NSMutableArray arrayWithArray:sortedSearchedNodes];
        [self reloadData];
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
            self.nodes = [MEGASdkManager.sharedMEGASdk childrenForParent:self.parentNode order:[Helper sortTypeFor:self.parentNode]];
            self.hasMediaFiles = [[self.nodes mnz_mediaNodesMutableArrayFromNodeList] count] > 0;
            
            break;
        }
            
        case DisplayModeRubbishBin: {
            [self updateNavigationBarTitle];
            self.nodes = [MEGASdkManager.sharedMEGASdk childrenForParent:self.parentNode order:[Helper sortTypeFor:self.parentNode]];
            self.moreMinimizedBarButtonItem.enabled = self.nodes.size.integerValue > 0;
            
            break;
        }
            
        case DisplayModeRecents: {
            self.recentActionBucket = [MEGASdkManager.sharedMEGASdk.recentActions objectOrNilAtIndex:self.recentIndex];
            self.nodes = self.recentActionBucket.nodesList;
            [self updateNavigationBarTitle];
            break;
            
        case DisplayModeBackup:
            [self updateNavigationBarTitle];
            self.nodes = [MEGASdkManager.sharedMEGASdk childrenForParent:self.parentNode order:[Helper sortTypeFor:self.parentNode]];
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
    AlbumsTableViewController *albumTableViewController = [AlbumsTableViewController.alloc initWithSelectionActionType:AlbumsSelectionActionTypeUpload selectionActionDisabledText:NSLocalizedString(@"upload", @"Used in Photos app browser view as a disabled action when there is no assets selected") completionBlock:^(NSArray<PHAsset *> * _Nonnull assets) {
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

- (void)toolbarActionsForShareType:(MEGAShareType )shareType isBackupNode:(BOOL)isBackupNode {
    UIBarButtonItem *flexibleItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    self.shareType = shareType;
    
    switch (shareType) {
        case MEGAShareTypeAccessRead:
        case MEGAShareTypeAccessReadWrite: {
            if (isBackupNode) {
                self.toolbar.items = @[self.downloadBarButtonItem, flexibleItem, self.shareLinkBarButtonItem, flexibleItem, self.actionsBarButtonItem];
            } else {
                self.toolbar.items = @[self.downloadBarButtonItem, flexibleItem, self.carbonCopyBarButtonItem];
            }
            break;
        }
            
        case MEGAShareTypeAccessFull: {
            self.toolbar.items = @[self.downloadBarButtonItem, flexibleItem, self.carbonCopyBarButtonItem, flexibleItem, self.moveBarButtonItem, flexibleItem, self.deleteBarButtonItem];
            break;
        }
            
        case MEGAShareTypeAccessOwner: {
            if (self.displayMode == DisplayModeCloudDrive) {
                [self.toolbar setItems:@[self.downloadBarButtonItem, flexibleItem, self.shareLinkBarButtonItem, flexibleItem, self.moveBarButtonItem, flexibleItem, self.deleteBarButtonItem, flexibleItem, self.actionsBarButtonItem]];
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
    self.shareLinkBarButtonItem.enabled = boolValue;
    self.moveBarButtonItem.enabled = boolValue;
    self.carbonCopyBarButtonItem.enabled = boolValue;
    self.deleteBarButtonItem.enabled = boolValue;
    self.restoreBarButtonItem.enabled = boolValue;
    self.actionsBarButtonItem.enabled = boolValue;
    
    if ((self.displayMode == DisplayModeRubbishBin) && boolValue) {
        for (MEGANode *n in self.selectedNodesArray) {
            if (!n.mnz_isRestorable) {
                self.restoreBarButtonItem.enabled = NO;
                break;
            }
        }
    }
}

- (void)internetConnectionChanged {
    [self reloadUI];
}

- (void)setNavigationBarButtonItems {
    switch (self.displayMode) {
        case DisplayModeCloudDrive:
        case DisplayModeRubbishBin: {
            [self setNavigationBarButtons];
            break;
        }
            
        case DisplayModeBackup: {
            [self setBackupNavigationBarButtons];
            break;
        }
            
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
        case DisplayModeBackup: {
            self.moreMinimizedBarButtonItem.enabled = boolValue;
            break;
        }
            
        default:
            break;
    }
}

- (void)newFolderAlertTextFieldDidChange:(UITextField *)textField {
    UIAlertController *newFolderAlertController = (UIAlertController *)self.navigationController.presentedViewController;
    if ([newFolderAlertController isKindOfClass:UIAlertController.class]) {
        UIAlertAction *rightButtonAction = newFolderAlertController.actions.lastObject;
        BOOL containsInvalidChars = textField.text.mnz_containsInvalidChars;
        newFolderAlertController.title = [self newFolderNameAlertTitleWithInvalidChars:containsInvalidChars];
        textField.textColor = containsInvalidChars ? UIColor.mnz_redError : UIColor.mnz_label;
        rightButtonAction.enabled = (!textField.text.mnz_isEmpty && !containsInvalidChars);
    }
}

- (void)presentScanDocument {
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
                
            case DisplayModeBackup: {
                [MyBackupsOCWrapper.alloc.init isMyBackupsRootNode:self.parentNode completionHandler:^(BOOL isMyBackupsRootNode) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        self.navigationItem.title = isMyBackupsRootNode ? NSLocalizedString(@"backups.title", @"Title of the backups section") :  [self.parentNode name];
                    });
                }];
            }
                break;
                
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

- (void)showNodeInfo:(MEGANode *)node {
    MEGANavigationController *nodeInfoNavigation = [NodeInfoViewController instantiateWithNode:node delegate:self];
    [self presentViewController:nodeInfoNavigation animated:YES completion:nil];
}

- (MEGAPhotoBrowserViewController *)photoBrowserForMediaNode:(MEGANode *)node {
    NSArray *nodesArray = (self.searchController.isActive && !self.searchController.searchBar.text.mnz_isEmpty) ? self.searchNodesArray : [self.nodes mnz_nodesArrayFromNodeList];
    NSMutableArray<MEGANode *> *mediaNodesArray = [[NSMutableArray alloc] initWithCapacity:nodesArray.count];
    for (MEGANode *n in nodesArray) {
        if (n.name.mnz_isVisualMediaPathExtension) {
            [mediaNodesArray addObject:n];
        }
    }
    
    DisplayMode displayMode = [[MEGASdkManager sharedMEGASdk] accessLevelForNode:node] == MEGAShareTypeAccessOwner ? self.displayMode : DisplayModeSharedItem;
    MEGAPhotoBrowserViewController *photoBrowserVC = [MEGAPhotoBrowserViewController photoBrowserWithMediaNodes:mediaNodesArray api:[MEGASdkManager sharedMEGASdk] displayMode:displayMode presentingNode:node];
    
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
    
    if (!self.cdTableView.tableView.isEditing && !self.cdCollectionView.collectionView.allowsMultipleSelection) {
        if (self.displayMode == DisplayModeBackup) {
            [self setBackupNavigationBarButtons];
        } else {
            [self setNavigationBarButtons];
        }
    }
}

- (void)setEditMode:(BOOL)editMode {
    if (self.viewModePreference == ViewModePreferenceList) {
        [self.cdTableView setTableViewEditing:editMode animated:YES];
    } else {
        [self.cdCollectionView setCollectionViewEditing:editMode animated:YES];
    }
}

- (void)dismissHUD {
    [SVProgressHUD dismiss];
}

- (void)search {
    if (self.searchController.searchBar.text.length >= kMinimumLettersToStartTheSearch) {
        NSString *text = self.searchController.searchBar.text;
        [SVProgressHUD show];
        self.cancelToken = MEGACancelToken.alloc.init;
        SearchOperation *searchOperation = [SearchOperation.alloc initWithParentNode:self.parentNode text:text cancelToken:self.cancelToken completion:^(NSArray <MEGANode *> *nodesFound, BOOL isCancelled) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.searchNodesArray = [NSMutableArray arrayWithArray:nodesFound];
                [self reloadData];
                self.cancelToken = nil;
                [self performSelector:@selector(dismissHUD) withObject:nil afterDelay:kHUDDismissDelay];
            });
        }];
        [self.searchQueue addOperation:searchOperation];
    } else {
        [self reloadData];
    }
}

- (void)cancelSearchIfNeeded {
    if (self.searchQueue.operationCount) {
        [self.cancelToken cancel];
        [self.searchQueue cancelAllOperations];
    }
}

- (void)openFileNode:(MEGANode *)node {
    if (node.name.mnz_isVisualMediaPathExtension) {
        [self showNode:node];
    } else {
        [node mnz_openNodeInNavigationController:self.navigationController folderLink:NO fileLink:nil];
    }
}

- (void)openFolderNode:(MEGANode *)node {
    CloudDriveViewController *cloudDriveVC = [self.storyboard instantiateViewControllerWithIdentifier:@"CloudDriveID"];
    cloudDriveVC.parentNode = node;
    cloudDriveVC.isFromSharedItem = self.isFromSharedItem;
    cloudDriveVC.isFromViewInFolder = self.isFromViewInFolder;
    
    if (self.displayMode == DisplayModeRubbishBin || self.displayMode == DisplayModeBackup) {
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

- (void)presentGetLinkVCForNodes:(NSArray<MEGANode *> *)nodes {
    if (MEGAReachabilityManager.isReachableHUDIfNot) {
        [CopyrightWarningViewController presentGetLinkViewControllerForNodes:nodes inViewController:UIApplication.mnz_presentingViewController];
    }
}

#pragma mark - IBActions

- (IBAction)selectAllAction:(UIBarButtonItem *)sender {
    [self.selectedNodesArray removeAllObjects];
    
    if (!self.allNodesSelected) {
        NSArray *nodesArray = (self.searchController.isActive && !self.searchController.searchBar.text.mnz_isEmpty) ? self.searchNodesArray : [self.nodes mnz_nodesArrayFromNodeList];
        
        self.selectedNodesArray = nodesArray.mutableCopy;
        
        self.allNodesSelected = YES;
        
        [self toolbarActionsWithNodeArray:self.selectedNodesArray];
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

- (void)createNewFolderAction {
    __weak __typeof__(self) weakSelf = self;
    
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
            MEGANode *existingChildNode = [[MEGASdkManager sharedMEGASdk] childNodeForParent:weakSelf.parentNode name:textField.text type:MEGANodeTypeFolder];
            if (existingChildNode) {
                [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"There is already a folder with the same name", @"A tooltip message which is shown when a folder name is duplicated during renaming or creation.")];
            } else {
                MEGACreateFolderRequestDelegate *createFolderRequestDelegate = [[MEGACreateFolderRequestDelegate alloc] initWithCompletion:^(MEGARequest *request) {
                    MEGANode *newFolderNode = [[MEGASdkManager sharedMEGASdk] nodeForHandle:request.nodeHandle];
                    [self didSelectNode:newFolderNode];
                }];
                [[MEGASdkManager sharedMEGASdk] createFolderWithName:textField.text.mnz_removeWhitespacesAndNewlinesFromBothEnds parent:weakSelf.parentNode delegate:createFolderRequestDelegate];
            }
        }
    }];
    createFolderAlertAction.enabled = NO;
    [newFolderAlertController addAction:createFolderAlertAction];
    
    [weakSelf presentViewController:newFolderAlertController animated:YES completion:nil];
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
        self.navigationItem.leftBarButtonItem = self.myAvatarManager.myAvatarBarButton;
        
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
    if (self.selectedNodesArray != nil) {
        [CancellableTransferRouterOCWrapper.alloc.init downloadNodes:self.selectedNodesArray presenter:self isFolderLink:NO];
    }
    [self setEditMode:NO];
}

- (IBAction)shareLinkAction:(UIBarButtonItem *)sender {
    [self presentGetLinkVCForNodes:self.selectedNodesArray];
    
    [self setEditMode:NO];
}

- (IBAction)moveAction:(UIBarButtonItem *)sender {
    [self showBrowserNavigationFor:self.selectedNodesArray action:BrowserActionMove];
}

- (IBAction)copyAction:(UIBarButtonItem *)sender {
    [self showBrowserNavigationFor:self.selectedNodesArray action:BrowserActionCopy];
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

- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls {
    NSMutableArray *transfers = [NSMutableArray<CancellableTransfer *> new];
    for (NSURL* url in urls) {
        NSString *appData = [[NSString new] mnz_appDataToSaveCoordinates:url.path.mnz_coordinatesOfPhotoOrVideo];
        [transfers addObject:[CancellableTransfer.alloc initWithHandle:MEGAInvalidHandle parentHandle:self.parentNode.handle fileLinkURL:nil localFileURL:url name:nil appData:appData priority:NO isFile:YES type:CancellableTransferTypeUpload]];
    }
    [CancellableTransferRouterOCWrapper.alloc.init uploadFiles:transfers presenter:UIApplication.mnz_visibleViewController type:CancellableTransferTypeUpload];
}

#pragma mark - MEGAGlobalDelegate

- (void)onNodesUpdate:(MEGASdk *)api nodeList:(MEGANodeList *)nodeList {
    BOOL shouldProcessOnNodesUpdate = [self shouldProcessOnNodesUpdateWith:nodeList childNodes:self.nodes.mnz_nodesArrayFromNodeList parentNode:self.parentNode];

    [self updateParentNodeIfNeeded:nodeList];
    
    [self updateControllersStackIfNeeded:nodeList];

    if (shouldProcessOnNodesUpdate) {
        if (self.nodes.size.unsignedIntegerValue == 0) {
            self.shouldDetermineViewMode = YES;
        }
        [self.nodesIndexPathMutableDictionary removeAllObjects];
        [self reloadUI];
        
        if (self.searchController.isActive) {
            [self search];
        }
    }
}

#pragma mark - MEGATransferDelegate

- (void)onTransferFinish:(MEGASdk *)api transfer:(MEGATransfer *)transfer error:(MEGAError *)error {
    if (transfer.isStreamingTransfer) {
        return;
    }
    
    if (transfer.type == MEGATransferTypeDownload && [transfer.path hasPrefix:[[FileSystemHelperOCWrapper new] documentsDirectory].path]) {
        switch (self.viewModePreference) {
            case ViewModePreferenceList:
                [self.cdTableView.tableView reloadData];
                break;
            case ViewModePreferenceThumbnail:
                [self.cdCollectionView reloadData];
                break;
            default:
                break;
        }
    }
}

#pragma mark - VNDocumentCameraViewControllerDelegate

- (void)documentCameraViewController:(VNDocumentCameraViewController *)controller didFinishWithScan:(VNDocumentCameraScan *)scan {
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

#pragma mark - NodeInfoViewControllerDelegate

- (void)nodeInfoViewController:(NodeInfoViewController *)nodeInfoViewController presentParentNode:(MEGANode *)node {
    [node navigateToParentAndPresent];
}

#pragma mark - RecentNodeActionDelegate

- (void)showCustomActionsForNode:(MEGANode *)node fromSender:(id)sender {
    [self showCustomActionsForNode:node sender:sender];
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

#pragma mark - BrowserViewControllerDelegate & ContatctsViewControllerDelegate

- (void)nodeEditCompleted:(BOOL)complete {
    [self setEditMode:!complete];
}

@end
