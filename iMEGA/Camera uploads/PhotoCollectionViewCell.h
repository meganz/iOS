#import <UIKit/UIKit.h>

@interface PhotoCollectionViewCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UIImageView *thumbnailImageView;
@property (weak, nonatomic) IBOutlet UIImageView *thumbnailPlayImageView;
@property (nonatomic) uint64_t nodeHandle;

@end
