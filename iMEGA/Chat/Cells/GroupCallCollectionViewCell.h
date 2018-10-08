
#import <UIKit/UIKit.h>
#import "MEGARemoteImageView.h"

@class MEGARemoteImageView, MEGAGroupCallPeer;

@interface GroupCallCollectionViewCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UIImageView *avatarImageView;
@property (weak, nonatomic) IBOutlet UIImageView *userMutedImageView;
@property (weak, nonatomic) IBOutlet UIView *lowQualityView;

@property (strong, nonatomic) IBOutlet MEGARemoteImageView *videoImageView;

- (void)configureCellForPeer:(MEGAGroupCallPeer *)peer inChat:(uint64_t)chatId;
- (void)networkQualityChangedForPeer:(MEGAGroupCallPeer *)peer reducedLayout:(BOOL)reduced;

@end
