
#import "MEGAPhotoBrowserPickerViewController.h"

#import "Helper.h"
#import "MEGAPhotoBrowserPickerCollectionViewCell.h"
#import "MEGAGetThumbnailRequestDelegate.h"

#import "NSString+MNZCategory.h"

@interface MEGAPhotoBrowserPickerViewController () <UICollectionViewDataSource, UICollectionViewDelegate>

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

@property (nonatomic) CGFloat cellInset;
@property (nonatomic) CGFloat cellSquareSize;

@end

@implementation MEGAPhotoBrowserPickerViewController

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    self.cellInset = 1.0f;
    [self calculateCellSize];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        [self calculateCellSize];
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
    // Video
    if (node.name.mnz_isVideoPathExtension) {
        cell.videoDurationLabel.text = node.duration>-1 ? [NSString mnz_stringFromTimeInterval:node.duration] : @"";
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
    return CGSizeMake(self.cellSquareSize, self.cellSquareSize);
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

    if([node hasThumbnail]) {
        MEGAGetThumbnailRequestDelegate *delegate = [[MEGAGetThumbnailRequestDelegate alloc] initWithCompletion:requestCompletion];
        NSString *path = [Helper pathForNode:node inSharedSandboxCacheDirectory:@"thumbnailsV3"];
        [self.api getThumbnailNode:node destinationFilePath:path delegate:delegate];
    }
}

#pragma mark - Private

- (void)calculateCellSize {
    CGRect collectionViewFrame = self.collectionView.frame;
    NSUInteger cellsInRow = collectionViewFrame.size.width < collectionViewFrame.size.height ? 4 : 8;
    if ([[UIDevice currentDevice] iPadDevice]) {
        cellsInRow *= 1.5;
    }
    self.cellSquareSize = ((collectionViewFrame.size.width-(cellsInRow+1)*self.cellInset) / cellsInRow);
    [self.collectionView.collectionViewLayout invalidateLayout];
}

@end
