#import "PhotosViewController.h"

#import "SVProgressHUD.h"
#import "UIScrollView+EmptyDataSet.h"

#import "Helper.h"
#import "MEGAAVViewController.h"
#import "MEGANavigationController.h"
#import "MEGAReachabilityManager.h"
#import "MEGAStore.h"

#import "PhotoCollectionViewCell.h"
#import "HeaderCollectionReusableView.h"
#import "CameraUploads.h"
#import "CameraUploadsTableViewController.h"
#import "BrowserViewController.h"

@interface PhotosViewController () <UIAlertViewDelegate, UICollectionViewDelegateFlowLayout, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate> {
    BOOL allNodesSelected;

    NSUInteger remainingOperations;
    
    NSUInteger itemsPerRow;
}

@property (nonatomic, strong) MEGANode *parentNode;
@property (nonatomic, strong) MEGANodeList *nodeList;
@property (nonatomic, strong) NSMutableArray *photosByMonthYearArray;
@property (nonatomic, strong) NSMutableArray *previewsArray;

@property (weak, nonatomic) IBOutlet UICollectionView *photosCollectionView;

@property (weak, nonatomic) IBOutlet UIView *uploadProgressView;
@property (weak, nonatomic) IBOutlet UILabel *photoNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *speedLabel;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@property (weak, nonatomic) IBOutlet UILabel *transferredBytesLabel;
@property (weak, nonatomic) IBOutlet UILabel *totalBytesLabel;

@property (weak, nonatomic) IBOutlet UIButton *enableCameraUploadsButton;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *uploadProgressViewTopLayoutConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *photosCollectionViewTopLayoutConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *photosCollectionViewBottonLayoutConstraint;

@property (nonatomic, strong) NSMutableDictionary *selectedItemsDictionary;

@property (strong, nonatomic) IBOutlet UIToolbar *toolbar;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *downloadBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *shareBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *moveBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *carbonCopyBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *deleteBarButtonItem;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *selectAllBarButtonItem;

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
    
    if ([[UIDevice currentDevice] iPadDevice]) {
        itemsPerRow = 7;
    } else {
        if ([[UIDevice currentDevice] iPhone4X] || [[UIDevice currentDevice] iPhone5X]) {
            itemsPerRow = 3;
        } else {
            itemsPerRow = 4;
        }
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(internetConnectionChanged) name:kReachabilityChangedNotification object:nil];
    
    [self setEditing:NO animated:NO];
    
    [self.enableCameraUploadsButton setTitle:AMLocalizedString(@"enableCameraUploadsButton", @"Enable Camera Uploads") forState:UIControlStateNormal];
    
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

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
        [self.photosCollectionView reloadEmptyDataSet];
    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        
    }];
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
    
    for (NSInteger i = 0; i < [self.nodeList.size integerValue]; i++) {
        MEGANode *node = [self.nodeList nodeAtIndex:i];
        
        if (!isImage([node name].lowercaseString.pathExtension) && !isVideo([node name].lowercaseString.pathExtension)) {
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
        [self.enableCameraUploadsButton setHidden:YES];
        [self.enableCameraUploadsButton setFrame:CGRectMake(0, 0, 0, 0)];
        
        self.photosCollectionViewBottonLayoutConstraint.constant = -49;
    } else {
        if ([self.photosByMonthYearArray count] == 0) {
            [self.enableCameraUploadsButton setHidden:YES];
        } else {
            [self.enableCameraUploadsButton setHidden:NO];
        }
        
        self.uploadProgressViewTopLayoutConstraint.constant = -60;
        self.photosCollectionViewTopLayoutConstraint.constant = 0;
        self.photosCollectionViewBottonLayoutConstraint.constant = 0;
    }
    
    if ([self.photosCollectionView allowsMultipleSelection]) {
        [self.navigationItem setTitle:AMLocalizedString(@"selectTitle", @"Select items")];
    } else {
        
        [self.navigationItem setTitle:@"Camera Uploads"]; //TODO: Translate or not?
    }
    
}

- (void)showProgressView {
    [UIView animateWithDuration:1 animations:^{
        self.uploadProgressViewTopLayoutConstraint.constant = 0;
        self.photosCollectionViewTopLayoutConstraint.constant = 60;
        
        [self.view layoutIfNeeded];
    }];
}

- (void)hideProgressView {
    [UIView animateWithDuration:1 animations:^{
        self.uploadProgressViewTopLayoutConstraint.constant = -60;
        self.photosCollectionViewTopLayoutConstraint.constant = 0;
        
        [self.view layoutIfNeeded];
    }];
}

- (void)internetConnectionChanged {
    [self setNavigationBarButtonItemsEnabled:[MEGAReachabilityManager isReachable]];
    
    if ([[CameraUploads syncManager] isCameraUploadsEnabled]) {
        if (![MEGAReachabilityManager isReachable]) {
            [self hideProgressView];
        }
    }
}

- (void)setNavigationBarButtonItemsEnabled:(BOOL)boolValue {
    [self.editButtonItem setEnabled:boolValue];
}

- (void)enableCameraUploadsAndShowItsSettings {
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

#pragma mark - IBAction

- (IBAction)enableCameraUploadsTouchUpInside:(UIButton *)sender {
    [self enableCameraUploadsAndShowItsSettings];
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
    } else {
        [self.editButtonItem setImage:[UIImage imageNamed:@"edit"]];
        allNodesSelected = NO;
        [self.navigationItem setTitle:@"Camera Uploads"];
        [self.photosCollectionView setAllowsMultipleSelection:NO];
        [self.selectedItemsDictionary removeAllObjects];
        [self.photosCollectionView reloadData];
        self.navigationItem.leftBarButtonItems = @[];
    }
    if (![self.selectedItemsDictionary count]) {
        [self setToolbarActionsEnabled:NO];
    }
    
    [self.tabBarController.tabBar addSubview:self.toolbar];
    
    [UIView animateWithDuration:animated ? .33 : 0 animations:^{
        self.toolbar.frame = CGRectMake(0, editing ? 0 : 49 , CGRectGetWidth(self.view.frame), 49);
    }];
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
    
    BrowserViewController *mcnvc = mcnc.viewControllers.firstObject;
    mcnvc.parentNode = [[MEGASdkManager sharedMEGASdk] rootNode];
    mcnvc.selectedNodesArray = [NSArray arrayWithArray:[self.selectedItemsDictionary allValues]];
    [mcnvc setBrowserAction:BrowserActionMove];
}

- (IBAction)copyAction:(UIBarButtonItem *)sender {
    if ([MEGAReachabilityManager isReachableHUDIfNot]) {
        MEGANavigationController *navigationController = [[UIStoryboard storyboardWithName:@"Cloud" bundle:nil] instantiateViewControllerWithIdentifier:@"BrowserNavigationControllerID"];
        BrowserViewController *browserVC = navigationController.viewControllers.firstObject;
        browserVC.parentNode = [[MEGASdkManager sharedMEGASdk] rootNode];
        browserVC.selectedNodesArray = [NSArray arrayWithArray:[self.selectedItemsDictionary allValues]];
        [browserVC setBrowserAction:BrowserActionCopy];
        [self presentViewController:navigationController animated:YES completion:nil];
    }
}

- (IBAction)deleteAction:(UIBarButtonItem *)sender {
    NSString *message = (self.selectedItemsDictionary.count > 1) ? [NSString stringWithFormat:AMLocalizedString(@"moveFilesToRubbishBinMessage", nil), self.selectedItemsDictionary.count] : [NSString stringWithString:AMLocalizedString(@"moveFileToRubbishBinMessage", nil)];
    
    UIAlertView *removeAlertView = [[UIAlertView alloc] initWithTitle:AMLocalizedString(@"moveToTheRubbishBin", nil) message:message delegate:self cancelButtonTitle:AMLocalizedString(@"cancel", nil) otherButtonTitles:AMLocalizedString(@"ok", nil), nil];
    removeAlertView.tag = 1;
    [removeAlertView show];
}

#pragma mark - UICollectioViewDataSource

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
    
    [cell.thumbnailPlayImageView setHidden:YES];
    if ([node hasThumbnail]) {
        [Helper thumbnailForNode:node api:[MEGASdkManager sharedMEGASdk] cell:cell];
    } else {
        [cell.thumbnailImageView setImage:[Helper imageForNode:node]];
    }
    
    cell.nodeHandle = [node handle];
    
    if ([self.selectedItemsDictionary objectForKey:[NSNumber numberWithLongLong:node.handle]]) {
        cell.thumbnailImageView.layer.borderColor = [[UIColor mnz_redD90007] CGColor];
        cell.thumbnailImageView.layer.borderWidth = 3.0;
        [cell.thumbnailImageView.layer setOpacity:0.6];
    } else {
        cell.thumbnailImageView.layer.borderColor = nil;
        cell.thumbnailImageView.layer.borderWidth = 0.0;
        [cell.thumbnailImageView.layer setOpacity:1.0];
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
        
        NSString *itemsPerMonth = nil;
        NSInteger numberPhotosPerMonth = [[dict objectForKey:month] count];
        if ( numberPhotosPerMonth > 1) {
            itemsPerMonth = [NSString stringWithFormat:AMLocalizedString(@"photosPerMonth", @"Number of photos by section"), numberPhotosPerMonth];
        } else {
            itemsPerMonth = [NSString stringWithFormat:AMLocalizedString(@"photoPerMonth", @"Number of photos by section"), numberPhotosPerMonth];
        }
        
        NSString *dateString = [NSString stringWithFormat:@"%@", month];
        [headerView.dateLabel setText:dateString];
        [headerView.itemsLabel setText:itemsPerMonth];
        
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

#pragma mark - UICollectioViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    self.previewsArray = [[NSMutableArray alloc] init];
    
    for (NSInteger i = 0; i < [[self.nodeList size] integerValue]; i++) {
        MEGANode *n = [self.nodeList nodeAtIndex:i];
        if (isImage([n name].pathExtension)) {
            MWPhoto *preview = [[MWPhoto alloc] initWithNode:n];
            [self.previewsArray addObject:preview];
        }
    }
    
    // Get the index of the array using the indexPath
    NSInteger index = 0;
    for (NSInteger i = 0; i < indexPath.section; i++) {
        NSDictionary *dict = [self.photosByMonthYearArray objectAtIndex:i];
        NSString *key = [[dict allKeys] objectAtIndex:0];
        NSArray *array = [dict objectForKey:key];
        index += array.count;
    }
    
    NSInteger videosCount = 0;
    for (NSInteger i = 0; i < index + indexPath.row; i++) {
        MEGANode *n = [self.nodeList nodeAtIndex:i];
        if (!isImage([n name].pathExtension)) {
            videosCount++;
        }
    }
    
    index += indexPath.row - videosCount;
    
    MEGANode *node = [self.nodeList nodeAtIndex:(index + videosCount)];
    
    
    if (![self.photosCollectionView allowsMultipleSelection]) {
        if (isImage([node name].pathExtension)) {
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
            MOOfflineNode *offlineNodeExist = [[MEGAStore shareInstance] fetchOfflineNodeWithFingerprint:[[MEGASdkManager sharedMEGASdk] fingerprintForNode:node]];
            
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

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(([UIScreen mainScreen].bounds.size.width-itemsPerRow-1)/itemsPerRow,([UIScreen mainScreen].bounds.size.width-itemsPerRow-1)/itemsPerRow);
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
    [self enableCameraUploadsAndShowItsSettings];
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    // Move to rubbish bin
    if (alertView.tag == 1) {
        if (buttonIndex == 1) {
            remainingOperations = self.selectedItemsDictionary.count;
            for (NSInteger i = 0; i < self.selectedItemsDictionary.count; i++) {
                    [[MEGASdkManager sharedMEGASdk] moveNode:[[self.selectedItemsDictionary allValues] objectAtIndex:i] newParent:[[MEGASdkManager sharedMEGASdk] rubbishNode] delegate:self];
            }
        }
    } else {
        if (buttonIndex == 1) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
        }
    }
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
                    [Helper setThumbnailForNode:node api:api cell:pcvc];
                }
            }
            break;
        }
            
            
        case MEGARequestTypeMove: {
            remainingOperations--;
            if (remainingOperations == 0) {
                NSString *message = (self.selectedItemsDictionary.count <= 1 ) ? AMLocalizedString(@"fileMovedToRubbishBinMessage", nil) : [NSString stringWithFormat:AMLocalizedString(@"filesMovedToRubbishBinMessage", nil), self.selectedItemsDictionary.count];
                [SVProgressHUD showImage:[UIImage imageNamed:@"hudRubbishBin"] status:message];
                [self setEditing:NO animated:NO];
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

- (void)onTransferUpdate:(MEGASdk *)api transfer:(MEGATransfer *)transfer {
    if ([transfer type] == MEGATransferTypeUpload) {
        if (self.uploadProgressViewTopLayoutConstraint.constant == -60) {
            [self showProgressView];
        }
        [self.photoNameLabel setText:[transfer fileName]];
        float percentage = [[transfer transferredBytes] floatValue] / [[transfer totalBytes] floatValue];
        [self.transferredBytesLabel setText:[NSByteCountFormatter stringFromByteCount:[[transfer transferredBytes] longLongValue]  countStyle:NSByteCountFormatterCountStyleMemory]];
        [self.totalBytesLabel setText:[NSByteCountFormatter stringFromByteCount:[[transfer totalBytes] longLongValue]  countStyle:NSByteCountFormatterCountStyleMemory]];
        [self.speedLabel setText:[NSString stringWithFormat:@"%@/s", [NSByteCountFormatter stringFromByteCount:[[transfer speed] longLongValue]  countStyle:NSByteCountFormatterCountStyleMemory]]];
        [self.progressView setProgress:percentage];
    }
}

- (void)onTransferFinish:(MEGASdk *)api transfer:(MEGATransfer *)transfer error:(MEGAError *)error {
    if ([[[CameraUploads syncManager] assetsOperationQueue] operationCount] == 1) {
        [self hideProgressView];
    }
}

@end
