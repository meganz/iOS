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
#import "NSArray+MNZCategory.h"

@import StoreKit;
@import Photos;
@import MEGAUIKit;

@interface PhotosViewController () <UICollectionViewDelegateFlowLayout, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, MEGAPhotoBrowserDelegate> {
    BOOL allNodesSelected;
}

@property (nonatomic) CGSize cellSize;
@property (nonatomic) CGFloat cellInset;

@property (weak, nonatomic) IBOutlet UIView *stateView;
@property (weak, nonatomic) IBOutlet UIButton *enableCameraUploadsButton;
@property (weak, nonatomic) IBOutlet UIProgressView *photosUploadedProgressView;
@property (weak, nonatomic) IBOutlet UILabel *photosUploadedLabel;
@property (weak, nonatomic) IBOutlet UILabel *stateLabel;
@property (weak, nonatomic) IBOutlet UIStackView *progressStackView;

@property (weak, nonatomic) IBOutlet UIView *photoContainerView;
@property (weak, nonatomic) IBOutlet UICollectionView *photosCollectionView;

@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *downloadBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *shareLinkBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *moveBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *deleteBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *actionBarButtonItem;

@property (assign, nonatomic) BOOL showToolBar;

@property (nonatomic) MEGACameraUploadsState currentState;

@property (nonatomic) NSIndexPath *browsingIndexPath;
@property (nonatomic) NSLayoutConstraint *stateViewHeightConstraint;
@end

@implementation PhotosViewController

#pragma mark - Lifecycle
- (void)viewDidLoad {
    [super viewDidLoad];
    [self.enableCameraUploadsButton setTitle:NSLocalizedString(@"enable", nil) forState:UIControlStateNormal];
    
    if (@available(iOS 14.0, *)) {
        [self objcWrapper_configPhotosBannerView];
    }
    
    self.currentState = MEGACameraUploadsStateLoading;
    
    [self configureContextMenuManager];
    [self configPhotoContainerView];
    [self updateAppearance];
    [self setupBarButtons];
    [self updateNavigationTitleBar];
}

- (void)setupBarButtons {
    self.editBarButtonItem = [self makeEditBarButton];
    self.cancelBarButtonItem = [self makeCancelBarButton];
    self.filterBarButtonItem = [self makeFilterActiveBarButton];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
        
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(didReceiveInternetConnectionChangedNotification) name:kReachabilityChangedNotification object:nil];
    
    [[MEGASdkManager sharedMEGASdk] addMEGARequestDelegate:self];
    [[MEGASdkManager sharedMEGASdk] addMEGAGlobalDelegate:self];
    
    [self.photoUpdatePublisher setupSubscriptions];
    
    if (!MEGAReachabilityManager.isReachable) {
        self.editBarButtonItem.enabled = NO;
    }
    
    [self.viewModel loadAllPhotos];
    [self refreshMyAvatar];
    
    if (@available(iOS 14.0, *)) {
        [self updateLimitedAccessBannerVisibility];
    }
    
    [self setupNavigationBarButtons];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    CGSize cellSize = [self.photosCollectionView mnz_calculateCellSizeForInset:self.cellInset];
    if (!CGSizeEqualToSize(cellSize, self.cellSize)) {
        self.cellSize = cellSize;
        [self.photosCollectionView reloadData];
    }
    [self setupStateViewHeight];
}

- (void)setupStateViewHeight {
    NSLayoutConstraint *heightConstraint = [self configureStackViewHeightWithView:self.stateView perviousConstraint:self.stateViewHeightConstraint];
    if (heightConstraint != nil) {
        self.stateViewHeightConstraint = heightConstraint;
    }
    [self.view layoutIfNeeded];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[TransfersWidgetViewController sharedTransferViewController].progressView showWidgetIfNeeded];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [NSNotificationCenter.defaultCenter removeObserver:self name:kReachabilityChangedNotification object:nil];
    
    [[MEGASdkManager sharedMEGASdk] removeMEGARequestDelegate:self];
    [[MEGASdkManager sharedMEGASdk] removeMEGAGlobalDelegate:self];
    
    [self.photoUpdatePublisher cancelSubscriptions];
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
    
    if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
        [AppearanceManager forceToolbarUpdate:self.toolbar traitCollection:self.traitCollection];
        [self updateAppearance];
        [self setupBarButtons];
        [self setupNavigationBarButtons];
    }
    
    [self updateBannerViewIfNeededWithPreviousTraitCollection:previousTraitCollection];
    [self setupStateViewHeight];
}

#pragma mark - config views
- (void)configPhotoContainerView {
    [self configPhotoCollectionView];
    
    if (@available(iOS 14.0, *)) {
        self.photosCollectionView.delegate = nil;
        self.photosCollectionView.dataSource = nil;
        
        [self objcWrapper_configPhotoLibraryViewIn:self.photoContainerView];
    }
}

- (void)configPhotoCollectionView {
    self.photosCollectionView.emptyDataSetSource = self;
    self.photosCollectionView.emptyDataSetDelegate = self;
    self.cellInset = 1.0f;
    self.cellSize = [self.photosCollectionView mnz_calculateCellSizeForInset:self.cellInset];
}

- (PhotoLibraryContentViewModel *)photoLibraryContentViewModel {
    if (_photoLibraryContentViewModel == nil) {
        _photoLibraryContentViewModel = [self createPhotoLibraryContentViewModel];
    }
    
    return _photoLibraryContentViewModel;
}

- (PhotoSelectionAdapter *)selection {
    if (_selection == nil) {
        _selection = [[PhotoSelectionAdapter alloc] initWithSdk:MEGASdkManager.sharedMEGASdk];
    }
    
    return _selection;
}

- (WarningViewModel *)warningViewModel {
    if (_warningViewModel == nil) {
        _warningViewModel = [self createWarningViewModel];
    }
    
    return _warningViewModel;
}

#pragma mark - uploads state

- (void)hideRightBarButtonItem:(BOOL)shouldHide {
    if (shouldHide) {
        if (@available(iOS 14.0, *)) {
            [self.objcWrapper_parent.navigationItem setRightBarButtonItem:nil];
            [self.objcWrapper_parent.navigationItem setRightBarButtonItems:nil];
        } else {
            [self.navigationItem setRightBarButtonItem:nil];
            [self.navigationItem setRightBarButtonItems:nil];
        }
    }
}

- (void)reloadHeader {
    MEGALogDebug(@"[Camera Upload] reload photos view header");
    
    if (!MEGAReachabilityManager.isReachable) {
        self.currentState = MEGACameraUploadsStateNoInternetConnection;
        
        return;
    }
    
    if (!CameraUploadManager.isCameraUploadEnabled) {
        if (self.viewModel.mediaNodesArray.count == 0) {
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
    self.photosUploadedProgressView.progress = uploadStats.progress;
    
    NSString *progressText;
    if (uploadStats.pendingFilesCount == 1) {
        if (CameraUploadManager.isCameraUploadPausedBecauseOfNoWiFiConnection) {
            progressText = NSLocalizedString(@"Upload paused because of no WiFi, 1 file pending", nil);
        } else {
            progressText = NSLocalizedString(@"cameraUploadsPendingFile", @"Message shown while uploading files. Singular.");
        }
    } else {
        if (CameraUploadManager.isCameraUploadPausedBecauseOfNoWiFiConnection) {
            progressText = [NSString stringWithFormat:NSLocalizedString(@"Upload paused because of no WiFi, %lu files pending", nil), uploadStats.pendingFilesCount];
        } else {
            progressText = [NSString stringWithFormat:NSLocalizedString(@"cameraUploadsPendingFiles", @"Message shown while uploading files. Plural."), uploadStats.pendingFilesCount];
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
        videoMessage = NSLocalizedString(@"Photos uploaded, video uploads are off, 1 video not uploaded", nil);
    } else {
        videoMessage = [NSString stringWithFormat:NSLocalizedString(@"Photos uploaded, video uploads are off, %lu videos not uploaded", nil), (unsigned long)count];
    }
    
    self.stateLabel.text = videoMessage;
}

- (void)setCurrentState:(MEGACameraUploadsState)currentState {
    if (_currentState == currentState) {
        return;
    }
    
    self.stateView.hidden = NO;
    self.stateLabel.hidden = NO;
    self.stateLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    self.progressStackView.hidden = YES;
    self.enableCameraUploadsButton.hidden = YES;
    
    switch (currentState) {
        case MEGACameraUploadsStateDisabled:
            self.stateLabel.text = NSLocalizedString(@"enableCameraUploadsButton", nil);
            self.enableCameraUploadsButton.hidden = NO;
            break;
        case MEGACameraUploadsStateUploading:
            self.stateLabel.hidden = YES;
            self.progressStackView.hidden = NO;
            break;
        case MEGACameraUploadsStateCompleted:
            self.stateLabel.text = NSLocalizedString(@"cameraUploadsComplete", @"Message shown when the camera uploads have been completed");
            break;
        case MEGACameraUploadsStateNoInternetConnection:
            if (self.viewModel.mediaNodesArray.count == 0) {
                self.stateView.hidden = YES;
            } else {
                self.stateLabel.text = NSLocalizedString(@"noInternetConnection", @"Text shown on the app when you don't have connection to the internet or when you have lost it");
            }
            break;
        case MEGACameraUploadsStateEmpty:
            self.stateView.hidden = YES;
            break;
        case MEGACameraUploadsStateLoading:
            self.stateLabel.text = NSLocalizedString(@"loading", nil);
            break;
        case MEGACameraUploadsStateEnableVideo:
            self.stateLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
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

- (void)reloadPhotos {
    [self updateNavigationTitleBar];
    [self reloadHeader];
    [self setupNavigationBarButtons];
    if (@available(iOS 14.0, *)) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self objcWrapper_updatePhotoLibraryBy: self.viewModel.mediaNodesArray];
            
            if (self.viewModel.mediaNodesArray.count == 0) {
                [self reloadPhotosCollectionView];
            }
            [self setupNavigationBarButtons];
        });
    } else {
        NSMutableDictionary *photosByMonthYearDictionary = [NSMutableDictionary new];
        self.photosByMonthYearArray = [NSMutableArray new];
        NSMutableArray *photosArray = [NSMutableArray new];
        
        for (MEGANode *node in self.viewModel.mediaNodesArray) {
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
        }
        
        [self reloadPhotosCollectionView];
        [self setupNavigationBarButtons];
    }
}

- (void)reloadPhotosCollectionView {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.photosCollectionView reloadData];
    });
}

- (void)updateNavigationTitleBar {
    if ([self.photosCollectionView allowsMultipleSelection]) {
        self.objcWrapper_parent.navigationItem.title = NSLocalizedString(@"selectTitle", @"Select items");
    } else {
        self.objcWrapper_parent.navigationItem.title = NSLocalizedString(@"photo.navigation.title", @"Title of one of the Settings sections where you can set up the 'Camera Uploads' options");
    }
}

- (void)setToolbarActionsEnabled:(BOOL)boolValue {
    self.downloadBarButtonItem.enabled = boolValue;
    self.shareLinkBarButtonItem.enabled = boolValue;
    self.moveBarButtonItem.enabled = boolValue;
    self.actionBarButtonItem.enabled = boolValue;
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

- (MEGANode *)nodeFromIndexPath:(NSIndexPath * _Nonnull)indexPath {
    NSDictionary *dict = [self.photosByMonthYearArray objectOrNilAtIndex:indexPath.section];
    if (dict == nil) {return nil;}
    NSString *key = dict.allKeys.firstObject;
    NSArray *array = [dict objectForKey:key];
    return [array objectOrNilAtIndex:indexPath.row];
}

- (BOOL)shouldSelectIndexPath:(NSIndexPath * _Nonnull)indexPath {
    MEGANode *node = [self nodeFromIndexPath:indexPath];
    return self.selection[node.handle] != nil;
}

#pragma mark - notifications

- (void)didReceiveInternetConnectionChangedNotification {
    if (!MEGAReachabilityManager.isReachable) {
        self.editBarButtonItem.enabled = NO;
    }
    
    [self reloadHeader];
    [self.photosCollectionView reloadEmptyDataSet];
}

#pragma mark - IBAction

- (IBAction)enableCameraUploadsTouchUpInside:(UIButton *)sender {
    if (self.photosCollectionView.allowsMultipleSelection) {
        [self setEditing:NO animated:NO];
    }
    
    if (self.currentState == MEGACameraUploadsStateEnableVideo && !CameraUploadManager.isVideoUploadEnabled) {
        [self pushVideoUploadSettings];
    } else {
        [self pushCameraUploadSettings];
    }
}

- (IBAction)selectAllAction:(UIBarButtonItem *)sender {
    [self.selection removeAll];
    
    if (!allNodesSelected) {
        [self.selection setSelectedNodes:self.viewModel.mediaNodesArray];
        allNodesSelected = YES;
    } else {
        allNodesSelected = NO;
    }
    
    [self didSelectedPhotoCountChange:self.selection.count];
    
    if (self.selection.isEmpty) {
        [self setToolbarActionsEnabled:NO];
    } else {
        [self setToolbarActionsEnabled:YES];
    }
    
    if (@available(iOS 14.0, *)) {
        [self objcWrapper_configPhotoLibrarySelectAll];
    }
    
    [self.photosCollectionView reloadData];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    
    if (@available(iOS 14.0, *)) {
        [self objcWrapper_enablePhotoLibraryEditMode:editing];
    } else {
        self.photosCollectionView.allowsMultipleSelection = editing;
    }
    
    if (editing) {
        [self objcWrapper_updateNavigationTitleWithSelectedPhotoCount:self.selection.count];
        [self.photosCollectionView setAllowsMultipleSelection:YES];
        
        UITabBar *tabBar = self.tabBarController.tabBar;
        if (tabBar == nil) {
            return;
        }
        
        if (![self.tabBarController.view.subviews containsObject:self.toolbar]) {
            [self.toolbar setAlpha:0.0];
            [self.tabBarController.view addSubview:self.toolbar];
            self.toolbar.translatesAutoresizingMaskIntoConstraints = NO;
            [self.toolbar setBackgroundColor:[UIColor mnz_mainBarsForTraitCollection:self.traitCollection]];
            
            NSLayoutAnchor *bottomAnchor = self.tabBarController.tabBar.safeAreaLayoutGuide.bottomAnchor;
            
            [NSLayoutConstraint activateConstraints:@[[self.toolbar.topAnchor constraintEqualToAnchor:self.tabBarController.tabBar.topAnchor constant:0],
                                                      [self.toolbar.leadingAnchor constraintEqualToAnchor:self.tabBarController.tabBar.leadingAnchor constant:0],
                                                      [self.toolbar.trailingAnchor constraintEqualToAnchor:self.tabBarController.tabBar.trailingAnchor constant:0],
                                                      [self.toolbar.bottomAnchor constraintEqualToAnchor:bottomAnchor constant:0]]];
            
            [UIView animateWithDuration:0.33f animations:^ {
                [self.toolbar setAlpha:1.0];
            }];
        }
    } else {
        allNodesSelected = NO;
        self.objcWrapper_parent.navigationItem.title = NSLocalizedString(@"photo.navigation.title", @"Title of one of the Settings sections where you can set up the 'Camera Uploads' options");
        [self.photosCollectionView setAllowsMultipleSelection:NO];
        [self.selection removeAll];
        [self.photosCollectionView reloadData];
        [UIView animateWithDuration:0.33f animations:^ {
            [self.toolbar setAlpha:0.0];
        } completion:^(BOOL finished) {
            if (finished) {
                [self.toolbar removeFromSuperview];
            }
        }];
    }
    
    if (self.selection.isEmpty) {
        [self setToolbarActionsEnabled:NO];
    }
}

- (void)showToolbar:(BOOL)showToolbar {
    self.showToolBar = showToolbar;
}

- (void)didSelectedPhotoCountChange:(NSInteger)count {
    [self objcWrapper_updateNavigationTitleWithSelectedPhotoCount:count];
    [self setToolbarActionsEnabled:count > 0];
}

- (IBAction)downloadAction:(UIBarButtonItem *)sender {
    [self handleDownloadActionFor:self.selection.nodes];
}

- (IBAction)shareLinkAction:(UIBarButtonItem *)sender {
    [self handleShareLinkFor:self.selection.nodes];
}

- (IBAction)moveAction:(UIBarButtonItem *)sender {
    [self showBrowserNavigationFor:self.selection.nodes action:BrowserActionMove];
}

- (IBAction)deleteAction:(UIBarButtonItem *)sender {
    [self handleDeleteActionFor:self.selection.nodes];
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
    NSDictionary *dict = [self.photosByMonthYearArray objectOrNilAtIndex:section];
    if (dict == nil) {return 0;}
    NSString *key = dict.allKeys.firstObject;
    NSArray *array = [dict objectForKey:key];
    
    return [array count];
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    
    if (self.photosCollectionView.allowsSelection) {
        BOOL shouldSelectActualCell = [self shouldSelectIndexPath:indexPath];
        
        if (shouldSelectActualCell) {
            [self.photosCollectionView selectItemAtIndexPath:indexPath animated:NO scrollPosition:UICollectionViewScrollPositionNone];
        }
        
        [cell setSelected:shouldSelectActualCell];
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"photoCellId";
    
    PhotoCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    
    MEGANode *node = [self nodeFromIndexPath:indexPath];
    
    if ([node hasThumbnail]) {
        [Helper thumbnailForNode:node api:[MEGASdkManager sharedMEGASdk] cell:cell];
    } else {
        [cell.thumbnailImageView setImage:[NodeAssetsManager.shared iconFor:node]];
    }
    
    cell.nodeHandle = [node handle];
    
    cell.thumbnailSelectionOverlayView.layer.borderColor = [UIColor mnz_turquoiseForTraitCollection:self.traitCollection].CGColor;
    
    cell.thumbnailVideoOverlayView.hidden = !node.name.mnz_isVideoPathExtension;
    cell.thumbnailPlayImageView.hidden = !node.name.mnz_isVideoPathExtension;
    cell.thumbnailVideoDurationLabel.text = (node.name.mnz_isVideoPathExtension && node.duration > -1) ? [NSString mnz_stringFromTimeInterval:node.duration] : @"";
    
    cell.thumbnailImageView.hidden = self.browsingIndexPath && self.browsingIndexPath == indexPath;
    
    cell.thumbnailImageView.accessibilityIgnoresInvertColors = YES;
    
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    if (kind == UICollectionElementKindSectionHeader) {
        static NSString *headerIdentifier = @"photoHeaderId";
        HeaderCollectionReusableView *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:headerIdentifier forIndexPath:indexPath];
        
        if (!headerView) {
            headerView = [[HeaderCollectionReusableView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.frame), 30)];
        }
        
        
        NSDictionary *dict = [self.photosByMonthYearArray objectOrNilAtIndex:indexPath.section];
        if (dict != nil) {
            NSString *month = dict.allKeys.firstObject;
            
            NSString *dateString = [NSString stringWithFormat:@"%@", month];
            [headerView.dateLabel setText:dateString];
        }
        
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
    MEGANode *node = [self nodeFromIndexPath:indexPath];
    if (node == nil) {
        return;
    }
    
    PhotoCollectionViewCell *cell = (PhotoCollectionViewCell *)[self.photosCollectionView cellForItemAtIndexPath:indexPath];
    
    if (![self.photosCollectionView allowsMultipleSelection]) {
        CGRect cellFrame = [collectionView convertRect:cell.frame toView:nil];
        
        MEGAPhotoBrowserViewController *photoBrowserVC = [MEGAPhotoBrowserViewController photoBrowserWithMediaNodes:[self.viewModel.mediaNodesArray mutableCopy] api:[MEGASdkManager sharedMEGASdk] displayMode:DisplayModeCloudDrive presentingNode:node];
        photoBrowserVC.originFrame = cellFrame;
        photoBrowserVC.delegate = self;
        
        [self presentViewController:photoBrowserVC animated:YES completion:nil];
        
        [collectionView clearSelectedItemsWithAnimated:NO];
    } else {
        self.selection[node.handle] = node;
        [self objcWrapper_updateNavigationTitleWithSelectedPhotoCount:self.selection.count];
        [self setToolbarActionsEnabled:YES];
        
        if (self.selection.count == self.viewModel.mediaNodesArray.count) {
            allNodesSelected = YES;
        } else {
            allNodesSelected = NO;
        }
    }
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    MEGANode * node = [self nodeFromIndexPath:indexPath];
    
    if ([self.photosCollectionView allowsMultipleSelection]) {
        [self.selection removeNodeBy:node.handle];
        [self didSelectedPhotoCountChange:self.selection.count];
    }
}

- (void)collectionView:(UICollectionView *)collectionView willDisplaySupplementaryView:(UICollectionReusableView *)view forElementKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath {
    view.layer.zPosition = 0.0;
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldBeginMultipleSelectionInteractionAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)collectionView:(UICollectionView *)collectionView didBeginMultipleSelectionInteractionAtIndexPath:(NSIndexPath *)indexPath {
    [self setEditing:YES animated:YES];
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
    boardingAlertVC.viewTitle = NSLocalizedString(@"enableCameraUploadsButton", @"Button title that enables the functionality 'Camera Uploads', which uploads all the photos in your device to MEGA");
    boardingAlertVC.detail = NSLocalizedString(@"Automatically backup your photos and videos to the Cloud Drive.", nil);
    boardingAlertVC.firstButtonTitle = NSLocalizedString(@"enable", @"Text button shown when camera upload will be enabled");
    boardingAlertVC.dismissButtonTitle = NSLocalizedString(@"notNow", nil);
    
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

#pragma mark - DZNEmptyDataSetSource

- (nullable UIView *)customViewForEmptyDataSet:(UIScrollView *)scrollView {
    EmptyStateView *emptyStateView = [self emptyStateViewWithImage:[self imageForEmptyState]
                                                             title:[self titleForEmptyState]
                                                       description:[self descriptionForEmptyState]
                                                       buttonTitle:[self buttonTitleForEmptyState]];
    
    return emptyStateView;
}

#pragma mark - Empty State

- (NSString *)titleForEmptyState {
    NSString *text;
    if ([MEGAReachabilityManager isReachable]) {
        if (CameraUploadManager.isCameraUploadEnabled) {
            if ([self.photosByMonthYearArray count] == 0) {
                text = NSLocalizedString(@"cameraUploadsEnabled", nil);
            } else {
                return nil;
            }
        } else {
            text = NSLocalizedString(@"enableCameraUploadsButton", @"Enable Camera Uploads");
        }
    } else {
        text = NSLocalizedString(@"noInternetConnection",  @"No Internet Connection");
    }
    
    return text;
}

- (NSString *)descriptionForEmptyState {
    NSString *text = @"";
    if (MEGAReachabilityManager.isReachable && !CameraUploadManager.isCameraUploadEnabled) {
        text = NSLocalizedString(@"Automatically backup your photos and videos to the Cloud Drive.", nil);
    } else if (!MEGAReachabilityManager.isReachable && !MEGAReachabilityManager.sharedManager.isMobileDataEnabled) {
        text = NSLocalizedString(@"Mobile Data is turned off", @"Information shown when the user has disabled the 'Mobile Data' setting for MEGA in the iOS Settings.");
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
            text = NSLocalizedString(@"enable", @"Text button shown when the chat is disabled and if tapped the chat will be enabled");
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
                [Helper setThumbnailForNode:node api:api cell:pcvc];
            }
        }
    }
}

#pragma mark - MEGAGlobalDelegate

- (void)onNodesUpdate:(MEGASdk *)api nodeList:(MEGANodeList *)nodeList {
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^{
        [self.viewModel onCameraAndMediaNodesUpdateWithNodeList:nodeList];
    });
}

@end
