
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class CloudDriveViewController;
@interface CloudDriveCollectionViewController : UIViewController

@property (nonatomic, strong) CloudDriveViewController *cloudDrive;

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

- (void)setCollectionViewEditing:(BOOL)editing animated:(BOOL)animated;
- (void)collectionViewSelectIndexPath:(NSIndexPath *)indexPath;
- (void)setCollectionTopConstraintValue:(NSInteger)value;

@end

NS_ASSUME_NONNULL_END
