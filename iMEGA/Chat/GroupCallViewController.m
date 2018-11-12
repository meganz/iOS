
#import "GroupCallViewController.h"

#import <AVFoundation/AVFoundation.h>
#import <QuartzCore/QuartzCore.h>

#import "LTHPasscodeViewController.h"

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
#import "MEGANavigationController.h"
#import "MEGASdkManager.h"

#define kSmallPeersLayout 7

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
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *collectionViewBottomConstraint;
@property (weak, nonatomic) IBOutlet MEGARemoteImageView *peerTalkingVideoView;
@property (weak, nonatomic) IBOutlet UIView *peerTalkingView;
@property (weak, nonatomic) IBOutlet UIImageView *peerTalkingImageView;
@property (weak, nonatomic) IBOutlet UIImageView *peerTalkingMuteView;
@property (weak, nonatomic) IBOutlet UIView *peerTalkingQualityView;

@property (weak, nonatomic) IBOutlet UIView *participantsView;
@property (weak, nonatomic) IBOutlet UILabel *participantsLabel;

@property BOOL loudSpeakerEnabled;

@property (strong, nonatomic) NSMutableArray<MEGAGroupCallPeer *> *peersInCall;
@property (assign, nonatomic) uint64_t lastPeerTalking;

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
    
    [self configureNavigation];
    [self configureControls];
    [self initDataSource];
 
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
        self.call = [[MEGASdkManager sharedMEGAChatSdk] chatCallForChatId:self.chatRoom.chatId];

        if (self.call.sessions.size != 0) {
            for (int i = 0; i < self.call.sessions.size; i ++) {
                MEGAChatSession *chatSession = [self.call sessionForPeer:[self.call.sessions megaHandleAtIndex:i]];
                MEGAGroupCallPeer *remoteUser = [[MEGAGroupCallPeer alloc] initWithSession:chatSession];
                [self.peersInCall insertObject:remoteUser atIndex:0];
            }
            self.incomingCallView.hidden = YES;
            [self initDurationTimer];
            [self initShowHideControls];
            [self updateParticipants];
            [self.collectionView reloadData];
        } else {
            __weak __typeof(self) weakSelf = self;
            
            MEGAChatStartCallRequestDelegate *startCallRequestDelegate = [[MEGAChatStartCallRequestDelegate alloc] initWithCompletion:^(MEGAChatError *error) {
                if (error.type) {
                    [weakSelf dismissViewControllerAnimated:YES completion:nil];
                } else {
                    weakSelf.call = [[MEGASdkManager sharedMEGAChatSdk] chatCallForChatId:weakSelf.chatRoom.chatId];
                    weakSelf.incomingCallView.hidden = YES;
                    
                    [self initDurationTimer];
                    [self initShowHideControls];
                    [self updateParticipants];
                    [self shouldChangeCallLayout];
                    [self.collectionView reloadData];
                }
            }];
            
            [[MEGASdkManager sharedMEGAChatSdk] startChatCall:self.chatRoom.chatId enableVideo:self.videoCall delegate:startCallRequestDelegate];
        }
    }
    
    [[UIDevice currentDevice] setProximityMonitoringEnabled:!self.videoCall];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didSessionRouteChange:) name:AVAudioSessionRouteChangeNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[MEGASdkManager sharedMEGAChatSdk] addChatCallDelegate:self];
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
}

- (void)viewDidAppear:(BOOL)animated {
    if (self.callType == CallTypeActive) {
        [self shouldChangeCallLayout];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [UINavigationBar appearanceWhenContainedInInstancesOfClasses:@[MEGANavigationController.class]].barTintColor = UIColor.mnz_redMain;

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
        if (self.call.numParticipants >= kSmallPeersLayout) {
            UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
            if (orientation == UIInterfaceOrientationPortrait) {
                [UIView animateWithDuration:0.3f animations:^{
                    self.peerTalkingViewHeightConstraint.constant = 400;
                    self.collectionViewBottomConstraint.constant = 100 + self.peerTalkingViewHeightConstraint.constant - self.view.frame.size.height;
                } completion:^(BOOL finished) {
                    if (finished) {
                        [self.collectionView.collectionViewLayout invalidateLayout];
                    }
                }];
            } else {
                [UIView animateWithDuration:0.3f animations:^{
                    self.collectionViewBottomConstraint.constant = 0;
                    self.peerTalkingViewHeightConstraint.constant = self.view.frame.size.height - 100;
                } completion:^(BOOL finished) {
                    if (finished) {
                        [self.collectionView.collectionViewLayout invalidateLayout];
                    }
                }];
            }
            self.collectionView.userInteractionEnabled = YES;
        } else {
            [self.collectionView.collectionViewLayout invalidateLayout];
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
    [cell configureCellForPeer:peer inChat:self.chatRoom.chatId];
    
    return cell;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    MEGAGroupCallPeer *peer = [self.peersInCall objectAtIndex:indexPath.row];
    GroupCallCollectionViewCell *groupCallCell = (GroupCallCollectionViewCell *)cell;
    [groupCallCell configureCellForPeer:peer inChat:self.chatRoom.chatId];
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
        if (self.callType == CallTypeActive) {
            [[MEGASdkManager sharedMEGAChatSdk] hangChatCall:self.chatRoom.chatId];
        } else {
            [self.megaCallManager endCall:self.call];
        }
    } else {
        [[MEGASdkManager sharedMEGAChatSdk] hangChatCall:self.chatRoom.chatId];
    }
}

- (IBAction)muteOrUnmuteCall:(UIButton *)sender {
    MEGAChatEnableDisableAudioRequestDelegate *enableDisableAudioRequestDelegate = [[MEGAChatEnableDisableAudioRequestDelegate alloc] initWithCompletion:^(MEGAChatError *error) {
        if (error.type == MEGAChatErrorTypeOk) {
            
            MEGAGroupCallPeer *localUserAudioFlagChanged = [self peerForId:0];
            
            if (localUserAudioFlagChanged) {
                localUserAudioFlagChanged.audio = sender.selected;
                NSUInteger index = [self.peersInCall indexOfObject:localUserAudioFlagChanged];
                GroupCallCollectionViewCell *cell = (GroupCallCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:index inSection:0]];
                [cell configureUserAudio:localUserAudioFlagChanged.audio];
                
                sender.selected = !sender.selected;
                self.loudSpeakerEnabled = !sender.selected;
            }
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
                    
                    MEGAGroupCallPeer *localUserVideoFlagChanged = [self peerForId:0];
                    
                    if (localUserVideoFlagChanged) {
                        localUserVideoFlagChanged.video = !sender.selected;
                        NSUInteger index = [self.peersInCall indexOfObject:localUserVideoFlagChanged];
                         GroupCallCollectionViewCell *cell = (GroupCallCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:index inSection:0]];
                        
                        if (sender.selected) {
                            [cell removeLocalVideoInChat:self.chatRoom.chatId];
                        } else {
                            [cell addLocalVideoInChat:self.chatRoom.chatId];
                        }
                        [[UIDevice currentDevice] setProximityMonitoringEnabled:sender.selected];
                        sender.selected = !sender.selected;
                        self.loudSpeakerEnabled = !sender.selected;
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
    MEGAGroupCallPeer *localUser = [self peerForId:0];
    [[NSUserDefaults standardUserDefaults] setBool:localUser.video forKey:@"groupCallLocalVideo"];
    [[NSUserDefaults standardUserDefaults] setBool:localUser.audio forKey:@"groupCallLocalAudio"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self.timer invalidate];
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Private

- (void)configureNavigation {
    if (self.callType == CallTypeActive) {
        self.title = self.chatRoom.title;
    } else {
        [self.navigationItem setTitleView:[Helper customNavigationBarLabelWithTitle:self.chatRoom.title subtitle:AMLocalizedString(@"connecting", nil)]];
        [self.navigationItem.titleView sizeToFit];
    }
    
    [UINavigationBar appearanceWhenContainedInInstancesOfClasses:@[MEGANavigationController.class]].barTintColor = [UIColor colorWithRed:0.08 green:0.08 blue:0.07 alpha:0.9];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.participantsView];
    [self updateParticipants];
}

- (void)configureControls {
    self.enableDisableVideoButton.selected = self.videoCall;
    self.enableDisableSpeaker.selected = self.videoCall;
    if (self.videoCall) {
        [self enableLoudspeaker];
    } else {
        [self disableLoudspeaker];
    }
}

- (void)initDataSource {
    self.peersInCall = [NSMutableArray new];
    MEGAGroupCallPeer *localUser = [MEGAGroupCallPeer new];
    localUser.video = [[NSUserDefaults standardUserDefaults] objectForKey:@"groupCallLocalVideo"] ? [[NSUserDefaults standardUserDefaults] boolForKey:@"groupCallLocalVideo"] : self.videoCall;
    localUser.audio = [[NSUserDefaults standardUserDefaults] objectForKey:@"groupCallLocalAudio"] ? [[NSUserDefaults standardUserDefaults] boolForKey:@"groupCallLocalAudio"] : YES;
    localUser.peerId = 0;
    [self.peersInCall addObject:localUser];
    
    self.enableDisableVideoButton.selected = localUser.video;
    self.muteUnmuteMicrophone.selected = !localUser.audio;

    self.lastPeerTalking = 0;
    self.peerTalkingVideoView.group = YES;
    [self.peerTalkingImageView mnz_setImageForUserHandle:[MEGASdkManager sharedMEGAChatSdk].myUserHandle];
}

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
    self.participantsLabel.text = [NSString stringWithFormat:@"%lu/%lu", self.peersInCall.count, (unsigned long)self.chatRoom.peerCount + 1];
}

- (void)shouldChangeCallLayout {
    if (self.call.numParticipants < kSmallPeersLayout) {
        if (!self.peerTalkingView.hidden) {
            NSUInteger previousPeerIndex = [self.peersInCall indexOfObject:[self peerForId:self.lastPeerTalking]];
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
                    [self.collectionView.collectionViewLayout invalidateLayout];
                }];
            }];
        }
    } else {
        if (self.peerTalkingView.hidden) {
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
                        [self.collectionView.collectionViewLayout invalidateLayout];
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
                        [self.collectionView.collectionViewLayout invalidateLayout];
                    }];
                }];
            }
            
        }
    }
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
    self.toastView.backgroundColor = [UIColor colorFromHexString:color];
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

- (MEGAGroupCallPeer *)peerForId:(uint64_t)peerId {
    for (MEGAGroupCallPeer *peer in self.peersInCall) {
        if (peer.peerId == peerId) {
            return peer;
        }
    }
    return nil;
}

#pragma mark - MEGAChatCallDelegate

- (void)onChatCallUpdate:(MEGAChatSdk *)api call:(MEGAChatCall *)call {
    MEGALogDebug(@"onChatCallUpdate %@", call);
    
    if (self.call.callId == call.callId) {
        self.call = call;
    } else {
        return;
    }
    
    switch (self.call.status) {
            
        case MEGAChatCallStatusInProgress: {
            
            if ([call hasChangedForType:MEGAChatCallChangeTypeRemoteAVFlags]) {

                MEGAChatSession *chatSessionWithAVFlags = [self.call sessionForPeer:[self.call peerSessionStatusChange]];
                
                MEGAGroupCallPeer *peerAVFlagsChanged = [self peerForId:chatSessionWithAVFlags.peerId];

                if (peerAVFlagsChanged) {
                    MEGALogDebug(@"GROUPCALLCELL ChangeTypeRemoteAVFlags for peer %llu, video: %d audio: %d", chatSessionWithAVFlags.peerId, chatSessionWithAVFlags.video, chatSessionWithAVFlags.audio);

                    NSUInteger index = [self.peersInCall indexOfObject:peerAVFlagsChanged];
                    GroupCallCollectionViewCell *cell = (GroupCallCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:index inSection:0]];
                    
                    if (peerAVFlagsChanged.video != chatSessionWithAVFlags.hasVideo) {
                        peerAVFlagsChanged.video = chatSessionWithAVFlags.hasVideo;
                        if (peerAVFlagsChanged.video) {
                            [cell addRemoteVideoForPeer:peerAVFlagsChanged inChat:self.chatRoom.chatId];
                        } else {
                            [cell removeRemoteVideoForPeer:peerAVFlagsChanged inChat:self.chatRoom.chatId];
                        }
                    }
                    
                    if (peerAVFlagsChanged.audio != chatSessionWithAVFlags.hasAudio) {
                        peerAVFlagsChanged.audio = chatSessionWithAVFlags.hasAudio;
                        [cell configureUserAudio:peerAVFlagsChanged.audio];
                    }
                } else {
                    MEGALogDebug(@"GROUPCALL session changed AV flags for remote peer %llu not found", chatSessionWithAVFlags.peerId);
                }
            }
            
            if ([call hasChangedForType:MEGAChatCallChangeTypeAudioLevel] && self.call.numParticipants >= kSmallPeersLayout) {
                MEGAChatSession *chatSessionWithAudioLevel = [self.call sessionForPeer:[self.call peerSessionStatusChange]];
                
                if (chatSessionWithAudioLevel.audioDetected) {
                    if (self.lastPeerTalking != chatSessionWithAudioLevel.peerId) {
                        NSUInteger previousPeerIndex = [self.peersInCall indexOfObject:[self peerForId:self.lastPeerTalking]];
                        GroupCallCollectionViewCell *cell = (GroupCallCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:previousPeerIndex inSection:0]];
                        [cell hideUserOnFocus];
                        [[MEGASdkManager sharedMEGAChatSdk] removeChatRemoteVideo:self.chatRoom.chatId peerId:self.lastPeerTalking delegate:self.peerTalkingVideoView];
                        MEGALogDebug(@"GROUPCALL remove user focused remote video for peer %llu", self.lastPeerTalking);
                        
                        NSUInteger peerIndex = [self.peersInCall indexOfObject:[self peerForId:chatSessionWithAudioLevel.peerId]];
                        cell = (GroupCallCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:peerIndex inSection:0]];
                        [cell showUserOnFocus];
                        
                        if (chatSessionWithAudioLevel.hasVideo) {
                            [[MEGASdkManager sharedMEGAChatSdk] addChatRemoteVideo:self.chatRoom.chatId peerId:chatSessionWithAudioLevel.peerId delegate:self.peerTalkingVideoView];
                            MEGALogDebug(@"GROUPCALL add user focused remote video for peer %llu", chatSessionWithAudioLevel.peerId);
                            self.lastPeerTalking = chatSessionWithAudioLevel.peerId;
                            self.peerTalkingVideoView.hidden = NO;
                            self.peerTalkingImageView.hidden = YES;
                        } else {
                            self.lastPeerTalking = chatSessionWithAudioLevel.peerId;
                            [self.peerTalkingImageView mnz_setImageForUserHandle:chatSessionWithAudioLevel.peerId];
                            self.peerTalkingVideoView.hidden = YES;
                            self.peerTalkingImageView.hidden = NO;
                        }
                    }
                    
                    self.peerTalkingMuteView.hidden = chatSessionWithAudioLevel.hasAudio;
                    self.peerTalkingQualityView.hidden = chatSessionWithAudioLevel.networkQuality < 2;
                }
            }
            
            if ([call hasChangedForType:MEGAChatCallChangeTypeNetworkQuality]) {
                
                MEGAChatSession *chatSessionWithNetworkQuality = [self.call sessionForPeer:[self.call peerSessionStatusChange]];
                
                MEGAGroupCallPeer *peerNetworkQuality = [self peerForId:chatSessionWithNetworkQuality.peerId];
                
                if (peerNetworkQuality) {
                    peerNetworkQuality.networkQuality = chatSessionWithNetworkQuality.networkQuality;
                    NSUInteger index = [self.peersInCall indexOfObject:peerNetworkQuality];
                    GroupCallCollectionViewCell *cell = (GroupCallCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:index inSection:0]];
                    
                    [cell networkQualityChangedForPeer:peerNetworkQuality];
                } else {
                    MEGALogDebug(@"GROUPCALL session network quality changed for peer %llu not found", chatSessionWithNetworkQuality.peerId);
                }
                
                if (chatSessionWithNetworkQuality.networkQuality < 2) {
                    [self showToastMessage:AMLocalizedString(@"Poor conection.", @"Message to inform the local user is having a bad quality network with someone in the current group call") color:@"#FFBF00"];
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
            
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"groupCallLocalVideo"];
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"groupCallLocalAudio"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            [self dismissViewControllerAnimated:YES completion:^{
                [self enablePasscodeIfNeeded];
            }];
            break;
        }
                        
        default:
            break;
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
                }
                
                MEGAGroupCallPeer *remoteUser = [[MEGAGroupCallPeer alloc] initWithSession:chatSession];
                [self.peersInCall insertObject:remoteUser atIndex:0];

                [self.collectionView insertItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:0 inSection:0]]];
                
                [self showToastMessage:[NSString stringWithFormat:AMLocalizedString(@"%@ joined the call.", @"Message to inform the local user that someone has joined the current group call"), [self.chatRoom peerFullnameByHandle:chatSession.peerId]] color:@"#00BFA5"];
                [self updateParticipants];

                break;
            }
                
            case MEGAChatSessionStatusInProgress: {
                self.outgoingCallView.hidden = NO;
                self.incomingCallView.hidden = YES;
                break;
            }
                
            case MEGAChatSessionStatusDestroyed: {
                
                MEGAGroupCallPeer *peerDestroyed = [self peerForId:chatSession.peerId];
                
                if (peerDestroyed) {
                    NSUInteger index = [self.peersInCall indexOfObject:peerDestroyed];
                    [self.peersInCall removeObject:peerDestroyed];
                    
                    GroupCallCollectionViewCell *cell = (GroupCallCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:index inSection:0]];
                    [cell removeRemoteVideoForPeer:peerDestroyed inChat:self.chatRoom.chatId];
                    [self.collectionView deleteItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:index inSection:0]]];

                    [self showToastMessage:[NSString stringWithFormat:AMLocalizedString(@"%@ left the call.", @"Message to inform the local user that someone has left the current group call"), [self.chatRoom peerFullnameByHandle:chatSession.peerId]] color:@"#00BFA5"];
                    [self updateParticipants];
                } else {
                    MEGALogDebug(@"GROUPCALL session destroyed for peer %llu not found", chatSession.peerId);
                }
                break;
            }
               
            case MEGAChatSessionStatusInvalid:
                MEGALogDebug(@"MEGAChatSessionStatusInvalid");
                break;
        }
    }
    
    if ([call hasChangedForType:MEGAChatCallChangeTypeCallComposition]) {
        [self shouldChangeCallLayout];
    }
}

@end
