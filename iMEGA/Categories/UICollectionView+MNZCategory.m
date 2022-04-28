
#import "UICollectionView+MNZCategory.h"

@implementation UICollectionView (MNZCategory)

- (CGSize)mnz_calculateCellSizeForInset:(CGFloat)inset {
    CGFloat minimumThumbnailSize = [[UIDevice currentDevice] iPadDevice] ? 100.0f : 93.0f;
    CGRect collectionViewFrame = self.frame;
    NSUInteger cellsInRow = floor(collectionViewFrame.size.width / minimumThumbnailSize);
    CGFloat cellSquareSize = ((collectionViewFrame.size.width - (cellsInRow + 1) * inset) / cellsInRow);
    
    return CGSizeMake(cellSquareSize, cellSquareSize);
}

- (NSInteger)mnz_totalRows {
    NSInteger totalSections = self.numberOfSections;
    NSInteger numberOfRows = 0;
    for (int section = 0; section < totalSections; section++) {
        numberOfRows += [self numberOfItemsInSection:section];
    }
    return numberOfRows;
}

- (void)scrollToLeftAnimated:(BOOL)animated {
    CGPoint off = self.contentOffset;
    off.x = 0 - self.contentInset.left;
    [self setContentOffset:off animated:animated];
}

@end
