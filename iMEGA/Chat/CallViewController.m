
#import "CallViewController.h"
#import "MEGARemoteImageView.h"
#import "MEGALocalImageView.h"
#import "AVAudioSession+MNZCategory.h"
#import "NSString+MNZCategory.h"
#import "UIApplication+MNZCategory.h"
#import "UIImageView+MNZCategory.h"

#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <MediaPlayer/MediaPlayer.h>

#import "LTHPasscodeViewController.h"

#import "MEGAChatAnswerCallRequestDelegate.h"
#import "MEGAChatEnableDisableVideoRequestDelegate.h"
#import "MEGAChatStartCallRequestDelegate.h"

#import "DevicePermissionsHelper.h"

@interface CallViewController () <UIGestureRecognizerDelegate, MEGAChatRequestDelegate, MEGAChatCallDelegate>

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

@property (weak, nonatomic) IBOutlet UIView *volumeContainerView;
@property (strong, nonatomic) MPVolumeView *mpVolumeView;

@property (weak, nonatomic) IBOutlet UIImageView *remoteMicImageView;
@property (weak, nonatomic) IBOutlet UIButton *minimizeButton;

@property BOOL statusBarShouldBeHidden;

@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, strong) NSDate *baseDate;

@property (strong, nonatomic) AVAudioPlayer *player;

@property NSUUID *currentCallUUID;
@property (assign, nonatomic) NSInteger initDuration;

@property (assign, nonatomic, getter=isSpeakerEnabled) BOOL speakerEnabled;

@end

@implementation CallViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
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
        
        if (self.call.status == MEGAChatCallStatusInProgress) {
            NSTimeInterval interval = ([NSDate date].timeIntervalSince1970 - [NSDate date].timeIntervalSince1970 + self.call.duration);
            self.statusCallLabel.text = [NSString mnz_stringFromTimeInterval:interval];
            [self initShowHideControls];
            [self initDurationTimer];
        } else {
            self.statusCallLabel.text = AMLocalizedString(@"calling...", @"Label shown when you call someone (outgoing call), before the call starts.");
        }
    }
    
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
    
    if (self.callType == CallTypeActive) {
        self.enableDisableVideoButton.selected = [[NSUserDefaults standardUserDefaults] objectForKey:@"oneOnOneCallLocalVideo"] ? [[NSUserDefaults standardUserDefaults] boolForKey:@"oneOnOneCallLocalVideo"] : self.videoCall;
        self.muteUnmuteMicrophone.selected = [[NSUserDefaults standardUserDefaults] objectForKey:@"oneOnOneCallLocalAudio"] ? [[NSUserDefaults standardUserDefaults] boolForKey:@"oneOnOneCallLocalAudio"] : YES;
        
        self.localVideoImageView.hidden = !self.enableDisableVideoButton.selected;
        
        MEGAChatSession *remoteSession = [self.call sessionForPeer:[self.call.sessionsPeerId megaHandleAtIndex:0] clientId:[self.call.sessionsClientId megaHandleAtIndex:0]];
        self.remoteMicImageView.hidden = remoteSession.status == MEGAChatSessionStatusInProgress ? remoteSession.hasAudio : YES;
        self.remoteVideoImageView.hidden = remoteSession.status == MEGAChatSessionStatusInProgress ? !remoteSession.hasVideo : YES;
        
        if (remoteSession.hasVideo) {
            [[MEGASdkManager sharedMEGAChatSdk] addChatRemoteVideo:self.chatRoom.chatId peerId:[self.call.sessionsPeerId megaHandleAtIndex:0] cliendId:[self.call.sessionsClientId megaHandleAtIndex:0] delegate:self.remoteVideoImageView];
            self.remoteAvatarImageView.hidden = YES;
        }
        
        if (self.enableDisableVideoButton.selected) {
            [[MEGASdkManager sharedMEGAChatSdk] addChatLocalVideo:self.chatRoom.chatId delegate:self.localVideoImageView];
            self.remoteAvatarImageView.hidden = YES;
        }
        
        self.localVideoImageView.userInteractionEnabled = remoteSession.hasVideo;
        [self.localVideoImageView remoteVideoEnable:remoteSession.hasVideo];
    } else if (self.videoCall) {
        self.enableDisableVideoButton.selected = self.videoCall;
        
        if (!AVAudioSession.sharedInstance.mnz_isBluetoothAudioConnected) {
            [self enableLoudspeaker];
        }
        
        self.remoteAvatarImageView.hidden = YES;
        self.localVideoImageView.hidden = NO;
        
        [[MEGASdkManager sharedMEGAChatSdk] addChatLocalVideo:self.chatRoom.chatId delegate:self.localVideoImageView];
    } else {
        if (!AVAudioSession.sharedInstance.mnz_isBluetoothAudioConnected) {
            [self disableLoudspeaker];
        }
    }
    
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    
    self.mpVolumeView = [[MPVolumeView alloc] initWithFrame:self.enableDisableSpeaker.bounds];
    self.mpVolumeView.showsVolumeSlider = NO;
    [self.volumeContainerView addSubview:self.mpVolumeView];
    
    [self updateAudioOutputImage];
    
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[MEGASdkManager sharedMEGAChatSdk] removeChatCallDelegate:self];
    
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
    
    MEGAChatSession *remoteSession = [self.call sessionForPeer:[self.call.sessionsPeerId megaHandleAtIndex:0] clientId:[self.call.sessionsClientId megaHandleAtIndex:0]];

    if (viewWillChangeOrientation && self.call.hasLocalVideo && remoteSession.hasVideo) {
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
    dispatch_async(dispatch_get_main_queue(), ^{
        NSDictionary *interuptionDict = notification.userInfo;
        const NSInteger routeChangeReason = [[interuptionDict valueForKey:AVAudioSessionRouteChangeReasonKey] integerValue];
        MEGALogDebug(@"didSessionRouteChange routeChangeReason: %ld, current route outputs %@", (long)routeChangeReason, [[[AVAudioSession sharedInstance] currentRoute] outputs]);
        if (routeChangeReason == AVAudioSessionRouteChangeReasonOverride) {
            if ([AVAudioSession.sharedInstance mnz_isOutputEqualToPortType:AVAudioSessionPortBuiltInSpeaker]) {
                self.speakerEnabled = YES;
            }
            if ([AVAudioSession.sharedInstance mnz_isOutputEqualToPortType:AVAudioSessionPortBuiltInReceiver]) {
                self.speakerEnabled = NO;
            }
        }
        if (routeChangeReason == AVAudioSessionRouteChangeReasonRouteConfigurationChange) {
            if (self.isSpeakerEnabled && self.call.status <= MEGAChatCallStatusInProgress) {
                [self enableLoudspeaker];
            }
        }

        [self updateAudioOutputImage];
    });
}

- (void)didWirelessRoutesAvailableChange:(NSNotification *)notification {
    MPVolumeView* volumeView = (MPVolumeView*)notification.object;
    if (volumeView.areWirelessRoutesAvailable) {
        self.volumeContainerView.hidden = NO;
        self.enableDisableSpeaker.hidden = YES;
    } else {
        self.enableDisableSpeaker.hidden = NO;
        self.volumeContainerView.hidden = YES;
    }
}

- (void)enableLoudspeaker {
    [[AVAudioSession sharedInstance] overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:nil];
}

- (void)disableLoudspeaker {
    self.speakerEnabled = NO;
    [[AVAudioSession sharedInstance] overrideOutputAudioPort:AVAudioSessionPortOverrideNone error:nil];
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
        tapGestureRecognizer.delegate = self;
        [self.view addGestureRecognizer:tapGestureRecognizer];
        
        [self showOrHideControls];
    });
}

- (void)deleteActiveCallFlags {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"oneOnOneCallLocalVideo"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"oneOnOneCallLocalAudio"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)updateAudioOutputImage {
    self.volumeContainerView.hidden = !self.mpVolumeView.areWirelessRoutesAvailable;
    self.enableDisableSpeaker.hidden = !self.volumeContainerView.hidden;
    
    if ([AVAudioSession.sharedInstance mnz_isOutputEqualToPortType:AVAudioSessionPortBuiltInReceiver] || [AVAudioSession.sharedInstance mnz_isOutputEqualToPortType:AVAudioSessionPortHeadphones]) {
        self.enableDisableSpeaker.selected = NO;
        [self.mpVolumeView setRouteButtonImage:[UIImage imageNamed:@"speakerOff"] forState:UIControlStateNormal];
    } else if ([AVAudioSession.sharedInstance mnz_isOutputEqualToPortType:AVAudioSessionPortBuiltInSpeaker]) {
        self.enableDisableSpeaker.selected = YES;
        [self.mpVolumeView setRouteButtonImage:[UIImage imageNamed:@"speakerOn"] forState:UIControlStateNormal];
    } else {
        [self.mpVolumeView setRouteButtonImage:[UIImage imageNamed:@"audioSourceActive"] forState:UIControlStateNormal];
    }
    
    [[UIDevice currentDevice] setProximityMonitoringEnabled:[AVAudioSession.sharedInstance mnz_isOutputEqualToPortType:AVAudioSessionPortBuiltInReceiver]];
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
    if (sender.selected) {
        [[MEGASdkManager sharedMEGAChatSdk] enableAudioForChat:self.chatRoom.chatId];
    } else {
        [[MEGASdkManager sharedMEGAChatSdk] disableAudioForChat:self.chatRoom.chatId];
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
    MEGAChatSession *remoteSession = [self.call sessionForPeer:[self.call.sessionsPeerId megaHandleAtIndex:0] clientId:[self.call.sessionsClientId megaHandleAtIndex:0]];
    if (remoteSession.hasVideo) {
        [[MEGASdkManager sharedMEGAChatSdk] removeChatRemoteVideo:self.chatRoom.chatId peerId:[self.call.sessionsPeerId megaHandleAtIndex:0] cliendId:[self.call.sessionsClientId megaHandleAtIndex:0] delegate:self.remoteVideoImageView];
    }
    
    if (!self.localVideoImageView.hidden) {        
        [[MEGASdkManager sharedMEGAChatSdk] removeChatLocalVideo:self.chatRoom.chatId delegate:self.localVideoImageView];
    }
    
    
    [[NSUserDefaults standardUserDefaults] setBool:!self.localVideoImageView.hidden forKey:@"oneOnOneCallLocalVideo"];
    [[NSUserDefaults standardUserDefaults] setBool:self.muteUnmuteMicrophone.selected forKey:@"oneOnOneCallLocalAudio"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self.timer invalidate];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if (touch.view.class == UIButton.class) {
        return NO;
    }
    
    return YES;
}

#pragma mark - MEGAChatCallDelegate

- (void)onChatCallUpdate:(MEGAChatSdk *)api call:(MEGAChatCall *)call {
    MEGALogDebug(@"onChatCallUpdate %@", call);
    
    if (self.call.callId == call.callId) {
        if (@available(iOS 10.0, *)) {
            if (self.currentCallUUID) {
                call.uuid = self.currentCallUUID;
            }
        }
        self.call = call;
    } else if (self.call.chatId == call.chatId) {
        MEGALogInfo(@"Two calls at same time in same chat.");
        if (@available(iOS 10.0, *)) {
            //Put the same UUID to the call that is going to replace the current one
            if (self.currentCallUUID) {
                call.uuid = self.currentCallUUID;
                [self.megaCallManager addCall:call];
            }
        }
        
        self.call = call;
    } else {
        return;
    }
    
    if ([call hasChangedForType:MEGAChatCallChangeTypeSessionStatus]) {
        MEGAChatSession *remoteSession = [self.call sessionForPeer:self.call.peerSessionStatusChange clientId:self.call.clientSessionStatusChange];

        if (remoteSession.status == MEGAChatSessionStatusInProgress) {
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
    
    if ([call hasChangedForType:MEGAChatCallChangeTypeLocalAVFlags]) {
        self.muteUnmuteMicrophone.selected = !call.hasLocalAudio;
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
            MEGAChatSession *remoteSession = [self.call sessionForPeer:self.call.peerSessionStatusChange clientId:self.call.clientSessionStatusChange];
            
            if ([call hasChangedForType:MEGAChatCallChangeTypeRemoteAVFlags]) {

                self.localVideoImageView.userInteractionEnabled = remoteSession.hasVideo;
                if (remoteSession.hasVideo) {
                    if (self.remoteVideoImageView.hidden) {
                        [[MEGASdkManager sharedMEGAChatSdk] addChatRemoteVideo:self.chatRoom.chatId peerId:[self.call.sessionsPeerId megaHandleAtIndex:0] cliendId:[self.call.sessionsClientId megaHandleAtIndex:0] delegate:self.remoteVideoImageView];
                        self.remoteVideoImageView.hidden = NO;
                        self.remoteAvatarImageView.hidden = YES;
                    }
                } else {
                    if (!self.remoteVideoImageView.hidden) {
                        [[MEGASdkManager sharedMEGAChatSdk] removeChatRemoteVideo:self.chatRoom.chatId peerId:[self.call.sessionsPeerId megaHandleAtIndex:0] cliendId:[self.call.sessionsClientId megaHandleAtIndex:0] delegate:self.remoteVideoImageView];
                        self.remoteVideoImageView.hidden = YES;
                        if (self.localVideoImageView.hidden) {
                            self.remoteAvatarImageView.hidden = UIDevice.currentDevice.iPadDevice ? NO : self.view.frame.size.width > self.view.frame.size.height;
                        }
                        [self.remoteAvatarImageView mnz_setImageForUserHandle:[self.chatRoom peerHandleAtIndex:0]];
                    }
                }
                [self.localVideoImageView remoteVideoEnable:remoteSession.hasVideo];
                self.remoteMicImageView.hidden = remoteSession.hasAudio;
            }
            
            if ([call hasChangedForType:MEGAChatCallChangeTypeSessionStatus]) {
                if (remoteSession.hasVideo && remoteSession.status == MEGAChatSessionStatusDestroyed) {
                    [[MEGASdkManager sharedMEGAChatSdk] removeChatRemoteVideo:self.chatRoom.chatId peerId:[self.call.sessionsPeerId megaHandleAtIndex:0] cliendId:[self.call.sessionsClientId megaHandleAtIndex:0] delegate:self.remoteVideoImageView];
                }
            }
            
            break;
        }
            
        case MEGAChatCallStatusTerminatingUserParticipation:
            if (!self.localVideoImageView.hidden) {
                [[MEGASdkManager sharedMEGAChatSdk] removeChatLocalVideo:self.chatRoom.chatId delegate:self.localVideoImageView];
            }
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
