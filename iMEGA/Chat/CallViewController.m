
#import "CallViewController.h"
#import "MEGARemoteImageView.h"
#import "MEGALocalImageView.h"
#import "NSString+MNZCategory.h"
#import "UIImageView+MNZCategory.h"

#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>

#import "MEGAChatAnswerCallRequestDelegate.h"
#import "MEGAChatEnableDisableAudioRequestDelegate.h"
#import "MEGAChatEnableDisableVideoRequestDelegate.h"
#import "MEGAChatStartCallRequestDelegate.h"

#import "DevicePermissionsHelper.h"

@interface CallViewController () <MEGAChatRequestDelegate, MEGAChatCallDelegate, MEGAChatVideoDelegate>

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

@property (weak, nonatomic) IBOutlet UIImageView *remoteMicImageView;

@property BOOL loudSpeakerEnabled;
@property BOOL statusBarShouldBeHidden;

@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, strong) NSDate *baseDate;

@property (strong, nonatomic) AVAudioPlayer *player;

@end

@implementation CallViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
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
    self.localVideoImageView.userInteractionEnabled = self.call.hasRemoteVideo;
    
    if (self.callType == CallTypeIncoming) {
        self.outgoingCallView.hidden = YES;
        if (@available(iOS 10.0, *)) {
            [self acceptCall:nil];
        } else {
            _call = [[MEGASdkManager sharedMEGAChatSdk] chatCallForChatId:self.chatRoom.chatId];
            self.statusCallLabel.text = AMLocalizedString(@"calling...", @"Label shown when you receive an incoming call, before start the call.");
        }
    } else {
        MEGAChatStartCallRequestDelegate *startCallRequestDelegate = [[MEGAChatStartCallRequestDelegate alloc] initWithCompletion:^(MEGAChatError *error) {
            if (error.type) {
                [self dismissViewControllerAnimated:YES completion:nil];
            } else {
                _call = [[MEGASdkManager sharedMEGAChatSdk] chatCallForChatId:self.chatRoom.chatId];
                self.incomingCallView.hidden = YES;

                self.statusCallLabel.text = AMLocalizedString(@"calling...", @"Label shown when you receive an incoming call, before start the call.");
                
                if (@available(iOS 10.0, *)) {
                    NSUUID *uuid = [[NSUUID alloc] init];
                    self.call.uuid = uuid;
                    [self.megaCallManager addCall:self.call];
                    
                    uint64_t peerHandle = [self.chatRoom peerHandleAtIndex:0];
                    NSString *peerEmail = [self.chatRoom peerEmailByHandle:peerHandle];
                    [self.megaCallManager startCall:self.call email:peerEmail];
                }
            }
        }];
        
        [[MEGASdkManager sharedMEGAChatSdk] startChatCall:self.chatRoom.chatId enableVideo:self.videoCall delegate:startCallRequestDelegate];
    }
    
    [[UIDevice currentDevice] setProximityMonitoringEnabled:!self.videoCall];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didSessionRouteChange:) name:AVAudioSessionRouteChangeNotification object:nil];
    
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
        [[MEGASdkManager sharedMEGAChatSdk] addChatRemoteVideoDelegate:self.remoteVideoImageView];
        [[MEGASdkManager sharedMEGAChatSdk] addChatLocalVideoDelegate:self.localVideoImageView];
    }
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[MEGASdkManager sharedMEGAChatSdk] removeChatCallDelegate:self];
    [[MEGASdkManager sharedMEGAChatSdk] removeChatRemoteVideoDelegate:self.remoteVideoImageView];
    [[MEGASdkManager sharedMEGAChatSdk] removeChatLocalVideoDelegate:self.localVideoImageView];
    
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
        self.remoteAvatarImageView.hidden = (size.width > size.height);
    }
    
    if (viewWillChangeOrientation && self.call.hasLocalVideo && self.call.hasRemoteVideo) {
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

- (void)updateLabel {
    NSTimeInterval interval = ([NSDate date].timeIntervalSince1970 - self.baseDate.timeIntervalSince1970);
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
        } else {
            [self.outgoingCallView setAlpha:0.0f];
            self.statusBarShouldBeHidden = YES;
            [UIView animateWithDuration:0.25 animations:^{
                [self setNeedsStatusBarAppearanceUpdate];
            }];
            [self.nameLabel setAlpha:0.0f];
            self.localVideoImageView.visibleControls = NO;
        }
         
        [self.view layoutIfNeeded];
    }];
}

- (UIAlertController *)videoPermisionHangCallAlertController {
    UIAlertController *permissionsAlertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"attention", @"Alert title to attract attention") message:AMLocalizedString(@"cameraPermissions", @"Alert message to remember that MEGA app needs permission to use the Camera to take a photo or video and it doesn't have it") preferredStyle:UIAlertControllerStyleAlert];
    [permissionsAlertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"cancel", @"Button title to cancel something") style:UIAlertActionStyleCancel handler:nil]];
    __weak __typeof(self) weakSelf = self;
    [permissionsAlertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"ok", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [weakSelf hangCall:nil];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
    }]];
    return permissionsAlertController;
}

#pragma mark - IBActions

- (IBAction)acceptCallWithVideo:(UIButton *)sender {
    MEGAChatAnswerCallRequestDelegate *answerCallRequestDelegate = [[MEGAChatAnswerCallRequestDelegate alloc] initWithCompletion:^(MEGAChatError *error) {
        if (error.type == MEGAChatErrorTypeOk) {
            [[MEGASdkManager sharedMEGAChatSdk] addChatLocalVideoDelegate:self.localVideoImageView];            
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
    [DevicePermissionsHelper videoPermissionWithCompletionHandler:^(BOOL granted) {
        if (granted) {
            MEGAChatEnableDisableVideoRequestDelegate *enableDisableVideoRequestDelegate = [[MEGAChatEnableDisableVideoRequestDelegate alloc] initWithCompletion:^(MEGAChatError *error) {
                if (error.type == MEGAChatErrorTypeOk) {
                    if (sender.selected) {
                        self.localVideoImageView.hidden = YES;
                        [[MEGASdkManager sharedMEGAChatSdk] removeChatLocalVideoDelegate:self.localVideoImageView];
                        if (self.remoteVideoImageView.hidden) {
                            self.remoteAvatarImageView.hidden = self.view.frame.size.width > self.view.frame.size.height;
                        }
                    } else {
                        self.remoteAvatarImageView.hidden = YES;
                        self.localVideoImageView.hidden = NO;
                        [[MEGASdkManager sharedMEGAChatSdk] addChatLocalVideoDelegate:self.localVideoImageView];
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
            [self presentViewController:[self videoPermisionHangCallAlertController] animated:YES completion:nil];
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


#pragma mark - MEGAChatCallDelegate

- (void)onChatCallUpdate:(MEGAChatSdk *)api call:(MEGAChatCall *)call {
    MEGALogDebug(@"onChatCallUpdate %@", call);
    
    if (self.call.callId == call.callId) {
        self.call = call;
    } else {
        return;
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
            if (!self.timer.isValid) {
                [self.player stop];
                
                _timer = [NSTimer timerWithTimeInterval:1.0f target:self selector:@selector(updateLabel) userInfo:nil repeats:YES];
                [[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
                _baseDate = [NSDate date];
                
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    //Add Tap to hide/show controls
                    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showOrHideControls)];
                    [tapGestureRecognizer setNumberOfTapsRequired:1];
                    [self.view addGestureRecognizer:tapGestureRecognizer];
                    
                    [self showOrHideControls];
                });

            }
            self.outgoingCallView.hidden = NO;
            self.incomingCallView.hidden = YES;
            
            if ([call hasChangedForType:MEGAChatCallChangeTypeRemoteAVFlags]) {
                self.localVideoImageView.userInteractionEnabled = call.hasRemoteVideo;
                if (call.hasRemoteVideo) {
                    if (self.remoteVideoImageView.hidden) {
                        [[MEGASdkManager sharedMEGAChatSdk] addChatRemoteVideoDelegate:self.remoteVideoImageView];
                        self.remoteVideoImageView.hidden = NO;
                        self.remoteAvatarImageView.hidden = YES;
                    }
                } else {
                    if (!self.remoteVideoImageView.hidden) {
                        [[MEGASdkManager sharedMEGAChatSdk] removeChatRemoteVideoDelegate:self.remoteVideoImageView];
                        self.remoteVideoImageView.hidden = YES;
                        if (self.localVideoImageView.hidden) {
                            self.remoteAvatarImageView.hidden = self.view.frame.size.width > self.view.frame.size.height;
                        }
                        [self.remoteAvatarImageView mnz_setImageForUserHandle:[self.chatRoom peerHandleAtIndex:0]];
                    }
                }
                [self.localVideoImageView remoteVideoEnable:call.remoteVideo];
                self.remoteMicImageView.hidden = call.hasRemoteAudio;
            }
            break;
        }
            
        case MEGAChatCallStatusTerminating:
            break;
            
        case MEGAChatCallStatusDestroyed: {
            self.incomingCallView.userInteractionEnabled = NO;
            
            [self.timer invalidate];
            
            [self.player stop];
            
            NSString *soundFilePath = [[NSBundle mainBundle] pathForResource:@"hang_out" ofType:@"mp3"];
            NSURL *soundFileURL = [NSURL fileURLWithPath:soundFilePath];
            self.player = [[AVAudioPlayer alloc] initWithContentsOfURL:soundFileURL error:nil];
            
            [self.player play];
            
            [self dismissViewControllerAnimated:YES completion:nil];
            break;
        }
            
        default:
            break;
    }
}

@end
