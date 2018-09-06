
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

@interface GroupCallViewController () <UICollectionViewDataSource, MEGAChatCallDelegate, UICollectionViewDelegateFlowLayout>

@property (weak, nonatomic) IBOutlet UIView *outgoingCallView;
@property (weak, nonatomic) IBOutlet UIView *incomingCallView;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

@property (weak, nonatomic) IBOutlet UIButton *enableDisableVideoButton;
@property (weak, nonatomic) IBOutlet UIButton *muteUnmuteMicrophone;
@property (weak, nonatomic) IBOutlet UIButton *enableDisableSpeaker;

@property (weak, nonatomic) IBOutlet UIView *toastView;
@property (weak, nonatomic) IBOutlet UILabel *toastLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *toastTopConstraint;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *peerTalkingViewHeightConstraint;
@property (weak, nonatomic) IBOutlet MEGARemoteImageView *peerTalkingVideoView;
@property (weak, nonatomic) IBOutlet UIView *peerTalkingView;
@property (weak, nonatomic) IBOutlet UIImageView *peerTalkingImageView;

@property (weak, nonatomic) IBOutlet UIView *participantsView;
@property (weak, nonatomic) IBOutlet UILabel *participantsLabel;

@property BOOL loudSpeakerEnabled;

@property (strong, nonatomic) AVAudioPlayer *player;
@property (strong, nonatomic) NSTimer *timer;
@property (strong, nonatomic) NSDate *baseDate;
@property (assign, nonatomic) NSInteger initDuration;
@property (assign, nonatomic) CGSize cellSize;

@end

@implementation GroupCallViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

    [self.navigationItem setTitleView:[Helper customNavigationBarLabelWithTitle:self.chatRoom.title subtitle:AMLocalizedString(@"calling...", @"Label shown when you receive an incoming call, before start the call.")]];
    [self.navigationItem.titleView sizeToFit];

    [Helper configureBlackNavigationAppearance];

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.participantsView];
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
        [self playCallingSound];

    } else  if (self.callType == CallTypeOutgoing) {
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
                [self playCallingSound];
            }
        }];
        
        [[MEGASdkManager sharedMEGAChatSdk] startChatCall:self.chatRoom.chatId enableVideo:self.videoCall delegate:startCallRequestDelegate];
    } else  if (self.callType == CallTypeActive) {
        self.incomingCallView.hidden = YES;
        if (@available(iOS 10.0, *)) {
            [self acceptCall:nil];
        } else {
            _call = [[MEGASdkManager sharedMEGAChatSdk] chatCallForChatId:self.chatRoom.chatId];
        }
        [self initDurationTimer];
        [self initShowHideControls];
        [self updateParticipants];
    }
    
    [[UIDevice currentDevice] setProximityMonitoringEnabled:!self.videoCall];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didSessionRouteChange:) name:AVAudioSessionRouteChangeNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[MEGASdkManager sharedMEGAChatSdk] addChatCallDelegate:self];
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [Helper configureRedNavigationAppearance];
    [[MEGASdkManager sharedMEGAChatSdk] removeChatCallDelegate:self];
    [[UIDevice currentDevice] setProximityMonitoringEnabled:NO];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
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
        cell.peerId = session.peerId;
        [cell.avatarImageView mnz_setImageForUserHandle:session.peerId];
        if (session.video) {
            [cell.videoImageView removeFromSuperview];
            MEGARemoteImageView *remoteImageView = [[MEGARemoteImageView alloc] initWithFrame:cell.bounds];
            [cell addSubview:remoteImageView];
            cell.videoImageView = remoteImageView;
            [[MEGASdkManager sharedMEGAChatSdk] addChatRemoteVideo:self.chatRoom.chatId peerId:session.peerId delegate:cell.videoImageView];
            cell.videoImageView.hidden = NO;
            cell.avatarImageView.hidden = YES;
        } else {
            cell.videoImageView.hidden = YES;
            cell.avatarImageView.hidden = NO;
        }
    } else {
        cell.tag = 1;
        cell.peerId = 0;
        [cell.avatarImageView mnz_setImageForUserHandle:[MEGASdkManager sharedMEGAChatSdk].myUserHandle];
        if (self.enableDisableVideoButton.selected) {
            [cell.videoImageView removeFromSuperview];
            MEGARemoteImageView *remoteImageView = [[MEGARemoteImageView alloc] initWithFrame:cell.bounds];
            [cell addSubview:remoteImageView];
            cell.videoImageView = remoteImageView;
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

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    switch (self.call.numParticipants) {
        case 1:
            self.cellSize = self.collectionView.frame.size;
            break;
            
        case 2: {
            float maxWidth = MAX(self.collectionView.frame.size.height, self.collectionView.frame.size.width);
            self.cellSize = CGSizeMake(floor(maxWidth / 2), floor(maxWidth / 2));
            break;
        }
            
        case 3: {
            float maxWidth = MAX(self.collectionView.frame.size.height, self.collectionView.frame.size.width);
            self.cellSize = CGSizeMake(floor(maxWidth / 3), floor(maxWidth / 3));
            break;
        }
            
        case 4: {
            float maxWidth = MIN(self.collectionView.frame.size.height, self.collectionView.frame.size.width);
            self.cellSize = CGSizeMake(floor(maxWidth / 2), floor(maxWidth / 2));
            break;
        }
            
        case 5: case 6: {
            float maxWidth = MIN(self.collectionView.frame.size.height, self.collectionView.frame.size.width);
            if ((maxWidth / 2) * 3 < MAX(self.collectionView.frame.size.height, self.collectionView.frame.size.width)) {
                self.cellSize = CGSizeMake(floor(maxWidth / 2), floor(maxWidth / 2));
            } else {
                maxWidth = MAX(self.collectionView.frame.size.height, self.collectionView.frame.size.width);
                self.cellSize = CGSizeMake(floor(maxWidth / 3) , floor(maxWidth / 3));
            }
            break;
        }
            
        default:
            self.cellSize = CGSizeMake(60, 60);
            break;
    }
    
    return self.cellSize;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    switch (self.call.numParticipants) {
        case 1: {
            return UIEdgeInsetsMake(0, 0, 0, 0);
        }
        
        case 2: case 3: {
            UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
            if (orientation == UIInterfaceOrientationPortrait) {
                float widthInset = (self.collectionView.frame.size.width - self.cellSize.width) / 2;
                return UIEdgeInsetsMake(0, widthInset, 0, widthInset);
            } else {
                float heightInset = (self.collectionView.frame.size.height - self.cellSize.height) / 2;
                return UIEdgeInsetsMake(heightInset, 0, heightInset, 0);
            }
        }
            
        case 4: {
                float widthInset = (self.collectionView.frame.size.width - self.cellSize.width * 2) / 2;
                float heightInset = (self.collectionView.frame.size.height - self.cellSize.height * 2) / 2;
                return UIEdgeInsetsMake(heightInset, widthInset, heightInset, widthInset);
        }
        
        case 5: case 6: {
            
            UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
            if (orientation == UIInterfaceOrientationPortrait) {
                float widthInset = (self.collectionView.frame.size.width - self.cellSize.width * 2) / 2;
                float heightInset = (self.collectionView.frame.size.height - self.cellSize.height * 3) / 2;
                return UIEdgeInsetsMake(heightInset, widthInset, heightInset, widthInset);
            } else {
                float widthInset = (self.collectionView.frame.size.width - self.cellSize.width * 3) / 2;
                float heightInset = (self.collectionView.frame.size.height - self.cellSize.height * 2) / 2;
                return UIEdgeInsetsMake(heightInset, widthInset, heightInset, widthInset);
            }
        }
            
        default: {
            float widthInset = (self.collectionView.frame.size.width - self.cellSize.width * self.call.numParticipants) / 2;
            return UIEdgeInsetsMake(0, widthInset, 0, widthInset);
        }
    }
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self.collectionView reloadData];
    } completion:nil];
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
                                if (!cell.videoImageView) {
                                    MEGARemoteImageView *remoteImageView = [[MEGARemoteImageView alloc] initWithFrame:cell.bounds];
                                    [cell addSubview:remoteImageView];
                                    cell.videoImageView = remoteImageView;
                                }
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

- (IBAction)hideCall:(UIBarButtonItem *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
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
    self.navigationItem.titleView =  [Helper customNavigationBarLabelWithTitle:self.chatRoom.title subtitle:[NSString mnz_stringFromTimeInterval:interval]];
    [self.navigationItem.titleView sizeToFit];
}

- (void)updateParticipants {
    self.participantsLabel.text = [NSString stringWithFormat:@"%lu/%lu", self.call.numParticipants, (unsigned long)self.chatRoom.peerCount];
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

- (void)initDurationTimer {
    self.initDuration = self.call.duration;
    self.timer = [NSTimer timerWithTimeInterval:1.0f target:self selector:@selector(updateDuration) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
    self.baseDate = [NSDate date];
}

- (void)initShowHideControls {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        //Add Tap to hide/show controls
        UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showOrHideControls)];
        [tapGestureRecognizer setNumberOfTapsRequired:1];
        [self.view addGestureRecognizer:tapGestureRecognizer];
        
        [self showOrHideControls];
    });
}

- (void)playCallingSound {
    if (@available(iOS 10.0, *)) {} else {
        NSString *soundFilePath = [[NSBundle mainBundle] pathForResource:@"incoming_voice_video_call" ofType:@"mp3"];
        NSURL *soundFileURL = [NSURL fileURLWithPath:soundFilePath];
        
        _player = [[AVAudioPlayer alloc] initWithContentsOfURL:soundFileURL error:nil];
        self.player.numberOfLoops = -1; //Infinite
        
        [self.player play];
    }
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
        switch (chatSession.status) {
            case MEGAChatSessionStatusInitial: {
                if (!self.timer.isValid) {
                    [self.player stop];
                    [self initDurationTimer];
                    [self initShowHideControls];
                    [self updateParticipants];
                } else {
                    [self showToastMessage:[NSString stringWithFormat:@"%@ joined the call", [self.chatRoom peerFullnameByHandle:chatSession.peerId]] color:@""];
                }
                [self.collectionView reloadData];
                break;
            }
                
            case MEGAChatSessionStatusInProgress: {
                self.outgoingCallView.hidden = NO;
                self.incomingCallView.hidden = YES;
                break;
            }
                
            case MEGAChatSessionStatusDestroyed:
                [self showToastMessage:[NSString stringWithFormat:@"%@ left the call", [self.chatRoom peerFullnameByHandle:chatSession.peerId]] color:@""];
                break;
                
            case MEGAChatSessionStatusInvalid:
                MEGALogDebug(@"MEGAChatSessionStatusInvalid");
                break;
        }
    }
    
    if ([call hasChangedForType:MEGAChatCallChangeTypeCallComposition]) {
        [self updateParticipants];
        
        if (self.peerTalkingView.hidden && call.numParticipants > 6) {
            self.collectionView.scrollEnabled = YES;
            self.peerTalkingView.hidden = NO;
            self.peerTalkingViewHeightConstraint.constant = self.collectionView.frame.size.width < 400 ? self.collectionView.frame.size.width : 400;
        }
        
        if (call.numParticipants <= 6 && !self.peerTalkingView.hidden) {
            self.collectionView.scrollEnabled = NO;
            self.peerTalkingView.hidden = YES;
            self.peerTalkingViewHeightConstraint.constant = 0;
            self.peerTalkingImageView = nil;
        }
        
        [self.collectionView layoutIfNeeded];
        [self.collectionView reloadData];
    }
    
    switch (self.call.status) {
            
        case MEGAChatCallStatusInProgress: {
            
            if ([call hasChangedForType:MEGAChatCallChangeTypeRemoteAVFlags]) {

                MEGAChatSession *chatSessionWithAVFlags = [self.call sessionForPeer:[self.call peerSessionStatusChange]];
                
                NSArray<GroupCallCollectionViewCell *> *cells = self.collectionView.visibleCells;

                for (GroupCallCollectionViewCell *cell in cells) {
                    if (cell.peerId == chatSessionWithAVFlags.peerId) {
                        if (chatSessionWithAVFlags.hasVideo) {
                            [[MEGASdkManager sharedMEGAChatSdk] removeChatRemoteVideo:self.chatRoom.chatId peerId:chatSessionWithAVFlags.peerId delegate:cell.videoImageView];
                            [cell.videoImageView removeFromSuperview];
                            MEGARemoteImageView *remoteImageView = [[MEGARemoteImageView alloc] initWithFrame:cell.bounds];
                            [cell addSubview:remoteImageView];
                            cell.videoImageView = remoteImageView;
                            [[MEGASdkManager sharedMEGAChatSdk] addChatRemoteVideo:self.chatRoom.chatId peerId:chatSessionWithAVFlags.peerId delegate:cell.videoImageView];
                            cell.avatarImageView.hidden = YES;
                            cell.videoImageView.hidden = NO;
                        } else {
                            [cell.videoImageView removeFromSuperview];
                            cell.avatarImageView.hidden = NO;
                            cell.videoImageView.hidden = YES;
                            [[MEGASdkManager sharedMEGAChatSdk] removeChatRemoteVideo:self.chatRoom.chatId peerId:chatSessionWithAVFlags.peerId delegate:cell.videoImageView];
                        }
                        break;
                    }
                }
            }
            
            if ([call hasChangedForType:MEGAChatCallChangeTypeAudioLevel] && self.call.numParticipants > 6) {
                MEGAChatSession *chatSessionWithAudioLevel = [self.call sessionForPeer:[self.call peerSessionStatusChange]];
                
                if (chatSessionWithAudioLevel.audioDetected) {
                    if (chatSessionWithAudioLevel.hasVideo) {
                        [self.peerTalkingVideoView removeFromSuperview];
                        MEGARemoteImageView *peerTalkingVideo = [[MEGARemoteImageView alloc] initWithFrame:self.peerTalkingView.bounds];
                        [self.peerTalkingView addSubview:peerTalkingVideo];
                        self.peerTalkingVideoView = peerTalkingVideo;
                        [[MEGASdkManager sharedMEGAChatSdk] addChatRemoteVideo:self.chatRoom.chatId peerId:chatSessionWithAudioLevel.peerId delegate:self.peerTalkingVideoView];
                        self.peerTalkingVideoView.hidden = NO;
                        self.peerTalkingImageView.hidden = YES;
                    } else {
                        [self.peerTalkingVideoView removeFromSuperview];
                        [self.peerTalkingImageView mnz_setImageForUserHandle:chatSessionWithAudioLevel.peerId];
                        self.peerTalkingVideoView.hidden = NO;
                        self.peerTalkingImageView.hidden = YES;
                    }
                }
            }
            
            if ([call hasChangedForType:MEGAChatCallChangeTypeNetworkQuality]) {
                
                MEGAChatSession *chatSessionWithNetworkQuality = [self.call sessionForPeer:[self.call peerSessionStatusChange]];
                
                NSArray<GroupCallCollectionViewCell *> *cells = self.collectionView.visibleCells;
                
                for (GroupCallCollectionViewCell *cell in cells) {
                    if (cell.peerId == chatSessionWithNetworkQuality.peerId) {
                        if (chatSessionWithNetworkQuality.networkQuality <= 1) {
                            //TODO: añadir frame amarillo
                        } else {
                            //TODO: eliminar frame amarillo
                        }
                        break;
                    }
                }
                
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
