
#import <UIKit/UIKit.h>

#import "CallPeerAudio.h"
#import "MEGARemoteImageView.h"

@class MEGARemoteImageView, MEGAGroupCallPeer;

@interface GroupCallCollectionViewCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet MEGARemoteImageView *videoImageView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *micTopConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *micTrailingConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *qualityBottomConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *qualityLeadingConstraint;

- (void)configureCellForPeer:(MEGAGroupCallPeer *)peer inChat:(uint64_t)chatId numParticipants:(NSInteger)numParticipants;
- (void)networkQualityChangedForPeer:(MEGAGroupCallPeer *)peer;
- (void)configureUserAudio:(CallPeerAudio)audio;
- (void)removeLocalVideoInChat:(uint64_t)chatId;
- (void)addLocalVideoInChat:(uint64_t)chatId;
- (void)removeRemoteVideoForPeer:(MEGAGroupCallPeer *)peer inChat:(uint64_t)chatId;
- (void)addRemoteVideoForPeer:(MEGAGroupCallPeer *)peer inChat:(uint64_t)chatId;
- (void)showUserOnFocus;
- (void)hideUserOnFocus;
- (void)configureConstraintsForInfoViews:(NSInteger)constant;
- (void)localVideoMirror:(BOOL)mirror;

@end
