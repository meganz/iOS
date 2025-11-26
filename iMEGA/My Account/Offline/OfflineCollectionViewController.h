#import <UIKit/UIKit.h>
#import "NodeCollectionViewCell.h"

NS_ASSUME_NONNULL_BEGIN

@class OfflineViewController;
@interface OfflineCollectionViewController : UIViewController

@property (nonatomic, weak) OfflineViewController *offline;

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (nonatomic, strong, nullable) UIView *headerContainerView;

- (void)setCollectionViewEditing:(BOOL)editing animated:(BOOL)animated;
- (void)collectionViewSelectIndexPath:(NSIndexPath *)indexPath;
- (void)reloadData;
- (nullable NSDictionary *)getItemAtIndexPath:(NSIndexPath *)indexPath;

@end

NS_ASSUME_NONNULL_END
