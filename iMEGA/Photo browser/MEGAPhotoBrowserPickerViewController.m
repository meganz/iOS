
#import "MEGAPhotoBrowserPickerViewController.h"

#import "Helper.h"
#import "MEGAPhotoBrowserPickerCollectionViewCell.h"
#import "MEGAGetThumbnailRequestDelegate.h"

#import "NSString+MNZCategory.h"
#import "UICollectionView+MNZCategory.h"
#import "UIColor+MNZCategory.h"

@interface MEGAPhotoBrowserPickerViewController () <UICollectionViewDataSource, UICollectionViewDelegate>

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UINavigationBar *navigationBar;
@property (weak, nonatomic) IBOutlet UINavigationItem *navigationItem;

@property (nonatomic) CGSize cellSize;
@property (nonatomic) CGFloat cellInset;

@end

@implementation MEGAPhotoBrowserPickerViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.navigationBar.barTintColor = [UIColor whiteColor];
    
    if (@available(iOS 11.0, *)) {} else {
        self.navigationBar.tintColor = [UIColor mnz_redFF4D52];
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    self.cellInset = 1.0f;
    self.cellSize = [self.collectionView mnz_calculateCellSizeForInset:self.cellInset];
    [self.collectionView.collectionViewLayout invalidateLayout];
    
    NSString *folderName = [self.api nodeForHandle:self.mediaNodes.firstObject.parentHandle].name;
    NSString *numberOfFiles;
    if (self.mediaNodes.count==1) {
        numberOfFiles = [NSString stringWithFormat:AMLocalizedString(@"oneFile", @"Subtitle shown on folders that gives you information about its content. This case \"{1} file\""), 1];
    } else {
        numberOfFiles = [NSString stringWithFormat:AMLocalizedString(@"files", @"Subtitle shown on folders that gives you information about its content. This case \"{1+} files\""), self.mediaNodes.count];
    }
    
    if (!folderName) {
        folderName = numberOfFiles;
        numberOfFiles = @"";
    }
    
    UILabel *titleLabel = [Helper customNavigationBarLabelWithTitle:folderName subtitle:numberOfFiles color:[UIColor mnz_black333333]];
    titleLabel.adjustsFontSizeToFitWidth = YES;
    titleLabel.minimumScaleFactor = 0.8f;
    self.navigationItem.titleView = titleLabel;
    [self.navigationItem.titleView sizeToFit];
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
        cell.imageView.image = [Helper imageForNode:node];
        [self updateCollectionView:collectionView withThumbnailOfNode:node];
    }
    
    if (node.name.mnz_isVideoPathExtension) {
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
