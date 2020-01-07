
#import "MEGAProviderDelegate.h"

#import <AVFoundation/AVFoundation.h>

#import <WebRTC/RTCDispatcher.h>
#import <WebRTC/RTCAudioSession.h>
#import <WebRTC/RTCAudioSessionConfiguration.h>

#import "LTHPasscodeViewController.h"

#import "CallViewController.h"
#import "GroupCallViewController.h"
#import "UIApplication+MNZCategory.h"

#import "MEGANavigationController.h"

@interface MEGAProviderDelegate ()

@property (nonatomic, copy) MEGACallManager *megaCallManager;
@property (nonatomic, strong) CXProvider *provider;

@property (strong, nonatomic) AVAudioPlayer *player;

@end

@implementation MEGAProviderDelegate

- (instancetype)initWithMEGACallManager:(MEGACallManager *)megaCallManager {
    self = [super init];
    
    if (self) {
        _megaCallManager = megaCallManager;
        
        CXProviderConfiguration *configuration = [[CXProviderConfiguration alloc] initWithLocalizedName:@"MEGA"];
        configuration.supportsVideo = YES;
        configuration.maximumCallsPerCallGroup = 1;
        configuration.maximumCallGroups = 1;
        configuration.supportedHandleTypes = [NSSet setWithObjects:@(CXHandleTypeEmailAddress), @(CXHandleTypeGeneric), nil];
        configuration.iconTemplateImageData = UIImagePNGRepresentation([UIImage imageNamed:@"MEGA_icon_call"]);
        _provider = [[CXProvider alloc] initWithConfiguration:configuration];
        
        [_provider setDelegate:self queue:nil];
    }
    
    return self;
}

- (void)reportIncomingCall:(MEGAChatCall *)call {
    MEGALogDebug(@"[CallKit] Report incoming call %@ with uuid %@, video %@", call, call.uuid, call.hasVideoInitialCall ? @"YES" : @"NO");
    
    MEGAChatRoom *chatRoom = [[MEGASdkManager sharedMEGAChatSdk] chatRoomForChatId:call.chatId];

    CXCallUpdate *update = [[CXCallUpdate alloc] init];
    update.remoteHandle = [[CXHandle alloc] initWithType:CXHandleTypeGeneric value:[MEGASdk base64HandleForUserHandle:chatRoom.chatId]];
    update.localizedCallerName = chatRoom.title;
    update.supportsHolding = NO;
    update.supportsGrouping = NO;
    update.supportsUngrouping = NO;
    update.supportsDTMF = NO;
    update.hasVideo = call.hasVideoInitialCall;
    [self.provider reportNewIncomingCallWithUUID:call.uuid update:update completion:^(NSError * _Nullable error) {
        if (error) {
            MEGALogError(@"Report new incoming call failed with error: %@", error);
        } else {
            [self.megaCallManager addCall:call];
        }
    }];
}

- (void)reportOutgoingCall:(MEGAChatCall *)call {
    NSUUID *uuid = [self.megaCallManager UUIDForCall:call];
    MEGALogDebug(@"[CallKit] Report outgoing call %@ with uuid %@", call, uuid);
    
    [self stopDialerTone];
    [self.provider reportOutgoingCallWithUUID:uuid connectedAtDate:nil];
}

- (void)reportEndCall:(MEGAChatCall *)call {
    NSUUID *uuid = [self.megaCallManager UUIDForCall:call];
    MEGALogDebug(@"[CallKit] Report end call %@ with uuid %@", call, uuid);
    if (!uuid) return;
    
    CXCallEndedReason callEndedReason = 0;
    switch (call.termCode) {
        case MEGAChatCallTermCodeError:
            callEndedReason = CXCallEndedReasonFailed;
            break;
            
        case MEGAChatCallTermCodeCallReject:
        case MEGAChatCallTermCodeCallReqCancel:
        case MEGAChatCallTermCodeUserHangup:
            if (!call.localTermCode) {
                callEndedReason = CXCallEndedReasonRemoteEnded;
            }
            break;
            
        case MEGAChatCallTermCodeRingOutTimeout:
        case MEGAChatCallTermCodeAnswerTimeout:
            callEndedReason = CXCallEndedReasonUnanswered;
            break;
            
        case MEGAChatCallTermCodeAnswerElseWhere:
            callEndedReason = CXCallEndedReasonAnsweredElsewhere;
            break;
            
        case MEGAChatCallTermCodeRejectElseWhere:
            callEndedReason = CXCallEndedReasonDeclinedElsewhere;
            break;
            
        default:
            break;
    }
    
    MEGALogDebug(@"[CallKit] Report end call reason %ld", (long)callEndedReason);
    if (callEndedReason) {
        [self.provider reportCallWithUUID:uuid endedAtDate:nil reason:callEndedReason];
    }
    [self.megaCallManager removeCallByUUID:uuid];
}

- (void)stopDialerTone {
    [self.player stop];
}

- (void)disablePasscodeIfNeeded {
    if (UIApplication.sharedApplication.applicationState == UIApplicationStateBackground || [[LTHPasscodeViewController sharedUser] isLockscreenPresent]) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"presentPasscodeLater"];
        [LTHPasscodeViewController close];
    }
    [[LTHPasscodeViewController sharedUser] disablePasscodeWhenApplicationEntersBackground];
}

#pragma mark - CXProviderDelegate

- (void)providerDidReset:(CXProvider *)provider {
    MEGALogDebug(@"[CallKit] Provider did reset");
    [self.megaCallManager removeAllCalls];
}

- (void)providerDidBegin:(CXProvider *)provider {
    MEGALogDebug(@"[CallKit] Provider did begin");
}

- (void)provider:(CXProvider *)provider performStartCallAction:(CXStartCallAction *)action {
    MEGAChatCall *call = [self.megaCallManager callForUUID:action.callUUID];
    
    MEGALogDebug(@"[CallKit] Provider perform start call: %@, uuid: %@", call, action.callUUID);
    
    if (call) {
        MEGAChatRoom *chatRoom = [[MEGASdkManager sharedMEGAChatSdk] chatRoomForChatId:call.chatId];
        
        CXCallUpdate *update = [[CXCallUpdate alloc] init];
        update.remoteHandle = [[CXHandle alloc] initWithType:CXHandleTypeGeneric value:[MEGASdk base64HandleForUserHandle:chatRoom.chatId]];
        update.localizedCallerName = chatRoom.title;
        update.supportsHolding = NO;
        update.supportsGrouping = NO;
        update.supportsUngrouping = NO;
        update.supportsDTMF = NO;
        update.hasVideo = call.hasVideoInitialCall;
        
        [provider reportCallWithUUID:action.callUUID updated:update];
        
        [provider reportOutgoingCallWithUUID:action.callUUID startedConnectingAtDate:nil];
        [action fulfill];
        [self disablePasscodeIfNeeded];
    } else {
        [action fail];
    }
}

- (void)provider:(CXProvider *)provider performAnswerCallAction:(CXAnswerCallAction *)action {
    MEGAChatCall *call = [self.megaCallManager callForUUID:action.callUUID];
    
    MEGALogDebug(@"[CallKit] Provider perform answer call: %@, uuid: %@", call, action.callUUID);
    
    [RTCDispatcher dispatchAsyncOnType:RTCDispatcherTypeAudioSession block:^{
        RTCAudioSession *audioSession = RTCAudioSession.sharedInstance;
        [audioSession lockForConfiguration];
        RTCAudioSessionConfiguration *configuration = [RTCAudioSessionConfiguration webRTCConfiguration];
        configuration.categoryOptions = AVAudioSessionCategoryOptionAllowBluetoothA2DP | AVAudioSessionCategoryOptionDuckOthers | AVAudioSessionCategoryOptionAllowBluetooth;
        [audioSession setConfiguration:configuration error:nil];
        [audioSession unlockForConfiguration];
    }];
    
    if (call) {
        MEGAChatRoom *chatRoom = [[MEGASdkManager sharedMEGAChatSdk] chatRoomForChatId:call.chatId];
        if (chatRoom.isGroup) {
            GroupCallViewController *groupCallVC = [[UIStoryboard storyboardWithName:@"Chat" bundle:nil] instantiateViewControllerWithIdentifier:@"GroupCallViewControllerID"];
            groupCallVC.videoCall = call.hasVideoInitialCall;
            groupCallVC.chatRoom = chatRoom;
            groupCallVC.megaCallManager = self.megaCallManager;
            groupCallVC.call = call;
            
            if ([UIApplication.mnz_presentingViewController isKindOfClass:CallViewController.class]) {
                [UIApplication.mnz_presentingViewController dismissViewControllerAnimated:YES completion:^{
                    [UIApplication.mnz_presentingViewController presentViewController:groupCallVC animated:YES completion:nil];
                }];
            } else if ([UIApplication.mnz_presentingViewController isKindOfClass:GroupCallViewController.class]) {
                [UIApplication.mnz_presentingViewController dismissViewControllerAnimated:YES completion:^{
                    [UIApplication.mnz_presentingViewController presentViewController:groupCallVC animated:YES completion:nil];
                }];
            } else {
                [UIApplication.mnz_presentingViewController presentViewController:groupCallVC animated:YES completion:nil];
            }
        } else {
            CallViewController *callVC = [[UIStoryboard storyboardWithName:@"Chat" bundle:nil] instantiateViewControllerWithIdentifier:@"CallViewControllerID"];
            callVC.chatRoom  = chatRoom;
            callVC.videoCall = call.hasVideoInitialCall;
            callVC.callType = CallTypeIncoming;
            callVC.megaCallManager = self.megaCallManager;
            callVC.call = call;
            
            if ([UIApplication.mnz_presentingViewController isKindOfClass:CallViewController.class] || [UIApplication.mnz_presentingViewController isKindOfClass:MEGANavigationController.class])  {
                [UIApplication.mnz_presentingViewController dismissViewControllerAnimated:YES completion:^{
                    [UIApplication.mnz_presentingViewController presentViewController:callVC animated:YES completion:nil];
                }];
            } else if ([UIApplication.mnz_presentingViewController isKindOfClass:GroupCallViewController.class]) {
                [UIApplication.mnz_presentingViewController dismissViewControllerAnimated:YES completion:^{
                    [UIApplication.mnz_presentingViewController presentViewController:callVC animated:YES completion:nil];
                }];
            } else {
                [UIApplication.mnz_presentingViewController presentViewController:callVC animated:YES completion:nil];
            }
        }
        [action fulfill];
        [self disablePasscodeIfNeeded];
    } else {
        [action fail];
    }
}

- (void)provider:(CXProvider *)provider performEndCallAction:(CXEndCallAction *)action {
    MEGAChatCall *call = [self.megaCallManager callForUUID:action.callUUID];
    
    MEGALogDebug(@"[CallKit] Provider perform end call: %@, uuid: %@", call, action.callUUID);
    
    if (call) {
        [action fulfill];
        [self.megaCallManager removeCallByUUID:action.callUUID];
        [[MEGASdkManager sharedMEGAChatSdk] hangChatCall:call.chatId];
    } else {
        [action fail];
    }
}

- (void)provider:(CXProvider *)provider performSetMutedCallAction:(CXSetMutedCallAction *)action {
    MEGAChatCall *call = [self.megaCallManager callForUUID:action.callUUID];
    
    MEGALogDebug(@"[CallKit] Provider perform mute call: %@, uuid: %@", call, action.callUUID);
    
    if (call) {
        if (call.hasLocalAudio) {
            [[MEGASdkManager sharedMEGAChatSdk] disableAudioForChat:call.chatId];
        } else {
            [[MEGASdkManager sharedMEGAChatSdk] enableAudioForChat:call.chatId];
        }
        [action fulfill];
    } else {
        [action fail];
    }
}

- (void)provider:(CXProvider *)provider timedOutPerformingAction:(CXAction *)action {
    MEGALogDebug(@"[CallKit] Provider time out performing action");
}

- (void)provider:(CXProvider *)provider didActivateAudioSession:(AVAudioSession *)audioSession {
    MEGALogDebug(@"[CallKit] Provider did activate audio session");
    
    if (self.isOutgoingCall) {
        NSString *soundFilePath = [[NSBundle mainBundle] pathForResource:@"incoming_voice_video_call" ofType:@"mp3"];
        NSURL *soundFileURL = [NSURL fileURLWithPath:soundFilePath];
        
        _player = [[AVAudioPlayer alloc] initWithContentsOfURL:soundFileURL error:nil];
        self.player.numberOfLoops = -1;
        
        [self.player play];
    }
}

- (void)provider:(CXProvider *)provider didDeactivateAudioSession:(AVAudioSession *)audioSession {
    MEGALogDebug(@"[CallKit] Provider did deactivate audio session");
}

@end
