
#import "MEGAVoiceClipMediaItem.h"

#import <MobileCoreServices/UTCoreTypes.h>

#import "JSQMessagesBubbleImageFactory.h"
#import "JSQMessagesMediaViewBubbleImageMasker.h"

#import "AVAudioSession+MNZCategory.h"
#import "MEGAChatMessage+MNZCategory.h"
#import "MEGANode+MNZCategory.h"
#import "MEGAMessageVoiceClipView.h"
#import "MEGASDKManager.h"
#import "MEGAStartDownloadTransferDelegate.h"
#import "NSString+MNZCategory.h"
#import "MEGA-Swift.h"

NSNotificationName kVoiceClipsShouldPauseNotification = @"kVoiceClipsShouldPauseNotification";

@interface MEGAVoiceClipMediaItem() <MEGAMessageVoiceClipViewDelegate>

@property (copy, nonatomic) MEGAChatMessage *message;
@property (nonatomic) MEGAMessageVoiceClipView *cachedVoiceClipView;
@property (nonatomic) AVPlayer *audioPlayer;
@property (nonatomic, getter=isPlaying) BOOL playing;
@property (nonatomic, getter=shouldStopMonitoring) BOOL stopMonitoring;
@property (nonatomic, getter=shouldRevertSpeaker) BOOL revertSpeaker;

@end

@implementation MEGAVoiceClipMediaItem

#pragma mark - Initialization

- (instancetype)initWithMEGAChatMessage:(MEGAChatMessage *)message {
    if (self = [super init]) {
        _message = message;
    }
    return self;
}

- (void)clearCachedMediaViews {
    [super clearCachedMediaViews];
    self.cachedVoiceClipView = nil;
}

- (BOOL)isContentDiscarded {
    return NO;
}

- (BOOL)beginContentAccess {
    return YES;
}

- (void)discardContentIfPossible {}

- (void)endContentAccess {}

#pragma mark - Setters

- (void)setAppliesMediaViewMaskAsOutgoing:(BOOL)appliesMediaViewMaskAsOutgoing {
    [super setAppliesMediaViewMaskAsOutgoing:appliesMediaViewMaskAsOutgoing];
    self.cachedVoiceClipView = nil;
}

#pragma mark - JSQMessageMediaData protocol

- (UIView *)mediaView {
    if (self.cachedVoiceClipView) {
        return self.cachedVoiceClipView;
    }
    
    MEGAMessageVoiceClipView *voiceClipView = [[NSBundle bundleForClass:MEGAMessageVoiceClipView.class] loadNibNamed:@"MEGAMessageVoiceClipView" owner:self options:nil].firstObject;
    
    // Sizes:
    CGSize voiceClipSize = [self mediaViewDisplaySize];
    voiceClipView.frame = CGRectMake(voiceClipView.frame.origin.x,
                                     voiceClipView.frame.origin.y,
                                     voiceClipSize.width,
                                     voiceClipSize.height);
    
    // Colors:
    if (self.message.userHandle == [MEGASdkManager sharedMEGAChatSdk].myUserHandle) {
        voiceClipView.backgroundColor = [UIColor mnz_chatOutgoingBubble:UIScreen.mainScreen.traitCollection];
        [voiceClipView.playerSlider setThumbImage:[UIImage imageNamed:@"thumbSliderWhite"] forState:UIControlStateNormal];
        voiceClipView.playerSlider.minimumTrackTintColor = UIColor.whiteColor;
        voiceClipView.timeLabel.textColor = UIColor.whiteColor;
    } else {
        voiceClipView.backgroundColor = [UIColor mnz_chatIncomingBubble:UIScreen.mainScreen.traitCollection];
        [voiceClipView.playerSlider setThumbImage:[UIImage imageNamed:@"thumbSliderGreen"] forState:UIControlStateNormal];
        voiceClipView.playerSlider.minimumTrackTintColor = [UIColor mnz_chatOutgoingBubble:UIScreen.mainScreen.traitCollection];
        voiceClipView.timeLabel.textColor = UIColor.mnz_label;
    }
    [self updatePlayAndPauseButtonAppearance];
    
    // Content:
    MEGANode *node = [self.message.nodeList nodeAtIndex:0];
    NSTimeInterval duration = node.duration > 0 ? node.duration : 0;
    voiceClipView.playerSlider.maximumValue = duration;
    voiceClipView.timeLabel.text = [NSString mnz_stringFromTimeInterval:duration];
    voiceClipView.delegate = self;
    
    NSString *nodePath = [node mnz_temporaryPathForDownloadCreatingDirectories:YES];
    if ([NSFileManager.defaultManager fileExistsAtPath:nodePath]) {
        voiceClipView.activityIndicator.hidden = YES;
        voiceClipView.playPauseButton.hidden = NO;
    } else {
        MEGAStartDownloadTransferDelegate *delegate = [[MEGAStartDownloadTransferDelegate alloc] initWithProgress:nil completion:^(MEGATransfer *transfer) {
            voiceClipView.activityIndicator.hidden = YES;
            voiceClipView.playPauseButton.hidden = NO;
        } onError:^(MEGAError *error) {
            self.message.richNumber = @(error.type);
            voiceClipView.activityIndicator.hidden = YES;
            voiceClipView.playPauseButton.hidden = NO;
            voiceClipView.playPauseButton.enabled = NO;
            voiceClipView.playerSlider.enabled = NO;
            voiceClipView.timeLabel.text = @"--:--";
        }];
        [[MEGASdkManager sharedMEGASdk] startDownloadTopPriorityWithNode:node localPath:nodePath appData:nil delegate:delegate];
    }
    
    // Bubble:
    JSQMessagesBubbleImageFactory *bubbleFactory = [[JSQMessagesBubbleImageFactory alloc] initWithBubbleImage:[UIImage imageNamed:@"bubble_tailless"] capInsets:UIEdgeInsetsZero layoutDirection:[UIApplication sharedApplication].userInterfaceLayoutDirection];
    JSQMessagesMediaViewBubbleImageMasker *messageMediaViewBubleImageMasker = [[JSQMessagesMediaViewBubbleImageMasker alloc] initWithBubbleImageFactory:bubbleFactory];
    [messageMediaViewBubleImageMasker applyOutgoingBubbleImageMaskToMediaView:voiceClipView];
    
    self.cachedVoiceClipView = voiceClipView;
    
    return self.cachedVoiceClipView;
}

- (CGSize)mediaViewDisplaySize {
    return CGSizeMake([UIDevice.currentDevice mnz_maxSideForChatBubbleWithMedia:YES], 44.0f);
}

- (NSUInteger)mediaHash {
    return self.hash;
}

- (NSString *)mediaDataType {
    return (NSString *)kUTTypePlainText;
}

- (id)mediaData {
    return AMLocalizedString(@"Voice message", @"Text shown when a notification or the last message of a chat corresponds to a voice clip");
}

#pragma mark - MEGAMessageVoiceClipViewDelegate

- (void)voiceClipViewShouldPlayOrPause:(MEGAMessageVoiceClipView *)voiceClipView {
    self.playing = !self.isPlaying;
    
    NSError *error;
    if (self.isPlaying) {
        if ([AVAudioSession.sharedInstance mnz_isOutputEqualToPortType:AVAudioSessionPortBuiltInReceiver]) {
            self.revertSpeaker = YES;
        }
        
        if (![AVAudioSession.sharedInstance setMode:AVAudioSessionModeDefault error:&error]) {
            MEGALogError(@"[Voice clips] Error setting default mode: %@", error);
        }

        if (![[AVAudioSession sharedInstance] setActive:YES error:&error]) {
            MEGALogError(@"[Voice clips] Error activating audio session: %@", error);
            return;
        }
        
        [AVAudioSession.sharedInstance mnz_setSpeakerEnabled:YES];

        if (!self.audioPlayer) {
            MEGANode *node = [self.message.nodeList nodeAtIndex:0];
            NSString *nodePath = [node mnz_temporaryPathForDownloadCreatingDirectories:YES];
            self.audioPlayer = [[AVPlayer alloc] initWithURL:[NSURL fileURLWithPath:nodePath]];
            if (!self.audioPlayer) {
                MEGALogError(@"[Voice clips] Error initializing audio player for voice clip: %@", error);
                return;
            }
            __weak MEGAVoiceClipMediaItem *weakSelf = self;
            [self.audioPlayer addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(0.04, NSEC_PER_SEC) queue:nil usingBlock:^(CMTime time) {
                weakSelf.cachedVoiceClipView.playerSlider.value = CMTimeGetSeconds(time);
                weakSelf.cachedVoiceClipView.timeLabel.text = [NSString mnz_stringFromTimeInterval:CMTimeGetSeconds(time)];
            }];
            [self.audioPlayer seekToTime:CMTimeMakeWithSeconds(self.cachedVoiceClipView.playerSlider.value, self.audioPlayer.currentTime.timescale)];
            [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(didChangeAudioRoute:) name:AVAudioSessionRouteChangeNotification object:nil];
        }
        
        [NSNotificationCenter.defaultCenter postNotificationName:kVoiceClipsShouldPauseNotification object:self.message];
        [self.audioPlayer play];
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(didPlayToEndTime:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(voiceClipWillPlayOrRecord:) name:kVoiceClipsShouldPauseNotification object:nil];
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(proximityChange:) name:UIDeviceProximityStateDidChangeNotification object:nil];
    } else {
        if (![AVAudioSession.sharedInstance setMode:AVAudioSessionModeVoiceChat error:&error]) {
            MEGALogError(@"[Voice clips] Error setting voice chat mode: %@", error);
        }
        
        [NSNotificationCenter.defaultCenter removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
        [NSNotificationCenter.defaultCenter removeObserver:self name:kVoiceClipsShouldPauseNotification object:nil];
        [NSNotificationCenter.defaultCenter removeObserver:self name:UIDeviceProximityStateDidChangeNotification object:nil];
        [self.audioPlayer pause];
    }
    [self updateUI];
}

- (void)voiceClipView:(MEGAMessageVoiceClipView *)voiceClipView shouldSeekTo:(float)destination {
    [self.audioPlayer seekToTime:CMTimeMakeWithSeconds(destination, self.audioPlayer.currentTime.timescale)];
    self.cachedVoiceClipView.timeLabel.text = [NSString mnz_stringFromTimeInterval:destination];
}

#pragma mark - Private

- (void)updatePlayAndPauseButtonAppearance {
    NSString *playPauseButtonImageName;
    if (self.message.userHandle == MEGASdkManager.sharedMEGAChatSdk.myUserHandle) {
        playPauseButtonImageName = self.isPlaying ? @"outgoing_pauseVoiceClip" : @"outgoing_playVoiceClip";
    } else {
        playPauseButtonImageName = self.isPlaying ? @"pauseVoiceClip" : @"playVoiceClip";
    }
    
    [self.cachedVoiceClipView.playPauseButton setImage:[UIImage imageNamed:playPauseButtonImageName] forState:UIControlStateNormal];
}

- (void)updateUI {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updatePlayAndPauseButtonAppearance];
        if (self.isPlaying) {
            if ([AVAudioSession.sharedInstance mnz_isOutputEqualToPortType:AVAudioSessionPortBuiltInSpeaker]) {
                UIDevice.currentDevice.proximityMonitoringEnabled = YES;
            }
        } else {
            if (!UIDevice.currentDevice.proximityState) {
                UIDevice.currentDevice.proximityMonitoringEnabled = NO;
            }
        }
        
        self.stopMonitoring = !self.isPlaying;
    });
}

#pragma mark - Notifications

- (void)didPlayToEndTime:(NSNotification*)aNotification {
    self.playing = NO;
    [self updateUI];
    
    self.cachedVoiceClipView.playerSlider.value = 0;
    
    MEGANode *node = [self.message.nodeList nodeAtIndex:0];
    NSTimeInterval duration = node.duration > 0 ? node.duration : 0;
    self.cachedVoiceClipView.timeLabel.text = [NSString mnz_stringFromTimeInterval:duration];
    
    self.audioPlayer = nil;
    
    NSError *error;
    if (![AVAudioSession.sharedInstance setMode:AVAudioSessionModeVoiceChat error:&error]) {
        MEGALogError(@"[Voice clips] Error setting voice chat mode: %@", error);
    }
    
    [NSNotificationCenter.defaultCenter removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    [NSNotificationCenter.defaultCenter removeObserver:self name:AVAudioSessionRouteChangeNotification object:nil];
    [NSNotificationCenter.defaultCenter removeObserver:self name:UIDeviceProximityStateDidChangeNotification object:nil];
    
    if (MEGASdkManager.sharedMEGAChatSdk.mnz_existsActiveCall) {
        if (self.shouldRevertSpeaker) {
            [AVAudioSession.sharedInstance mnz_setSpeakerEnabled:NO];
            self.revertSpeaker = NO;
        }
    } else {
        if (![[AVAudioSession sharedInstance] setActive:NO withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:&error]) {
            MEGALogError(@"[Voice clips] Error deactivating audio session: %@", error);
        }
    }
}

- (void)didChangeAudioRoute:(NSNotification*)aNotification {
    if ((self.audioPlayer.timeControlStatus == AVPlayerTimeControlStatusPlaying && !self.isPlaying) || (self.audioPlayer.timeControlStatus == AVPlayerTimeControlStatusPaused && self.isPlaying)) {
        self.playing = !self.isPlaying;
        [self updateUI];
    }
}

- (void)proximityChange:(NSNotification*)aNotification {
    if (!UIDevice.currentDevice.proximityState && self.shouldStopMonitoring) {
        UIDevice.currentDevice.proximityMonitoringEnabled = NO;
        return;
    }
    
    if (![AVAudioSession.sharedInstance mnz_isOutputEqualToPortType:AVAudioSessionPortBuiltInReceiver] && ![AVAudioSession.sharedInstance mnz_isOutputEqualToPortType:AVAudioSessionPortBuiltInSpeaker]) {
        return;
    }
    
    if (UIDevice.currentDevice.proximityState) {
        [AVAudioSession.sharedInstance overrideOutputAudioPort:AVAudioSessionPortOverrideNone error:nil];
    } else {
        [AVAudioSession.sharedInstance overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:nil];
    }
}

- (void)voiceClipWillPlayOrRecord:(NSNotification*)aNotification {
    if (!self.isPlaying) {
        return;
    }
    
    MEGAChatMessage *message = aNotification.object;
    NSNumber *deletedNumber = [aNotification.userInfo objectForKey:@"deleted"];
    BOOL deleted = deletedNumber ? deletedNumber.boolValue : NO;
    if (message && message.chatId == self.message.chatId && message.messageId == self.message.messageId) {
        if (deleted) {
            [self voiceClipViewShouldPlayOrPause:self.cachedVoiceClipView];
        }
    } else {
        if (!deleted) {
            [self voiceClipViewShouldPlayOrPause:self.cachedVoiceClipView];
        }
    }
}

#pragma mark - NSObject

- (NSUInteger)hash {
    MEGANode *node = [self.message.nodeList nodeAtIndex:0];
    return super.hash ^ (NSUInteger)node.handle;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: message=%@>", [self class], self.message];
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        _message = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(message))];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:self.message forKey:NSStringFromSelector(@selector(message))];
}

#pragma mark - NSCopying

- (instancetype)copyWithZone:(NSZone *)zone {
    MEGAVoiceClipMediaItem *copy = [[MEGAVoiceClipMediaItem allocWithZone:zone] initWithMEGAChatMessage:self.message];
    copy.appliesMediaViewMaskAsOutgoing = self.appliesMediaViewMaskAsOutgoing;
    return copy;
}

@end
