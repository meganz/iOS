#import <UIKit/UIKit.h>

@interface PhotoCollectionViewCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UIImageView *thumbnailImageView;
@property (weak, nonatomic) IBOutlet UIImageView *thumbnailPlayImageView;
@property (weak, nonatomic) IBOutlet UIView *thumbnailVideoOverlayView;
@property (weak, nonatomic) IBOutlet UILabel *thumbnailVideoDurationLabel;
@property (weak, nonatomic) IBOutlet UIView *thumbnailSelectionOverlayView;
@property (nonatomic) uint64_t nodeHandle;

@end
