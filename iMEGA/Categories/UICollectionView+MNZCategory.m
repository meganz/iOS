
#import "UICollectionView+MNZCategory.h"

@implementation UICollectionView (MNZCategory)

- (CGSize)mnz_calculateCellSizeForInset:(CGFloat)inset {
    CGFloat minimumThumbnailSize = [[UIDevice currentDevice] iPadDevice] ? 100.0f : 93.0f;
    CGRect collectionViewFrame = self.frame;
    NSUInteger cellsInRow = floor(collectionViewFrame.size.width / minimumThumbnailSize);
    CGFloat cellSquareSize = ((collectionViewFrame.size.width - (cellsInRow + 1) * inset) / cellsInRow);
    
    return CGSizeMake(cellSquareSize, cellSquareSize);
}

@end
