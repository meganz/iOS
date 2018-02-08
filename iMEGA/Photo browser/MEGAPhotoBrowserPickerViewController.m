
#import "MEGAPhotoBrowserPickerViewController.h"

#import "Helper.h"
#import "MEGAPhotoBrowserPickerCollectionViewCell.h"

#import "NSString+MNZCategory.h"

@interface MEGAPhotoBrowserPickerViewController () <UICollectionViewDataSource, UICollectionViewDelegate>

@property (nonatomic) CGFloat cellInset;
@property (nonatomic) CGFloat cellSquareSize;

@end

@implementation MEGAPhotoBrowserPickerViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.cellInset = 1.0f;
    self.cellSquareSize = ((self.view.frame.size.width-5*self.cellInset) / 4);
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(nonnull UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.mediaNodes.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    MEGAPhotoBrowserPickerCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"photoBrowserPickerCellId" forIndexPath:indexPath];
    
    MEGANode *node = [self.mediaNodes objectAtIndex:indexPath.item];
    NSString *thumbnailPath = [Helper pathForNode:node inSharedSandboxCacheDirectory:@"thumbnailsV3"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:thumbnailPath]) {
        cell.imageView.image = [UIImage imageWithContentsOfFile:thumbnailPath];
    } else {
        [self.delegate updateImageView:cell.imageView withThumbnailOfNode:node];
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

@end
