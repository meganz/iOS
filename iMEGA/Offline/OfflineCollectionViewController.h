
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class OfflineViewController;
@interface OfflineCollectionViewController : UIViewController

@property (nonatomic, strong) OfflineViewController *offline;

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

- (void)setCollectionViewEditing:(BOOL)editing animated:(BOOL)animated;
- (void)collectionViewSelectIndexPath:(NSIndexPath *)indexPath;
- (void)reloadData;

@end

NS_ASSUME_NONNULL_END
