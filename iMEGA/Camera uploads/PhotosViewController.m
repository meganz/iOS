#import "PhotosViewController.h"

#import "SVProgressHUD.h"
#import "UIScrollView+EmptyDataSet.h"

#import "Helper.h"
#import "MEGAAVViewController.h"
#import "MEGAMoveRequestDelegate.h"
#import "MEGANavigationController.h"
#import "MEGANode+MNZCategory.h"
#import "MEGANodeList+MNZCategory.h"
#import "MEGAReachabilityManager.h"
#import "MEGAStore.h"
#import "NSString+MNZCategory.h"

#import "PhotoCollectionViewCell.h"
#import "HeaderCollectionReusableView.h"
#import "CameraUploads.h"
#import "CameraUploadsTableViewController.h"
#import "BrowserViewController.h"

@interface PhotosViewController () <UICollectionViewDelegateFlowLayout, UIViewControllerPreviewingDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate> {
    BOOL allNodesSelected;

    NSUInteger remainingOperations;
}

@property (nonatomic) id<UIViewControllerPreviewing> previewingContext;

@property (nonatomic, strong) MEGANode *parentNode;
@property (nonatomic, strong) MEGANodeList *nodeList;
@property (nonatomic, strong) NSMutableArray *photosByMonthYearArray;
@property (nonatomic, strong) NSMutableArray *previewsArray;

@property (nonatomic) CGSize sizeForItem;
@property (nonatomic) CGFloat portraitThumbnailSize;
@property (nonatomic) CGFloat landscapeThumbnailSize;

@property (nonatomic, strong) NSMutableDictionary *selectedItemsDictionary;

@property (weak, nonatomic) IBOutlet UIView *stateView;
@property (weak, nonatomic) IBOutlet UIButton *toggleCameraUploadsButton;
@property (weak, nonatomic) IBOutlet UIProgressView *photosUploadedProgressView;
@property (weak, nonatomic) IBOutlet UILabel *photosUploadedLabel;
@property (weak, nonatomic) IBOutlet UILabel *stateLabel;

@property (weak, nonatomic) IBOutlet UICollectionView *photosCollectionView;

@property (strong, nonatomic) IBOutlet UIToolbar *toolbar;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *downloadBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *shareBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *moveBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *carbonCopyBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *deleteBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *selectAllBarButtonItem;

@property (nonatomic) MEGACameraUploadsState currentState;
@property (nonatomic) NSUInteger totalPhotosUploading;
@property (nonatomic) NSUInteger currentPhotosUploaded;

@end

@implementation PhotosViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.photosCollectionView.emptyDataSetSource = self;
    self.photosCollectionView.emptyDataSetDelegate = self;
    
    self.selectedItemsDictionary = [[NSMutableDictionary alloc] init];
    
    UIBarButtonItem *negativeSpaceBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    if ([[UIDevice currentDevice] iPadDevice] || [[UIDevice currentDevice] iPhone6XPlus]) {
        [negativeSpaceBarButtonItem setWidth:-8.0];
    } else {
        [negativeSpaceBarButtonItem setWidth:-4.0];
    }
    [self.navigationItem setRightBarButtonItems:@[negativeSpaceBarButtonItem, self.editButtonItem]];
    [self.editButtonItem setImage:[UIImage imageNamed:@"edit"]];
    
    [self calculateSizeForItem];
    
    // Long press to select:
    [self.view addGestureRecognizer:[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)]];
    
    [self.toolbar setFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.frame), 49)];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(internetConnectionChanged) name:kReachabilityChangedNotification object:nil];
    
    [self setEditing:NO animated:NO];
    
    [[MEGASdkManager sharedMEGASdk] retryPendingConnections];
    [[MEGASdkManager sharedMEGASdk] addMEGARequestDelegate:self];
    [[MEGASdkManager sharedMEGASdk] addMEGATransferDelegate:self];
    [[MEGASdkManager sharedMEGASdk] addMEGAGlobalDelegate:self];
    
    [self setNavigationBarButtonItemsEnabled:[MEGAReachabilityManager isReachable]];
    
    [self reloadUI];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
    
    [[MEGASdkManager sharedMEGASdk] removeMEGARequestDelegate:self];
    [[MEGASdkManager sharedMEGASdk] removeMEGATransferDelegate:self];
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
            [self calculateSizeForItem];
            [self.photosCollectionView reloadData];
        }
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

- (void)setCurrentState:(MEGACameraUploadsState)currentState {
    switch (currentState) {
        case MEGACameraUploadsStateDisabled:
            self.stateView.hidden = NO;
            self.photosUploadedProgressView.hidden = YES;
            self.photosUploadedLabel.hidden = YES;
            self.stateLabel.hidden = NO;
            self.stateLabel.text = AMLocalizedString(@"enableCameraUploadsButton", nil);
            [self.toggleCameraUploadsButton setTitle:AMLocalizedString(@"enable", nil) forState:UIControlStateNormal];
            self.toggleCameraUploadsButton.hidden = NO;
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            break;
            
        case MEGACameraUploadsStateUploading:
            self.stateView.hidden = NO;
            self.photosUploadedProgressView.hidden = NO;
            self.photosUploadedLabel.hidden = NO;
            self.stateLabel.hidden = YES;
            [self.toggleCameraUploadsButton setTitle:AMLocalizedString(@"disable", @"Text button shown when an option is enabled, to allow to disable it. String as sort as possible.") forState:UIControlStateNormal];
            self.toggleCameraUploadsButton.hidden = NO;
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
            break;
            
        case MEGACameraUploadsStateCompleted:
            self.stateView.hidden = NO;
            self.photosUploadedProgressView.hidden = YES;
            self.photosUploadedLabel.hidden = YES;
            self.stateLabel.hidden = NO;
            self.stateLabel.text = AMLocalizedString(@"cameraUploadsComplete", @"Message shown when the camera uploads have been completed");
            [self.toggleCameraUploadsButton setTitle:AMLocalizedString(@"disable", @"Text button shown when an option is enabled, to allow to disable it. String as sort as possible.") forState:UIControlStateNormal];
            self.toggleCameraUploadsButton.hidden = NO;
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            break;
            
        case MEGACameraUploadsStateDisconnected:
            self.stateView.hidden = NO;
            self.photosUploadedProgressView.hidden = YES;
            self.photosUploadedLabel.hidden = YES;
            self.stateLabel.hidden = NO;
            self.stateLabel.text = AMLocalizedString(@"noInternetConnection", @"Text shown on the app when you don't have connection to the internet or when you have lost it");
            self.toggleCameraUploadsButton.hidden = YES;
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            break;
            
        case MEGACameraUploadsStateEmpty:
            self.stateView.hidden = YES;
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            break;
    }
    
    _currentState = currentState;
}

#pragma mark - Private

- (void)reloadUI {
    NSMutableDictionary *photosByMonthYearDictionary = [NSMutableDictionary new];
    
    self.photosByMonthYearArray = [NSMutableArray new];
    NSMutableArray *photosArray = [NSMutableArray new];
    
    self.parentNode = [[MEGASdkManager sharedMEGASdk] childNodeForParent:[[MEGASdkManager sharedMEGASdk] rootNode] name:@"Camera Uploads"];
    
    self.nodeList = [[MEGASdkManager sharedMEGASdk] childrenForParent:self.parentNode order:MEGASortOrderTypeModificationDesc];
    
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    df.dateStyle = NSDateFormatterLongStyle;
    df.timeStyle = NSDateFormatterNoStyle;
    df.locale = [NSLocale currentLocale];
    df.dateFormat = @"LLLL yyyy";
    
    self.previewsArray = [[NSMutableArray alloc] init];
    
    for (NSInteger i = 0; i < [self.nodeList.size integerValue]; i++) {
        MEGANode *node = [self.nodeList nodeAtIndex:i];
        
        if (node.name.mnz_isImagePathExtension) {
            MWPhoto *preview = [[MWPhoto alloc] initWithNode:node];
            [self.previewsArray addObject:preview];
        }
        
        if (!node.name.mnz_isImagePathExtension && !node.name.mnz_isVideoPathExtension) {
            continue;
        }
        
        NSString *currentMonthYearString = [df stringFromDate:[node modificationTime]];
        
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
    
    [self.photosCollectionView reloadData];
    
    if ([[CameraUploads syncManager] isCameraUploadsEnabled]) {
        if (self.currentState != MEGACameraUploadsStateUploading) {
            self.currentState = MEGACameraUploadsStateCompleted;
        }
    } else {
        if ([self.photosByMonthYearArray count] == 0) {
            self.currentState = MEGACameraUploadsStateEmpty;
        } else {
            self.currentState = MEGACameraUploadsStateDisabled;
        }
    }
    
    if ([self.photosCollectionView allowsMultipleSelection]) {
        self.navigationItem.title = AMLocalizedString(@"selectTitle", @"Select items");
    } else {
        self.navigationItem.title = AMLocalizedString(@"cameraUploadsLabel", @"Title of one of the Settings sections where you can set up the 'Camera Uploads' options");
    }
}

- (void)internetConnectionChanged {
    [self setNavigationBarButtonItemsEnabled:[MEGAReachabilityManager isReachable]];
    
    if ([[CameraUploads syncManager] isCameraUploadsEnabled]) {
        if (![MEGAReachabilityManager isReachable]) {
            self.currentState = MEGACameraUploadsStateDisconnected;
        }
    }
}

- (void)setNavigationBarButtonItemsEnabled:(BOOL)boolValue {
    [self.editButtonItem setEnabled:boolValue];
}

- (void)pushCameraUploadSettings {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Settings" bundle:nil];
    CameraUploadsTableViewController *cameraUploadsTableViewController = [storyboard instantiateViewControllerWithIdentifier:@"CameraUploadsSettingsID"];
    [self.navigationController pushViewController:cameraUploadsTableViewController animated:YES];
}

- (void)setToolbarActionsEnabled:(BOOL)boolValue {
    self.downloadBarButtonItem.enabled = boolValue;
    self.shareBarButtonItem.enabled = ((self.selectedItemsDictionary.count < 100) ? boolValue : NO);
    self.moveBarButtonItem.enabled = boolValue;
    self.carbonCopyBarButtonItem.enabled = boolValue;
    self.deleteBarButtonItem.enabled = boolValue;
}

- (void)calculateSizeForItem {
    UIInterfaceOrientation interfaceOrientation = [UIApplication sharedApplication].statusBarOrientation;
    if (UIInterfaceOrientationIsPortrait(interfaceOrientation)) {
        if (self.portraitThumbnailSize) {
            self.sizeForItem = CGSizeMake(self.portraitThumbnailSize, self.portraitThumbnailSize);
        } else {
            [self calculateMinimumThumbnailSizeForInterfaceOrientation:interfaceOrientation];
        }
    } else {
        if (UIInterfaceOrientationIsLandscape(interfaceOrientation)) {
            if (self.landscapeThumbnailSize) {
                self.sizeForItem = CGSizeMake(self.landscapeThumbnailSize, self.landscapeThumbnailSize);
            } else {
                [self calculateMinimumThumbnailSizeForInterfaceOrientation:interfaceOrientation];
            }
        }
    }
}

- (void)calculateMinimumThumbnailSizeForInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    CGFloat screenWidth = CGRectGetWidth([UIScreen mainScreen].bounds);
    CGFloat minimumThumbnailSize = [[UIDevice currentDevice] iPadDevice] ? 100.0f : 93.0f;
    NSUInteger minimumNumberOfItemsPerRow = (screenWidth / minimumThumbnailSize);
    CGFloat sizeNeededToFitMinimums = (((minimumThumbnailSize + 1) * minimumNumberOfItemsPerRow) - 1);
    CGFloat incrementForThumbnailSize = 0.1f;
    while (screenWidth > sizeNeededToFitMinimums) {
        minimumThumbnailSize += incrementForThumbnailSize;
        NSUInteger minimumItemsPerRowWithCurrentMinimum = (screenWidth / minimumThumbnailSize);
        if (minimumItemsPerRowWithCurrentMinimum < minimumNumberOfItemsPerRow) {
            minimumThumbnailSize -= incrementForThumbnailSize;
            break;
        }
        sizeNeededToFitMinimums = (((minimumThumbnailSize + 1) * minimumNumberOfItemsPerRow) - 1);
        if (sizeNeededToFitMinimums >= screenWidth) {
            minimumThumbnailSize -= incrementForThumbnailSize;
            break;
        }
    }
    
    if (UIInterfaceOrientationIsPortrait(interfaceOrientation)) {
        self.portraitThumbnailSize = minimumThumbnailSize;
    } else {
        if (UIInterfaceOrientationIsLandscape(interfaceOrientation)) {
            self.landscapeThumbnailSize = minimumThumbnailSize;
        }
    }
    
    self.sizeForItem = CGSizeMake(minimumThumbnailSize, minimumThumbnailSize);
}

- (void)updateProgressData {
    if ([CameraUploads syncManager].assetsOperationQueue.operationCount > 0) {
        self.totalPhotosUploading = [CameraUploads syncManager].assetsOperationQueue.operationCount + self.currentPhotosUploaded;
        [self updateProgressUI];
        self.currentState = MEGACameraUploadsStateUploading;
    }
}

- (void)updateProgressUI {
    self.photosUploadedProgressView.progress = (float)((float)self.currentPhotosUploaded/(float)self.totalPhotosUploading);

    NSString *progressText;
    if (self.totalPhotosUploading == 1) {
        progressText = AMLocalizedString(@"cameraUploadsUploadingFile", @"Singular, please do not change the placeholders as they will be replaced by numbers. e.g. 1 of 1 file.");
    } else {
        progressText = AMLocalizedString(@"cameraUploadsUploadingFiles", @"Plural, please do not change the placeholders as they will be replaced by numbers. e.g. 1 of 3 files.");
    }
    progressText = [progressText stringByReplacingOccurrencesOfString:@"%1$d" withString:[NSString stringWithFormat:@"%lu", (unsigned long)self.currentPhotosUploaded]];
    progressText = [progressText stringByReplacingOccurrencesOfString:@"%2$d" withString:[NSString stringWithFormat:@"%lu", (unsigned long)self.totalPhotosUploading]];
    
    self.photosUploadedLabel.text = progressText;
}

#pragma mark - IBAction

- (IBAction)enableCameraUploadsTouchUpInside:(UIButton *)sender {
    [self pushCameraUploadSettings];
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

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    
    [self.editButtonItem setTitle:@""];
    
    if (editing) {
        [self.editButtonItem setImage:[UIImage imageNamed:@"done"]];
        [self.navigationItem setTitle:AMLocalizedString(@"selectTitle", @"Select items")];
        [self.photosCollectionView setAllowsMultipleSelection:YES];
        self.navigationItem.leftBarButtonItems = @[self.selectAllBarButtonItem];
        
        [self.toolbar setAlpha:0.0];
        [self.tabBarController.tabBar addSubview:self.toolbar];
        [UIView animateWithDuration:0.33f animations:^ {
            [self.toolbar setAlpha:1.0];
        }];
    } else {
        [self.editButtonItem setImage:[UIImage imageNamed:@"edit"]];
        allNodesSelected = NO;
        [self.navigationItem setTitle:@"Camera Uploads"];
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
        [Helper downloadNode:n folderPath:[Helper relativePathForOffline] isFolderLink:NO];
    }
    [self setEditing:NO animated:YES];
}

- (IBAction)shareAction:(UIBarButtonItem *)sender {
    UIActivityViewController *activityVC = [Helper activityViewControllerForNodes:self.selectedItemsDictionary.allValues button:self.shareBarButtonItem];
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
    NSString *message = (self.selectedItemsDictionary.count > 1) ? [NSString stringWithFormat:AMLocalizedString(@"moveFilesToRubbishBinMessage", @"Alert message to confirm if the user wants to move to the Rubbish Bin '{1+} files'"), self.selectedItemsDictionary.count] : [NSString stringWithString:AMLocalizedString(@"moveFileToRubbishBinMessage", @"Alert message to confirm if the user wants to move to the Rubbish Bin '1 file'")];
    UIAlertController *moveToTheRubbishBinAlertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"moveToTheRubbishBin", @"Title for the action that allows you to 'Move to the Rubbish Bin' files or folders") message:message preferredStyle:UIAlertControllerStyleAlert];
    
    [moveToTheRubbishBinAlertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"cancel", nil) style:UIAlertActionStyleCancel handler:nil]];
    
    [moveToTheRubbishBinAlertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"ok", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        remainingOperations = self.selectedItemsDictionary.count;
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
    }]];
    
    [self presentViewController:moveToTheRubbishBinAlertController animated:YES completion:nil];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    if ([self.photosByMonthYearArray count] == 0) {
        [self setNavigationBarButtonItemsEnabled:NO];
    } else {
        [self setNavigationBarButtonItemsEnabled:[MEGAReachabilityManager isReachable]];
    }
    
    return [self.photosByMonthYearArray count];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    NSDictionary *dict = [self.photosByMonthYearArray objectAtIndex:section];
    NSString *key = [[dict allKeys] objectAtIndex:0];
    NSArray *array = [dict objectForKey:key];
    
    return [array count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"photoCellId";
    
    PhotoCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    
    MEGANode *node = nil;
    
    NSDictionary *dict = [self.photosByMonthYearArray objectAtIndex:indexPath.section];
    NSString *key = [[dict allKeys] objectAtIndex:0];
    NSArray *array = [dict objectForKey:key];
    
    node = [array objectAtIndex:indexPath.row];
    
    if ([node hasThumbnail]) {
        [Helper thumbnailForNode:node api:[MEGASdkManager sharedMEGASdk] cell:cell];
    } else {
        [cell.thumbnailImageView setImage:[Helper imageForNode:node]];
    }
    
    cell.nodeHandle = [node handle];
    
    cell.thumbnailSelectionOverlayView.layer.borderColor = [[UIColor mnz_redFF333A] CGColor];
    cell.thumbnailSelectionOverlayView.layer.borderWidth = 2.0;
    cell.thumbnailSelectionOverlayView.hidden = [self.selectedItemsDictionary objectForKey:[NSNumber numberWithLongLong:node.handle]] == nil;

    if (node.name.mnz_videoPathExtension) {
        cell.thumbnailVideoDurationLabel.text = [NSString mnz_stringFromTimeInterval:node.duration];
    }
    
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
        NSString *month = [[dict allKeys] objectAtIndex:0];
                
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
    NSInteger index = 0;
    for (NSInteger i = 0; i < indexPath.section; i++) {
        NSDictionary *dict = [self.photosByMonthYearArray objectAtIndex:i];
        NSString *key = [[dict allKeys] objectAtIndex:0];
        NSArray *array = [dict objectForKey:key];
        index += array.count;
    }
    
    NSInteger videosCount = 0;
    NSInteger count = index + indexPath.row;
    for (NSInteger i = 0; i < count; i++) {
        MEGANode *n = [self.nodeList nodeAtIndex:i];
        if (n.isFile && n.name.mnz_videoPathExtension) {
            videosCount++;
        }
        
        if (!n.name.mnz_isImagePathExtension && !n.name.mnz_isVideoPathExtension) {
            count++;
        }
    }
    
    index += indexPath.row - videosCount;
    
    NSDictionary *dict = [self.photosByMonthYearArray objectAtIndex:indexPath.section];
    NSString *key = [dict.allKeys objectAtIndex:0];
    NSArray *array = [dict objectForKey:key];
    MEGANode *node = [array objectAtIndex:indexPath.row];
    
    if (![self.photosCollectionView allowsMultipleSelection]) {
        if (node.name.mnz_isImagePathExtension) {
            MWPhotoBrowser *photoBrowser = [[MWPhotoBrowser alloc] initWithPhotos:self.previewsArray];            
            photoBrowser.displayActionButton = YES;
            photoBrowser.displayNavArrows = YES;
            photoBrowser.displaySelectionButtons = NO;
            photoBrowser.zoomPhotosToFill = YES;
            photoBrowser.alwaysShowControls = NO;
            photoBrowser.enableGrid = YES;
            photoBrowser.startOnGrid = NO;
            
            [self.navigationController pushViewController:photoBrowser animated:YES];
            
            [photoBrowser showNextPhotoAnimated:YES];
            [photoBrowser showPreviousPhotoAnimated:YES];
            [photoBrowser setCurrentPhotoIndex:index];
        } else {
            MOOfflineNode *offlineNodeExist = [[MEGAStore shareInstance] offlineNodeWithNode:node api:[MEGASdkManager sharedMEGASdk]];
            
            if (offlineNodeExist) {
                NSURL *path = [NSURL fileURLWithPath:[[Helper pathForOffline] stringByAppendingString:offlineNodeExist.localPath]];
                MEGAAVViewController *megaAVViewController = [[MEGAAVViewController alloc] initWithURL:path];
                [self presentViewController:megaAVViewController animated:YES completion:nil];
                return;
            } else if ([[MEGASdkManager sharedMEGASdk] httpServerStart:YES port:4443]) {
                MEGAAVViewController *megaAVViewController = [[MEGAAVViewController alloc] initWithNode:node folderLink:NO];
                [self presentViewController:megaAVViewController animated:YES completion:nil];
                return;
            }
        }
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
    return self.sizeForItem;
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
                NSInteger index = 0;
                for (NSInteger i = 0; i < indexPath.section; i++) {
                    NSDictionary *dict = [self.photosByMonthYearArray objectAtIndex:i];
                    NSString *key = [[dict allKeys] objectAtIndex:0];
                    NSArray *array = [dict objectForKey:key];
                    index += array.count;
                }
                index += indexPath.row;
                
                NSDictionary *monthPhotosDictionary = [self.photosByMonthYearArray objectAtIndex:indexPath.section];
                NSString *monthKey = [monthPhotosDictionary.allKeys objectAtIndex:0];
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
    NSString *monthKey = [monthPhotosDictionary.allKeys objectAtIndex:0];
    NSArray *monthPhotosArray = [monthPhotosDictionary objectForKey:monthKey];
    MEGANode *nodeSelected = [monthPhotosArray objectAtIndex:indexPath.row];
    if (nodeSelected.name.mnz_isImagePathExtension) {
        return [nodeSelected mnz_photoBrowserWithNodes:[self.nodeList mnz_nodesArrayFromNodeList] folderLink:NO displayMode:0 enableMoveToRubbishBin:YES hideControls:YES];
    } else {
        UIViewController *viewController = [nodeSelected mnz_viewControllerForNodeInFolderLink:NO];        
        return viewController;
    }
    
    return nil;
}

- (void)previewingContext:(id<UIViewControllerPreviewing>)previewingContext commitViewController:(UIViewController *)viewControllerToCommit {
    if (viewControllerToCommit.class == MWPhotoBrowser.class) {
        [self.navigationController pushViewController:viewControllerToCommit animated:YES];
    } else {
        [self.navigationController presentViewController:viewControllerToCommit animated:YES completion:nil];
    }
}

#pragma mark - DZNEmptyDataSetSource

- (NSAttributedString *)titleForEmptyDataSet:(UIScrollView *)scrollView {
    NSString *text;
    if ([MEGAReachabilityManager isReachable]) {
        if ([[CameraUploads syncManager] isCameraUploadsEnabled]) {
            if ([self.photosByMonthYearArray count] == 0) {
                text = AMLocalizedString(@"cameraUploadsEnabled", nil);
            } else {
                return nil;
            }
        } else {
            text = @"";
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
        if ([[CameraUploads syncManager] isCameraUploadsEnabled]) {
            if ([self.photosByMonthYearArray count] == 0) {
                image = [UIImage imageNamed:@"emptyCameraUploads"];
            }
        } else {
            image = [UIImage imageNamed:@"emptyCameraUploads"];
        }
    } else {
        image = [UIImage imageNamed:@"noInternetConnection"];
    }
    
    return image;
}

- (NSAttributedString *)buttonTitleForEmptyDataSet:(UIScrollView *)scrollView forState:(UIControlState)state {
    NSString *text = @"";
    if ([MEGAReachabilityManager isReachable]) {
        if (![[CameraUploads syncManager] isCameraUploadsEnabled]) {
            text = AMLocalizedString(@"enable", @"Text button shown when the chat is disabled and if tapped the chat will be enabled");
        }
    }
    
    NSDictionary *attributes = @{NSFontAttributeName:[UIFont mnz_SFUIRegularWithSize:18.0f], NSForegroundColorAttributeName:[UIColor mnz_gray777777]};
    
    return [[NSAttributedString alloc] initWithString:text attributes:attributes];
}

- (UIImage *)buttonBackgroundImageForEmptyDataSet:(UIScrollView *)scrollView forState:(UIControlState)state {
    UIEdgeInsets capInsets = [Helper capInsetsForEmptyStateButton];
    UIEdgeInsets rectInsets = [Helper rectInsetsForEmptyStateButton];
    
    return [[[UIImage imageNamed:@"buttonBorder"] resizableImageWithCapInsets:capInsets resizingMode:UIImageResizingModeStretch] imageWithAlignmentRectInsets:rectInsets];
}

- (UIColor *)backgroundColorForEmptyDataSet:(UIScrollView *)scrollView {
    if ([[CameraUploads syncManager] isCameraUploadsEnabled]) {
        return nil;
    }
    
    return [UIColor whiteColor];
}

- (CGFloat)verticalOffsetForEmptyDataSet:(UIScrollView *)scrollView {
    return [Helper verticalOffsetForEmptyStateWithNavigationBarSize:self.navigationController.navigationBar.frame.size searchBarActive:NO];
}

- (CGFloat)spaceHeightForEmptyDataSet:(UIScrollView *)scrollView {
    CGFloat spaceHeight = [Helper spaceHeightForEmptyState];
    if (![[CameraUploads syncManager] isCameraUploadsEnabled] || ![[UIDevice currentDevice] iPhone4X]) {
        spaceHeight += 20.0f;
    }
    
    return spaceHeight;
}

#pragma mark - DZNEmptyDataSetDelegate Methods

- (void)emptyDataSet:(UIScrollView *)scrollView didTapButton:(UIButton *)button {
    [self pushCameraUploadSettings];
}

#pragma mark - MEGARequestDelegate

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    if ([error type]) {
        return;
    }
    
    switch ([request type]) {
        case MEGARequestTypeGetAttrFile: {
            for (PhotoCollectionViewCell *pcvc in [self.photosCollectionView visibleCells]) {
                if ([request nodeHandle] == [pcvc nodeHandle]) {
                    MEGANode *node = [api nodeForHandle:request.nodeHandle];
                    [Helper setThumbnailForNode:node api:api cell:pcvc reindexNode:YES];
                }
            }
            break;
        }
            
        default:
            break;
    }
}

#pragma mark - MEGAGlobalDelegate

- (void)onNodesUpdate:(MEGASdk *)api nodeList:(MEGANodeList *)nodeList {
    [self reloadUI];
}

#pragma mark - MEGATransferDelegate

- (void)onTransferStart:(MEGASdk *)api transfer:(MEGATransfer *)transfer {
    [self updateProgressData];
}

- (void)onTransferUpdate:(MEGASdk *)api transfer:(MEGATransfer *)transfer {
    [self updateProgressData];
}

- (void)onTransferFinish:(MEGASdk *)api transfer:(MEGATransfer *)transfer error:(MEGAError *)error {
    if ([CameraUploads syncManager].assetsOperationQueue.operationCount == 1) {
        self.totalPhotosUploading = 0;
        self.currentPhotosUploaded = 0;
        self.currentState = MEGACameraUploadsStateCompleted;
    } else {
        self.currentPhotosUploaded++;
        [self updateProgressUI];
    }
}

@end
