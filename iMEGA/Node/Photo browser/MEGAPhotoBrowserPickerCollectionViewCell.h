
#import <UIKit/UIKit.h>

@interface MEGAPhotoBrowserPickerCollectionViewCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIView *videoOverlay;
@property (weak, nonatomic) IBOutlet UILabel *videoDurationLabel;
@property (weak, nonatomic) IBOutlet UIImageView *playView;
@property (nonatomic) uint64_t nodeHandle;

@end
