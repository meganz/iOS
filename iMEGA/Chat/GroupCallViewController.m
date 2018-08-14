
#import "GroupCallViewController.h"

#import <AVFoundation/AVFoundation.h>

#import "UIApplication+MNZCategory.h"
#import "NSString+MNZCategory.h"
#import "UIImageView+MNZCategory.h"

#import "LTHPasscodeViewController.h"

#import "MEGASdkManager.h"
#import "MEGACallManager.h"

#import "MEGAChatAnswerCallRequestDelegate.h"
#import "MEGAChatStartCallRequestDelegate.h"
#import "MEGAChatEnableDisableAudioRequestDelegate.h"
#import "MEGAChatEnableDisableVideoRequestDelegate.h"

#import "DevicePermissionsHelper.h"
#import "Helper.h"

#import "GroupCallCollectionViewCell.h"

@interface GroupCallViewController () <UICollectionViewDataSource, MEGAChatCallDelegate>

@property (weak, nonatomic) IBOutlet UIView *outgoingCallView;
@property (weak, nonatomic) IBOutlet UIView *incomingCallView;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

@property (weak, nonatomic) IBOutlet UIButton *enableDisableVideoButton;
@property (weak, nonatomic) IBOutlet UIButton *muteUnmuteMicrophone;
@property (weak, nonatomic) IBOutlet UIButton *enableDisableSpeaker;

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *durationLabel;
@property (weak, nonatomic) IBOutlet UILabel *participantsLabel;
@property (weak, nonatomic) IBOutlet UIButton *closeButton;

@property (weak, nonatomic) IBOutlet UIView *toastView;
@property (weak, nonatomic) IBOutlet UILabel *toastLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *toastTopConstraint;

@property BOOL loudSpeakerEnabled;

@property (strong, nonatomic) AVAudioPlayer *player;
@property (strong, nonatomic) NSTimer *timer;
@property (strong, nonatomic) NSDate *baseDate;
@property (assign, nonatomic) NSInteger initDuration;

@end

@implementation GroupCallViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

    self.titleLabel.text = self.chatRoom.title;
    self.durationLabel.text = AMLocalizedString(@"calling...", @"Label shown when you receive an incoming call, before start the call.");
    [self updateParticipants];
    
    self.enableDisableVideoButton.selected = self.videoCall;
    self.enableDisableSpeaker.selected = self.videoCall;
    if (self.videoCall) {
        [self enableLoudspeaker];
    } else {
        [self disableLoudspeaker];
    }
 
    if (self.callType == CallTypeIncoming) {
        self.outgoingCallView.hidden = YES;
        if (@available(iOS 10.0, *)) {
            [self acceptCall:nil];
        } else {
            _call = [[MEGASdkManager sharedMEGAChatSdk] chatCallForChatId:self.chatRoom.chatId];
        }
    } else {
        __weak __typeof(self) weakSelf = self;

        MEGAChatStartCallRequestDelegate *startCallRequestDelegate = [[MEGAChatStartCallRequestDelegate alloc] initWithCompletion:^(MEGAChatError *error) {
            if (error.type) {
                [weakSelf dismissViewControllerAnimated:YES completion:nil];
            } else {
                weakSelf.call = [[MEGASdkManager sharedMEGAChatSdk] chatCallForChatId:weakSelf.chatRoom.chatId];
                weakSelf.incomingCallView.hidden = YES;
                
                if (@available(iOS 10.0, *)) {
                    NSUUID *uuid = [[NSUUID alloc] init];
                    weakSelf.call.uuid = uuid;
                    [weakSelf.megaCallManager addCall:weakSelf.call];
                    
                    uint64_t peerHandle = [weakSelf.chatRoom peerHandleAtIndex:0];
                    NSString *peerEmail = [weakSelf.chatRoom peerEmailByHandle:peerHandle];
                    [weakSelf.megaCallManager startCall:weakSelf.call email:peerEmail];
                }
               
                [self.collectionView reloadData];
            }
        }];
        
        [[MEGASdkManager sharedMEGAChatSdk] startChatCall:self.chatRoom.chatId enableVideo:self.videoCall delegate:startCallRequestDelegate];
    }
    
    [[UIDevice currentDevice] setProximityMonitoringEnabled:!self.videoCall];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didSessionRouteChange:) name:AVAudioSessionRouteChangeNotification object:nil];
    
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
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
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

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.call.sessions.size + 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    GroupCallCollectionViewCell *cell = (GroupCallCollectionViewCell *) [self.collectionView dequeueReusableCellWithReuseIdentifier:@"GroupCallCell" forIndexPath:indexPath];
    
    MEGAChatSession *session = [self.call sessionForPeer:[self.call.sessions megaHandleAtIndex:indexPath.row]];
    
    if (session.peerId) {
        cell.tag = 0;
        [cell.avatarImageView mnz_setImageForUserHandle:session.peerId];
        if (session.video) {
            [[MEGASdkManager sharedMEGAChatSdk] removeChatLocalVideo:self.chatRoom.chatId delegate:cell.videoImageView];
            for (int i = 0; i < self.call.sessions.size; i++) {
                [[MEGASdkManager sharedMEGAChatSdk] removeChatRemoteVideo:self.chatRoom.chatId peerId:[self.call.sessions megaHandleAtIndex:i] delegate:cell.videoImageView];
            }
            [[MEGASdkManager sharedMEGAChatSdk] addChatRemoteVideo:self.chatRoom.chatId peerId:session.peerId delegate:cell.videoImageView];
            cell.videoImageView.hidden = NO;
            cell.avatarImageView.hidden = YES;
        } else {
            cell.videoImageView.hidden = YES;
            cell.avatarImageView.hidden = NO;
        }
    } else {
        cell.tag = 1;
        [cell.avatarImageView mnz_setImageForUserHandle:[MEGASdkManager sharedMEGAChatSdk].myUserHandle];
        if (self.enableDisableVideoButton.selected) {
            for (int i = 0; i < self.call.sessions.size; i++) {
                [[MEGASdkManager sharedMEGAChatSdk] removeChatRemoteVideo:self.chatRoom.chatId peerId:[self.call.sessions megaHandleAtIndex:i] delegate:cell.videoImageView];
            }
            [[MEGASdkManager sharedMEGAChatSdk] removeChatLocalVideo:self.chatRoom.chatId delegate:cell.videoImageView];
            [[MEGASdkManager sharedMEGAChatSdk] addChatLocalVideo:self.chatRoom.chatId delegate:cell.videoImageView];
            cell.videoImageView.hidden = NO;
            cell.avatarImageView.hidden = YES;
        } else {
            cell.videoImageView.hidden = YES;
            cell.avatarImageView.hidden = NO;
        }
    }
    
    return cell;
}

#pragma mark - IBActions

- (IBAction)acceptCallWithVideo:(UIButton *)sender {
    MEGAChatAnswerCallRequestDelegate *answerCallRequestDelegate = [[MEGAChatAnswerCallRequestDelegate alloc] initWithCompletion:^(MEGAChatError *error) {
        if (error.type == MEGAChatErrorTypeOk) {
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
                    NSArray<GroupCallCollectionViewCell *> *cells = self.collectionView.visibleCells;

                    for (GroupCallCollectionViewCell *cell in cells) {
                        if (cell.tag == 1) {
                            if (sender.selected) {
                                cell.avatarImageView.hidden = NO;
                                cell.videoImageView.hidden = YES;
                                [[MEGASdkManager sharedMEGAChatSdk] removeChatLocalVideo:self.chatRoom.chatId delegate:cell.videoImageView];
                            } else {
                                cell.avatarImageView.hidden = YES;
                                cell.videoImageView.hidden = NO;
                                [[MEGASdkManager sharedMEGAChatSdk] addChatLocalVideo:self.chatRoom.chatId delegate:cell.videoImageView];
                            }
                            sender.selected = !sender.selected;
                            self.loudSpeakerEnabled = sender.selected;
                            break;
                        }
                    }
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

- (void)updateDuration {
    NSTimeInterval interval = ([NSDate date].timeIntervalSince1970 - self.baseDate.timeIntervalSince1970 + self.initDuration);
    self.durationLabel.text = [NSString mnz_stringFromTimeInterval:interval];
}

- (void)updateParticipants {
    self.participantsLabel.text = [NSString stringWithFormat:@"%lu/%lu", self.call.sessions.size + 1, (unsigned long)self.chatRoom.peerCount];
}

- (void)showOrHideControls {
    [UIView animateWithDuration:0.3f animations:^{
        if (self.outgoingCallView.alpha != 1.0f) {
            [self.outgoingCallView setAlpha:1.0f];
            [UIView animateWithDuration:0.25 animations:^{
                [self setNeedsStatusBarAppearanceUpdate];
            }];
        } else {
            [self.outgoingCallView setAlpha:0.0f];
            [UIView animateWithDuration:0.25 animations:^{
                [self setNeedsStatusBarAppearanceUpdate];
            }];
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

- (void)enablePasscodeIfNeeded {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"presentPasscodeLater"] && [LTHPasscodeViewController doesPasscodeExist]) {
        [[LTHPasscodeViewController sharedUser] showLockScreenOver:UIApplication.mnz_visibleViewController.view
                                                     withAnimation:YES
                                                        withLogout:NO
                                                    andLogoutTitle:nil];
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"presentPasscodeLater"];
    }
    [[LTHPasscodeViewController sharedUser] enablePasscodeWhenApplicationEntersBackground];
}

- (void)showToastMessage:(NSString *)message color:(NSString *)color {
    self.toastTopConstraint.constant = -22;
    self.toastLabel.text = message;
    self.toastView.hidden = NO;
    
    [UIView animateWithDuration:.25 animations:^{
        self.toastTopConstraint.constant = 0;
        [self.view layoutIfNeeded];
    } completion:^(BOOL finished) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            self.toastView.hidden = YES;
            self.toastTopConstraint.constant = -22;
            self.toastLabel.text = @"";
        });
    }];
}

#pragma mark - MEGAChatCallDelegate

- (void)onChatCallUpdate:(MEGAChatSdk *)api call:(MEGAChatCall *)call {
    MEGALogDebug(@"onChatCallUpdate %@", call);
    
    if (self.call.callId == call.callId) {
        self.call = call;
    } else {
        return;
    }
    
    if ([call hasChangedForType:MEGAChatCallChangeTypeSessionStatus]) {
        MEGAChatSession *chatSession = [self.call sessionForPeer:[self.call peerSessionStatusChange]];
        if (chatSession.status == MEGAChatSessionStatusInProgress) {
            if (!self.timer.isValid) {
                [self.player stop];
                
                self.initDuration = self.call.duration;
                _timer = [NSTimer timerWithTimeInterval:1.0f target:self selector:@selector(updateDuration) userInfo:nil repeats:YES];
                [[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
                _baseDate = [NSDate date];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    //Add Tap to hide/show controls
                    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showOrHideControls)];
                    [tapGestureRecognizer setNumberOfTapsRequired:1];
                    [self.view addGestureRecognizer:tapGestureRecognizer];
                    
                    [self showOrHideControls];
                });
                [self.collectionView reloadData];
                [self updateParticipants];
            }
        }
    }
    
    switch (self.call.status) {
            
        case MEGAChatCallStatusJoining:
            [self.collectionView reloadData];
            break;
            
        case MEGAChatCallStatusInProgress: {
            self.outgoingCallView.hidden = NO;
            self.incomingCallView.hidden = YES;
            
            if ([call hasChangedForType:MEGAChatCallChangeTypeCallComposition]) {
                [self.collectionView reloadData];
                [self updateParticipants];
                MEGAChatSession *chatSessionWithCallComposition = [self.call sessionForPeer:[self.call peerSessionStatusChange]];
                for (int i = 0; i < self.call.sessions.size; i++) {
                    uint64_t sessionPeerId = [self.call.sessions megaHandleAtIndex:i];
                    if (chatSessionWithCallComposition.peerId == sessionPeerId) {
                        [self showToastMessage:[NSString stringWithFormat:@"%@ joined the call", [self.chatRoom peerFullnameByHandle:chatSessionWithCallComposition.peerId]] color:@""];
                        break;
                    }
                }
            }
            
            if ([call hasChangedForType:MEGAChatCallChangeTypeRemoteAVFlags]) {
                                            [self.collectionView reloadData];

                /*MEGAChatSession *chatSessionWithAVFlags = [self.call sessionForPeer:[self.call peerSessionStatusChange]];
                
                for (int i = 0; i < self.call.sessions.size; i++) {
                    uint64_t sessionPeerId = [self.call.sessions megaHandleAtIndex:i];
                    if (chatSessionWithAVFlags.peerId == sessionPeerId) {
                        GroupCallCollectionViewCell *cell = (GroupCallCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:i inSection:0]];
                        if (cell) {
//                            if ([call hasChangedForType:MEGAChatCallChangeTypeSessionStatus]) {
//                                [self.collectionView reloadData];
//                            } else {
                                if (chatSessionWithAVFlags.video) {
                                    cell.avatarImageView.hidden = YES;
                                    cell.videoImageView.hidden = NO;
                                    for (int i = 0; i < self.call.sessions.size; i++) {
                                        [[MEGASdkManager sharedMEGAChatSdk] removeChatRemoteVideo:self.chatRoom.chatId peerId:[self.call.sessions megaHandleAtIndex:i] delegate:cell.videoImageView];
                                    }
                                    [[MEGASdkManager sharedMEGAChatSdk] addChatRemoteVideo:self.chatRoom.chatId peerId:chatSessionWithAVFlags.peerId delegate:cell.videoImageView];
                                } else {
                                    cell.avatarImageView.hidden = NO;
                                    cell.videoImageView.hidden = YES;
                                    for (int i = 0; i < self.call.sessions.size; i++) {
                                        [[MEGASdkManager sharedMEGAChatSdk] removeChatRemoteVideo:self.chatRoom.chatId peerId:[self.call.sessions megaHandleAtIndex:i] delegate:cell.videoImageView];
                                    }
                                }
//                        } else {
//                            [self.collectionView reloadData];
//                        }
                        }
                        break;
                    }
                }*/
            }
            
            break;
        }
    
        case MEGAChatCallStatusTerminatingUserParticipation:
        case MEGAChatCallStatusDestroyed: {
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
