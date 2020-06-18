
#import "GroupCallViewController.h"

#import <AVFoundation/AVFoundation.h>
#import <QuartzCore/QuartzCore.h>
#import <MediaPlayer/MediaPlayer.h>

#import "LTHPasscodeViewController.h"
#import "SVProgressHUD.h"

#import "AVAudioSession+MNZCategory.h"
#import "NSString+MNZCategory.h"
#import "UIApplication+MNZCategory.h"
#import "UIImageView+MNZCategory.h"

#import "DevicePermissionsHelper.h"
#import "GroupCallCollectionViewCell.h"
#import "Helper.h"
#import "MEGACallManager.h"
#import "MEGAChatAnswerCallRequestDelegate.h"
#import "MEGAChatEnableDisableAudioRequestDelegate.h"
#import "MEGAChatEnableDisableVideoRequestDelegate.h"
#import "MEGAChatStartCallRequestDelegate.h"
#import "MEGAGroupCallPeer.h"
#import "MEGASdkManager.h"
#import "MEGA-Swift.h"

#define kSmallPeersLayout 7

@interface GroupCallViewController () <UICollectionViewDataSource, MEGAChatCallDelegate, UICollectionViewDelegateFlowLayout, UIGestureRecognizerDelegate>

@property (nonatomic, strong) MEGAChatCall *call;

@property (weak, nonatomic) IBOutlet UIView *callControlsView;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

@property (weak, nonatomic) IBOutlet UIButton *enableDisableVideoButton;
@property (weak, nonatomic) IBOutlet UIButton *muteUnmuteMicrophone;
@property (weak, nonatomic) IBOutlet UIButton *enableDisableSpeaker;
@property (weak, nonatomic) IBOutlet UIButton *switchCameraButton;
@property (weak, nonatomic) IBOutlet UIButton *minimizeButton;

@property (weak, nonatomic) IBOutlet UIView *toastView;
@property (weak, nonatomic) IBOutlet UILabel *toastLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *toastTopConstraint;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *peerTalkingViewHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *collectionViewBottomConstraint;
@property (weak, nonatomic) IBOutlet MEGARemoteImageView *peerTalkingVideoView;
@property (weak, nonatomic) IBOutlet UIView *peerTalkingView;
@property (weak, nonatomic) IBOutlet UIImageView *peerTalkingImageView;
@property (weak, nonatomic) IBOutlet UIImageView *peerTalkingMuteView;
@property (weak, nonatomic) IBOutlet UIView *peerTalkingQualityView;

@property (weak, nonatomic) IBOutlet UIView *participantsView;
@property (weak, nonatomic) IBOutlet UILabel *participantsLabel;

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *collectionActivity;

@property (weak, nonatomic) IBOutlet UIView *volumeContainerView;
@property (strong, nonatomic) MPVolumeView *mpVolumeView;

@property (strong, nonatomic) NSMutableArray<MEGAGroupCallPeer *> *peersInCall;
@property (strong, nonatomic) MEGAGroupCallPeer *localPeer;
@property (strong, nonatomic) MEGAGroupCallPeer *lastPeerTalking;

@property (strong, nonatomic) AVAudioPlayer *player;
@property (strong, nonatomic) NSTimer *timer;
@property (strong, nonatomic) NSDate *baseDate;
@property (assign, nonatomic) NSInteger initDuration;
@property (assign, nonatomic) CGSize cellSize;

@property (nonatomic, getter=isManualMode) BOOL manualMode;
@property (assign, nonatomic) MEGAGroupCallPeer *peerManualMode;

@property (nonatomic) BOOL shouldHideAcivity;

@property (weak, nonatomic) IBOutlet UILabel *navigationTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *navigationSubtitleLabel;

@property (assign, nonatomic, getter=isSpeakerEnabled) BOOL speakerEnabled;

@property (assign, nonatomic, getter=isReconnecting) BOOL reconnecting;

@property (nonatomic) NSString *backCamera;
@property (nonatomic) NSString *frontCamera;

@end

@implementation GroupCallViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.frontCamera = [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInWideAngleCamera mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionFront].localizedName;
    self.backCamera = [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInWideAngleCamera mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionBack].localizedName;
    
    [self customNavigationBarLabel];
    [self updateParticipants];
    [self initDataSource];
 
    if (self.callType == CallTypeIncoming) {
        self.call = [MEGASdkManager.sharedMEGAChatSdk chatCallForCallId:self.callId];
        [self answerChatCall];
    } else  if (self.callType == CallTypeOutgoing) {
        [self startOutgoingCall];
    } else  if (self.callType == CallTypeActive) {
        self.call = [[MEGASdkManager sharedMEGAChatSdk] chatCallForChatId:self.chatRoom.chatId];
        self.callId = self.call.callId;
        if (self.call.status == MEGAChatCallStatusUserNoPresent) {
            [self joinActiveCall];
        } else {
            [self instantiatePeersInCall];
        }
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[MEGASdkManager sharedMEGAChatSdk] addChatCallDelegate:self];
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(didSessionRouteChange:) name:AVAudioSessionRouteChangeNotification object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(didWirelessRoutesAvailableChange:) name:MPVolumeViewWirelessRoutesAvailableDidChangeNotification object:nil];
    
    self.mpVolumeView = [[MPVolumeView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 60.0f, 60.0f)];
    self.mpVolumeView.showsVolumeSlider = NO;
    [self.volumeContainerView addSubview:self.mpVolumeView];
        
    [self updateAudioOutputImage];
    
    if (self.callType == CallTypeOutgoing && self.videoCall && !AVAudioSession.sharedInstance.mnz_isBluetoothAudioRouteAvailable) {
        MEGALogDebug(@"[Audio] Enable loud speaker is video call and there is no bluetooth connected");
        [self enableLoudspeaker];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    if (self.callType == CallTypeActive && self.peersInCall.count >= kSmallPeersLayout) {
        [self configureUserFocusedCallLayout];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[MEGASdkManager sharedMEGAChatSdk] removeChatCallDelegate:self];
    [[UIDevice currentDevice] setProximityMonitoringEnabled:NO];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self removeAllVideoListeners];
        if (self.call.numParticipants >= kSmallPeersLayout) {
            UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
            if (orientation == UIInterfaceOrientationPortrait) {
                [UIView animateWithDuration:0.3f animations:^{
                    self.peerTalkingViewHeightConstraint.constant = 400;
                    self.collectionViewBottomConstraint.constant = 100 + self.peerTalkingViewHeightConstraint.constant - self.view.frame.size.height;
                } completion:^(BOOL finished) {
                    if (finished) {
                        [self.collectionView reloadData];
                        MEGALogDebug(@"[Group Call] Reload data %s", __PRETTY_FUNCTION__);
                    }
                }];
            } else {
                [UIView animateWithDuration:0.3f animations:^{
                    self.collectionViewBottomConstraint.constant = 0;
                    self.peerTalkingViewHeightConstraint.constant = self.view.frame.size.height - 100;
                } completion:^(BOOL finished) {
                    if (finished) {
                        [self.collectionView reloadData];
                        MEGALogDebug(@"[Group Call] Reload data %s", __PRETTY_FUNCTION__);
                    }
                }];
            }
            self.collectionView.userInteractionEnabled = YES;
        } else {
            [self.collectionView reloadData];
            MEGALogDebug(@"[Group Call] Reload data %s", __PRETTY_FUNCTION__);
            self.collectionView.userInteractionEnabled = NO;
        }
    } completion:nil];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.peersInCall.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    GroupCallCollectionViewCell *cell = (GroupCallCollectionViewCell *) [self.collectionView dequeueReusableCellWithReuseIdentifier:@"GroupCallCell" forIndexPath:indexPath];
    
    MEGAGroupCallPeer *peer = [self.peersInCall objectAtIndex:indexPath.row];
    [cell configureCellForPeer:peer inChat:self.chatRoom.chatId numParticipants:self.call.numParticipants];
    
    return cell;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    MEGAGroupCallPeer *peer = [self.peersInCall objectAtIndex:indexPath.row];
    GroupCallCollectionViewCell *groupCallCell = (GroupCallCollectionViewCell *)cell;
    [groupCallCell configureCellForPeer:peer inChat:self.chatRoom.chatId numParticipants:self.call.numParticipants];
    if (self.peersInCall.count >= kSmallPeersLayout && self.manualMode && [peer isEqualToPeer:self.peerManualMode]) {
        [groupCallCell showUserOnFocus];
    } else {
        [groupCallCell hideUserOnFocus];
    }
}

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    if (self.peersInCall.count >= kSmallPeersLayout) {
        MEGAGroupCallPeer *peer = [self.peersInCall objectAtIndex:indexPath.row];
        GroupCallCollectionViewCell *groupCallCell = (GroupCallCollectionViewCell *)cell;
        if (!groupCallCell.videoImageView.hidden) {
            if (indexPath.item + 1 == self.peersInCall.count) {
                [groupCallCell removeLocalVideoInChat:self.chatRoom.chatId];
            } else {
                [groupCallCell removeRemoteVideoForPeer:peer inChat:self.chatRoom.chatId];
            }
        }
    }
}


- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.item == self.peersInCall.count - 1) {
        return;
    }
    if (self.peersInCall.count >= kSmallPeersLayout) {
        //remove border stroke of previous manual selected participant
        NSUInteger previousPeerIndex;
        if (self.manualMode) {
            previousPeerIndex = [self.peersInCall indexOfObject:[self peerForPeerId:self.peerManualMode.peerId clientId:self.peerManualMode.clientId]];
        } else {
            previousPeerIndex = [self.peersInCall indexOfObject:[self peerForPeerId:self.lastPeerTalking.peerId clientId:self.lastPeerTalking.clientId]];
        }
        GroupCallCollectionViewCell *cell = (GroupCallCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:previousPeerIndex inSection:0]];
        [cell hideUserOnFocus];
        
        MEGAGroupCallPeer *peerSelected = [self.peersInCall objectAtIndex:indexPath.item];
        if ([peerSelected isEqualToPeer:self.peerManualMode]) {
            if (self.manualMode) {
                self.lastPeerTalking = self.peerManualMode;
                self.peerManualMode = nil;
                self.manualMode = NO;
            } else {
                [self configureUserOnFocus:peerSelected manual:YES];
            }
        } else {
            [self configureUserOnFocus:peerSelected manual:YES];
        }
    }
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    switch (self.peersInCall.count) {
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
    switch (self.peersInCall.count) {
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
            return UIEdgeInsetsMake(0, 0, 0, 0);
        }
    }
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    switch (self.call.numParticipants) {
        case 1: case 2: case 3: case 4: case 5: case 6:
            return 0;
            
        default:
            return 8;
    }
}

#pragma mark - IBActions

- (IBAction)hangCall:(UIButton *)sender {
    [self removeAllVideoListeners];
    [self.megaCallManager endCallWithCallId:self.callId chatId:self.chatRoom.chatId];
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
    [DevicePermissionsHelper videoPermissionWithCompletionHandler:^(BOOL granted) {
        if (granted) {
            MEGAChatEnableDisableVideoRequestDelegate *enableDisableVideoRequestDelegate = [[MEGAChatEnableDisableVideoRequestDelegate alloc] initWithCompletion:^(MEGAChatError *error) {
                if (error.type == MEGAChatErrorTypeOk) {
                    
                    MEGAGroupCallPeer *localUserVideoFlagChanged = self.localPeer;
                    
                    if (localUserVideoFlagChanged) {
                        localUserVideoFlagChanged.video = !sender.selected;
                        NSUInteger index = [self.peersInCall indexOfObject:localUserVideoFlagChanged];
                         GroupCallCollectionViewCell *cell = (GroupCallCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:index inSection:0]];
                        
                        if (sender.selected) {
                            [cell removeLocalVideoInChat:self.chatRoom.chatId];
                        } else {
                            [cell addLocalVideoInChat:self.chatRoom.chatId];
                            [self updateSelectedCamera];
                        }
                        sender.selected = !sender.selected;
                        self.switchCameraButton.hidden = !sender.selected;
                        
                        [self updateParticipants];
                    }
                } else if (error.type == MEGAChatErrorTooMany) {
                    [SVProgressHUD showErrorWithStatus:AMLocalizedString(@"Error. No more video are allowed in this group call.", @"Message show when a call cannot be established because there are too many video activated in the group call")];
                }
            }];
            if (sender.selected) {
                [[MEGASdkManager sharedMEGAChatSdk] disableVideoForChat:self.chatRoom.chatId delegate:enableDisableVideoRequestDelegate];
            } else {
                [[MEGASdkManager sharedMEGAChatSdk] enableVideoForChat:self.chatRoom.chatId delegate:enableDisableVideoRequestDelegate];
            }
        } else {
            [DevicePermissionsHelper alertVideoPermissionWithCompletionHandler:^{
                __weak __typeof(self) weakSelf = self;
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
    [self removeAllVideoListeners];
    [[NSUserDefaults standardUserDefaults] setBool:self.localPeer.video forKey:@"groupCallLocalVideo"];
    [[NSUserDefaults standardUserDefaults] setBool:self.localPeer.audio forKey:@"groupCallLocalAudio"];
    [[NSUserDefaults standardUserDefaults] setBool:self.switchCameraButton.selected forKey:@"groupCallCameraSwitched"];
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

#pragma mark - Public

- (void)tapOnVideoCallkitWhenDeviceIsLocked {
    self.enableDisableVideoButton.selected = NO;
    [self enableDisableVideo:self.enableDisableVideoButton];
    self.call = [[MEGASdkManager sharedMEGAChatSdk] chatCallForChatId:self.chatRoom.chatId];
    self.localPeer.video = YES;
    MEGALogDebug(@"[Audio] Enable loud speaker, tap on video callkit icon when device is locked");
    [self enableLoudspeaker];
}

#pragma mark - Private

- (void)answerChatCall {
    if ([MEGASdkManager.sharedMEGAChatSdk chatConnectionState:self.chatRoom.chatId] == MEGAChatConnectionOnline) {
        MEGAChatAnswerCallRequestDelegate *answerCallRequestDelegate = [MEGAChatAnswerCallRequestDelegate.alloc initWithCompletion:^(MEGAChatError *error) {
            if (error.type != MEGAChatErrorTypeOk) {
                [self dismissViewControllerAnimated:YES completion:^{
                    if (error.type == MEGAChatErrorTooMany) {
                        [SVProgressHUD showErrorWithStatus:AMLocalizedString(@"Error. No more participants are allowed in this group call.", @"Message show when a call cannot be established because there are too many participants in the group call")];
                    }
                }];
            } else {
                if (self.videoCall && !AVAudioSession.sharedInstance.mnz_isBluetoothAudioRouteAvailable) {
                    MEGALogDebug(@"[Audio] Enable loud speaker is video call and there is no bluetooth connected");
                    [self enableLoudspeaker];
                }
            }
        }];
        [MEGASdkManager.sharedMEGAChatSdk answerChatCall:self.chatRoom.chatId enableVideo:NO delegate:answerCallRequestDelegate];
    } else {
        self.enableDisableVideoButton.enabled = self.minimizeButton.enabled = NO;
        self.navigationSubtitleLabel.text = AMLocalizedString(@"connecting", @"Label in login screen to inform about the chat initialization proccess");
    }
}

- (void)customNavigationBarLabel {
    self.navigationTitleLabel.text = self.chatRoom.title;
    
    switch (self.callType) {
        case CallTypeActive: {
            MEGAChatCall *call = [[MEGASdkManager sharedMEGAChatSdk] chatCallForChatId:self.chatRoom.chatId];
            self.navigationSubtitleLabel.text = call && call.status == MEGAChatCallStatusInProgress ? @"" : AMLocalizedString(@"calling...", @"Label shown when you call someone (outgoing call), before the call starts.");
            break;
        }
            
        case CallTypeOutgoing:
            self.navigationSubtitleLabel.text = AMLocalizedString(@"calling...", @"Label shown when you call someone (outgoing call), before the call starts.");
            break;
            
        case CallTypeIncoming:
            self.navigationSubtitleLabel.text = AMLocalizedString(@"connecting", nil);
            break;
            
        default:
            break;
    }
}

- (void)configureControlsForLocalUser:(MEGAGroupCallPeer *)localUser {
    self.enableDisableVideoButton.selected = localUser.video;
    self.muteUnmuteMicrophone.selected = !localUser.audio;
    self.switchCameraButton.hidden = !localUser.video;
    [self updateSelectedCamera];
}

- (void)initDataSource {
    self.peersInCall = [NSMutableArray new];
    self.localPeer = [MEGAGroupCallPeer new];
    self.localPeer.video = [[NSUserDefaults standardUserDefaults] objectForKey:@"groupCallLocalVideo"] ? [[NSUserDefaults standardUserDefaults] boolForKey:@"groupCallLocalVideo"] : NO;
    self.localPeer.audio = [[NSUserDefaults standardUserDefaults] objectForKey:@"groupCallLocalAudio"] ? [[NSUserDefaults standardUserDefaults] boolForKey:@"groupCallLocalAudio"] : YES;
    self.switchCameraButton.selected = [[NSUserDefaults standardUserDefaults] objectForKey:@"groupCallCameraSwitched"] ? [[NSUserDefaults standardUserDefaults] boolForKey:@"groupCallCameraSwitched"] : NO;
    self.localPeer.peerId = 0;
    self.localPeer.clientId = 0;
    [self.peersInCall addObject:self.localPeer];
    
    [self configureControlsForLocalUser:self.localPeer];
    
    self.peerManualMode = nil;
    self.lastPeerTalking = nil;
    self.peerTalkingVideoView.group = YES;
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
    if (@available(iOS 11.0, *)) {
        self.navigationSubtitleLabel.text = [NSString mnz_stringFromTimeInterval:interval];
    } else {
        self.navigationItem.titleView =  [Helper customNavigationBarLabelWithTitle:self.chatRoom.title subtitle:[NSString mnz_stringFromTimeInterval:interval]];
        [self.navigationItem.titleView sizeToFit];
    }
}

- (void)updateParticipants {
    self.participantsLabel.text = [NSString stringWithFormat:@"%tu/%tu", [self participantsWithVideo], [MEGASdkManager sharedMEGAChatSdk].getMaxVideoCallParticipants];
}

- (NSInteger)participantsWithVideo {
    NSInteger videos = 0;
    for (MEGAGroupCallPeer *peer in self.peersInCall) {
        if (peer.video == CallPeerVideoOn) {
            videos = videos + 1;
        }
    }
    return videos;
}

- (void)configureGridCallLayout {
    self.manualMode = NO;
    self.peerManualMode = nil;
    if (!self.peerTalkingView.hidden) {
        [self removeAllVideoListeners];
        NSUInteger previousPeerIndex = [self.peersInCall indexOfObject:self.lastPeerTalking];
        GroupCallCollectionViewCell *cell = (GroupCallCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:previousPeerIndex inSection:0]];
        [cell hideUserOnFocus];
        self.peerTalkingView.hidden = YES;
        [UIView animateWithDuration:0.3f animations:^{
            self.peerTalkingViewHeightConstraint.constant = 0;
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.3f animations:^{
                self.collectionViewBottomConstraint.constant = 0;
                self.collectionView.userInteractionEnabled = NO;
            } completion:^(BOOL finished) {
                [self.collectionView reloadData];
                MEGALogDebug(@"[Group Call] Reload data %s", __PRETTY_FUNCTION__);
                [self hideSpinner];
            }];
        }];
    }
}

- (void)configureUserFocusedCallLayout {
    if (self.peerTalkingView.hidden) {
        [self removeAllVideoListeners];
        MEGAGroupCallPeer *firstPeer = self.peersInCall.firstObject;
        [self configureUserOnFocus:firstPeer manual:NO];
        [self.peerTalkingImageView mnz_setImageForUserHandle:firstPeer.peerId name:firstPeer.name];
        self.peerTalkingView.hidden = NO;
        UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
        if (orientation == UIInterfaceOrientationPortrait) {
            [UIView animateWithDuration:0.3f animations:^{
                self.peerTalkingViewHeightConstraint.constant = self.collectionView.frame.size.width;
            } completion:^(BOOL finished) {
                [UIView animateWithDuration:0.3f animations:^{
                    self.collectionViewBottomConstraint.constant = 80 - self.collectionView.frame.size.height;
                    self.collectionView.userInteractionEnabled = YES;
                } completion:^(BOOL finished) {
                    [self.collectionView reloadData];
                    MEGALogDebug(@"[Group Call] Reload data %s", __PRETTY_FUNCTION__);
                }];
            }];
        } else {
            [UIView animateWithDuration:0.3f animations:^{
                self.peerTalkingViewHeightConstraint.constant =  self.collectionView.frame.size.height - 80;
            } completion:^(BOOL finished) {
                [UIView animateWithDuration:0.3f animations:^{
                    self.collectionViewBottomConstraint.constant = 0;
                    self.collectionView.userInteractionEnabled = YES;
                } completion:^(BOOL finished) {
                    [self.collectionView reloadData];
                    MEGALogDebug(@"[Group Call] Reload data %s", __PRETTY_FUNCTION__);
                }];
            }];
        }
    }
}

- (void)removeAllVideoListeners {
    for (GroupCallCollectionViewCell *cell in self.collectionView.visibleCells) {
        if (!cell.videoImageView.hidden) {
            NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
            MEGAGroupCallPeer *peer = [self.peersInCall objectAtIndex:indexPath.item];
            if (peer.peerId != 0) {
                [cell removeRemoteVideoForPeer:peer inChat:self.chatRoom.chatId];
            } else {
                [cell removeLocalVideoInChat:self.chatRoom.chatId];
            }
        }
    }
    
    MEGAGroupCallPeer *previousPeerSelected = self.manualMode ? self.peerManualMode : self.lastPeerTalking;
    if (!self.peerTalkingVideoView.hidden && previousPeerSelected) {
        [[MEGASdkManager sharedMEGAChatSdk] removeChatRemoteVideo:self.chatRoom.chatId peerId:previousPeerSelected.peerId cliendId:previousPeerSelected.clientId delegate:self.peerTalkingVideoView];
        MEGALogDebug(@"[Group Call] Remove user focused remote video %p for peer %llu in client %llu --> %s", self.peerTalkingVideoView, previousPeerSelected.peerId, previousPeerSelected.clientId, __PRETTY_FUNCTION__);
    }
}

- (void)showOrHideControls {
    [UIView animateWithDuration:0.3f animations:^{
        if (self.callControlsView.alpha != 1.0f) {
            [self.callControlsView setAlpha:1.0f];
            [UIView animateWithDuration:0.25 animations:^{
                [self setNeedsStatusBarAppearanceUpdate];
            }];
        } else {
            [self.callControlsView setAlpha:0.0f];
            [UIView animateWithDuration:0.25 animations:^{
                [self setNeedsStatusBarAppearanceUpdate];
            }];
        }
        
        [self.view layoutIfNeeded];
    }];
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

- (void)showToastMessage:(NSString *)message color:(NSString *)color shouldHide:(BOOL)shouldHide {
    if (self.toastView.hidden) {
        self.toastTopConstraint.constant = -22;
        self.toastLabel.text = message;
        self.toastView.backgroundColor = [UIColor colorFromHexString:color];
        self.toastView.hidden = NO;
        
        [UIView animateWithDuration:.25 animations:^{
            self.toastTopConstraint.constant = 0;
            [self.view layoutIfNeeded];
        } completion:^(BOOL finished) {
            if (shouldHide) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    self.toastView.hidden = YES;
                    self.toastTopConstraint.constant = -22;
                    self.toastLabel.text = @"";
                });
            }
        }];
    }
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

- (MEGAGroupCallPeer *)peerForSession:(MEGAChatSession *)session {
    for (MEGAGroupCallPeer *peer in self.peersInCall) {
        if (peer.peerId == session.peerId && peer.clientId == session.clientId) {
            return peer;
        }
    }
    return nil;
}

- (MEGAGroupCallPeer *)peerForPeerId:(uint64_t)peerId clientId:(uint64_t)clientId {
    for (int i = 0; i < self.peersInCall.count; i++) {
        MEGAGroupCallPeer *peer = self.peersInCall[i];
        if (peerId == peer.peerId && clientId == peer.clientId) {
            return peer;
        }
    }
    return nil;
}

- (void)deleteActiveCallFlags {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"groupCallLocalVideo"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"groupCallLocalAudio"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"groupCallCameraSwitched"];
    if (@available(iOS 12.0, *)) {} else {
        [NSUserDefaults.standardUserDefaults synchronize];
    }
}

- (void)configureInitialUI {
    if (!self.timer.isValid) {
        [self.player stop];
        [self initDurationTimer];
        [self initShowHideControls];
        [self updateParticipants];
        self.enableDisableVideoButton.enabled = self.minimizeButton.enabled = YES;
    }
}

- (void)instantiatePeersInCall {
    for (int i = 0; i < self.call.sessionsPeerId.size; i ++) {
        uint64_t peerId = [self.call.sessionsPeerId megaHandleAtIndex:i];
        uint64_t clientId = [self.call.sessionsClientId megaHandleAtIndex:i];
        MEGAChatSession *chatSession = [self.call sessionForPeer:peerId clientId:clientId];
        MEGAGroupCallPeer *remoteUser = [[MEGAGroupCallPeer alloc] initWithSession:chatSession];
        [self.peersInCall insertObject:remoteUser atIndex:0];
    }
    if (self.call.numParticipants >= kSmallPeersLayout) {
        [self showSpinner];
        self.shouldHideAcivity = YES;
        [self configureUserOnFocus:self.peersInCall.firstObject manual:NO];
    }
    
    if (self.call.status == MEGAChatCallStatusInProgress) {
        [self initShowHideControls];
        [self initDurationTimer];
    }
    [self updateParticipants];
    [self.collectionView reloadData];
    MEGALogDebug(@"[Group Call] Reload data %s", __PRETTY_FUNCTION__);
}

- (void)joinActiveCall {
    __weak __typeof(self) weakSelf = self;
    
    [self deleteActiveCallFlags];
    
    MEGAChatStartCallRequestDelegate *startCallRequestDelegate = [[MEGAChatStartCallRequestDelegate alloc] initWithCompletion:^(MEGAChatError *error) {
        if (error.type) {
            [weakSelf dismissViewControllerAnimated:YES completion:^{
                if (error.type == MEGAChatErrorTooMany) {
                    [SVProgressHUD showErrorWithStatus:AMLocalizedString(@"Error. No more participants are allowed in this group call.", @"Message show when a call cannot be established because there are too many participants in the group call")];
                }
            }];
        } else {
            [self initDataSource];
            weakSelf.call = [[MEGASdkManager sharedMEGAChatSdk] chatCallForChatId:weakSelf.chatRoom.chatId];
            [weakSelf.megaCallManager addCall:weakSelf.call];
            [weakSelf.megaCallManager startCall:weakSelf.call];
            if (self.call.numParticipants >= kSmallPeersLayout) {
                [self showSpinner];
                [self configureUserOnFocus:self.peersInCall.firstObject manual:NO];
            }
            [self initDurationTimer];
            [self initShowHideControls];
            [self updateParticipants];
        }
    }];
    
    [[MEGASdkManager sharedMEGAChatSdk] startChatCall:self.chatRoom.chatId enableVideo:self.videoCall delegate:startCallRequestDelegate];
}

- (void)startOutgoingCall {
    __weak __typeof(self) weakSelf = self;
    
    MEGAChatStartCallRequestDelegate *startCallRequestDelegate = [[MEGAChatStartCallRequestDelegate alloc] initWithCompletion:^(MEGAChatError *error) {
        if (error.type) {
            [weakSelf dismissViewControllerAnimated:YES completion:nil];
        } else {
            weakSelf.call = [[MEGASdkManager sharedMEGAChatSdk] chatCallForChatId:weakSelf.chatRoom.chatId];
            weakSelf.callId = weakSelf.call.callId;
            [weakSelf.megaCallManager addCall:weakSelf.call];
            [weakSelf.megaCallManager startCall:weakSelf.call];
            
            [self.collectionView reloadData];
            MEGALogDebug(@"[Group Call] Reload data %s", __PRETTY_FUNCTION__);
            
            [AVAudioSession.sharedInstance mnz_setSpeakerEnabled:NO];
        }
    }];
    
    [[MEGASdkManager sharedMEGAChatSdk] startChatCall:self.chatRoom.chatId enableVideo:self.videoCall delegate:startCallRequestDelegate];
}

- (void)configureUserOnFocus:(MEGAGroupCallPeer *)peerSelected manual:(BOOL)manual {
    //if previous manual selected participant has video, remove it
    MEGAGroupCallPeer *previousPeerSelected = self.manualMode ? self.peerManualMode : self.lastPeerTalking;
    if (previousPeerSelected && !self.peerTalkingVideoView.hidden) {
        [[MEGASdkManager sharedMEGAChatSdk] removeChatRemoteVideo:self.chatRoom.chatId peerId:previousPeerSelected.peerId cliendId:previousPeerSelected.clientId delegate:self.peerTalkingVideoView];
        MEGALogDebug(@"[Group Call] Remove user focused remote video %p for peer %llu in client %llu --> %s", self.peerTalkingVideoView, previousPeerSelected.peerId, previousPeerSelected.clientId, __PRETTY_FUNCTION__);
    }
    
    self.manualMode = manual;
    
    //show border stroke of manual selected participant
    if (self.manualMode) {
        self.peerManualMode = peerSelected;
        NSUInteger peerIndex = [self.peersInCall indexOfObject:[self peerForPeerId:self.peerManualMode.peerId clientId:self.peerManualMode.clientId]];
        GroupCallCollectionViewCell *cell = (GroupCallCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:peerIndex inSection:0]];
        [cell showUserOnFocus];
    }
    
    //configure large view for manual selected participant
    MEGAChatSession *chatSessionManualMode = [self.call sessionForPeer:self.peerManualMode.peerId clientId:self.peerManualMode.clientId];
    if (chatSessionManualMode.hasVideo) {
        [[MEGASdkManager sharedMEGAChatSdk] addChatRemoteVideo:self.chatRoom.chatId peerId:chatSessionManualMode.peerId cliendId:chatSessionManualMode.clientId  delegate:self.peerTalkingVideoView];
        MEGALogDebug(@"[Group Call] Add user focused remote video %p for peer %llu in client %llu --> %s", self.peerTalkingVideoView, chatSessionManualMode.peerId, chatSessionManualMode.clientId, __PRETTY_FUNCTION__);
        self.peerTalkingVideoView.hidden = NO;
        self.peerTalkingImageView.hidden = YES;
    } else {
        [self.peerTalkingImageView mnz_setImageForUserHandle:self.peerManualMode.peerId name:self.peerManualMode.name];
        self.peerTalkingVideoView.hidden = YES;
        self.peerTalkingImageView.hidden = NO;
    }
    self.peerTalkingMuteView.hidden = chatSessionManualMode.hasAudio;
    self.peerTalkingQualityView.hidden = chatSessionManualMode.networkQuality < 2;
}

- (void)showSpinner {
    [self.collectionActivity startAnimating];
    self.collectionView.alpha = 0;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (self.collectionActivity.animating) {
            MEGALogDebug(@"GROUPCALL forcing hide spinner");
            [self hideSpinner];
            [self.collectionView reloadData];
            MEGALogDebug(@"[Group Call] Reload data %s", __PRETTY_FUNCTION__);
        }
    });
}

- (void)hideSpinner {
    [self.collectionActivity stopAnimating];
    self.collectionView.alpha = 1;
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

- (void)createChatSession:(MEGAChatSession *)chatSession {
    [self configureInitialUI];
    
    MEGAGroupCallPeer *remoteUser = [[MEGAGroupCallPeer alloc] initWithSession:chatSession];
    remoteUser.video = CallPeerVideoUnknown;
    remoteUser.audio = CallPeerAudioUnknown;
    
    NSString *displayName = [self.chatRoom userDisplayNameForUserHandle:chatSession.peerId];
    if (displayName) {
        remoteUser.name = displayName;
    } else {
        MEGAChatGenericRequestDelegate *delegate = [[MEGAChatGenericRequestDelegate alloc] initWithCompletion:^(MEGAChatRequest * _Nonnull request, MEGAChatError * _Nonnull error) {
            if (error.type) {
                return;
            }
            self.chatRoom = [MEGASdkManager.sharedMEGAChatSdk chatRoomForChatId:self.chatRoom.chatId];
            NSString *displayName = [self.chatRoom userDisplayNameForUserHandle:chatSession.peerId];
            remoteUser.name = displayName;
        }];
        [MEGASdkManager.sharedMEGAChatSdk loadUserAttributesForChatId:self.chatRoom.chatId usersHandles:@[@(chatSession.peerId)] delegate:delegate];
    }
    
    [self.peersInCall insertObject:remoteUser atIndex:0];
    
    if (UIApplication.sharedApplication.applicationState == UIApplicationStateActive) {
        [self.collectionView insertItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:0 inSection:0]]];
    } else {
        [self.collectionView reloadData];
    }
    
    if (self.peersInCall.count == kSmallPeersLayout) {
        [self configureUserFocusedCallLayout];
    }
}

- (void)destroyChatSession:(MEGAChatSession *)chatSession {
    MEGAGroupCallPeer *peerDestroyed = [self peerForSession:chatSession];
    
    if (peerDestroyed) {
        NSUInteger index = [self.peersInCall indexOfObject:peerDestroyed];
        GroupCallCollectionViewCell *cell = (GroupCallCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:index inSection:0]];
        if (!cell.videoImageView.hidden) {
            [cell removeRemoteVideoForPeer:peerDestroyed inChat:self.chatRoom.chatId];
        }
        
        [self.peersInCall removeObject:peerDestroyed];
        [self.collectionView deleteItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:index inSection:0]]];
        
        if (self.peersInCall.count == kSmallPeersLayout - 1) {
            [self configureGridCallLayout];
        }
        
        if (self.call.numParticipants >= kSmallPeersLayout) {
            MEGAGroupCallPeer *focusedPeer = self.manualMode ? self.peerManualMode : self.lastPeerTalking;
            if ([focusedPeer isEqualToPeer:peerDestroyed]) {
                [self configureUserOnFocus:self.peersInCall.firstObject manual:NO];
            }
        }
    } else {
        MEGALogDebug(@"GROUPCALL session destroyed for peer %llu not found", chatSession.peerId);
    }
}

- (void)updateSelectedCamera {
    NSString *currentlySelected = [MEGASdkManager.sharedMEGAChatSdk videoDeviceSelected];
    NSString *shouldBeSelected = self.switchCameraButton.selected ? self.backCamera : self.frontCamera;
    if (![currentlySelected isEqualToString:shouldBeSelected]) {
        [MEGASdkManager.sharedMEGAChatSdk setChatVideoInDevices:shouldBeSelected];
    }

    NSUInteger index = [self.peersInCall indexOfObject:self.localPeer];
     GroupCallCollectionViewCell *cell = (GroupCallCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:index inSection:0]];
    [cell localVideoMirror:!self.switchCameraButton.selected];
}

#pragma mark - MEGAChatCallDelegate

- (void)onChatSessionUpdate:(MEGAChatSdk *)api chatId:(uint64_t)chatId callId:(uint64_t)callId session:(MEGAChatSession *)session{
    MEGALogDebug(@"onChatSessionUpdate %@", session);

    if (self.callId != callId) {
        return;
    }
    
    MEGAGroupCallPeer *peerUpdated = [self peerForSession:session];
    
    if ([session hasChanged:MEGAChatSessionChangeRemoteAvFlags]) {
        if (peerUpdated) {
            NSUInteger index = [self.peersInCall indexOfObject:peerUpdated];
            GroupCallCollectionViewCell *cell = (GroupCallCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:index inSection:0]];
            
            if (peerUpdated.video != session.hasVideo) {
                peerUpdated.video = session.hasVideo;
                if (peerUpdated.video) {
                    if (cell.videoImageView.hidden) {
                        [cell addRemoteVideoForPeer:peerUpdated inChat:self.chatRoom.chatId];
                    }
                } else {
                    if (!cell.videoImageView.hidden) {
                        [cell removeRemoteVideoForPeer:peerUpdated inChat:self.chatRoom.chatId];
                    }
                }
                if (self.manualMode && [self.peerManualMode isEqualToPeer:peerUpdated]) {
                    if (peerUpdated.video) {
                        [[MEGASdkManager sharedMEGAChatSdk] addChatRemoteVideo:self.chatRoom.chatId peerId:peerUpdated.peerId cliendId:peerUpdated.clientId delegate:self.peerTalkingVideoView];
                        MEGALogDebug(@"[Group Call] Add user focused remote video %p for peer %llu in client %llu --> %s", self.peerTalkingVideoView, peerUpdated.peerId, peerUpdated.clientId, __PRETTY_FUNCTION__);
                        self.peerTalkingVideoView.hidden = NO;
                        self.peerTalkingImageView.hidden = YES;
                    } else {
                        [self.peerTalkingImageView mnz_setImageForUserHandle:peerUpdated.peerId name:peerUpdated.name];
                        self.peerTalkingVideoView.hidden = YES;
                        self.peerTalkingImageView.hidden = NO;
                    }
                    self.peerTalkingMuteView.hidden = peerUpdated.audio;
                    self.peerTalkingQualityView.hidden = peerUpdated.networkQuality < 2;
                }
                [self updateParticipants];
            }
            
            if (peerUpdated.audio != session.hasAudio) {
                peerUpdated.audio = session.hasAudio;
                [cell configureUserAudio:peerUpdated.audio];
                MEGAGroupCallPeer *previousPeerSelected = self.manualMode ? self.peerManualMode : self.lastPeerTalking;
                if ([previousPeerSelected isEqualToPeer:[self peerForSession:session]]) {
                    self.peerTalkingMuteView.hidden = peerUpdated.audio;
                }
            }
        } else {
            MEGALogDebug(@"GROUPCALL session changed AV flags for remote peer %llu not found", session.peerId);
        }
    }
    
    if ([session hasChanged:MEGAChatSessionChangeAudioLevel] && self.call.numParticipants >= kSmallPeersLayout && !self.isManualMode) {
        
        if (session.audioDetected) {
            if (self.lastPeerTalking.peerId != session.peerId) {
                if (!self.peerTalkingVideoView.hidden) {
                    [[MEGASdkManager sharedMEGAChatSdk] removeChatRemoteVideo:self.chatRoom.chatId peerId:self.lastPeerTalking.peerId cliendId:self.lastPeerTalking.clientId delegate:self.peerTalkingVideoView];
                    MEGALogDebug(@"[Group Call] Remove user focused remote video %p for peer %llu in client %llu --> %s", self.peerTalkingVideoView, session.peerId, session.clientId, __PRETTY_FUNCTION__);
                }
                
                if (session.hasVideo) {
                    [[MEGASdkManager sharedMEGAChatSdk] addChatRemoteVideo:self.chatRoom.chatId peerId:session.peerId cliendId:session.clientId delegate:self.peerTalkingVideoView];
                    MEGALogDebug(@"[Group Call] Add user focused remote video %p for peer %llu in client %llu --> %s", self.peerTalkingVideoView, session.peerId, session.clientId, __PRETTY_FUNCTION__);
                    self.peerTalkingVideoView.hidden = NO;
                    self.peerTalkingImageView.hidden = YES;
                } else {
                    [self.peerTalkingImageView mnz_setImageForUserHandle:session.peerId name:peerUpdated.name];
                    self.peerTalkingVideoView.hidden = YES;
                    self.peerTalkingImageView.hidden = NO;
                }
                self.lastPeerTalking = [[MEGAGroupCallPeer alloc] initWithSession:session];
            }
            
            self.peerTalkingMuteView.hidden = session.hasAudio;
            self.peerTalkingQualityView.hidden = session.networkQuality < 2;
        }
    }
    
    if ([session hasChanged:MEGAChatSessionChangeNetworkQuality]) {
        if (peerUpdated) {
            peerUpdated.networkQuality = session.networkQuality;
            NSUInteger index = [self.peersInCall indexOfObject:peerUpdated];
            GroupCallCollectionViewCell *cell = (GroupCallCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:index inSection:0]];
            
            [cell networkQualityChangedForPeer:peerUpdated];
        } else {
            MEGALogDebug(@"GROUPCALL session network quality changed for peer %llu not found", session.peerId);
        }
        
        if (session.networkQuality < 2) {
            [self showToastMessage:AMLocalizedString(@"Poor connection.", @"Message to inform the local user is having a bad quality network with someone in the current group call") color:@"#FFBF00" shouldHide:YES];
        }
    }
    
    if ([session hasChanged:MEGAChatSessionChangeStatus]) {
        MEGALogDebug(@"GROUPCALLACTIVITY MEGAChatCallChangeTypeSessionStatus with call participants: %tu and session status: %tu", self.call.numParticipants, session.status);
        switch (session.status) {
            case MEGAChatSessionStatusInitial:
                [self createChatSession:session];
                break;
                
            case MEGAChatSessionStatusDestroyed:
                [self destroyChatSession:session];
                break;
                
            case MEGAChatSessionStatusInvalid:
                MEGALogDebug(@"MEGAChatSessionStatusInvalid");
                break;
                
            case MEGAChatSessionStatusInProgress:
                MEGALogDebug(@"MEGAChatSessionStatusInProgress");
                break;
        }
    }
}

- (void)onChatCallUpdate:(MEGAChatSdk *)api call:(MEGAChatCall *)call {
    MEGALogDebug(@"onChatCallUpdate %@", call);
    
    if (self.callId == call.callId) {
        self.call = call;
    } else {
        return;
    }
    
    if ([call hasChangedForType:MEGAChatCallChangeTypeLocalAVFlags]) {
        if (self.localPeer) {
            self.muteUnmuteMicrophone.selected = !call.hasLocalAudio;
            self.localPeer.audio = call.hasLocalAudio ? CallPeerAudioOn : CallPeerAudioOff;
            NSUInteger index = [self.peersInCall indexOfObject:self.localPeer];
            GroupCallCollectionViewCell *cell = (GroupCallCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:index inSection:0]];
            [cell configureUserAudio:self.localPeer.audio];
        }
    }
    
    switch (call.status) {
            
        case MEGAChatCallStatusInProgress: {
            
            if (self.isReconnecting) {
                self.reconnecting = NO;
                self.toastView.hidden = YES;
                [self showToastMessage:AMLocalizedString(@"You are back!", @"Title shown when the user reconnect in a call.") color:@"#00BFA5" shouldHide:YES];
            }
            
            if ([call hasChangedForType:MEGAChatCallChangeTypeCallComposition]) {
                MEGALogDebug(@"GROUPCALLACTIVITY MEGAChatCallChangeTypeCallComposition with call participants: %tu and peers in call: %tu with call composition change: %llu", call.numParticipants, self.peersInCall.count, call.callCompositionChange);

                switch (call.callCompositionChange) {
                    case MEGAChatCallCompositionChangePeerRemoved: {
                        NSString *displayName = [self.chatRoom userDisplayNameForUserHandle:call.peeridCallCompositionChange];
                        if (displayName) {
                            [self showToastMessage:[NSString stringWithFormat:AMLocalizedString(@"%@ left the call.", @"Message to inform the local user that someone has left the current group call"), displayName] color:@"#00BFA5" shouldHide:YES];
                        } else {
                            MEGAChatGenericRequestDelegate *delegate = [[MEGAChatGenericRequestDelegate alloc] initWithCompletion:^(MEGAChatRequest * _Nonnull request, MEGAChatError * _Nonnull error) {
                                if (error.type) {
                                    return;
                                }
                                
                                self.chatRoom = [MEGASdkManager.sharedMEGAChatSdk chatRoomForChatId:self.chatRoom.chatId];
                                [self showToastMessage:[NSString stringWithFormat:AMLocalizedString(@"%@ left the call.", @"Message to inform the local user that someone has left the current group call"), [self.chatRoom userDisplayNameForUserHandle:call.peeridCallCompositionChange]] color:@"#00BFA5" shouldHide:YES];
                            }];
                            [MEGASdkManager.sharedMEGAChatSdk loadUserAttributesForChatId:self.chatRoom.chatId usersHandles:@[@(call.peeridCallCompositionChange)] delegate:delegate];
                        }
                        
                        break;
                    }
                        
                    case MEGAChatCallCompositionChangePeerAdded: {
                        NSString *displayName = [self.chatRoom userDisplayNameForUserHandle:call.peeridCallCompositionChange];
                        if (displayName) {
                            [self showToastMessage:[NSString stringWithFormat:AMLocalizedString(@"%@ joined the call.", @"Message to inform the local user that someone has joined the current group call"), displayName] color:@"#00BFA5" shouldHide:YES];
                        } else {
                            MEGAChatGenericRequestDelegate *delegate = [[MEGAChatGenericRequestDelegate alloc] initWithCompletion:^(MEGAChatRequest * _Nonnull request, MEGAChatError * _Nonnull error) {
                                if (error.type) {
                                    return;
                                }
                                
                                self.chatRoom = [MEGASdkManager.sharedMEGAChatSdk chatRoomForChatId:self.chatRoom.chatId];
                                [self showToastMessage:[NSString stringWithFormat:AMLocalizedString(@"%@ joined the call.", @"Message to inform the local user that someone has joined the current group call"), [self.chatRoom userDisplayNameForUserHandle:call.peeridCallCompositionChange]] color:@"#00BFA5" shouldHide:YES];
                            }];
                            [MEGASdkManager.sharedMEGAChatSdk loadUserAttributesForChatId:self.chatRoom.chatId usersHandles:@[@(call.peeridCallCompositionChange)] delegate:delegate];
                        }
                        
                        break;
                    }
                        
                    default:
                        break;
                }
                [self updateParticipants];
            }
            
            break;
        }
    
        case MEGAChatCallStatusTerminatingUserParticipation:
        case MEGAChatCallStatusDestroyed: {
            
            [self.timer invalidate];

            [self.player stop];
            
            NSString *soundFilePath = [[NSBundle mainBundle] pathForResource:@"hang_out" ofType:@"mp3"];
            NSURL *soundFileURL = [NSURL fileURLWithPath:soundFilePath];
            self.player = [[AVAudioPlayer alloc] initWithContentsOfURL:soundFileURL error:nil];
            
            [self.player play];
            
            [self deleteActiveCallFlags];
            
            [self dismissViewControllerAnimated:YES completion:^{
                [self enablePasscodeIfNeeded];
            }];
            break;
        }
            
        case MEGAChatCallStatusReconnecting: {
            self.reconnecting = YES;
            [self showToastMessage:AMLocalizedString(@"Reconnecting...", @"Title shown when the user lost the connection in a call, and the app will try to reconnect the user again") color:@"#F5A623" shouldHide:NO];
            NSUInteger size = call.sessionsPeerId.size;
            for (int i = 0; i < size; i++) {
                MEGAChatSession *chatSession = [call sessionForPeer:[call.sessionsPeerId megaHandleAtIndex:i] clientId:[call.sessionsClientId megaHandleAtIndex:i]];
                [self destroyChatSession:chatSession];
            }
            break;
        }
            
        default:
            break;
    }
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    
    if (touch.view.class == UIButton.class) {
        return NO;
    }
    
    if ((CGRectContainsPoint(self.collectionView.frame, [touch locationInView:self.view]) && self.call.numParticipants >= kSmallPeersLayout)) {
        return NO;
    }
    
    return YES;
}

@end
