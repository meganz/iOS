
#import "CallViewController.h"

#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <MediaPlayer/MediaPlayer.h>

#import "LTHPasscodeViewController.h"

#import "MEGALocalImageView.h"
#import "MEGARemoteImageView.h"
#import "AVAudioSession+MNZCategory.h"
#import "NSString+MNZCategory.h"
#import "UIApplication+MNZCategory.h"
#import "UIImageView+MNZCategory.h"

#import "MEGAChatAnswerCallRequestDelegate.h"
#import "MEGAChatEnableDisableVideoRequestDelegate.h"
#import "MEGAChatStartCallRequestDelegate.h"

#import "DevicePermissionsHelper.h"
#import "MEGA-Swift.h"

@interface CallViewController () <UIGestureRecognizerDelegate, MEGAChatRequestDelegate, MEGAChatCallDelegate>

@property (nonatomic, strong) MEGAChatCall *call;

@property (weak, nonatomic) IBOutlet MEGARemoteImageView *remoteVideoImageView;
@property (weak, nonatomic) IBOutlet MEGALocalImageView *localVideoImageView;
@property (weak, nonatomic) IBOutlet UIImageView *remoteAvatarImageView;

@property (weak, nonatomic) IBOutlet UIButton *enableDisableVideoButton;
@property (weak, nonatomic) IBOutlet UIButton *muteUnmuteMicrophone;
@property (weak, nonatomic) IBOutlet UIButton *enableDisableSpeaker;
@property (weak, nonatomic) IBOutlet UIButton *switchCameraButton;

@property (weak, nonatomic) IBOutlet UIView *callControlsView;
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

@property (assign, nonatomic) NSInteger initDuration;

@property (assign, nonatomic, getter=isSpeakerEnabled) BOOL speakerEnabled;

@property (assign, nonatomic, getter=isReconnecting) BOOL reconnecting;

@property (nonatomic) NSString *backCamera;
@property (nonatomic) NSString *frontCamera;

@end

@implementation CallViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.frontCamera = [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInWideAngleCamera mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionFront].localizedName;
    self.backCamera = [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInWideAngleCamera mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionBack].localizedName;
    
    _statusBarShouldBeHidden = NO;
    
    [self.remoteAvatarImageView mnz_setImageForUserHandle:[self.chatRoom peerHandleAtIndex:0]];
    
    self.localVideoImageView.transform = CGAffineTransformMakeScale(-1, 1); //Flipped horizontally

    self.localVideoImageView.layer.masksToBounds = YES;
    self.localVideoImageView.layer.cornerRadius = 4;
    self.localVideoImageView.corner = CornerTopRight;
    
    if (self.callType == CallTypeIncoming) {
        self.call = [MEGASdkManager.sharedMEGAChatSdk chatCallForCallId:self.callId];
        [self answerChatCall];
    } else if (self.callType == CallTypeOutgoing) {
        MEGAChatStartCallRequestDelegate *startCallRequestDelegate = [[MEGAChatStartCallRequestDelegate alloc] initWithCompletion:^(MEGAChatError *error) {
            if (error.type) {
                [self dismissViewControllerAnimated:YES completion:nil];
            } else {
                self.call = [[MEGASdkManager sharedMEGAChatSdk] chatCallForChatId:self.chatRoom.chatId];
                self.callId = self.call.callId;

                self.statusCallLabel.text = AMLocalizedString(@"calling...", @"Label shown when you call someone (outgoing call), before the call starts.");
                [self.megaCallManager addCall:self.call];
                [self.megaCallManager startCall:self.call];
            }
        }];
        
        [[MEGASdkManager sharedMEGAChatSdk] startChatCall:self.chatRoom.chatId enableVideo:self.videoCall delegate:startCallRequestDelegate];
    } else {
        self.call = [[MEGASdkManager sharedMEGAChatSdk] chatCallForChatId:self.chatRoom.chatId];
        self.callId = self.call.callId;
        
        if (self.call.status == MEGAChatCallStatusInProgress) {
            NSTimeInterval interval = ([NSDate date].timeIntervalSince1970 - [NSDate date].timeIntervalSince1970 + self.call.duration);
            self.statusCallLabel.text = [NSString mnz_stringFromTimeInterval:interval];
            [self initShowHideControls];
            [self initDurationTimer];
        } else {
            self.statusCallLabel.text = AMLocalizedString(@"calling...", @"Label shown when you call someone (outgoing call), before the call starts.");
        }
    }
    
    self.localVideoImageView.userInteractionEnabled = self.call.hasVideoInitialCall;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didSessionRouteChange:) name:AVAudioSessionRouteChangeNotification object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(didWirelessRoutesAvailableChange:) name:MPVolumeViewWirelessRoutesAvailableDidChangeNotification object:nil];
    
    uint64_t peerHandle = [self.chatRoom peerHandleAtIndex:0];
    NSString *displayName = [self.chatRoom userDisplayNameForUserHandle:peerHandle];
    if (displayName) {
        self.nameLabel.text = displayName;
    } else {
        MEGAChatGenericRequestDelegate *delegate = [[MEGAChatGenericRequestDelegate alloc] initWithCompletion:^(MEGAChatRequest * _Nonnull request, MEGAChatError * _Nonnull error) {
            if (error.type) {
                return;
            }
            self.chatRoom = [MEGASdkManager.sharedMEGAChatSdk chatRoomForChatId:self.chatRoom.chatId];
            self.nameLabel.text = [self.chatRoom userDisplayNameForUserHandle:peerHandle];
        }];
        [MEGASdkManager.sharedMEGAChatSdk loadUserAttributesForChatId:self.chatRoom.chatId usersHandles:@[@(peerHandle)] delegate:delegate];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[MEGASdkManager sharedMEGAChatSdk] addChatCallDelegate:self];
    
    if (self.callType == CallTypeActive) {
        self.enableDisableVideoButton.selected = [[NSUserDefaults standardUserDefaults] objectForKey:@"oneOnOneCallLocalVideo"] ? [[NSUserDefaults standardUserDefaults] boolForKey:@"oneOnOneCallLocalVideo"] : self.videoCall;
        self.muteUnmuteMicrophone.selected = [[NSUserDefaults standardUserDefaults] objectForKey:@"oneOnOneCallLocalAudio"] ? [[NSUserDefaults standardUserDefaults] boolForKey:@"oneOnOneCallLocalAudio"] : YES;
        self.switchCameraButton.selected = [[NSUserDefaults standardUserDefaults] objectForKey:@"oneOnOneCallCameraSwitched"] ? [[NSUserDefaults standardUserDefaults] boolForKey:@"oneOnOneCallCameraSwitched"] : NO;

        self.localVideoImageView.hidden = !self.enableDisableVideoButton.selected;
        
        MEGAChatSession *remoteSession = [self.call sessionForPeer:[self.call.sessionsPeerId megaHandleAtIndex:0] clientId:[self.call.sessionsClientId megaHandleAtIndex:0]];
        self.remoteMicImageView.hidden = remoteSession.status == MEGAChatSessionStatusInProgress ? remoteSession.hasAudio : YES;
        self.remoteVideoImageView.hidden = remoteSession.status == MEGAChatSessionStatusInProgress ? !remoteSession.hasVideo : YES;
        
        if (remoteSession.hasVideo) {
            [[MEGASdkManager sharedMEGAChatSdk] addChatRemoteVideo:self.chatRoom.chatId peerId:remoteSession.peerId cliendId:remoteSession.clientId delegate:self.remoteVideoImageView];
            self.remoteAvatarImageView.hidden = YES;
        }
        
        if (self.enableDisableVideoButton.selected) {
            [[MEGASdkManager sharedMEGAChatSdk] addChatLocalVideo:self.chatRoom.chatId delegate:self.localVideoImageView];
            self.remoteAvatarImageView.hidden = YES;
        }
        
        self.localVideoImageView.userInteractionEnabled = remoteSession.hasVideo;
        [self.localVideoImageView remoteVideoEnable:remoteSession.hasVideo];
    } else if (self.videoCall) {
        if (self.callType == CallTypeOutgoing) {
            self.enableDisableVideoButton.selected = YES;
            self.localVideoImageView.hidden = NO;
        }
        
        if (!AVAudioSession.sharedInstance.mnz_isBluetoothAudioRouteAvailable) {
            MEGALogDebug(@"[Audio] Enable loud speaker is video call and there is no bluetooth connected");
            [self enableLoudspeaker];
        }
        
        self.remoteAvatarImageView.hidden = YES;
        
        [[MEGASdkManager sharedMEGAChatSdk] addChatLocalVideo:self.chatRoom.chatId delegate:self.localVideoImageView];
    } else {
        if (!AVAudioSession.sharedInstance.mnz_isBluetoothAudioRouteAvailable) {
            MEGALogDebug(@"[Audio] Disable loud speaker is not a video call and there is no bluetooth connected");
            [self disableLoudspeaker];
        }
    }
    
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    
    self.mpVolumeView = [[MPVolumeView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 60.0f, 60.0f)];
    self.mpVolumeView.showsVolumeSlider = NO;
    [self.volumeContainerView addSubview:self.mpVolumeView];
    
    [self updateAudioOutputImage];
    
    self.switchCameraButton.hidden = !self.enableDisableVideoButton.selected;
    [self updateSelectedCamera];
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

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    
    if (@available(iOS 13.0, *)) {
        if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
            [self updateAppearance];
        }
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
    MEGALogDebug(@"[Audio] Enable loud speaker, tap on video callkit icon when device is locked");
    [self enableLoudspeaker];
}

#pragma mark - Private

- (void)updateAppearance {
    self.nameLabel.textColor = self.statusCallLabel.textColor = UIColor.whiteColor;
}

- (void)answerChatCall {
    if ([MEGASdkManager.sharedMEGAChatSdk chatConnectionState:self.chatRoom.chatId] == MEGAChatConnectionOnline) {
        MEGAChatAnswerCallRequestDelegate *answerCallRequestDelegate = [MEGAChatAnswerCallRequestDelegate.alloc initWithCompletion:^(MEGAChatError *error) {
            if (error.type != MEGAChatErrorTypeOk) {
                [self dismissViewControllerAnimated:YES completion:nil];
            }
        }];
        [MEGASdkManager.sharedMEGAChatSdk answerChatCall:self.chatRoom.chatId enableVideo:NO delegate:answerCallRequestDelegate];
    } else {
        self.enableDisableVideoButton.enabled = self.minimizeButton.enabled = NO;
        self.statusCallLabel.text = AMLocalizedString(@"connecting", @"Label in login screen to inform about the chat initialization proccess");
    }
}

- (void)didSessionRouteChange:(NSNotification *)notification {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSDictionary *interuptionDict = notification.userInfo;
        const AVAudioSessionRouteChangeReason routeChangeReason = [[interuptionDict valueForKey:AVAudioSessionRouteChangeReasonKey] integerValue];
        MEGALogDebug(@"[Audio] Did session route changed, reason: %@, current route outputs %@", [AVAudioSession.sharedInstance stringForAVAudioSessionRouteChangeReason:routeChangeReason], [[[AVAudioSession sharedInstance] currentRoute] outputs]);
        if (routeChangeReason == AVAudioSessionRouteChangeReasonOverride) {
            if ([AVAudioSession.sharedInstance mnz_isOutputEqualToPortType:AVAudioSessionPortBuiltInReceiver]) {
                if (self.isSpeakerEnabled) {
                    MEGALogDebug(@"[Audio] Enable loud speaker, override to built in receiver, but speaker was enabled");
                    [self enableLoudspeaker];
                }
            }
        }
        if (routeChangeReason == AVAudioSessionRouteChangeReasonCategoryChange) {
            if (self.isSpeakerEnabled && (self.call.status <= MEGAChatCallStatusInProgress || self.call.status == MEGAChatCallStatusReconnecting)) {
                MEGALogDebug(@"[Audio] Enable loud speaker, category changed, but speaker was enabled");
                [self enableLoudspeaker];
            }
        }

        [self updateAudioOutputImage];
    });
}

- (void)didWirelessRoutesAvailableChange:(NSNotification *)notification {
    if (AVAudioSession.sharedInstance.mnz_isBluetoothAudioRouteAvailable) {
        self.volumeContainerView.hidden = NO;
        self.enableDisableSpeaker.hidden = YES;
    } else {
        self.enableDisableSpeaker.hidden = NO;
        self.volumeContainerView.hidden = YES;
    }
}

- (void)enableLoudspeaker {
    self.speakerEnabled = YES;
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
        if (self.callControlsView.alpha != 1.0f) {
            [self.callControlsView setAlpha:1.0f];
            [self.nameLabel setAlpha:1.0f];
            self.statusBarShouldBeHidden = NO;
            [UIView animateWithDuration:0.25 animations:^{
                [self setNeedsStatusBarAppearanceUpdate];
            }];
            self.localVideoImageView.visibleControls = YES;
            self.minimizeButton.hidden = NO;
        } else {
            [self.callControlsView setAlpha:0.0f];
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
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"oneOnOneCallCameraSwitched"];
    
    if (@available(iOS 12.0, *)) {} else {
        [NSUserDefaults.standardUserDefaults synchronize];
    }
}

- (void)updateAudioOutputImage {
    if (AVAudioSession.sharedInstance.mnz_isBluetoothAudioRouteAvailable) {
        self.volumeContainerView.hidden = NO;
        self.enableDisableSpeaker.hidden = YES;
    } else {
        self.enableDisableSpeaker.hidden = NO;
        self.volumeContainerView.hidden = YES;
    }
    
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

- (void)updateSelectedCamera {
    NSString *currentlySelected = [MEGASdkManager.sharedMEGAChatSdk videoDeviceSelected];
    NSString *shouldBeSelected = self.switchCameraButton.selected ? self.backCamera : self.frontCamera;
    if (![currentlySelected isEqualToString:shouldBeSelected]) {
        [MEGASdkManager.sharedMEGAChatSdk setChatVideoInDevices:shouldBeSelected];
    }
    
    self.localVideoImageView.transform = self.switchCameraButton.selected ? CGAffineTransformMakeScale(1, 1) : CGAffineTransformMakeScale(-1, 1);
}

#pragma mark - IBActions

- (IBAction)hangCall:(UIButton *)sender {
    [self.megaCallManager endCallWithCallId:self.callId chatId:self.chatRoom.chatId];
    [MEGASdkManager.sharedMEGAChatSdk hangChatCall:self.chatRoom.chatId];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)muteOrUnmuteCall:(UIButton *)sender {
    if (sender.selected) {
        [self.megaCallManager muteUnmuteCallWithCallId:self.callId chatId:self.chatRoom.chatId muted:NO];
    } else {
        [self.megaCallManager muteUnmuteCallWithCallId:self.callId chatId:self.chatRoom.chatId muted:YES];
    }
    self.muteUnmuteMicrophone.selected = !sender.selected;
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
                        [self updateSelectedCamera];
                    }
                    sender.selected = !sender.selected;
                    self.switchCameraButton.hidden = !sender.selected;
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
    MEGALogDebug(@"[Audio] %@ button speaker tapped", sender.selected ? @"Disable" : @"Enable");
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
        [[MEGASdkManager sharedMEGAChatSdk] removeChatRemoteVideo:self.chatRoom.chatId peerId:remoteSession.peerId cliendId:remoteSession.clientId delegate:self.remoteVideoImageView];
    }
    
    if (!self.localVideoImageView.hidden) {        
        [[MEGASdkManager sharedMEGAChatSdk] removeChatLocalVideo:self.chatRoom.chatId delegate:self.localVideoImageView];
    }
    
    
    [[NSUserDefaults standardUserDefaults] setBool:!self.localVideoImageView.hidden forKey:@"oneOnOneCallLocalVideo"];
    [[NSUserDefaults standardUserDefaults] setBool:self.muteUnmuteMicrophone.selected forKey:@"oneOnOneCallLocalAudio"];
    [[NSUserDefaults standardUserDefaults] setBool:self.switchCameraButton.selected forKey:@"oneOnOneCallCameraSwitched"];
    if (@available(iOS 12.0, *)) {} else {
        [NSUserDefaults.standardUserDefaults synchronize];
    }
    
    [self.timer invalidate];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)switchCamera:(UIButton *)sender {
    sender.selected = !sender.selected;
    [self updateSelectedCamera];
}


#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if (touch.view.class == UIButton.class) {
        return NO;
    }
    
    return YES;
}

#pragma mark - MEGAChatCallDelegate

- (void)onChatSessionUpdate:(MEGAChatSdk *)api chatId:(uint64_t)chatId callId:(uint64_t)callId session:(MEGAChatSession *)session {
    MEGALogDebug(@"onChatSessionUpdate %@", session);

    if (self.callId != callId) {
        return;
    }
    
    if ([session hasChanged:MEGAChatSessionChangeStatus]) {

        switch (session.status) {
            case MEGAChatSessionStatusInProgress: {
                if (!self.timer.isValid) {
                    [self.player stop];
                    [self initShowHideControls];
                    [self initDurationTimer];
                    self.enableDisableVideoButton.enabled = self.minimizeButton.enabled = YES;
                }
                break;
            }
                
            case MEGAChatSessionStatusInitial:
                if (self.isReconnecting) {
                    self.reconnecting = NO;
                    self.statusCallLabel.text = AMLocalizedString(@"You are back!", @"Title shown when the user reconnect in a call.");
                } else {
                    self.statusCallLabel.text = AMLocalizedString(@"connecting", nil);
                }

            case MEGAChatSessionStatusDestroyed:
                if (session.hasVideo) {
                    [MEGASdkManager.sharedMEGAChatSdk removeChatRemoteVideo:self.chatRoom.chatId peerId:session.peerId cliendId:session.clientId delegate:self.remoteVideoImageView];
                    self.remoteVideoImageView.hidden = YES;
                }
                break;
                
            default:
                break;
        }
    }
    
    if ([session hasChanged:MEGAChatSessionChangeRemoteAvFlags]) {

        self.localVideoImageView.userInteractionEnabled = session.hasVideo;
        if (session.hasVideo) {
            if (self.remoteVideoImageView.hidden) {
                [MEGASdkManager.sharedMEGAChatSdk addChatRemoteVideo:self.chatRoom.chatId peerId:session.peerId cliendId:session.clientId delegate:self.remoteVideoImageView];
                self.remoteVideoImageView.hidden = NO;
                self.remoteAvatarImageView.hidden = YES;
            }
        } else {
            if (!self.remoteVideoImageView.hidden) {
                [[MEGASdkManager sharedMEGAChatSdk] removeChatRemoteVideo:self.chatRoom.chatId peerId:session.peerId cliendId:session.clientId delegate:self.remoteVideoImageView];
                self.remoteVideoImageView.hidden = YES;
                if (self.localVideoImageView.hidden) {
                    self.remoteAvatarImageView.hidden = UIDevice.currentDevice.iPadDevice ? NO : self.view.frame.size.width > self.view.frame.size.height;
                }
                [self.remoteAvatarImageView mnz_setImageForUserHandle:[self.chatRoom peerHandleAtIndex:0]];
            }
        }
        [self.localVideoImageView remoteVideoEnable:session.hasVideo];
        self.remoteMicImageView.hidden = session.hasAudio;
    }
}

- (void)onChatCallUpdate:(MEGAChatSdk *)api call:(MEGAChatCall *)call {
    MEGALogDebug(@"onChatCallUpdate %@", call);
    
    if (self.callId == call.callId) {
        self.call = call;
    } else if (self.call.chatId == call.chatId) {
        MEGALogInfo(@"Two calls at same time in same chat.");
        self.call = call;
    } else {
        return;
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
            
        case MEGAChatCallStatusInProgress:
            break;
            
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
            
        case MEGAChatCallStatusReconnecting:
            [self.timer invalidate];
            self.reconnecting = YES;
            self.statusCallLabel.text = AMLocalizedString(@"Reconnecting...", @"Title shown when the user lost the connection in a call, and the app will try to reconnect the user again");
            break;
        
        default:
            break;
    }
}

@end
