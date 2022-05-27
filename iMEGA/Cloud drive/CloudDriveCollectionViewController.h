
#import <UIKit/UIKit.h>
#import "NodeCollectionViewCell.h"

NS_ASSUME_NONNULL_BEGIN

@class CloudDriveViewController;
@interface CloudDriveCollectionViewController : UIViewController

@property (weak, nonatomic) CloudDriveViewController *cloudDrive;

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

- (void)setCollectionViewEditing:(BOOL)editing animated:(BOOL)animated;
- (void)collectionViewSelectIndexPath:(NSIndexPath *)indexPath;
- (void)reloadData;
- (nullable MEGANode *)thumbnailNodeAtIndexPath:(NSIndexPath *)indexPath;

@end

NS_ASSUME_NONNULL_END
