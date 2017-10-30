
#import "CallViewController.h"
#import "MEGARemoteImageView.h"
#import "MEGALocalImageView.h"

#import "UIImageView+MNZCategory.h"

#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>

@interface CallViewController () <MEGAChatRequestDelegate, MEGAChatCallDelegate, MEGAChatVideoDelegate>

@property (weak, nonatomic) IBOutlet MEGARemoteImageView *remoteVideoImageView;
@property (weak, nonatomic) IBOutlet MEGALocalImageView *localVideoImageView;

@property (weak, nonatomic) IBOutlet UIButton *enableDisableVideoButton;
@property (weak, nonatomic) IBOutlet UIButton *muteUnmuteMicrophone;

@property (weak, nonatomic) IBOutlet UIView *outgoingCallView;
@property (weak, nonatomic) IBOutlet UIView *incomingCallView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;

@property BOOL loudSpeakerEnabled;

@end

@implementation CallViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.enableDisableVideoButton.selected = self.videoCall;
    self.loudSpeakerEnabled = self.videoCall;
    
    [self.remoteVideoImageView mnz_setImageForUserHandle:[self.chatRoom peerHandleAtIndex:0]];
    
    if (self.callType == CallTypeIncoming) {
        self.outgoingCallView.hidden = YES;
    } else {
        [[MEGASdkManager sharedMEGAChatSdk] startChatCall:self.chatRoom.chatId enableVideo:self.videoCall delegate:self];
        self.incomingCallView.hidden = YES;

        [[UIDevice currentDevice] setProximityMonitoringEnabled:YES];
        
        // These observers should be removed when the call finishes
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didSessionRouteChange:) name:AVAudioSessionRouteChangeNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sensorStateMonitor:) name:@"UIDeviceProximityStateDidChangeNotification" object:nil];
    }
    
    self.nameLabel.text = [self.chatRoom peerFullnameAtIndex:0];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[MEGASdkManager sharedMEGAChatSdk] addChatCallDelegate:self];
    if (self.videoCall) {
        [[MEGASdkManager sharedMEGAChatSdk] addChatRemoteVideoDelegate:self.remoteVideoImageView];
        [[MEGASdkManager sharedMEGAChatSdk] addChatLocalVideoDelegate:self.localVideoImageView];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[MEGASdkManager sharedMEGAChatSdk] removeChatCallDelegate:self];
    [[MEGASdkManager sharedMEGAChatSdk] removeChatRemoteVideoDelegate:self.remoteVideoImageView];
    [[MEGASdkManager sharedMEGAChatSdk] removeChatLocalVideoDelegate:self.localVideoImageView];
}

#pragma mark - Private

- (void)sensorStateMonitor:(NSNotificationCenter *)notification
{
    if (!self.videoCall)
    {
        return;
    }
    
    if ([[UIDevice currentDevice] proximityState] == YES)
    {
        [self disableLoudspeaker];
    }
    
    else
    {
        [self enableLoudspeaker];
    }
}

- (void)didSessionRouteChange:(NSNotification *)notification
{
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
- (IBAction)acceptCallWithVideo:(UIButton *)sender {
    [[MEGASdkManager sharedMEGAChatSdk] answerChatCall:self.chatRoom.chatId enableVideo:YES delegate:self];
    [[MEGASdkManager sharedMEGAChatSdk] addChatLocalVideoDelegate:self.localVideoImageView];
}

- (IBAction)acceptCall:(UIButton *)sender {
    [[MEGASdkManager sharedMEGAChatSdk] answerChatCall:self.chatRoom.chatId enableVideo:NO delegate:self];
}

- (IBAction)hangCall:(UIButton *)sender {
    [[MEGASdkManager sharedMEGAChatSdk] hangChatCall:self.chatRoom.chatId delegate:self];
}

- (IBAction)muteCall:(UIButton *)sender {
    if (sender.selected) {
        [[MEGASdkManager sharedMEGAChatSdk] enableAudioForChat:self.chatRoom.chatId delegate:self];
    } else {
        [[MEGASdkManager sharedMEGAChatSdk] disableAudioForChat:self.chatRoom.chatId delegate:self];
    }
    sender.selected = !sender.selected;
}

- (IBAction)enableDisableVideo:(UIButton *)sender {
    if (sender.selected) {
        [[MEGASdkManager sharedMEGAChatSdk] disableVideoForChat:self.chatRoom.chatId delegate:self];
        self.localVideoImageView.hidden = YES;
        [[MEGASdkManager sharedMEGAChatSdk] removeChatLocalVideoDelegate:self.localVideoImageView];
    } else {
        [[MEGASdkManager sharedMEGAChatSdk] enableVideoForChat:self.chatRoom.chatId delegate:self];
        self.localVideoImageView.hidden = NO;
        [[MEGASdkManager sharedMEGAChatSdk] addChatLocalVideoDelegate:self.localVideoImageView];
    }
    sender.selected = !sender.selected;
}

#pragma mark - MEGAChatCallDelegate

- (void)onChatCallUpdate:(MEGAChatSdk *)api call:(MEGAChatCall *)call {
    MEGALogDebug(@"onChatCallUpdate %@", call);
    
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
                if (call.hasRemoteVideo) {                    
                    [[MEGASdkManager sharedMEGAChatSdk] addChatRemoteVideoDelegate:self.remoteVideoImageView];
                } else {
                    [[MEGASdkManager sharedMEGAChatSdk] removeChatRemoteVideoDelegate:self.remoteVideoImageView];
                    [self.remoteVideoImageView mnz_setImageForUserHandle:[self.chatRoom peerHandleAtIndex:0]];
                }
            }
            break;
        }
        case MEGAChatCallStatusTerminating:
        case MEGAChatCallStatusDestroyed:
        case MEGAChatCallStatusDisconnected:
            [self dismissViewControllerAnimated:YES completion:nil];
            break;
            
        default:
            break;
    }
}

@end
