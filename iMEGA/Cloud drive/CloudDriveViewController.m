#import "CloudDriveViewController.h"

#import <AVFoundation/AVCaptureDevice.h>
#import <AVFoundation/AVMediaFormat.h>
#import <VisionKit/VisionKit.h>
#import <PDFKit/PDFKit.h>

#import "SVProgressHUD.h"
#import "UIScrollView+EmptyDataSet.h"

#import "NSFileManager+MNZCategory.h"
#import "NSString+MNZCategory.h"
#import "UIApplication+MNZCategory.h"
#import "UIImageView+MNZCategory.h"


#import "Helper.h"
#import "MEGACreateFolderRequestDelegate.h"
#import "MEGANode+MNZCategory.h"
#import "NSDate+MNZCategory.h"
#import "MEGANodeList+MNZCategory.h"
#import "MEGAPurchase.h"
#import "MEGAReachabilityManager.h"
#import "MEGARemoveRequestDelegate.h"
#import "MEGASdk+MNZCategory.h"
#import "MEGAStore.h"
#import "MEGA-Swift.h"
#import "NSArray+MNZCategory.h"
#import "NSURL+MNZCategory.h"
#import "UITextField+MNZCategory.h"

#import "BrowserViewController.h"
#import "ContactsViewController.h"
#import "EmptyStateView.h"
#import "CustomModalAlertViewController.h"
#import "MEGAImagePickerController.h"
#import "MEGANavigationController.h"
#import "MEGAPhotoBrowserViewController.h"
#import "NodeTableViewCell.h"
#import "PhotosViewController.h"
#import "SharedItemsViewController.h"
#import "UIViewController+MNZCategory.h"

@import Photos;
@import MEGADomain;
@import MEGAL10nObjc;
@import MEGAUIKit;
@import MEGASDKRepo;

static const NSTimeInterval kSearchTimeDelay = .5;
static const NSTimeInterval kHUDDismissDelay = .3;
static const NSUInteger kMinDaysToEncourageToUpgrade = 3;

@interface CloudDriveViewController () <MEGANavigationControllerDelegate, UISearchBarDelegate, UISearchResultsUpdating, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, MEGADelegate, MEGARequestDelegate, NodeInfoViewControllerDelegate, UITextFieldDelegate, UISearchControllerDelegate, VNDocumentCameraViewControllerDelegate, RecentNodeActionDelegate, TextFileEditable>

@property (weak, nonatomic) IBOutlet UIBarButtonItem *moreBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *moreMinimizedBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *editBarButtonItem;

@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;

@property (nonatomic, strong) NSArray *nodesArray;

@property (nonatomic, strong) NSMutableArray *cloudImages;

@property (strong, nonatomic) NSOperationQueue *searchQueue;
@property (strong, nonatomic) MEGACancelToken *cancelToken;

@property (nonatomic, assign) BOOL onlyUploadOptions;
@property (nonatomic, assign) BOOL didShowMediaDiscoveryAutomatically;

@end

@implementation CloudDriveViewController

#pragma mark - Lifecycle

- (void)awakeFromNib{
    [super awakeFromNib];
    [self makeDefaultViewModeStoreCreator];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setUpInvokeCommands];
    [self assignViewModeStore];
    
    self.view.backgroundColor = self.pageBackgroundColor;

    self.definesPresentationContext = YES;

    [self configureContextMenuManagerIfNeeded];

    switch (self.displayMode) {
        case DisplayModeCloudDrive: {
            if (!self.parentNode) {
                self.parentNode = [MEGASdk.shared rootNode];
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
    
    if (self.displayMode != DisplayModeCloudDrive || (([MEGASdk.shared accessLevelForNode:self.parentNode] != MEGAShareTypeAccessOwner) && MEGAReachabilityManager.isReachable)) {
    }
    
    [self setNavigationBarButtonItems];
    
    if (self.displayMode == DisplayModeBackup) {
        [self toolbarActionsForNode:self.parentNode];
    } else {
        MEGAShareType shareType = [MEGASdk.shared accessLevelForNode:self.parentNode];
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
    
    self.moreBarButtonItem.accessibilityLabel = LocalizedString(@"more", @"Top menu option which opens more menu options in a context menu.");
    
    _searchQueue = NSOperationQueue.new;
    self.searchQueue.name = @"searchQueue";
    self.searchQueue.qualityOfService = NSQualityOfServiceUserInteractive;
    self.searchQueue.maxConcurrentOperationCount = 1;
    
    [self showStorageFullAlertIfNeeded];
    self.searchController = [UISearchController customSearchControllerWithSearchResultsUpdaterDelegate:self searchBarDelegate:self];
    
    self.searchController.hidesNavigationBarDuringPresentation = NO;
    self.searchController.delegate = self;
    [self assignAsMEGANavigationDelegateWithDelegate:self];
    
    self.wasSelectingFavoriteUnfavoriteNodeActionOption = NO;

    [self configureWarningBanner];
    
    [AppearanceManager forceSearchBarUpdate:self.searchController.searchBar 
       backgroundColorWhenDesignTokenEnable:[UIColor searchBarSurface1BackgroundColor]
                            traitCollection:self.traitCollection];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(internetConnectionChanged) name:kReachabilityChangedNotification object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(reloadUI) name:MEGASortingPreference object:nil];
    
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(reloadUI) name:NSNotification.didFallbackToMakingOfflineForMediaNode object:nil];
    
    [self observeViewModeNotification];
    
    [MEGASdk.shared addMEGADelegate:self];
    [[MEGAReachabilityManager sharedManager] retryPendingConnections];
    
    [self updateSensitivitySettingOnNextSearch];
    [self reloadUI];
    
    if (self.displayMode != DisplayModeRecents) {
        self.shouldRemovePlayerDelegate = YES;
    }
    
    if (self.myAvatarManager != nil) {
        [self refreshMyAvatar];
    }
    
    [self configureAdsVisibility];
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
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSNotification.didFallbackToMakingOfflineForMediaNode object:nil];
    [MEGASdk.shared removeMEGADelegateAsync:self];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    if (self.viewModel.editModeActive) {
        self.selectedNodesArray = nil;
        [self toggleWithEditModeActive:NO];
    }
    
    if (self.shouldRemovePlayerDelegate) {
        [AudioPlayerManager.shared removeDelegate:self];
    }
    
    [self configureAdsVisibility];
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
        [AppearanceManager forceSearchBarUpdate:self.searchController.searchBar 
           backgroundColorWhenDesignTokenEnable:[UIColor searchBarSurface1BackgroundColor]
                                traitCollection:self.traitCollection];
        
        [self reloadList];
    }
}

- (CloudDriveViewModel *)viewModel {
    if (_viewModel == nil) {
        _viewModel = [self createCloudDriveViewModel];
    }
    return _viewModel;
}

- (DefaultNodeAccessoryActionDelegate *)defaultNodeAccessoryActionDelegate {
    if (_defaultNodeAccessoryActionDelegate == nil) {
        _defaultNodeAccessoryActionDelegate = [DefaultNodeAccessoryActionDelegate new];
    }
    return _defaultNodeAccessoryActionDelegate;
}

#pragma mark - Layout

- (void)initTable {
    [self clearViewModeChildren];
    self.viewModePreference_ObjC = ViewModePreferenceEntityList;
    [self updateSearchAppearanceFor:self.viewModePreference_ObjC];
    
    self.cdTableView = [self.storyboard instantiateViewControllerWithIdentifier:@"CloudDriveTableID"];
    [self addChildViewController:self.cdTableView];
    [self.containerStackView addArrangedSubview:self.cdTableView.view];
    [self.cdTableView didMoveToParentViewController:self];
    
    self.cdTableView.cloudDrive = self;
    self.cdTableView.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    self.cdTableView.tableView.emptyDataSetDelegate = self;
    self.cdTableView.tableView.emptyDataSetSource = self;
}

- (void)initCollection {
    [self clearViewModeChildren];
    self.viewModePreference_ObjC = ViewModePreferenceEntityThumbnail;
    [self updateSearchAppearanceFor:self.viewModePreference_ObjC];
    
    self.cdCollectionView = [self.storyboard instantiateViewControllerWithIdentifier:@"CloudDriveCollectionID"];
    self.cdCollectionView.cloudDrive = self;
    [self addChildViewController:self.cdCollectionView];
    [self.containerStackView addArrangedSubview:self.cdCollectionView.view];
    [self.cdCollectionView didMoveToParentViewController:self];
    
    self.cdCollectionView.collectionView.emptyDataSetDelegate = self;
    self.cdCollectionView.collectionView.emptyDataSetSource = self;
}

#pragma mark - Public

- (nullable MEGANode *)nodeAtIndexPath:(NSIndexPath *)indexPath {
    BOOL isInSearch = self.searchController.searchBar.text.length >= kMinimumLettersToStartTheSearch;
    MEGANode *node;
    if (self.viewModePreference_ObjC == ViewModePreferenceEntityList) {
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
    return self.viewModePreference_ObjC == ViewModePreferenceEntityList;
}

- (BOOL)isThumbnailViewModeSelected {
    return self.viewModePreference_ObjC == ViewModePreferenceEntityThumbnail;
}

- (BOOL)isMediaDiscoveryViewModeSelected {
    return self.viewModePreference_ObjC == ViewModePreferenceEntityMediaDiscovery;
}

-(void)changeModeToListView {
    [self change: ViewModePreferenceEntityList];
}

-(void)changeModeToThumbnail {
    [self change: ViewModePreferenceEntityThumbnail];
}

-(void)changeModeToMediaDiscovery {
    [self change: ViewModePreferenceEntityMediaDiscovery];
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
    __weak typeof(self) weakSelf = self;
    [self prepareForReloadUIWithCompletion:^{
        [weakSelf reloadData];
    }];
}

- (void)reloadUI:(MEGANodeList *)updatedNodes {
    __weak typeof(self) weakSelf = self;
    [self prepareForReloadUIWithCompletion:^{
        __strong __typeof__(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        if (updatedNodes) {
            if (strongSelf.displayMode == DisplayModeCloudDrive && updatedNodes.size == 1 && strongSelf.viewModePreference_ObjC == ViewModePreferenceEntityThumbnail && strongSelf.wasSelectingFavoriteUnfavoriteNodeActionOption) {
                MEGANode *updatedNode = [updatedNodes nodeAtIndex:0];
                NSIndexPath *indexPath = [strongSelf findIndexPathFor:updatedNode source:strongSelf.nodesArray];
                [strongSelf reloadDataAtIndexPaths:@[indexPath]];
                
                strongSelf.wasSelectingFavoriteUnfavoriteNodeActionOption = false;
            } else if (strongSelf.displayMode == DisplayModeRecents) {
                [strongSelf reloadRecentActionBucketAfterNodeUpdatesUsing:MEGASdk.shared];
            } else {
                [strongSelf reloadData];
            }
        } else {
            [strongSelf reloadData];
        }
    }];
}

- (void)prepareForReloadUIWithCompletion:(void (^)(void))completion {
    __weak typeof(self) weakSelf = self;
    [self nodesForDisplayModeWithCompletionHandler:^(MEGANodeList * _Nullable nodes) {
        __strong __typeof__(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            completion();
            return;
        }
        strongSelf.nodes = nodes;
        [strongSelf prepareNodesAndNavigationBarForDisplayMode:strongSelf.displayMode];
        strongSelf.nodesArray = [strongSelf mapNodeListToArray:strongSelf.nodes];
        
        if (strongSelf.displayMode == DisplayModeCloudDrive &&
            strongSelf.parentNode.type != MEGANodeTypeRoot &&
            !strongSelf.isFromSharedItem &&
            !strongSelf.didShowMediaDiscoveryAutomatically &&
            [strongSelf.viewModel shouldShowMediaDiscoveryAutomaticallyForNodes:strongSelf.nodes]) {
            strongSelf.didShowMediaDiscoveryAutomatically = YES;
            strongSelf.viewModePreference_ObjC = ViewModePreferenceEntityMediaDiscovery;
            [strongSelf configureMediaDiscoveryViewModeWithIsShowingAutomatically:YES];
            strongSelf.shouldDetermineViewMode = NO;
            return;
        }
        
        if(strongSelf.nodes.size > 0
           && strongSelf.viewModePreference_ObjC == ViewModePreferenceEntityMediaDiscovery
           && !strongSelf.hasMediaFiles) {
            strongSelf.shouldDetermineViewMode = YES;
        }
        
        if (strongSelf.shouldDetermineViewMode) {
            [strongSelf determineViewMode];
        }
        completion();
    }];
}

- (void)prepareNodesAndNavigationBarForDisplayMode:(DisplayMode)displayMode {
    switch (displayMode) {
        case DisplayModeCloudDrive: {
            [self updateNavigationBarTitle];
            self.hasMediaFiles = [self.viewModel hasMediaFilesWithNodes:self.nodes];
            [self updateSearchAppearanceFor:self.viewModePreference_ObjC];
            break;
        }
            
        case DisplayModeRubbishBin: {
            [self updateNavigationBarTitle];
            self.moreMinimizedBarButtonItem.enabled = self.nodes.size > 0;
            self.navigationItem.searchController = self.searchController;
            break;
        }
            
        case DisplayModeRecents: {
            [self updateNavigationBarTitle];
            self.navigationItem.searchController = self.searchController;
            break;
        }
            
        case DisplayModeBackup: {
            [self updateNavigationBarTitle];
            self.navigationItem.searchController = self.searchController;
            break;
        }
            
        default:
            break;
    }
    
    [self setNavigationBarButtonItemsEnabled:MEGAReachabilityManager.isReachable];
    self.navigationItem.hidesSearchBarWhenScrolling = NO;
}

- (void)loadPhotoAlbumBrowser {
    AlbumsTableViewController *albumTableViewController = [AlbumsTableViewController.alloc initWithSelectionActionType:AlbumsSelectionActionTypeUpload selectionActionDisabledText:LocalizedString(@"upload", @"Used in Photos app browser view as a disabled action when there is no assets selected") completionBlock:^(NSArray<PHAsset *> * _Nonnull assets) {
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
    [self updateToolbarButtonsEnabled:boolValue selectedNodesArray:self.selectedNodesArray];
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
            self.navigationItem.leftBarButtonItem =[[UIBarButtonItem alloc] initWithTitle:LocalizedString(@"close", @"A button label.")
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
        textField.textColor = containsInvalidChars ? self.invalidTextFieldColor : self.validTextFieldColor;
        rightButtonAction.enabled = (!textField.text.mnz_isEmpty && !containsInvalidChars);
    }
}

- (void)presentScanDocument {
    if (!VNDocumentCameraViewController.isSupported) {
        [SVProgressHUD showErrorWithStatus:LocalizedString(@"Document scanning is not available", @"A tooltip message which is shown when device does not support document scanning")];
        return;
    }
    
    [self presentViewController:({
        VNDocumentCameraViewController *scanVC = [VNDocumentCameraViewController.alloc init];
        scanVC.delegate = self;
        scanVC;
    }) animated:YES completion:nil];
}

- (void)encourageToUpgrade {
    if (self.tabBarController == nil) { //Avoid presenting Upgrade view when peeking
        return;
    }
    
    static BOOL alreadyPresented = NO;
    
    NSDate *accountCreationDate = MEGASdk.shared.accountCreationDate;
    NSInteger days = [NSCalendar.currentCalendar components:NSCalendarUnitDay
                                                   fromDate:accountCreationDate
                                                     toDate:NSDate.date
                                                    options:NSCalendarWrapComponents].day;
    
    if (!alreadyPresented && ![MEGASdk.shared mnz_isProAccount] && days > kMinDaysToEncourageToUpgrade) {
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
        MEGAAccountDetails *accountDetails = [MEGASdk.shared mnz_accountDetails];
        if (accountDetails && (arc4random_uniform(20) == 0)) { // 5 % of the times
            [self showUpgradePlanView];
            [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:@"lastEncourageUpgradeDate"];
            alreadyPresented = YES;
        }
    }
}

- (void)reloadList {
    if (self.viewModePreference_ObjC == ViewModePreferenceEntityList) {
        [self.cdTableView.tableView reloadData];
    } else {
        [self.cdCollectionView reloadData];
    }
}

- (void)reloadListAt:(NSArray<NSIndexPath *> *)indexPaths {
    if (self.viewModePreference_ObjC == ViewModePreferenceEntityList) {
        [self.cdTableView.tableView reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
    } else {
        [self.cdCollectionView reloadDataAtIndexPaths:indexPaths];
    }
}

- (void)reloadData {
    [self reloadList];
    
    if (!self.cdTableView.tableView.isEditing && !self.cdCollectionView.collectionView.allowsMultipleSelection) {
        if (self.displayMode == DisplayModeBackup) {
            [self setBackupNavigationBarButtons];
        } else {
            [self setNavigationBarButtons];
        }
    }
}

- (void)reloadDataAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths {
    [self reloadListAt:indexPaths];
    
    if (!self.cdTableView.tableView.isEditing && !self.cdCollectionView.collectionView.allowsMultipleSelection) {
        if (self.displayMode == DisplayModeBackup) {
            [self setBackupNavigationBarButtons];
        } else {
            [self setNavigationBarButtons];
        }
    }
}

- (void)setEditMode:(BOOL)editMode {
    
    switch (self.viewModePreference_ObjC) {
        case ViewModePreferenceEntityList:
            [self.cdTableView setTableViewEditing:editMode animated:YES];
            break;
        case ViewModePreferenceEntityThumbnail:
            [self.cdCollectionView setCollectionViewEditing:editMode animated:YES];
            break;
        case ViewModePreferenceEntityMediaDiscovery:
            [self.mdHostedController setEditing:editMode animated:YES];
            break;
        case ViewModePreferenceEntityPerFolder:
            return;
    }
    
    [self setViewEditing:editMode];
}

- (void)dismissHUD {
    [SVProgressHUD dismiss];
}

- (void)search {
    if (self.searchController.searchBar.text.length >= kMinimumLettersToStartTheSearch) {
        NSString *text = self.searchController.searchBar.text;
        self.cancelToken = MEGACancelToken.alloc.init;
        __weak typeof(self) weakSelf = self;
        [self.viewModel shouldExcludeSensitiveItemsWithCompletionHandler:^(BOOL shouldExcludeSharedItems) {
            __strong __typeof__(weakSelf) strongSelf = weakSelf;
            if (!strongSelf) {
                return;
            }
            SearchWithFilterOperation *searchOperation = [strongSelf makeSearchWithFilterOperationWithSearchText:text
                                                                                                    parentHandle:strongSelf.parentNode.handle
                                                                                                excludeSensitive:shouldExcludeSharedItems
                                                                                                     cancelToken:strongSelf.cancelToken
                                                                                                      completion:^(MEGANodeList*nodeList, BOOL isCancelled) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    strongSelf.cancelToken = nil;

                    if (!isCancelled) {
                        strongSelf.searchNodesArray = [NSMutableArray arrayWithArray: [nodeList toNodeArray]];
                        [strongSelf reloadData];
                    }

                    if (self.searchQueue.operationCount == 0) {
                        if (!isCancelled) {
                            [strongSelf performSelector:@selector(dismissHUD) withObject:nil afterDelay:kHUDDismissDelay];
                        } else {
                            [strongSelf dismissHUD];
                        }
                    }
                });
            }];

            dispatch_async(dispatch_get_main_queue(), ^{
                if (!SVProgressHUD.isVisible) {
                    [SVProgressHUD show];
                }
            });
            [strongSelf.searchQueue addOperation:searchOperation];
        }];
    } else {
        [self reloadData];
    }
}

- (void)cancelSearchIfNeeded {
    if (self.searchQueue.operationCount) {
        @synchronized(self) {
            [self.cancelToken cancel];
        }
        [self.searchQueue cancelAllOperations];
    }
}

- (void)confirmDeleteActionFiles:(NSUInteger)numFilesAction andFolders:(NSUInteger)numFoldersAction {
    
    // For some reason `numFilesAction` `numFoldersAction` might be both zero,
    // we need to check for files and folder count before showing the alert.
    if ([self.viewModel shouldShowConfirmationAlertForRemovedFiles:numFilesAction andFolders:numFoldersAction]) {
        NSString *alertTitle = [self.viewModel alertTitleForRemovedFiles:numFilesAction andFolders:numFoldersAction];
        NSString *message = [self.viewModel alertMessageForRemovedFiles:numFilesAction andFolders:numFoldersAction];
        UIAlertController *removeAlertController = [UIAlertController alertControllerWithTitle:alertTitle message:message preferredStyle:UIAlertControllerStyleAlert];
        [removeAlertController addAction:[UIAlertAction actionWithTitle:LocalizedString(@"cancel", @"Button title to cancel something") style:UIAlertActionStyleCancel handler:nil]];
        
        __weak typeof(self) weakSelf = self;
        [removeAlertController addAction:[UIAlertAction actionWithTitle:LocalizedString(@"ok", @"Button title to cancel something") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [weakSelf deleteSelectedNodesForFiles:numFilesAction andFolders:numFoldersAction];
        }]];
        
        [self presentViewController:removeAlertController animated:YES completion:nil];
    } else {
        [self deleteSelectedNodesForFiles:numFilesAction andFolders:numFoldersAction];
    }
}

- (void)deleteSelectedNodesForFiles:(NSUInteger)numFilesAction andFolders:(NSUInteger)numFoldersAction {
    MEGARemoveRequestDelegate *removeRequestDelegate = [MEGARemoveRequestDelegate.alloc initWithMode:DisplayModeRubbishBin files:numFilesAction folders:numFoldersAction completion:^{
        [self toggleWithEditModeActive:NO];
    }];
    for (MEGANode *node in self.selectedNodesArray) {
        [MEGASdk.shared removeNode:node delegate:removeRequestDelegate];
    }
}

#pragma mark - IBActions

- (IBAction)selectAllAction:(UIBarButtonItem *)sender {
    [self.selectedNodesArray removeAllObjects];
    
    switch (self.viewModePreference_ObjC) {
        case ViewModePreferenceEntityMediaDiscovery:
            [self mediaDiscoveryToggleAllSelected];
            return;
        case ViewModePreferenceEntityPerFolder:
        case ViewModePreferenceEntityList:
        case ViewModePreferenceEntityThumbnail:
            break;
    }
    
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
    
    UIAlertController *newFolderAlertController = [UIAlertController alertControllerWithTitle:LocalizedString(@"newFolder", @"Menu option from the `Add` section that allows you to create a 'New Folder'") message:nil preferredStyle:UIAlertControllerStyleAlert];
    
    [newFolderAlertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = LocalizedString(@"newFolderMessage", @"Hint text shown on the create folder alert.");
        [textField addTarget:weakSelf action:@selector(newFolderAlertTextFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
        textField.shouldReturnCompletion = ^BOOL(UITextField *textField) {
            return (!textField.text.mnz_isEmpty && !textField.text.mnz_containsInvalidChars);
        };
    }];
    
    [newFolderAlertController addAction:[UIAlertAction actionWithTitle:LocalizedString(@"cancel", @"Button title to cancel something") style:UIAlertActionStyleCancel handler:nil]];
    
    UIAlertAction *createFolderAlertAction = [UIAlertAction actionWithTitle:LocalizedString(@"createFolderButton", @"Title button for the create folder alert.") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        if ([MEGAReachabilityManager isReachableHUDIfNot]) {
            UITextField *textField = [[newFolderAlertController textFields] firstObject];
            MEGANode *existingChildNode = [MEGASdk.shared childNodeForParent:weakSelf.parentNode name:textField.text type:MEGANodeTypeFolder];
            if (existingChildNode) {
                [SVProgressHUD showErrorWithStatus:LocalizedString(@"There is already a folder with the same name", @"A tooltip message which is shown when a folder name is duplicated during renaming or creation.")];
            } else {
                MEGACreateFolderRequestDelegate *createFolderRequestDelegate = [[MEGACreateFolderRequestDelegate alloc] initWithCompletion:^(MEGARequest *request) {
                    MEGANode *newFolderNode = [MEGASdk.shared nodeForHandle:request.nodeHandle];
                    [self didSelectNode:newFolderNode];
                }];
                [MEGASdk.shared createFolderWithName:textField.text.mnz_removeWhitespacesAndNewlinesFromBothEnds parent:weakSelf.parentNode delegate:createFolderRequestDelegate];
            }
        }
    }];
    createFolderAlertAction.enabled = NO;
    [newFolderAlertController addAction:createFolderAlertAction];
    
    [weakSelf presentViewController:newFolderAlertController animated:YES completion:nil];
}

- (void)setViewEditing:(BOOL)editing {
    [self updateNavigationBarTitle];
    
    [self setEditing:editing];
    
    if (editing) {
        self.editBarButtonItem.title = LocalizedString(@"cancel", @"Button title to cancel something");
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
            [self.toolbar setBackgroundColor:self.toolBarBackgroundColor];

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
        self.isEditingModeBeingDisabled = YES;
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
    [self toggleWithEditModeActive:NO];
}

- (IBAction)shareLinkAction:(UIBarButtonItem *)sender {
    [self presentGetLinkFor:self.selectedNodesArray];
    
    [self toggleWithEditModeActive:NO];
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
    
    [self toggleWithEditModeActive:NO];
}

#pragma mark - UISearchBarDelegate

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    self.searchNodesArray = nil;
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    if (self.viewModePreference_ObjC == ViewModePreferenceEntityThumbnail) {
        self.cdCollectionView.collectionView.clipsToBounds = YES;
    }
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
    if (self.viewModePreference_ObjC == ViewModePreferenceEntityThumbnail) {
        self.cdCollectionView.collectionView.clipsToBounds = NO;
    }
}

#pragma mark - UISearchResultsUpdating

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    if (self.searchController.searchBar.text.length >= kMinimumLettersToStartTheSearch) {
        [self cancelSearchIfNeeded];
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(search) object:nil];
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(dismissHUD) object:nil];
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

    BOOL didParentNodeUpdate = [self updateParentNodeIfNeeded:nodeList];
    
    [self updateControllersStackIfNeeded:nodeList];

    if (shouldProcessOnNodesUpdate) {
        [self.nodesIndexPathMutableDictionary removeAllObjects];
        [self reloadUI: nodeList];
        
        if (self.searchController.isActive) {
            [self search];
        }
    } else if (didParentNodeUpdate) {
        [self reloadUI: nil];
    }
}

#pragma mark - MEGATransferDelegate

- (void)onTransferFinish:(MEGASdk *)api transfer:(MEGATransfer *)transfer error:(MEGAError *)error {
    if (transfer.isStreamingTransfer) {
        return;
    }
    
    if (transfer.type == MEGATransferTypeDownload && [transfer.path hasPrefix:[[FileSystemHelperOCWrapper new] documentsDirectory].path]) {
        switch (self.viewModePreference_ObjC) {
            case ViewModePreferenceEntityList:
                [self.cdTableView.tableView reloadData];
                break;
            case ViewModePreferenceEntityThumbnail:
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
            [nav addLeftDismissButtonWithText:LocalizedString(@"cancel", @"")];
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

#pragma mark - MEGANavigationControllerDelegate
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

#pragma mark - BrowserViewControllerDelegate & ContactsViewControllerDelegate

- (void)nodeEditCompleted:(BOOL)complete {
    
    if(complete) {
        [self toggleWithEditModeActive:NO];
    }
}

@end
