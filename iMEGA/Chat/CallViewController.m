
#import "CallViewController.h"
#import "MEGARemoteImageView.h"
#import "MEGALocalImageView.h"
#import "NSString+MNZCategory.h"
#import "UIApplication+MNZCategory.h"
#import "UIImageView+MNZCategory.h"

#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <MediaPlayer/MediaPlayer.h>

#import "LTHPasscodeViewController.h"

#import "MEGAChatAnswerCallRequestDelegate.h"
#import "MEGAChatEnableDisableAudioRequestDelegate.h"
#import "MEGAChatEnableDisableVideoRequestDelegate.h"
#import "MEGAChatStartCallRequestDelegate.h"

#import "DevicePermissionsHelper.h"

@interface CallViewController () <MEGAChatRequestDelegate, MEGAChatCallDelegate>

@property (weak, nonatomic) IBOutlet MEGARemoteImageView *remoteVideoImageView;
@property (weak, nonatomic) IBOutlet MEGALocalImageView *localVideoImageView;
@property (weak, nonatomic) IBOutlet UIImageView *remoteAvatarImageView;

@property (weak, nonatomic) IBOutlet UIButton *enableDisableVideoButton;
@property (weak, nonatomic) IBOutlet UIButton *muteUnmuteMicrophone;
@property (weak, nonatomic) IBOutlet UIButton *enableDisableSpeaker;

@property (weak, nonatomic) IBOutlet UIView *outgoingCallView;
@property (weak, nonatomic) IBOutlet UIView *incomingCallView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *statusCallLabel;
@property (weak, nonatomic) IBOutlet UIView *volumeView;

@property (weak, nonatomic) IBOutlet UIImageView *remoteMicImageView;
@property (weak, nonatomic) IBOutlet UIButton *minimizeButton;

@property BOOL loudSpeakerEnabled;
@property BOOL statusBarShouldBeHidden;

@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, strong) NSDate *baseDate;

@property (strong, nonatomic) AVAudioPlayer *player;

@property NSUUID *currentCallUUID;
@property (assign, nonatomic) NSInteger initDuration;

@end

@implementation CallViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.enableDisableVideoButton.selected = self.videoCall;
    self.enableDisableSpeaker.selected = self.videoCall;
    if (self.videoCall) {
        [self enableLoudspeaker];
        self.remoteAvatarImageView.hidden = YES;
        self.localVideoImageView.hidden = NO;
    } else {
        [self disableLoudspeaker];
    }
    self.loudSpeakerEnabled = self.videoCall;
    _statusBarShouldBeHidden = NO;
    
    [self.remoteAvatarImageView mnz_setImageForUserHandle:[self.chatRoom peerHandleAtIndex:0]];
    
    self.localVideoImageView.transform = CGAffineTransformMakeScale(-1, 1); //Flipped horizontally

    self.localVideoImageView.layer.masksToBounds = YES;
    self.localVideoImageView.layer.cornerRadius = 4;
    self.localVideoImageView.corner = CornerTopRight;
    self.localVideoImageView.userInteractionEnabled = self.call.hasVideoInitialCall;
    
    if (self.callType == CallTypeIncoming) {
        self.outgoingCallView.hidden = YES;
        if (@available(iOS 10.0, *)) {
            [self acceptCall:nil];
        } else {
            self.call = [[MEGASdkManager sharedMEGAChatSdk] chatCallForChatId:self.chatRoom.chatId];
            self.statusCallLabel.text = AMLocalizedString(@"Incoming call", nil);
        }
    } else if (self.callType == CallTypeOutgoing) {
        MEGAChatStartCallRequestDelegate *startCallRequestDelegate = [[MEGAChatStartCallRequestDelegate alloc] initWithCompletion:^(MEGAChatError *error) {
            if (error.type) {
                [self dismissViewControllerAnimated:YES completion:nil];
            } else {
                self.call = [[MEGASdkManager sharedMEGAChatSdk] chatCallForChatId:self.chatRoom.chatId];
                self.incomingCallView.hidden = YES;

                self.statusCallLabel.text = AMLocalizedString(@"calling...", @"Label shown when you call someone (outgoing call), before the call starts.");
                
                if (@available(iOS 10.0, *)) {
                    NSUUID *uuid = [[NSUUID alloc] init];
                    self.call.uuid = uuid;
                    self.currentCallUUID = uuid;
                    [self.megaCallManager addCall:self.call];
                    
                    uint64_t peerHandle = [self.chatRoom peerHandleAtIndex:0];
                    NSString *peerEmail = [self.chatRoom peerEmailByHandle:peerHandle];
                    [self.megaCallManager startCall:self.call email:peerEmail];
                }
            }
        }];
        
        [[MEGASdkManager sharedMEGAChatSdk] startChatCall:self.chatRoom.chatId enableVideo:self.videoCall delegate:startCallRequestDelegate];
    } else {
        self.call = [[MEGASdkManager sharedMEGAChatSdk] chatCallForChatId:self.chatRoom.chatId];
        self.incomingCallView.hidden = YES;
        self.outgoingCallView.hidden = NO;
        
        NSTimeInterval interval = ([NSDate date].timeIntervalSince1970 - [NSDate date].timeIntervalSince1970 + self.call.duration);
        self.statusCallLabel.text = [NSString mnz_stringFromTimeInterval:interval];

        [self initShowHideControls];
        [self initDurationTimer];
        
    }
    
    [[UIDevice currentDevice] setProximityMonitoringEnabled:!self.videoCall];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didSessionRouteChange:) name:AVAudioSessionRouteChangeNotification object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(didWirelessRoutesAvailableChange:) name:MPVolumeViewWirelessRoutesAvailableDidChangeNotification object:nil];
    
    self.nameLabel.text = [self.chatRoom peerFullnameAtIndex:0];
    
    if (@available(iOS 10.0, *)) {} else {
        NSString *soundFilePath = [[NSBundle mainBundle] pathForResource:@"incoming_voice_video_call" ofType:@"mp3"];
        NSURL *soundFileURL = [NSURL fileURLWithPath:soundFilePath];
        
        _player = [[AVAudioPlayer alloc] initWithContentsOfURL:soundFileURL error:nil];
        self.player.numberOfLoops = -1; //Infinite
        
        [self.player play];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[MEGASdkManager sharedMEGAChatSdk] addChatCallDelegate:self];
    
    if (self.videoCall) {
        [[MEGASdkManager sharedMEGAChatSdk] addChatRemoteVideo:self.chatRoom.chatId peerId:[self.chatRoom peerHandleAtIndex:0] delegate:self.remoteVideoImageView];
        [[MEGASdkManager sharedMEGAChatSdk] addChatLocalVideo:self.chatRoom.chatId delegate:self.localVideoImageView];
    } else if (self.callType == CallTypeActive) {
        self.enableDisableVideoButton.selected = [[NSUserDefaults standardUserDefaults] objectForKey:@"oneOnOneCallLocalVideo"] ? [[NSUserDefaults standardUserDefaults] boolForKey:@"oneOnOneCallLocalVideo"] : self.videoCall;
        self.muteUnmuteMicrophone.selected = [[NSUserDefaults standardUserDefaults] objectForKey:@"oneOnOneCallLocalAudio"] ? [[NSUserDefaults standardUserDefaults] boolForKey:@"oneOnOneCallLocalAudio"] : YES;
        self.enableDisableSpeaker.selected = [[NSUserDefaults standardUserDefaults] objectForKey:@"oneOnOneCallSpeaker"] ? [[NSUserDefaults standardUserDefaults] boolForKey:@"oneOnOneCallSpeaker"] : self.videoCall;
        
        self.localVideoImageView.hidden = !self.enableDisableVideoButton.selected;
        
        if (self.enableDisableSpeaker.selected) {
            [self enableLoudspeaker];
        } else {
            [self disableLoudspeaker];
        }
        
        MEGAChatSession *session = [self.call sessionForPeer:[self.chatRoom peerHandleAtIndex:0]];
        self.remoteMicImageView.hidden = session.hasAudio;
        self.remoteVideoImageView.hidden = !session.hasVideo;
        
        if (session.hasVideo) {
            [[MEGASdkManager sharedMEGAChatSdk] addChatRemoteVideo:self.chatRoom.chatId peerId:[self.chatRoom peerHandleAtIndex:0] delegate:self.remoteVideoImageView];
            self.remoteAvatarImageView.hidden = YES;
        }
        
        if (self.enableDisableVideoButton.selected) {
            [[MEGASdkManager sharedMEGAChatSdk] addChatLocalVideo:self.chatRoom.chatId delegate:self.localVideoImageView];
            self.remoteAvatarImageView.hidden = YES;
        }
        
        self.localVideoImageView.userInteractionEnabled = session.hasVideo;
        [self.localVideoImageView remoteVideoEnable:session.hasVideo];
    }
    
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    
    MPVolumeView *volumeView = [[MPVolumeView alloc] initWithFrame:self.enableDisableSpeaker.bounds];
    volumeView.showsVolumeSlider = NO;
    [volumeView setRouteButtonImage:[UIImage imageNamed:@"audioSourceActive"] forState:UIControlStateNormal];
    [self.volumeView addSubview:volumeView];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[MEGASdkManager sharedMEGAChatSdk] removeChatCallDelegate:self];
    [[MEGASdkManager sharedMEGAChatSdk] removeChatRemoteVideo:self.chatRoom.chatId peerId:[self.chatRoom peerHandleAtIndex:0] delegate:self.remoteVideoImageView];
    [[MEGASdkManager sharedMEGAChatSdk] removeChatLocalVideo:self.chatRoom.chatId delegate:self.localVideoImageView];
    
    [[UIDevice currentDevice] setProximityMonitoringEnabled:NO];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {    
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    BOOL viewWillChangeOrientation = (size.height != self.view.bounds.size.height);
    
    if (self.remoteVideoImageView.hidden && self.localVideoImageView.hidden) {
        self.remoteAvatarImageView.hidden = UIDevice.currentDevice.iPadDevice ? NO : size.width > size.height;
    }
    
    MEGAChatSession *chatSession = [self.call sessionForPeer:[self.chatRoom peerHandleAtIndex:0]];
    if (viewWillChangeOrientation && self.call.hasLocalVideo && chatSession.hasVideo) {
        [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
            [self.localVideoImageView rotate];
        } completion:nil];
    }
}

#pragma mark - Status bar

- (BOOL)prefersStatusBarHidden {
    return self.statusBarShouldBeHidden;
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation {
    return UIStatusBarAnimationFade;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

#pragma mark - Public

- (void)tapOnVideoCallkitWhenDeviceIsLocked {
    self.enableDisableVideoButton.selected = NO;
    [self enableDisableVideo:self.enableDisableVideoButton];
}

#pragma mark - Private

- (void)didSessionRouteChange:(NSNotification *)notification {
    NSDictionary *interuptionDict = notification.userInfo;
    const NSInteger routeChangeReason = [[interuptionDict valueForKey:AVAudioSessionRouteChangeReasonKey] integerValue];
    
    if (routeChangeReason == AVAudioSessionRouteChangeReasonRouteConfigurationChange) {
        if (self.loudSpeakerEnabled) {
            [self enableLoudspeaker];
        }
        else {
            [self disableLoudspeaker];
        }
    }
}

- (void)didWirelessRoutesAvailableChange:(NSNotification *)notification {
    MPVolumeView* volumeView = (MPVolumeView*)notification.object;
    if (volumeView.areWirelessRoutesAvailable) {
        self.volumeView.hidden = NO;
        self.enableDisableSpeaker.hidden = YES;
    } else {
        self.enableDisableSpeaker.hidden = NO;
        self.volumeView.hidden = YES;
    }
}

- (void)enableLoudspeaker {
    self.loudSpeakerEnabled = TRUE;
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    AVAudioSessionCategoryOptions options = audioSession.categoryOptions;
    if (options & AVAudioSessionCategoryOptionDefaultToSpeaker) return;
    options |= AVAudioSessionCategoryOptionDefaultToSpeaker;
    [audioSession setActive:YES error:nil];
    [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:options error:nil];
}

- (void)disableLoudspeaker {
    self.loudSpeakerEnabled = FALSE;
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    AVAudioSessionCategoryOptions options = audioSession.categoryOptions;
    if (options & AVAudioSessionCategoryOptionDefaultToSpeaker) {
        options &= ~AVAudioSessionCategoryOptionDefaultToSpeaker;
        [audioSession setActive:YES error:nil];
        [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:options error:nil];
    }
}

- (void)updateDuration {
    NSTimeInterval interval = ([NSDate date].timeIntervalSince1970 - self.baseDate.timeIntervalSince1970 + self.initDuration);
    self.statusCallLabel.text = [NSString mnz_stringFromTimeInterval:interval];
}

- (void)showOrHideControls {
    [UIView animateWithDuration:0.3f animations:^{
        if (self.outgoingCallView.alpha != 1.0f) {
            [self.outgoingCallView setAlpha:1.0f];
            [self.nameLabel setAlpha:1.0f];
            self.statusBarShouldBeHidden = NO;
            [UIView animateWithDuration:0.25 animations:^{
                [self setNeedsStatusBarAppearanceUpdate];
            }];
            self.localVideoImageView.visibleControls = YES;
            self.minimizeButton.hidden = NO;
        } else {
            [self.outgoingCallView setAlpha:0.0f];
            self.statusBarShouldBeHidden = YES;
            [UIView animateWithDuration:0.25 animations:^{
                [self setNeedsStatusBarAppearanceUpdate];
            }];
            [self.nameLabel setAlpha:0.0f];
            self.localVideoImageView.visibleControls = NO;
            self.minimizeButton.hidden = YES;
        }
         
        [self.view layoutIfNeeded];
    }];
}

- (void)enablePasscodeIfNeeded {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"presentPasscodeLater"] && [LTHPasscodeViewController doesPasscodeExist]) {
        [[LTHPasscodeViewController sharedUser] showLockScreenOver:UIApplication.mnz_presentingViewController.view
                                                     withAnimation:YES
                                                        withLogout:NO
                                                    andLogoutTitle:nil];
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"presentPasscodeLater"];
    }
    [[LTHPasscodeViewController sharedUser] enablePasscodeWhenApplicationEntersBackground];
}

- (void)initDurationTimer {
    self.initDuration = (NSInteger)self.call.duration;
    self.timer = [NSTimer timerWithTimeInterval:1.0f target:self selector:@selector(updateDuration) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
    self.baseDate = [NSDate date];
}

- (void)initShowHideControls {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        //Add Tap to hide/show controls
        UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showOrHideControls)];
        tapGestureRecognizer.numberOfTapsRequired = 1;
        tapGestureRecognizer.cancelsTouchesInView = NO;        
        [self.view addGestureRecognizer:tapGestureRecognizer];
        
        [self showOrHideControls];
    });
}

- (void)deleteActiveCallFlags {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"oneOnOneCallLocalVideo"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"oneOnOneCallLocalAudio"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"oneOnOneCallSpeaker"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)configureLocalControls {
}

#pragma mark - IBActions

- (IBAction)acceptCallWithVideo:(UIButton *)sender {
    MEGAChatAnswerCallRequestDelegate *answerCallRequestDelegate = [[MEGAChatAnswerCallRequestDelegate alloc] initWithCompletion:^(MEGAChatError *error) {
        if (error.type == MEGAChatErrorTypeOk) {
            [[MEGASdkManager sharedMEGAChatSdk] addChatLocalVideo:self.chatRoom.chatId delegate:self.localVideoImageView];
            self.enableDisableVideoButton.selected = YES;
        } else {
            [self dismissViewControllerAnimated:YES completion:nil];
        }
    }];
    [[MEGASdkManager sharedMEGAChatSdk] answerChatCall:self.chatRoom.chatId enableVideo:YES delegate:answerCallRequestDelegate];
}

- (IBAction)acceptCall:(UIButton *)sender {
    MEGAChatAnswerCallRequestDelegate *answerCallRequestDelegate = [[MEGAChatAnswerCallRequestDelegate alloc] initWithCompletion:^(MEGAChatError *error) {
        if (error.type != MEGAChatErrorTypeOk) {
            [self dismissViewControllerAnimated:YES completion:nil];
        } else {
            self.incomingCallView.hidden = YES;
            self.outgoingCallView.hidden = NO;
        }
    }];
    [[MEGASdkManager sharedMEGAChatSdk] answerChatCall:self.chatRoom.chatId enableVideo:self.videoCall delegate:answerCallRequestDelegate];
}

- (IBAction)hangCall:(UIButton *)sender {
    if (@available(iOS 10.0, *)) {
        [self.megaCallManager endCall:self.call];
    } else {
        [[MEGASdkManager sharedMEGAChatSdk] hangChatCall:self.chatRoom.chatId];
    }
}

- (IBAction)muteOrUnmuteCall:(UIButton *)sender {
    MEGAChatEnableDisableAudioRequestDelegate *enableDisableAudioRequestDelegate = [[MEGAChatEnableDisableAudioRequestDelegate alloc] initWithCompletion:^(MEGAChatError *error) {
        if (error.type == MEGAChatErrorTypeOk) {
            sender.selected = !sender.selected;
        }
    }];
    
    if (sender.selected) {
        [[MEGASdkManager sharedMEGAChatSdk] enableAudioForChat:self.chatRoom.chatId delegate:enableDisableAudioRequestDelegate];
    } else {
        [[MEGASdkManager sharedMEGAChatSdk] disableAudioForChat:self.chatRoom.chatId delegate:enableDisableAudioRequestDelegate];
    }
}

- (IBAction)enableDisableVideo:(UIButton *)sender {
    __weak CallViewController *weakSelf = self;
    [DevicePermissionsHelper videoPermissionWithCompletionHandler:^(BOOL granted) {
        if (granted) {
            MEGAChatEnableDisableVideoRequestDelegate *enableDisableVideoRequestDelegate = [[MEGAChatEnableDisableVideoRequestDelegate alloc] initWithCompletion:^(MEGAChatError *error) {
                if (error.type == MEGAChatErrorTypeOk) {
                    if (sender.selected) {
                        self.localVideoImageView.hidden = YES;
                        [[MEGASdkManager sharedMEGAChatSdk] removeChatLocalVideo:self.chatRoom.chatId delegate:self.localVideoImageView];
                        if (self.remoteVideoImageView.hidden) {
                            self.remoteAvatarImageView.hidden = UIDevice.currentDevice.iPadDevice ? NO : self.view.frame.size.width > self.view.frame.size.height;
                        }
                    } else {
                        self.remoteAvatarImageView.hidden = YES;
                        self.localVideoImageView.hidden = NO;
                        [[MEGASdkManager sharedMEGAChatSdk] addChatLocalVideo:self.chatRoom.chatId delegate:self.localVideoImageView];
                    }
                    sender.selected = !sender.selected;
                    self.loudSpeakerEnabled = sender.selected;
                }
            }];
            if (sender.selected) {
                [[MEGASdkManager sharedMEGAChatSdk] disableVideoForChat:self.chatRoom.chatId delegate:enableDisableVideoRequestDelegate];
            } else {
                [[MEGASdkManager sharedMEGAChatSdk] enableVideoForChat:self.chatRoom.chatId delegate:enableDisableVideoRequestDelegate];
            }
        } else {
            [DevicePermissionsHelper alertVideoPermissionWithCompletionHandler:^{
                [weakSelf hangCall:nil];
            }];
        }
    }];
}

- (IBAction)enableDisableSpeaker:(UIButton *)sender {
    if (sender.selected) {
        [self disableLoudspeaker];
    } else {
        [self enableLoudspeaker];
    }
    sender.selected = !sender.selected;
}

- (IBAction)hideCall:(UIButton *)sender {
    [[NSUserDefaults standardUserDefaults] setBool:!self.localVideoImageView.hidden forKey:@"oneOnOneCallLocalVideo"];
    [[NSUserDefaults standardUserDefaults] setBool:self.muteUnmuteMicrophone.selected forKey:@"oneOnOneCallLocalAudio"];
    [[NSUserDefaults standardUserDefaults] setBool:self.enableDisableSpeaker.selected forKey:@"oneOnOneCallSpeaker"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self.timer invalidate];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - MEGAChatCallDelegate

- (void)onChatCallUpdate:(MEGAChatSdk *)api call:(MEGAChatCall *)call {
    MEGALogDebug(@"onChatCallUpdate %@", call);
    
    if (self.call.callId == call.callId) {
        self.call = call;
    } else if (self.call.chatId == call.chatId) {
        MEGALogInfo(@"Two calls at same time in same chat.");
        if (@available(iOS 10.0, *)) {
            //Put the same UUID to the call that is going to replace the current one
            call.uuid = self.currentCallUUID;
            [self.megaCallManager addCall:call];
        }
        
        self.call = call;
    } else {
        return;
    }
    
    if ([call hasChangedForType:MEGAChatCallChangeTypeSessionStatus]) {
        MEGAChatSession *chatSession = [self.call sessionForPeer:[self.call peerSessionStatusChange]];

        if (chatSession.status == MEGAChatSessionStatusInProgress) {
            if (!self.timer.isValid) {
                [self.player stop];
                
                _timer = [NSTimer timerWithTimeInterval:1.0f target:self selector:@selector(updateDuration) userInfo:nil repeats:YES];
                [[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
                _baseDate = [NSDate date];
                [self initShowHideControls];
            }
        } else {
            self.statusCallLabel.text = AMLocalizedString(@"connecting", nil);
        }
    }

    switch (call.status) {
        case MEGAChatCallStatusInitial:
            break;
            
        case MEGAChatCallStatusHasLocalStream:
            break;
            
        case MEGAChatCallStatusRequestSent:
            break;
            
        case MEGAChatCallStatusRingIn:
            break;
            
        case MEGAChatCallStatusJoining:
            break;
            
        case MEGAChatCallStatusInProgress: {
            self.outgoingCallView.hidden = NO;
            self.incomingCallView.hidden = YES;
            
            if ([call hasChangedForType:MEGAChatCallChangeTypeRemoteAVFlags]) {
                MEGAChatSession *chatSession = [self.call sessionForPeer:[self.call peerSessionStatusChange]];
                self.localVideoImageView.userInteractionEnabled = chatSession.hasVideo;
                if (chatSession.hasVideo) {
                    if (self.remoteVideoImageView.hidden) {
                        [[MEGASdkManager sharedMEGAChatSdk] addChatRemoteVideo:self.chatRoom.chatId peerId:[self.chatRoom peerHandleAtIndex:0] delegate:self.remoteVideoImageView];
                        self.remoteVideoImageView.hidden = NO;
                        self.remoteAvatarImageView.hidden = YES;
                    }
                } else {
                    if (!self.remoteVideoImageView.hidden) {
                        [[MEGASdkManager sharedMEGAChatSdk] removeChatRemoteVideo:self.chatRoom.chatId peerId:[self.chatRoom peerHandleAtIndex:0] delegate:self.remoteVideoImageView];
                        self.remoteVideoImageView.hidden = YES;
                        if (self.localVideoImageView.hidden) {
                            self.remoteAvatarImageView.hidden = UIDevice.currentDevice.iPadDevice ? NO : self.view.frame.size.width > self.view.frame.size.height;
                        }
                        [self.remoteAvatarImageView mnz_setImageForUserHandle:[self.chatRoom peerHandleAtIndex:0]];
                    }
                }
                [self.localVideoImageView remoteVideoEnable:chatSession.hasVideo];
                self.remoteMicImageView.hidden = chatSession.hasAudio;
            }
            break;
        }
            
        case MEGAChatCallStatusTerminatingUserParticipation:
            break;
            
        case MEGAChatCallStatusDestroyed: {
            if (call.termCode == MEGAChatCallTermCodeDestroyByCallCollision) {
                MEGALogInfo(@"Two calls at same time in same chat. Outgoing call associated with the lower user handle has ended.");
                [self.player stop];
                return;
            }
            
            [self deleteActiveCallFlags];
            
            self.incomingCallView.userInteractionEnabled = NO;
            
            [self.timer invalidate];
            
            [self.player stop];
            
            NSString *soundFilePath = [[NSBundle mainBundle] pathForResource:@"hang_out" ofType:@"mp3"];
            NSURL *soundFileURL = [NSURL fileURLWithPath:soundFilePath];
            self.player = [[AVAudioPlayer alloc] initWithContentsOfURL:soundFileURL error:nil];
            
            [self.player play];
            
            [self dismissViewControllerAnimated:YES completion:^{
                [self enablePasscodeIfNeeded];
            }];
            break;
        }
            
        default:
            break;
    }
}

@end
