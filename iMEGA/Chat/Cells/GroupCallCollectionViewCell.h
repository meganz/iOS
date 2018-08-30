
#import <UIKit/UIKit.h>
#import "MEGARemoteImageView.h"

@interface GroupCallCollectionViewCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UIImageView *avatarImageView;
@property (strong, nonatomic) MEGARemoteImageView *videoImageView;

@property (assign, nonatomic) uint64_t peerId;

@end
