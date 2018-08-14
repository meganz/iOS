
#import <UIKit/UIKit.h>
#import "MEGARemoteImageView.h"

@interface GroupCallCollectionViewCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UIImageView *avatarImageView;
@property (weak, nonatomic) IBOutlet MEGARemoteImageView *videoImageView;

@end
