
#import "GroupCallCollectionViewCell.h"

#import "UIImageView+MNZCategory.h"

#import "MEGASdkManager.h"

#import "MEGAGroupCallPeer.h"

@implementation GroupCallCollectionViewCell

#pragma mark - Public

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.videoImageView.group = YES;
}

- (void)configureCellForPeer:(MEGAGroupCallPeer *)peer inChat:(uint64_t)chatId {
    
    if (peer.peerId == 0) {
        self.tag = 1;
        [self.avatarImageView mnz_setImageForUserHandle:[MEGASdkManager sharedMEGAChatSdk].myUserHandle];
        if (peer.video) {
            if (self.videoImageView.hidden) {
                [[MEGASdkManager sharedMEGAChatSdk] addChatLocalVideo:chatId delegate:self.videoImageView];
                self.videoImageView.hidden = NO;
                self.avatarImageView.hidden = YES;
            }
        } else {
            if (self.avatarImageView.hidden) {
                [[MEGASdkManager sharedMEGAChatSdk] removeChatLocalVideo:chatId delegate:self.videoImageView];
                self.videoImageView.hidden = YES;
                self.avatarImageView.hidden = NO;
            }
        }
    } else {
        self.tag = 0;
        [self.avatarImageView mnz_setImageForUserHandle:peer.peerId];
        if (peer.video) {
            if (self.videoImageView.hidden) {
                [[MEGASdkManager sharedMEGAChatSdk] addChatRemoteVideo:chatId peerId:peer.peerId delegate:self.videoImageView];
                self.videoImageView.hidden = NO;
                self.avatarImageView.hidden = YES;
            }
        } else {
            if (self.avatarImageView.hidden) {
                [[MEGASdkManager sharedMEGAChatSdk] removeChatRemoteVideo:chatId peerId:peer.peerId delegate:self.videoImageView];
                self.videoImageView.hidden = YES;
                self.avatarImageView.hidden = NO;
            }
        }
    }
    
    self.userMutedImageView.hidden = peer.audio;
}

- (void)networkQualityChangedForPeer:(MEGAGroupCallPeer *)peer reducedLayout:(BOOL)reduced {
    if (peer.networkQuality < 2) {
        [self showLowQualityViewForReducedLayout:reduced];
    } else {
        [self hideLowQualityView];
    }
}

#pragma mark - Private

- (void)showLowQualityViewForReducedLayout:(BOOL)reduced {
    if (reduced) {
        self.lowQualityView.hidden = NO;
    } else {
        self.layer.borderWidth = 2;
        self.layer.borderColor = [[UIColor colorWithRed:1 green:0.83 blue:0 alpha:1] CGColor];
    }
}

- (void)hideLowQualityView {
    self.lowQualityView.hidden = YES;
    self.contentView.layer.borderWidth = 0;
}

@end
