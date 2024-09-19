#import "MEGAPhotoBrowserPickerViewController.h"

#import "Helper.h"
#import "MEGAPhotoBrowserPickerCollectionViewCell.h"
#import "MEGAGetThumbnailRequestDelegate.h"

#import "NSString+MNZCategory.h"
#import "UICollectionView+MNZCategory.h"
#import "UIImageView+MNZCategory.h"

#import "MEGA-Swift.h"

@import MEGAL10nObjc;
@import MEGAUIKit;

@interface MEGAPhotoBrowserPickerViewController () <UICollectionViewDataSource, UICollectionViewDelegate>

@property (weak, nonatomic) IBOutlet UIView *statusBarBackground;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UINavigationBar *navigationBar;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *closeBarButtonItem;
@property (weak, nonatomic) IBOutlet UINavigationItem *navigationItem;

@property (nonatomic) CGSize cellSize;
@property (nonatomic) CGFloat cellInset;

@end

@implementation MEGAPhotoBrowserPickerViewController

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    self.cellInset = 1.0f;
    self.cellSize = [self.collectionView mnz_calculateCellSizeForInset:self.cellInset];
    [self.collectionView.collectionViewLayout invalidateLayout];
    
    self.closeBarButtonItem.title = LocalizedString(@"close", @"A button label.");
    
    NSString *folderName = [self.api nodeForHandle:self.mediaNodes.firstObject.parentHandle].name;
    NSString *numberOfFiles = [NSString stringWithFormat:LocalizedString(@"general.format.count.file", @"Subtitle shown on folders that gives you information about its file content count. e.g 1 file, 2 files"), self.mediaNodes.count];
    
    if (!folderName) {
        folderName = numberOfFiles;
        numberOfFiles = @"";
    }
    
    UILabel *titleLabel = [UILabel customNavigationBarLabelWithTitle:folderName subtitle:numberOfFiles traitCollection:self.traitCollection];
    titleLabel.adjustsFontSizeToFitWidth = YES;
    titleLabel.minimumScaleFactor = 0.8f;
    self.navigationItem.titleView = titleLabel;
    [self.navigationItem.titleView sizeToFit];
    
    self.statusBarBackground.backgroundColor = self.navigationBar.backgroundColor = [UIColor surface1Background];
    self.navigationBar.tintColor = [UIColor mnz_navigationBarTintFor:self.traitCollection];
    self.view.backgroundColor = UIColor.systemBackgroundColor;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        self.cellSize = [self.collectionView mnz_calculateCellSizeForInset:self.cellInset];
        [self.collectionView.collectionViewLayout invalidateLayout];
    } completion:nil];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(nonnull UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.mediaNodes.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    MEGAPhotoBrowserPickerCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"photoBrowserPickerCellId" forIndexPath:indexPath];
    
    MEGANode *node = [self.mediaNodes objectAtIndex:indexPath.item];
    cell.nodeHandle = node.handle;
    
    NSString *thumbnailPath = [Helper pathForNode:node inSharedSandboxCacheDirectory:@"thumbnailsV3"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:thumbnailPath]) {
        cell.imageView.image = [UIImage imageWithContentsOfFile:thumbnailPath];
    } else {
        [cell.imageView setImage:[NodeAssetsManager.shared iconFor:node]];
        [self updateCollectionView:collectionView withThumbnailOfNode:node];
    }
    
    if ([FileExtensionGroupOCWrapper verifyIsVideo:node.name]) {
        cell.videoDurationLabel.text = node.duration > -1 ? [NSString mnz_stringFromTimeInterval:node.duration] : @"";
        cell.videoOverlay.hidden = NO;
        cell.playView.hidden = NO;
    } else {
        cell.videoDurationLabel.text = @"";
        cell.videoOverlay.hidden = YES;
        cell.playView.hidden = YES;
    }
    
    return cell;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [self.delegate updateCurrentIndexTo:indexPath.item];
    [self dismissViewControllerAnimated:YES completion:nil];
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

#pragma mark - IBActions

- (IBAction)didPressClose:(UIBarButtonItem *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Getting the thumbnails

- (void)updateCollectionView:(UICollectionView *)collectionView withThumbnailOfNode:(MEGANode *)node {
    void (^requestCompletion)(MEGARequest *request) = ^(MEGARequest *request) {
        for (MEGAPhotoBrowserPickerCollectionViewCell *cell in collectionView.visibleCells) {
            if (cell.nodeHandle == request.nodeHandle) {
                cell.imageView.image = [UIImage imageWithContentsOfFile:request.file];
            }
        }
    };

    if (node.hasThumbnail) {
        MEGAGetThumbnailRequestDelegate *delegate = [[MEGAGetThumbnailRequestDelegate alloc] initWithCompletion:requestCompletion];
        NSString *path = [Helper pathForNode:node inSharedSandboxCacheDirectory:@"thumbnailsV3"];
        [self.api getThumbnailNode:node destinationFilePath:path delegate:delegate];
    }
}

@end
