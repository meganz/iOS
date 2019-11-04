
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class CloudDriveViewController;
@interface CloudDriveCollectionViewController : UIViewController

@property (weak, nonatomic) CloudDriveViewController *cloudDrive;

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

- (void)resetSearchBarPosition;

- (void)setCollectionViewEditing:(BOOL)editing animated:(BOOL)animated;
- (void)collectionViewSelectIndexPath:(NSIndexPath *)indexPath;

@end

NS_ASSUME_NONNULL_END
