#import "PhotosViewController.h"

#import "UIScrollView+EmptyDataSet.h"
#import "EmptyStateView.h"
#import "Helper.h"
#import "MEGAMoveRequestDelegate.h"
#import "MEGANavigationController.h"
#import "MEGANode+MNZCategory.h"
#import "MEGANodeList+MNZCategory.h"
#import "MEGAReachabilityManager.h"
#import "MEGA-Swift.h"
#import "NSDate+MNZCategory.h"
#import "NSString+MNZCategory.h"
#import "MEGAPhotoBrowserViewController.h"
#import "UICollectionView+MNZCategory.h"
#import "UIImageView+MNZCategory.h"
#import "PhotoCollectionViewCell.h"
#import "HeaderCollectionReusableView.h"
#import "CameraUploadsTableViewController.h"
#import "DisplayMode.h"
#import "BrowserViewController.h"
#import "CameraUploadManager.h"
#import "CameraUploadManager+Settings.h"
#import "CustomModalAlertViewController.h"
#import "UploadStats.h"
#import "UIViewController+MNZCategory.h"
#import "UIActivityViewController+MNZCategory.h"

@import StoreKit;
@import Photos;

static const NSTimeInterval PhotosViewReloadTimeDelay = .35;
static const NSTimeInterval HeaderStateViewReloadTimeDelay = .25;

@interface PhotosViewController () <UICollectionViewDelegateFlowLayout, UIViewControllerPreviewingDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, MEGAPhotoBrowserDelegate> {
    BOOL allNodesSelected;
}

@property (nonatomic, strong) MEGANode *parentNode;
@property (nonatomic, strong) MEGANodeList *nodeList;
@property (nonatomic, strong) NSMutableArray<MEGANode *> *mediaNodesArray;
@property (nonatomic, strong) NSMutableArray *photosByMonthYearArray;

@property (nonatomic) CGSize cellSize;
@property (nonatomic) CGFloat cellInset;

@property (nonatomic, strong) NSMutableDictionary *selectedItemsDictionary;

@property (weak, nonatomic) IBOutlet UIView *stateView;
@property (weak, nonatomic) IBOutlet UIButton *enableCameraUploadsButton;
@property (weak, nonatomic) IBOutlet UIProgressView *photosUploadedProgressView;
@property (weak, nonatomic) IBOutlet UILabel *photosUploadedLabel;
@property (weak, nonatomic) IBOutlet UILabel *stateLabel;
@property (weak, nonatomic) IBOutlet UIStackView *progressStackView;

@property (weak, nonatomic) IBOutlet UICollectionView *photosCollectionView;

@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *downloadBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *shareBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *moveBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *carbonCopyBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *deleteBarButtonItem;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *editBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *selectAllBarButtonItem;

@property (nonatomic) MEGACameraUploadsState currentState;

@property (nonatomic) NSIndexPath *browsingIndexPath;

@end

@implementation PhotosViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.photosCollectionView.emptyDataSetSource = self;
    self.photosCollectionView.emptyDataSetDelegate = self;
    
    [self.enableCameraUploadsButton setTitle:AMLocalizedString(@"enable", nil) forState:UIControlStateNormal];
    
    self.selectedItemsDictionary = [[NSMutableDictionary alloc] init];
    
    self.editBarButtonItem.title = AMLocalizedString(@"select", @"Caption of a button to select files");
    
    [self.view addGestureRecognizer:[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)]];
    
    self.cellInset = 1.0f;
    self.cellSize = [self.photosCollectionView mnz_calculateCellSizeForInset:self.cellInset];
    
    self.currentState = MEGACameraUploadsStateLoading;
    
    if (@available(iOS 13.0, *)) {
        [self configPreviewingRegistration];
    }
    
    [self updateAppearance];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self setEditing:NO animated:NO];
    
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(didReceiveInternetConnectionChangedNotification) name:kReachabilityChangedNotification object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(didReceiveCameraUploadStatsChangedNotification) name:MEGACameraUploadStatsChangedNotification object:nil];
    
    [[MEGASdkManager sharedMEGASdk] addMEGARequestDelegate:self];
    [[MEGASdkManager sharedMEGASdk] addMEGAGlobalDelegate:self];

    self.editBarButtonItem.enabled = MEGAReachabilityManager.isReachable;
    [self reloadUI];
    [self reloadHeader];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    CGSize cellSize = [self.photosCollectionView mnz_calculateCellSizeForInset:self.cellInset];
    if (!CGSizeEqualToSize(cellSize, self.cellSize)) {
        self.cellSize = cellSize;
        [self.photosCollectionView reloadData];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[TransfersWidgetViewController sharedTransferViewController].progressView showWidgetIfNeeded];

    if (self.photosByMonthYearArray.count > 0 && CameraUploadManager.shouldShowCameraUploadBoardingScreen) {
        [self showCameraUploadBoardingScreen];
    } else if (CameraUploadManager.shared.isDiskStorageFull) {
        [self showLocalDiskIsFullWarningScreen];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [NSNotificationCenter.defaultCenter removeObserver:self name:kReachabilityChangedNotification object:nil];
    [NSNotificationCenter.defaultCenter removeObserver:self name:MEGACameraUploadStatsChangedNotification object:nil];
    
    [[MEGASdkManager sharedMEGASdk] removeMEGARequestDelegate:self];
    [[MEGASdkManager sharedMEGASdk] removeMEGAGlobalDelegate:self];
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
        if (self.photosByMonthYearArray.count == 0) {
            [self.photosCollectionView reloadEmptyDataSet];
        } else {
            CGSize cellSize = [self.photosCollectionView mnz_calculateCellSizeForInset:self.cellInset];
            if (!CGSizeEqualToSize(cellSize, self.cellSize)) {
                self.cellSize = cellSize;
                [self.photosCollectionView reloadData];
            }
        }
    } completion:nil];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    
    if (@available(iOS 13.0, *)) {
        if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
            [AppearanceManager forceToolbarUpdate:self.toolbar traitCollection:self.traitCollection];
            
            [self updateAppearance];
        }
    }
    
    [self configPreviewingRegistration];
}

#pragma mark - uploads state

- (void)reloadHeader {
    MEGALogDebug(@"[Camera Upload] reload photos view header");
    
    if (!MEGAReachabilityManager.isReachable) {
        self.currentState = MEGACameraUploadsStateNoInternetConnection;

        return;
    }
    
    if (!CameraUploadManager.isCameraUploadEnabled) {
        if (self.photosByMonthYearArray.count == 0) {
            self.currentState = MEGACameraUploadsStateEmpty;
        } else {
            self.currentState = MEGACameraUploadsStateDisabled;
        }
        
        return;
    }

    [self loadUploadStats];
}

- (void)loadUploadStats {
    if (self.currentState != MEGACameraUploadsStateUploading && self.currentState != MEGACameraUploadsStateCompleted) {
        self.currentState = MEGACameraUploadsStateLoading;
    }
    
    [CameraUploadManager.shared loadCurrentUploadStatsWithCompletion:^(UploadStats * _Nullable uploadStats, NSError * _Nullable error) {
        if (error || uploadStats == nil) {
            MEGALogError(@"[Camera Upload] error when to fetch upload stats %@", error);
            return;
        }
        
        MEGALogDebug(@"[Camera Upload] pending count %lu, done count: %lu, total count: %lu", (unsigned long)uploadStats.pendingFilesCount, (unsigned long)uploadStats.finishedFilesCount, (unsigned long)uploadStats.totalFilesCount);
        dispatch_async(dispatch_get_main_queue(), ^{
            self.currentState = uploadStats.pendingFilesCount > 0 ? MEGACameraUploadsStateUploading : MEGACameraUploadsStateCompleted;
            [self configUploadProgressByStats:uploadStats];
            [self loadEnableVideoStateIfNeeded];
        });
    }];
}

- (void)configUploadProgressByStats:(UploadStats *)uploadStats {
    self.photosUploadedProgressView.progress = (float)uploadStats.finishedFilesCount / (float)uploadStats.totalFilesCount;
    
    NSString *progressText;
    if (uploadStats.pendingFilesCount == 1) {
        if (CameraUploadManager.isCameraUploadPausedBecauseOfNoWiFiConnection) {
            progressText = AMLocalizedString(@"Upload paused because of no WiFi, 1 file pending", nil);
        } else {
            progressText = AMLocalizedString(@"cameraUploadsPendingFile", @"Message shown while uploading files. Singular.");
        }
    } else {
        if (CameraUploadManager.isCameraUploadPausedBecauseOfNoWiFiConnection) {
            progressText = [NSString stringWithFormat:AMLocalizedString(@"Upload paused because of no WiFi, %lu files pending", nil), uploadStats.pendingFilesCount];
        } else {
            progressText = [NSString stringWithFormat:AMLocalizedString(@"cameraUploadsPendingFiles", @"Message shown while uploading files. Plural."), uploadStats.pendingFilesCount];
        }
    }
    self.photosUploadedLabel.text = progressText;
}

- (void)loadEnableVideoStateIfNeeded {
    if (self.currentState != MEGACameraUploadsStateCompleted || CameraUploadManager.isVideoUploadEnabled) {
        return;
    }
    
    [CameraUploadManager.shared loadUploadStatsForMediaTypes:@[@(PHAssetMediaTypeVideo)] completion:^(UploadStats * _Nullable uploadStats, NSError * _Nullable error) {
        if (error) {
            MEGALogError(@"[Camera Upload] error when to load record count for video %@", error);
            return;
        }
        
        if (uploadStats.pendingFilesCount == 0) {
            return;
        }
        
        MEGALogDebug(@"[Camera Upload] %lu video count loaded", (unsigned long)uploadStats.pendingFilesCount);
        dispatch_async(dispatch_get_main_queue(), ^{
            self.currentState = MEGACameraUploadsStateEnableVideo;
            [self configStateLabelByVideoPendingCount:uploadStats.pendingFilesCount];
        });
    }];
}

- (void)configStateLabelByVideoPendingCount:(NSUInteger)count {
    NSString *videoMessage;
    if (count == 1) {
        videoMessage = AMLocalizedString(@"Photos uploaded, video uploads are off, 1 video not uploaded", nil);
    } else {
        videoMessage = [NSString stringWithFormat:AMLocalizedString(@"Photos uploaded, video uploads are off, %lu videos not uploaded", nil), (unsigned long)count];
    }
    
    self.stateLabel.text = videoMessage;
}

- (void)setCurrentState:(MEGACameraUploadsState)currentState {
    if (_currentState == currentState) {
        return;
    }
    
    self.stateView.hidden = NO;
    self.stateLabel.hidden = NO;
    self.stateLabel.font = [UIFont systemFontOfSize:17.0];
    self.progressStackView.hidden = YES;
    self.enableCameraUploadsButton.hidden = YES;
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    
    switch (currentState) {
        case MEGACameraUploadsStateDisabled:
            self.stateLabel.text = AMLocalizedString(@"enableCameraUploadsButton", nil);
            self.enableCameraUploadsButton.hidden = NO;
            break;
        case MEGACameraUploadsStateUploading:
            self.stateLabel.hidden = YES;
            self.progressStackView.hidden = NO;
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
            break;
        case MEGACameraUploadsStateCompleted:
            self.stateLabel.text = AMLocalizedString(@"cameraUploadsComplete", @"Message shown when the camera uploads have been completed");
            break;
        case MEGACameraUploadsStateNoInternetConnection:
            if (self.photosByMonthYearArray.count == 0) {
                self.stateView.hidden = YES;
            } else {
                self.stateLabel.text = AMLocalizedString(@"noInternetConnection", @"Text shown on the app when you don't have connection to the internet or when you have lost it");
            }
            break;
        case MEGACameraUploadsStateEmpty:
            self.stateView.hidden = YES;
            break;
        case MEGACameraUploadsStateLoading:
            self.stateLabel.text = AMLocalizedString(@"loading", nil);
            break;
        case MEGACameraUploadsStateEnableVideo:
            self.stateLabel.font = [UIFont systemFontOfSize:15.0];
            self.enableCameraUploadsButton.hidden = NO;
            break;
    }
    
    _currentState = currentState;
}

#pragma mark - Private

- (void)updateAppearance {
    self.view.backgroundColor = UIColor.mnz_background;
    
    self.stateView.backgroundColor = [UIColor mnz_mainBarsForTraitCollection:self.traitCollection];
    
    self.enableCameraUploadsButton.tintColor = [UIColor mnz_turquoiseForTraitCollection:self.traitCollection];
}

- (void)reloadUI {
    MEGALogDebug(@"[Camera Upload] reload photos collection view");
    NSMutableDictionary *photosByMonthYearDictionary = [NSMutableDictionary new];
    
    self.photosByMonthYearArray = [NSMutableArray new];
    NSMutableArray *photosArray = [NSMutableArray new];
    
    self.parentNode = [[MEGASdkManager sharedMEGASdk] childNodeForParent:[[MEGASdkManager sharedMEGASdk] rootNode] name:MEGACameraUploadsNodeName];
    
    self.nodeList = [[MEGASdkManager sharedMEGASdk] childrenForParent:self.parentNode order:MEGASortOrderTypeModificationDesc];
    
    self.mediaNodesArray = [[NSMutableArray alloc] initWithCapacity:self.nodeList.size.unsignedIntegerValue];
    
    for (NSInteger i = 0; i < [self.nodeList.size integerValue]; i++) {
        MEGANode *node = [self.nodeList nodeAtIndex:i];
        
        if (!node.name.mnz_isImagePathExtension && !node.name.mnz_isVideoPathExtension) {
            continue;
        }
        
        NSString *currentMonthYearString = node.modificationTime.mnz_formattedMonthAndYear;
        
        if (![photosByMonthYearDictionary objectForKey:currentMonthYearString]) {
            photosByMonthYearDictionary = [NSMutableDictionary new];
            photosArray = [NSMutableArray new];
            [photosArray addObject:node];
            [photosByMonthYearDictionary setObject:photosArray forKey:currentMonthYearString];
            [self.photosByMonthYearArray addObject:photosByMonthYearDictionary];
        } else {
            [photosArray addObject:node];
        }
        
        [self.mediaNodesArray addObject:node];
    }
    
    [self.photosCollectionView reloadData];
    
    if ([self.photosCollectionView allowsMultipleSelection]) {
        self.navigationItem.title = AMLocalizedString(@"selectTitle", @"Select items");
    } else {
        self.navigationItem.title = AMLocalizedString(@"cameraUploadsLabel", @"Title of one of the Settings sections where you can set up the 'Camera Uploads' options");
    }
}

- (void)setToolbarActionsEnabled:(BOOL)boolValue {
    self.downloadBarButtonItem.enabled = boolValue;
    self.shareBarButtonItem.enabled = ((self.selectedItemsDictionary.count < 100) ? boolValue : NO);
    self.moveBarButtonItem.enabled = boolValue;
    self.carbonCopyBarButtonItem.enabled = boolValue;
    self.deleteBarButtonItem.enabled = boolValue;
}

- (NSIndexPath *)indexPathForNode:(MEGANode *)node {
    NSUInteger section = 0;
    for (NSDictionary *sectionInArray in self.photosByMonthYearArray) {
        NSUInteger item = 0;
        NSArray *nodesInSection = [sectionInArray objectForKey:sectionInArray.allKeys.firstObject];
        for (MEGANode *n in nodesInSection) {
            if (n.handle == node.handle) {
                return [NSIndexPath indexPathForItem:item inSection:section];
            }
            item++;
        }
        section++;
    }
    
    return nil;
}

#pragma mark - notifications

- (void)didReceiveCameraUploadStatsChangedNotification {
    dispatch_async(dispatch_get_main_queue(), ^{
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(reloadHeader) object:nil];
        [self performSelector:@selector(reloadHeader) withObject:nil afterDelay:HeaderStateViewReloadTimeDelay];
    });
}

- (void)didReceiveInternetConnectionChangedNotification {
    self.editBarButtonItem.enabled = MEGAReachabilityManager.isReachable;
    [self reloadHeader];
    [self.photosCollectionView reloadEmptyDataSet];
}

#pragma mark - IBAction

- (IBAction)enableCameraUploadsTouchUpInside:(UIButton *)sender {
    if (self.photosCollectionView.allowsMultipleSelection) {
        [self setEditing:NO animated:NO];
    }
    
    if (self.currentState == MEGACameraUploadsStateEnableVideo && !CameraUploadManager.isVideoUploadEnabled) {
        if (CameraUploadManager.isHEVCFormatSupported) {
            [self pushVideoUploadSettings];
        } else {
            [self pushCameraUploadSettings];
        }
    } else {
        [self pushCameraUploadSettings];
    }
}

- (IBAction)selectAllAction:(UIBarButtonItem *)sender {
    [self.selectedItemsDictionary removeAllObjects];
    
    if (!allNodesSelected) {
        MEGANode *n = nil;
        NSInteger nodeListSize = [[self.nodeList size] integerValue];
        
        for (NSInteger i = 0; i < nodeListSize; i++) {
            n = [self.nodeList nodeAtIndex:i];
            [self.selectedItemsDictionary setObject:n forKey:[NSNumber numberWithLongLong:n.handle]];
        }
        
        allNodesSelected = YES;
        [self.navigationItem setTitle:[NSString stringWithFormat:AMLocalizedString(@"itemsSelected", @"%lu Items selected"), (long)[[self.nodeList size] unsignedIntegerValue]]];
    } else {
        allNodesSelected = NO;
        [self.navigationItem setTitle:AMLocalizedString(@"selectTitle", @"Select title")];
    }
    
    if (self.selectedItemsDictionary.count == 0) {
        [self setToolbarActionsEnabled:NO];
    } else {
        [self setToolbarActionsEnabled:YES];
    }
    
    [self.photosCollectionView reloadData];
}

- (IBAction)editTapped:(UIBarButtonItem *)sender {
    BOOL enableEditing = !self.photosCollectionView.allowsMultipleSelection;
    [self setEditing:enableEditing animated:YES];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    
    if (editing) {
        self.editBarButtonItem.title = AMLocalizedString(@"cancel", @"Button title to cancel something");
        
        [self.navigationItem setTitle:AMLocalizedString(@"selectTitle", @"Select items")];
        [self.photosCollectionView setAllowsMultipleSelection:YES];
        self.navigationItem.leftBarButtonItems = @[self.selectAllBarButtonItem];
        
        [self.toolbar setAlpha:0.0];
        [self.tabBarController.view addSubview:self.toolbar];
        self.toolbar.translatesAutoresizingMaskIntoConstraints = NO;
        
        NSLayoutAnchor *bottomAnchor;
        if (@available(iOS 11.0, *)) {
            bottomAnchor = self.tabBarController.tabBar.safeAreaLayoutGuide.bottomAnchor;
        } else {
            bottomAnchor = self.tabBarController.tabBar.bottomAnchor;
        }
        
        [NSLayoutConstraint activateConstraints:@[[self.toolbar.topAnchor constraintEqualToAnchor:self.tabBarController.tabBar.topAnchor constant:0],
                                                  [self.toolbar.leadingAnchor constraintEqualToAnchor:self.tabBarController.tabBar.leadingAnchor constant:0],
                                                  [self.toolbar.trailingAnchor constraintEqualToAnchor:self.tabBarController.tabBar.trailingAnchor constant:0],
                                                  [self.toolbar.bottomAnchor constraintEqualToAnchor:bottomAnchor constant:0]]];
        
        [UIView animateWithDuration:0.33f animations:^ {
            [self.toolbar setAlpha:1.0];
        }];
    } else {
        self.editBarButtonItem.title = AMLocalizedString(@"select", @"Caption of a button to select files");
        
        allNodesSelected = NO;
        self.navigationItem.title = AMLocalizedString(@"cameraUploadsLabel", @"Title of one of the Settings sections where you can set up the 'Camera Uploads' options");
        [self.photosCollectionView setAllowsMultipleSelection:NO];
        [self.selectedItemsDictionary removeAllObjects];
        [self.photosCollectionView reloadData];
        self.navigationItem.leftBarButtonItems = @[];
        
        [UIView animateWithDuration:0.33f animations:^ {
            [self.toolbar setAlpha:0.0];
        } completion:^(BOOL finished) {
            if (finished) {
                [self.toolbar removeFromSuperview];
            }
        }];
    }
    if (![self.selectedItemsDictionary count]) {
        [self setToolbarActionsEnabled:NO];
    }
}

- (IBAction)downloadAction:(UIBarButtonItem *)sender {
    for (MEGANode *n in [self.selectedItemsDictionary allValues]) {
        if (![Helper isFreeSpaceEnoughToDownloadNode:n isFolderLink:NO]) {
            [self setEditing:NO animated:YES];
            return;
        }
    }
    
    for (MEGANode *n in [self.selectedItemsDictionary allValues]) {
        [Helper downloadNode:n folderPath:[Helper relativePathForOffline] isFolderLink:NO shouldOverwrite:NO];
    }
    [self setEditing:NO animated:YES];
}

- (IBAction)shareAction:(UIBarButtonItem *)sender {
    UIActivityViewController *activityVC = [UIActivityViewController activityViewControllerForNodes:self.selectedItemsDictionary.allValues sender:self.shareBarButtonItem];
    [self presentViewController:activityVC animated:YES completion:nil];
}

- (IBAction)moveAction:(UIBarButtonItem *)sender {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Cloud" bundle:nil];
    MEGANavigationController *mcnc = [storyboard instantiateViewControllerWithIdentifier:@"BrowserNavigationControllerID"];
    [self presentViewController:mcnc animated:YES completion:nil];
    
    BrowserViewController *browserVC = mcnc.viewControllers.firstObject;
    browserVC.selectedNodesArray = [NSArray arrayWithArray:[self.selectedItemsDictionary allValues]];
    browserVC.browserAction = BrowserActionMove;
}

- (IBAction)copyAction:(UIBarButtonItem *)sender {
    if ([MEGAReachabilityManager isReachableHUDIfNot]) {
        MEGANavigationController *navigationController = [[UIStoryboard storyboardWithName:@"Cloud" bundle:nil] instantiateViewControllerWithIdentifier:@"BrowserNavigationControllerID"];
        BrowserViewController *browserVC = navigationController.viewControllers.firstObject;
        browserVC.selectedNodesArray = [NSArray arrayWithArray:[self.selectedItemsDictionary allValues]];
        [browserVC setBrowserAction:BrowserActionCopy];
        [self presentViewController:navigationController animated:YES completion:nil];
    }
}

- (IBAction)deleteAction:(UIBarButtonItem *)sender {
    NSUInteger count = self.selectedItemsDictionary.count;
    NSArray *selectedItemsArray = [self.selectedItemsDictionary allValues];
    MEGANode *rubbishBinNode = [[MEGASdkManager sharedMEGASdk] rubbishNode];
    MEGAMoveRequestDelegate *moveRequestDelegate = [[MEGAMoveRequestDelegate alloc] initToMoveToTheRubbishBinWithFiles:selectedItemsArray.count folders:0 completion:^{
        [self setEditing:NO animated:NO];
    }];
    
    for (NSUInteger i = 0; i < count; i++) {
        [[MEGASdkManager sharedMEGASdk] moveNode:[selectedItemsArray objectAtIndex:i] newParent:rubbishBinNode delegate:moveRequestDelegate];
    }
    
    [self setEditing:NO animated:YES];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    if ([self.photosByMonthYearArray count] == 0) {
        self.editBarButtonItem.enabled = NO;
    } else {
        self.editBarButtonItem.enabled = MEGAReachabilityManager.isReachable;
    }
    
    return [self.photosByMonthYearArray count];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    NSDictionary *dict = [self.photosByMonthYearArray objectAtIndex:section];
    NSString *key = dict.allKeys.firstObject;
    NSArray *array = [dict objectForKey:key];
    
    return [array count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"photoCellId";
    
    PhotoCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    
    MEGANode *node = nil;
    
    NSDictionary *dict = [self.photosByMonthYearArray objectAtIndex:indexPath.section];
    NSString *key = dict.allKeys.firstObject;
    NSArray *array = [dict objectForKey:key];
    
    node = [array objectAtIndex:indexPath.row];
    
    if ([node hasThumbnail]) {
        [Helper thumbnailForNode:node api:[MEGASdkManager sharedMEGASdk] cell:cell];
    } else {
        [cell.thumbnailImageView mnz_imageForNode:node];
    }
    
    cell.nodeHandle = [node handle];
    
    cell.thumbnailSelectionOverlayView.layer.borderColor = [UIColor mnz_turquoiseForTraitCollection:self.traitCollection].CGColor;
    cell.thumbnailSelectionOverlayView.hidden = [self.selectedItemsDictionary objectForKey:[NSNumber numberWithLongLong:node.handle]] == nil;
    
    cell.thumbnailVideoOverlayView.hidden = !node.name.mnz_isVideoPathExtension;
    cell.thumbnailPlayImageView.hidden = !node.name.mnz_isVideoPathExtension;
    cell.thumbnailVideoDurationLabel.text = (node.name.mnz_isVideoPathExtension && node.duration > -1) ? [NSString mnz_stringFromTimeInterval:node.duration] : @"";

    cell.thumbnailImageView.hidden = self.browsingIndexPath && self.browsingIndexPath == indexPath;
    
    if (@available(iOS 11.0, *)) {
        cell.thumbnailImageView.accessibilityIgnoresInvertColors = YES;
    }
    
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    if (kind == UICollectionElementKindSectionHeader) {
        static NSString *headerIdentifier = @"photoHeaderId";        
        HeaderCollectionReusableView *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:headerIdentifier forIndexPath:indexPath];
        
        if (!headerView) {
            headerView = [[HeaderCollectionReusableView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.frame), 30)];
        }
        
        
        NSDictionary *dict = [self.photosByMonthYearArray objectAtIndex:indexPath.section];
        NSString *month = dict.allKeys.firstObject;
                
        NSString *dateString = [NSString stringWithFormat:@"%@", month];
        [headerView.dateLabel setText:dateString];
        
        return headerView;
    } else {
        static NSString *footerIdentifier = @"photoFooterId";
        UICollectionReusableView *footerView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:footerIdentifier forIndexPath:indexPath];
        
        if (!footerView) {
            footerView = [[UICollectionReusableView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.frame), 20)];
        }
        return  footerView;
    }
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section {
    if (section == self.photosByMonthYearArray.count - 1) {
        return CGSizeMake(0, 0);
    } else {
        return CGSizeMake(collectionView.frame.size.width, 20);
    }
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *dict = [self.photosByMonthYearArray objectAtIndex:indexPath.section];
    NSString *key = dict.allKeys.firstObject;
    NSArray *array = [dict objectForKey:key];
    MEGANode *node = [array objectAtIndex:indexPath.row];
    
    if (![self.photosCollectionView allowsMultipleSelection]) {
        UICollectionViewCell *cell = [self collectionView:collectionView cellForItemAtIndexPath:indexPath];
        CGRect cellFrame = [collectionView convertRect:cell.frame toView:nil];
        
        MEGAPhotoBrowserViewController *photoBrowserVC = [MEGAPhotoBrowserViewController photoBrowserWithMediaNodes:self.mediaNodesArray api:[MEGASdkManager sharedMEGASdk] displayMode:DisplayModeCloudDrive presentingNode:node preferredIndex:0];
        photoBrowserVC.originFrame = cellFrame;
        photoBrowserVC.delegate = self;
        
        [self presentViewController:photoBrowserVC animated:YES completion:nil];
    } else {
        if ([self.selectedItemsDictionary objectForKey:[NSNumber numberWithLongLong:node.handle]]) {
            [self.selectedItemsDictionary removeObjectForKey:[NSNumber numberWithLongLong:node.handle]];
        }
        else {
            [self.selectedItemsDictionary setObject:node forKey:[NSNumber numberWithLongLong:node.handle]];
        }
        
        if ([self.selectedItemsDictionary count]) {
            NSString *message = (self.selectedItemsDictionary.count <= 1 ) ? [NSString stringWithFormat:AMLocalizedString(@"oneItemSelected", nil), self.selectedItemsDictionary.count] : [NSString stringWithFormat:AMLocalizedString(@"itemsSelected", nil), self.selectedItemsDictionary.count];
            
            [self.navigationItem setTitle:message];
            
            [self setToolbarActionsEnabled:YES];
        } else {
            [self.navigationItem setTitle:AMLocalizedString(@"selectTitle", @"Select items")];
            
            [self setToolbarActionsEnabled:NO];
        }
        
        if ([self.selectedItemsDictionary count] == self.nodeList.size.integerValue) {
            allNodesSelected = YES;
        } else {
            allNodesSelected = NO;
        }
        
        [self.photosCollectionView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForRow:indexPath.row inSection:indexPath.section]]];
    }
}

- (void)collectionView:(UICollectionView *)collectionView willDisplaySupplementaryView:(UICollectionReusableView *)view forElementKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath {
    if (@available(iOS 11.0, *)) {
        view.layer.zPosition = 0.0;
    }
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return self.cellSize;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(self.cellInset, self.cellInset, self.cellInset, self.cellInset);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return self.cellInset;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return self.cellInset/2;
}

#pragma mark - View transitions

- (void)showCameraUploadBoardingScreen {
    CustomModalAlertViewController *boardingAlertVC = [[CustomModalAlertViewController alloc] init];
    boardingAlertVC.image = [UIImage imageNamed:@"cameraUploadsBoarding"];
    boardingAlertVC.viewTitle = AMLocalizedString(@"enableCameraUploadsButton", @"Button title that enables the functionality 'Camera Uploads', which uploads all the photos in your device to MEGA");
    boardingAlertVC.detail = AMLocalizedString(@"Automatically backup your photos and videos to the Cloud Drive.", nil);
    boardingAlertVC.firstButtonTitle = AMLocalizedString(@"enable", @"Text button shown when camera upload will be enabled");
    boardingAlertVC.dismissButtonTitle = AMLocalizedString(@"notNow", nil);
    
    boardingAlertVC.firstCompletion = ^{
        [self dismissViewControllerAnimated:YES completion:^{
            [self pushCameraUploadSettings];
        }];
    };
    
    boardingAlertVC.dismissCompletion = ^{
        [self dismissViewControllerAnimated:YES completion:nil];
        CameraUploadManager.cameraUploadEnabled = NO;
    };
    
    [self presentViewController:boardingAlertVC animated:YES completion:nil];
    CameraUploadManager.boardingScreenLastShowedDate = NSDate.date;
}

- (void)pushCameraUploadSettings {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"CameraUploadSettings" bundle:nil];
    CameraUploadsTableViewController *cameraUploadsTableViewController = [storyboard instantiateViewControllerWithIdentifier:@"CameraUploadsSettingsID"];
    [self.navigationController pushViewController:cameraUploadsTableViewController animated:YES];
}

- (void)pushVideoUploadSettings {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"CameraUploadSettings" bundle:nil];
    UIViewController *videoUploadsController = [storyboard instantiateViewControllerWithIdentifier:@"VideoUploadsTableViewControllerID"];
    [self.navigationController pushViewController:videoUploadsController animated:YES];
}

- (void)showLocalDiskIsFullWarningScreen {
    StorageFullModalAlertViewController *warningVC = StorageFullModalAlertViewController.alloc.init;
    [warningVC show];
}

#pragma mark - UILongPressGestureRecognizer

- (void)longPress:(UILongPressGestureRecognizer *)longPressGestureRecognizer {
    if (longPressGestureRecognizer.state == UIGestureRecognizerStateBegan) {
        CGPoint touchPoint = [longPressGestureRecognizer locationInView:self.photosCollectionView];
        NSIndexPath *indexPath = [self.photosCollectionView indexPathForItemAtPoint:touchPoint];
        
        if (!indexPath || ![self.photosCollectionView numberOfSections] || ![self.photosCollectionView numberOfItemsInSection:indexPath.section]) {
            return;
        }
        
        if (self.isEditing) {
            // Only stop editing if long pressed over a cell that is the only one selected or when selected none
            if (self.selectedItemsDictionary.count == 0) {
                [self setEditing:NO animated:YES];
            }
            if (self.selectedItemsDictionary.count == 1) {
                NSDictionary *monthPhotosDictionary = [self.photosByMonthYearArray objectAtIndex:indexPath.section];
                NSString *monthKey = monthPhotosDictionary.allKeys.firstObject;
                NSArray *monthPhotosArray = [monthPhotosDictionary objectForKey:monthKey];
                MEGANode *nodeSelected = [monthPhotosArray objectAtIndex:indexPath.row];
                if ([self.selectedItemsDictionary objectForKey:[NSNumber numberWithLongLong:nodeSelected.handle]]) {
                    [self setEditing:NO animated:YES];
                }
            }
        } else {
            [self setEditing:YES animated:YES];
            [self collectionView:self.photosCollectionView didSelectItemAtIndexPath:indexPath];
        }
    }
}

#pragma mark - UIViewControllerPreviewingDelegate

- (UIViewController *)previewingContext:(id<UIViewControllerPreviewing>)previewingContext viewControllerForLocation:(CGPoint)location {
    if ([self.photosCollectionView allowsMultipleSelection]) {
        return nil;
    }
    
    CGPoint itemPoint = [self.photosCollectionView convertPoint:location fromView:self.view];
    NSIndexPath *indexPath = [self.photosCollectionView indexPathForItemAtPoint:itemPoint];
    if (!indexPath || ![self.photosCollectionView numberOfSections] || ![self.photosCollectionView numberOfItemsInSection:indexPath.section]) {
        return nil;
    }
    
    previewingContext.sourceRect = [self.photosCollectionView convertRect:[self.photosCollectionView cellForItemAtIndexPath:indexPath].frame toView:self.view];
    
    NSDictionary *monthPhotosDictionary = [self.photosByMonthYearArray objectAtIndex:indexPath.section];
    NSString *monthKey = monthPhotosDictionary.allKeys.firstObject;
    NSArray *monthPhotosArray = [monthPhotosDictionary objectForKey:monthKey];
    MEGANode *node = [monthPhotosArray objectAtIndex:indexPath.row];
    if (node.name.mnz_isImagePathExtension || node.name.mnz_isVideoPathExtension) {
        MEGAPhotoBrowserViewController *photoBrowserVC = [MEGAPhotoBrowserViewController photoBrowserWithMediaNodes:self.mediaNodesArray api:[MEGASdkManager sharedMEGASdk] displayMode:DisplayModeCloudDrive presentingNode:node preferredIndex:0];
        
        return photoBrowserVC;
    } else {
        return [node mnz_viewControllerForNodeInFolderLink:NO fileLink:nil];
    }
    
    return nil;
}

- (void)previewingContext:(id<UIViewControllerPreviewing>)previewingContext commitViewController:(UIViewController *)viewControllerToCommit {
    [self.navigationController presentViewController:viewControllerToCommit animated:YES completion:nil];
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
        if (CameraUploadManager.isCameraUploadEnabled) {
            if ([self.photosByMonthYearArray count] == 0) {
                text = AMLocalizedString(@"cameraUploadsEnabled", nil);
            } else {
                return nil;
            }
        } else {
            text = AMLocalizedString(@"enableCameraUploadsButton", @"Enable Camera Uploads");
        }
    } else {
        text = AMLocalizedString(@"noInternetConnection",  @"No Internet Connection");
    }
    
    return text;
}

- (NSString *)descriptionForEmptyState {
    NSString *text = @"";
    if (MEGAReachabilityManager.isReachable && !CameraUploadManager.isCameraUploadEnabled) {
        text = AMLocalizedString(@"Automatically backup your photos and videos to the Cloud Drive.", nil);
    } else if (!MEGAReachabilityManager.isReachable && !MEGAReachabilityManager.sharedManager.isMobileDataEnabled) {
        text = AMLocalizedString(@"Mobile Data is turned off", @"Information shown when the user has disabled the 'Mobile Data' setting for MEGA in the iOS Settings.");
    }
    
    return text;
}

- (UIImage *)imageForEmptyState {
    UIImage *image = nil;
    if ([MEGAReachabilityManager isReachable]) {
        if (CameraUploadManager.isCameraUploadEnabled) {
            if ([self.photosByMonthYearArray count] == 0) {
                image = [UIImage imageNamed:@"cameraEmptyState"];
            }
        } else {
            image = [UIImage imageNamed:@"cameraUploadsBoarding"];
        }
    } else {
        image = [UIImage imageNamed:@"noInternetEmptyState"];
    }
    
    return image;
}

- (NSString *)buttonTitleForEmptyState {
    NSString *text = @"";
    if ([MEGAReachabilityManager isReachable]) {
        if (!CameraUploadManager.isCameraUploadEnabled) {
            text = AMLocalizedString(@"enable", @"Text button shown when the chat is disabled and if tapped the chat will be enabled");
        }
    } else {
        if (!MEGAReachabilityManager.sharedManager.isMobileDataEnabled) {
            text = AMLocalizedString(@"Turn Mobile Data on", @"Button title to go to the iOS Settings to enable 'Mobile Data' for the MEGA app.");
        }
    }
    
    return text;
}

- (void)buttonTouchUpInsideEmptyState {
    if (MEGAReachabilityManager.isReachable) {
        [self pushCameraUploadSettings];
    } else {
        if (!MEGAReachabilityManager.sharedManager.isMobileDataEnabled) {
            [UIApplication.sharedApplication openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString] options:@{} completionHandler:nil];
        }
    }
}

#pragma mark - MEGAPhotoBrowserDelegate

- (void)photoBrowser:(MEGAPhotoBrowserViewController *)photoBrowser didPresentNode:(MEGANode *)node {
    NSIndexPath *indexPath = [self indexPathForNode:node];
    if (indexPath) {
        [self.photosCollectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredVertically animated:NO];
        PhotoCollectionViewCell *cell = [self collectionView:self.photosCollectionView cellForItemAtIndexPath:indexPath];
        CGRect cellFrame = [self.photosCollectionView convertRect:cell.frame toView:nil];
        photoBrowser.originFrame = cellFrame;
    }
    self.browsingIndexPath = indexPath;
    [self.photosCollectionView reloadData];
}

- (void)didDismissPhotoBrowser:(MEGAPhotoBrowserViewController *)photoBrowser {
    self.browsingIndexPath = nil;
    [self.photosCollectionView reloadData];
}

#pragma mark - MEGARequestDelegate

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    if ([error type]) {
        return;
    }
    
    if (request.type == MEGARequestTypeGetAttrFile) {
        for (PhotoCollectionViewCell *pcvc in [self.photosCollectionView visibleCells]) {
            if ([request nodeHandle] == [pcvc nodeHandle]) {
                MEGANode *node = [api nodeForHandle:request.nodeHandle];
                [Helper setThumbnailForNode:node api:api cell:pcvc reindexNode:YES];
            }
        }
    }
}

#pragma mark - MEGAGlobalDelegate

- (void)onNodesUpdate:(MEGASdk *)api nodeList:(MEGANodeList *)nodeList {
    if ([nodeList mnz_shouldProcessOnNodesUpdateForParentNode:self.parentNode childNodesArray:self.nodeList.mnz_nodesArrayFromNodeList]) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(reloadUI) object:nil];
        [self performSelector:@selector(reloadUI) withObject:nil afterDelay:PhotosViewReloadTimeDelay];
    }
}

@end
