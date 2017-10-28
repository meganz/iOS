
#import "CallViewController.h"
#import "MEGARemoteImageView.h"
#import "MEGALocalImageView.h"

@interface CallViewController () <MEGAChatRequestDelegate, MEGAChatCallDelegate, MEGAChatVideoDelegate>

@property (weak, nonatomic) IBOutlet MEGARemoteImageView *remoteVideoImageView;
@property (weak, nonatomic) IBOutlet MEGALocalImageView *localVideoImageView;

@property (weak, nonatomic) IBOutlet UIButton *enableDisableVideoButton;
@property (weak, nonatomic) IBOutlet UIButton *muteUnmuteMicrophone;

@property (weak, nonatomic) IBOutlet UIView *outgoingCallView;
@property (weak, nonatomic) IBOutlet UIView *incomingCallView;

@end

@implementation CallViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.enableDisableVideoButton.selected = self.videoCall;
    
    if (self.callType == CallTypeIncoming) {
        self.outgoingCallView.hidden = YES;
    } else {
        [[MEGASdkManager sharedMEGAChatSdk] startChatCall:self.chatId enableVideo:self.videoCall delegate:self];
        self.incomingCallView.hidden = YES;
    }
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
- (IBAction)acceptCallWithVideo:(UIButton *)sender {
    [[MEGASdkManager sharedMEGAChatSdk] answerChatCall:self.chatId enableVideo:YES delegate:self];
}

- (IBAction)acceptCall:(UIButton *)sender {
    [[MEGASdkManager sharedMEGAChatSdk] answerChatCall:self.chatId enableVideo:NO delegate:self];
}

- (IBAction)hangCall:(UIButton *)sender {    
    [[MEGASdkManager sharedMEGAChatSdk] hangChatCall:self.chatId delegate:self];
}

- (IBAction)muteCall:(UIButton *)sender {
    if (sender.selected) {
        [[MEGASdkManager sharedMEGAChatSdk] enableAudioForChat:self.chatId delegate:self];
    } else {
        [[MEGASdkManager sharedMEGAChatSdk] disableAudioForChat:self.chatId delegate:self];
    }
    sender.selected = !sender.selected;
}

- (IBAction)enableDisableVideo:(UIButton *)sender {
    if (sender.selected) {
        [[MEGASdkManager sharedMEGAChatSdk] disableVideoForChat:self.chatId delegate:self];
        self.localVideoImageView.hidden = YES;
        [[MEGASdkManager sharedMEGAChatSdk] removeChatLocalVideoDelegate:self.localVideoImageView];
    } else {
        [[MEGASdkManager sharedMEGAChatSdk] enableVideoForChat:self.chatId delegate:self];
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
            if (call.remoteVideo) {
                [[MEGASdkManager sharedMEGAChatSdk] addChatRemoteVideoDelegate:self.remoteVideoImageView];
            }
            self.outgoingCallView.hidden = NO;
            self.incomingCallView.hidden = YES;
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
