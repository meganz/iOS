#import <UIKit/UIKit.h>

@class PhotoBrowserPickerCollectionViewCellViewModel;

@interface MEGAPhotoBrowserPickerCollectionViewCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIView *videoOverlay;
@property (weak, nonatomic) IBOutlet UILabel *videoDurationLabel;
@property (weak, nonatomic) IBOutlet UIImageView *playView;
@property (strong, nonatomic, nullable) PhotoBrowserPickerCollectionViewCellViewModel *viewModel;
@property (strong, nonatomic, nullable) NSSet<id> *cancellables;

@end
