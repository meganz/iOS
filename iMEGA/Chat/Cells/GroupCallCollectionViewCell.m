
#import "GroupCallCollectionViewCell.h"

#import "UIImageView+MNZCategory.h"

#import "MEGASdkManager.h"

#import "MEGAGroupCallPeer.h"

@interface GroupCallCollectionViewCell ()

@property (weak, nonatomic) IBOutlet UIImageView *avatarImageView;
@property (weak, nonatomic) IBOutlet UIImageView *userMutedImageView;
@property (weak, nonatomic) IBOutlet UIView *lowQualityView;

@end

@implementation GroupCallCollectionViewCell

#pragma mark - Public

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.videoImageView.group = YES;
}

- (void)configureCellForPeer:(MEGAGroupCallPeer *)peer inChat:(uint64_t)chatId numParticipants:(NSInteger)numParticipants {
    
    if (peer.peerId == 0) {
        [self.avatarImageView mnz_setImageForUserHandle:[MEGASdkManager sharedMEGAChatSdk].myUserHandle];
        if (peer.video) {
            if (self.videoImageView.hidden) {
                [self addLocalVideoInChat:chatId];
            }
        } else {
            if (!self.videoImageView.hidden) {
                [self removeLocalVideoInChat:chatId];
            }
        }
    } else {
        [self.avatarImageView mnz_setImageForUserHandle:peer.peerId];
        if (peer.video) {
            if (self.videoImageView.hidden) {
                [self addRemoteVideoForPeer:peer inChat:chatId];
            }
        } else {
            if (!self.videoImageView.hidden) {
                [self removeRemoteVideoForPeer:peer inChat:chatId];
            }
        }
    }
    
    [self configureUserAudio:peer.audio];
    
    if (numParticipants < 7) {
        self.micTopConstraint.constant = self.micTrailingConstraint.constant = self.qualityBottomConstraint.constant = self.qualityLeadingConstraint.constant = 12;
    } else {
        self.micTopConstraint.constant = self.micTrailingConstraint.constant = self.qualityBottomConstraint.constant = self.qualityLeadingConstraint.constant = 0;
    }
}

- (void)configureConstraintsForInfoViews:(NSInteger)constant {
    self.micTopConstraint.constant = self.micTrailingConstraint.constant = self.qualityBottomConstraint.constant = self.qualityLeadingConstraint.constant = constant;
}

- (void)networkQualityChangedForPeer:(MEGAGroupCallPeer *)peer {
    if (peer.networkQuality < 2) {
        self.lowQualityView.hidden = NO;
    } else {
        self.lowQualityView.hidden = YES;
    }
}

- (void)removeLocalVideoInChat:(uint64_t)chatId {
    [[MEGASdkManager sharedMEGAChatSdk] removeChatLocalVideo:chatId delegate:self.videoImageView];
    self.videoImageView.hidden = YES;
    self.avatarImageView.hidden = NO;
    MEGALogDebug(@"GROUPCALLCELLVIDEO remove local video");
}

- (void)addLocalVideoInChat:(uint64_t)chatId {
    [[MEGASdkManager sharedMEGAChatSdk] addChatLocalVideo:chatId delegate:self.videoImageView];
    self.videoImageView.hidden = NO;
    self.avatarImageView.hidden = YES;
    MEGALogDebug(@"GROUPCALLCELLVIDEO add local video");
}

- (void)removeRemoteVideoForPeer:(MEGAGroupCallPeer *)peer inChat:(uint64_t)chatId {
    [[MEGASdkManager sharedMEGAChatSdk] removeChatRemoteVideo:chatId peerId:peer.peerId cliendId:peer.clientId delegate:self.videoImageView];
    self.videoImageView.hidden = YES;
    self.avatarImageView.hidden = NO;
    MEGALogDebug(@"GROUPCALLCELLVIDEO remove remote video for peer %llu in client %llu", peer.peerId, peer.clientId);
}

- (void)addRemoteVideoForPeer:(MEGAGroupCallPeer *)peer inChat:(uint64_t)chatId {
    [[MEGASdkManager sharedMEGAChatSdk] addChatRemoteVideo:chatId peerId:peer.peerId cliendId:peer.clientId delegate:self.videoImageView];
    self.videoImageView.hidden = NO;
    self.avatarImageView.hidden = YES;
    MEGALogDebug(@"GROUPCALLCELLVIDEO add remote video for peer %llu in client %llu", peer.peerId, peer.clientId);
}

- (void)configureUserAudio:(BOOL)audio {
    self.userMutedImageView.hidden = audio;
}

- (void)showUserOnFocus {
    self.layer.borderWidth = 2;
    self.layer.borderColor = UIColor.mnz_orangeFFD300.CGColor;
}

- (void)hideUserOnFocus {
    self.layer.borderWidth = 0;
}

@end
