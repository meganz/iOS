
#import <UIKit/UIKit.h>
#import "MEGARemoteImageView.h"

@class MEGARemoteImageView, MEGAGroupCallPeer;

@interface GroupCallCollectionViewCell : UICollectionViewCell

- (void)configureCellForPeer:(MEGAGroupCallPeer *)peer inChat:(uint64_t)chatId;
- (void)networkQualityChangedForPeer:(MEGAGroupCallPeer *)peer;
- (void)configureUserAudio:(BOOL)audio;
- (void)removeLocalVideoInChat:(uint64_t)chatId;
- (void)addLocalVideoInChat:(uint64_t)chatId;
- (void)removeRemoteVideoForPeer:(MEGAGroupCallPeer *)peer inChat:(uint64_t)chatId;
- (void)addRemoteVideoForPeer:(MEGAGroupCallPeer *)peer inChat:(uint64_t)chatId;
- (void)showUserOnFocus;
- (void)hideUserOnFocus;

@end
