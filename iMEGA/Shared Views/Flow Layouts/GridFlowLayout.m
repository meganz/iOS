
#import "GridFlowLayout.h"

@implementation GridFlowLayout

- (void)prepareLayout {
    [super prepareLayout];
    
    CGSize contentSize = self.collectionViewContentSize;
    CGFloat originalMinimunInteritemSpacing = self.minimumInteritemSpacing;
    CGSize itemSize = CGSizeMake(150, 200);

    NSInteger numberOfItemsPerLine = (contentSize.width - self.sectionInset.left - self.sectionInset.right) / itemSize.width;
    CGFloat interitemSpacing = contentSize.width - self.sectionInset.left - self.sectionInset.right - itemSize.width * numberOfItemsPerLine;
    NSInteger collectionWidthForCells = contentSize.width - self.sectionInset.left - self.sectionInset.right - self.minimumInteritemSpacing * numberOfItemsPerLine;

    CGFloat distanceToItem = itemSize.width - interitemSpacing;
    CGFloat distanceToInteritem = interitemSpacing - originalMinimunInteritemSpacing;
    BOOL enoughInteritemSpacingForOneMore = distanceToItem < distanceToInteritem;
    if (enoughInteritemSpacingForOneMore) { //decrease cell size to allow one item more per row
        self.itemSize = CGSizeMake(collectionWidthForCells / (numberOfItemsPerLine + 1), collectionWidthForCells / (numberOfItemsPerLine + 1) * itemSize.height / itemSize.width);
    } else { //increase cell size to reduce interitemSpacing
        self.itemSize = CGSizeMake(collectionWidthForCells / numberOfItemsPerLine, collectionWidthForCells / numberOfItemsPerLine * itemSize.height / itemSize.width);
    }
}

@end
