
#import <Foundation/Foundation.h>

@interface UICollectionView (MNZCategory)

- (CGSize)mnz_calculateCellSizeForInset:(CGFloat)inset;
- (NSInteger)mnz_totalRows;

/**
 Scroll content to left.
 
 @param animated  Use animation.
 */
- (void)scrollToLeftAnimated:(BOOL)animated;

@end
