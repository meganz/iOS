
#import "GroupCallCollectionViewCell.h"

#import "UIImageView+MNZCategory.h"

#import "MEGASdkManager.h"

#import "MEGAGroupCallPeer.h"

@interface GroupCallCollectionViewCell ()

@property (weak, nonatomic) IBOutlet UIImageView *avatarImageView;
@property (weak, nonatomic) IBOutlet UIImageView *userMutedImageView;
@property (weak, nonatomic) IBOutlet UIView *lowQualityView;

@property (strong, nonatomic) MEGAGroupCallPeer *peer;

@end

@implementation GroupCallCollectionViewCell

#pragma mark - Public

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.videoImageView.group = YES;
}

- (void)configureCellForPeer:(MEGAGroupCallPeer *)peer inChat:(uint64_t)chatId numParticipants:(NSInteger)numParticipants {
    
    if (self.peer && peer.peerId != self.peer.peerId && !self.videoImageView.hidden) {
        if (self.peer.peerId == 0) {
            [self removeLocalVideoInChat:chatId];
        } else {
            [self removeRemoteVideoForPeer:self.peer inChat:chatId];
        }
    }
    
    self.peer = peer;
    
    if (self.peer.peerId == 0) {
        [self.avatarImageView mnz_setImageForUserHandle:[MEGASdkManager sharedMEGAChatSdk].myUserHandle];
        if (self.peer.video == CallPeerVideoOn) {
            if (self.videoImageView.hidden) {
                [self addLocalVideoInChat:chatId];
            }
        } else {
            if (self.peer.video == CallPeerVideoOff && !self.videoImageView.hidden) {
                [self removeLocalVideoInChat:chatId];
            }
        }
    } else {
        [self.avatarImageView mnz_setImageForUserHandle:self.peer.peerId name:self.peer.name];
        if (self.peer.video == CallPeerVideoOn) {
            if (self.videoImageView.hidden) {
                [self addRemoteVideoForPeer:self.peer inChat:chatId];
            }
        } else {
            if (self.peer.video == CallPeerVideoOff && !self.videoImageView.hidden) {
                [self removeRemoteVideoForPeer:self.peer inChat:chatId];
            }
        }
    }
    
    [self configureUserAudio:self.peer.audio];
    
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
    if (self.peer.peerId == peer.peerId) {
        self.peer = peer;
        if (self.peer.networkQuality < 2) {
            self.lowQualityView.hidden = NO;
        } else {
            self.lowQualityView.hidden = YES;
        }
    }
}

- (void)removeLocalVideoInChat:(uint64_t)chatId {
    [[MEGASdkManager sharedMEGAChatSdk] removeChatLocalVideo:chatId delegate:self.videoImageView];
    self.videoImageView.hidden = YES;
    self.avatarImageView.hidden = NO;
    MEGALogDebug(@"[Group Call] Remove local video %p", self.videoImageView);
}

- (void)addLocalVideoInChat:(uint64_t)chatId {
    [[MEGASdkManager sharedMEGAChatSdk] addChatLocalVideo:chatId delegate:self.videoImageView];
    self.videoImageView.hidden = NO;
    self.videoImageView.transform = CGAffineTransformMakeScale(-1, 1);
    self.avatarImageView.hidden = YES;
    MEGALogDebug(@"[Group Call] Add local video %p", self.videoImageView);
}

- (void)removeRemoteVideoForPeer:(MEGAGroupCallPeer *)peer inChat:(uint64_t)chatId {
    [[MEGASdkManager sharedMEGAChatSdk] removeChatRemoteVideo:chatId peerId:peer.peerId cliendId:peer.clientId delegate:self.videoImageView];
    self.videoImageView.hidden = YES;
    self.avatarImageView.hidden = NO;
    MEGALogDebug(@"[Group Call] Remove remote video %p for peer %llu in client %llu", self.videoImageView, peer.peerId, peer.clientId);
}

- (void)addRemoteVideoForPeer:(MEGAGroupCallPeer *)peer inChat:(uint64_t)chatId {
    [[MEGASdkManager sharedMEGAChatSdk] addChatRemoteVideo:chatId peerId:peer.peerId cliendId:peer.clientId delegate:self.videoImageView];
    self.videoImageView.hidden = NO;
    self.videoImageView.transform = CGAffineTransformMakeScale(1, 1);
    self.avatarImageView.hidden = YES;
    MEGALogDebug(@"[Group Call] Add remote video %p for peer %llu in client %llu", self.videoImageView, peer.peerId, peer.clientId);
}

- (void)configureUserAudio:(CallPeerAudio)audio {
    self.userMutedImageView.hidden = audio != CallPeerAudioOff;
}

- (void)showUserOnFocus {
    self.layer.borderWidth = 2;
    self.layer.borderColor = UIColor.systemYellowColor.CGColor;
}

- (void)hideUserOnFocus {
    self.layer.borderWidth = 0;
}

- (void)localVideoMirror:(BOOL)mirror {
    self.videoImageView.transform = mirror ? CGAffineTransformMakeScale(-1, 1) : CGAffineTransformMakeScale(1, 1);
}

@end
