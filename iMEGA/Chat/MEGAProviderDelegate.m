
#import "MEGAProviderDelegate.h"

#import <AVFoundation/AVFoundation.h>
#import <UserNotifications/UserNotifications.h>

#import "LTHPasscodeViewController.h"

#import "DevicePermissionsHelper.h"
#import "NSString+MNZCategory.h"
#import "UIApplication+MNZCategory.h"

#import "MEGANavigationController.h"
#import "MEGA-Swift.h"

@interface MEGAProviderDelegate () <MEGAChatCallDelegate, MEGAChatDelegate>

@property (nonatomic, strong) MEGACallManager *megaCallManager;
@property (nonatomic, strong) CXProvider *provider;
@property (nonatomic, assign) BOOL isAudioSessionActive;

@property (strong, nonatomic) AVAudioPlayer *player;

@property (getter=isCallKitAnsweredCall) BOOL callKitAnsweredCall;
@property (nonatomic, strong) NSNumber *answeredChatId;

@property (nonatomic, strong) NSNumber *callId;
@property (nonatomic, strong) NSNumber *chatId;
@property (getter=shouldAnswerCallWhenConnect) BOOL answerCallWhenConnect;
@property (getter=shouldMuteAudioWhenConnect) BOOL muteAudioWhenConnect;
@property (getter=shouldEndCallWhenConnect) BOOL endCallWhenConnect;

@property (nonatomic, strong) NSMutableDictionary <NSNumber *, MEGAChatCall *> *endedCalls;

@property (nonatomic, getter=shouldPlayCallEndedSound) BOOL playCallEndedSound;

@end

@implementation MEGAProviderDelegate

- (instancetype)initWithMEGACallManager:(MEGACallManager *)megaCallManager {
    self = [super init];
    
    if (self) {
        _megaCallManager = megaCallManager;
        
        CXProviderConfiguration *configuration = [[CXProviderConfiguration alloc] init];
        configuration.supportsVideo = YES;
        configuration.maximumCallsPerCallGroup = 1;
        configuration.maximumCallGroups = 1;
        configuration.supportedHandleTypes = [NSSet setWithObjects:@(CXHandleTypeEmailAddress), @(CXHandleTypeGeneric), nil];
        configuration.iconTemplateImageData = UIImagePNGRepresentation([UIImage imageNamed:@"MEGA_icon_call"]);
        _provider = [[CXProvider alloc] initWithConfiguration:configuration];
        
        [_provider setDelegate:self queue:nil];
        
        _endedCalls = NSMutableDictionary.new;
    }
    
    [MEGASdkManager.sharedMEGAChatSdk addChatCallDelegate:self];
    [MEGASdkManager.sharedMEGAChatSdk addChatDelegate:self];
    
    return self;
}

- (void)invalidateProvider {
    self.megaCallManager = nil;
    [MEGASdkManager.sharedMEGAChatSdk removeChatCallDelegate:self];
    [MEGASdkManager.sharedMEGAChatSdk removeChatDelegate:self];
    [self.provider invalidate];
}

- (void)reportIncomingCallWithCallId:(uint64_t)callId chatId:(uint64_t)chatId completion:(void (^)(void))completion {
    MEGALogDebug(@"[CallKit] Report incoming call with callid %@ and chatid %@", [MEGASdk base64HandleForUserHandle:callId], [MEGASdk base64HandleForUserHandle:chatId]);
        
    // Callkit abnormal behaviour when trying to enable loudspeaker from the lock screen.
    // Solution provided in the below link.
    // https://stackoverflow.com/questions/48023629/abnormal-behavior-of-speaker-button-on-system-provided-call-screen?rq=1
    [self configureAudioSession];
    MEGAChatCall *call = [MEGASdkManager.sharedMEGAChatSdk chatCallForCallId:callId];
    MEGAChatRoom *chatRoom = [MEGASdkManager.sharedMEGAChatSdk chatRoomForChatId:chatId];
    
    NSUUID *uuid = [self.megaCallManager uuidForChatId:chatId callId:callId];
    
    if ([self.megaCallManager callIdForUUID:uuid]) {
        MEGALogDebug(@"[CallKit] Call has already been reported with callid %@ and chatid %@", [MEGASdk base64HandleForUserHandle:callId], [MEGASdk base64HandleForUserHandle:chatId]);
        return;
    }

    if (call && chatRoom) {
        [self reportNewIncomingCallWithValue:[MEGASdk base64HandleForUserHandle:chatRoom.chatId]
                                  callerName:chatRoom.title
                                    hasVideo:call.hasLocalVideo
                                        uuid:call.uuid
                                      callId:callId
                                  completion:completion];
    } else {
        self.callId = @(callId);
        self.chatId = @(chatId);
        self.endCallWhenConnect = self.answerCallWhenConnect = self.muteAudioWhenConnect = NO;
        NSUUID *uuid = [self.megaCallManager uuidForChatId:chatId callId:callId];
        if (chatRoom) {
            [self reportNewIncomingCallWithValue:[MEGASdk base64HandleForUserHandle:chatRoom.chatId]
                                      callerName:chatRoom.title
                                        hasVideo:NO
                                            uuid:uuid
                                          callId:callId
                                      completion:completion];
        } else {
            [self reportNewIncomingCallWithValue:[MEGASdk base64HandleForUserHandle:chatId]
                                      callerName:NSLocalizedString(@"connecting", nil)
                                        hasVideo:NO
                                            uuid:uuid
                                          callId:callId
                                      completion:completion];
        }
    }
}

- (void)reportEndCall:(MEGAChatCall *)call {
    MEGALogDebug(@"[CallKit] Report end call %@", call);
    if (!call.uuid) return;
    
    CXCallEndedReason callEndedReason = 0;
    switch (call.termCode) {
        case MEGAChatCallTermCodeInvalid:
        case MEGAChatCallTermCodeError:
        case MEGAChatCallTermCodeTooManyParticipants:
            callEndedReason = CXCallEndedReasonFailed;
            break;
            
        case MEGAChatCallTermCodeCallReject:
        case MEGAChatCallTermCodeUserHangup:
        case MEGAChatCallTermCodeNoParticipate:
            callEndedReason = CXCallEndedReasonRemoteEnded;
            break;
    }
    
    if (callEndedReason == 0) {
        for (NSUInteger i = 0; i < call.participants.size; i++) {
            uint64_t handle = [call.participants megaHandleAtIndex:i];
            if (MEGASdkManager.sharedMEGAChatSdk.myUserHandle == handle) {
                callEndedReason = CXCallEndedReasonAnsweredElsewhere;
                break;
            }
        }
    }
    
    MEGALogDebug(@"[CallKit] Report end call reason %ld", (long)callEndedReason);
    if (callEndedReason) {
        self.endedCalls[@(call.callId)] = call;
        [self.provider reportCallWithUUID:call.uuid endedAtDate:nil reason:callEndedReason];
    }
    [self.megaCallManager removeCallByUUID:call.uuid];
    
    [self sendAudioPlayerInterruptDidEndNotificationIfNeeded];
}

#pragma mark - Private

- (void)stopDialerTone {
    [self.player stop];
    self.player = nil;
    [[CallActionManager shared] enableRTCAudioIfRequired];
}

- (void)disablePasscodeIfNeeded {
    if (UIApplication.sharedApplication.applicationState == UIApplicationStateBackground || [[LTHPasscodeViewController sharedUser] isLockscreenPresent]) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"presentPasscodeLater"];
        [LTHPasscodeViewController close];
    }
    [[LTHPasscodeViewController sharedUser] disablePasscodeWhenApplicationEntersBackground];
}

- (void)updateCall:(MEGAChatCall *)call {
    if (self.shouldEndCallWhenConnect) return;
    
    MEGALogDebug(@"[CallKit] Update call %@, video %@", call, call.hasLocalVideo ? @"YES" : @"NO");
    
    MEGAChatRoom *chatRoom = [MEGASdkManager.sharedMEGAChatSdk chatRoomForChatId:call.chatId];
    CXCallUpdate *update = [self callUpdateWithValue:[MEGASdk base64HandleForUserHandle:chatRoom.chatId] localizedCallerName:chatRoom.title hasVideo:call.hasLocalVideo];
    [self.provider reportCallWithUUID:call.uuid updated:update];
}

- (void)reportNewIncomingCallWithValue:(NSString *)value
                            callerName:(NSString *)callerName
                              hasVideo:(BOOL)hasVideo
                                  uuid:(NSUUID *)uuid
                                callId:(uint64_t)callId
                            completion:(void (^)(void))completion {
    
    CXCallUpdate *update = [self callUpdateWithValue:value localizedCallerName:callerName hasVideo:hasVideo];
    
    __weak __typeof__(self) weakSelf = self;
    
    MEGAChatCall *endedCall = self.endedCalls[@(callId)];
    if (UIApplication.sharedApplication.applicationState != UIApplicationStateBackground && endedCall) {
        MEGALogWarning(@"[CallKit] A VoIP push has been received for an ended call and the application is in foreground");
        completion();
    } else {
        [self.provider reportNewIncomingCallWithUUID:uuid update:update completion:^(NSError * _Nullable error) {
            if (error) {
                MEGALogError(@"[CallKit] Report new incoming call failed with error: %@", error);
            } else {
                MEGAChatCall *call = [MEGASdkManager.sharedMEGAChatSdk chatCallForCallId:callId];
                if (call) {
                    [weakSelf.megaCallManager addCall:call];
                } else {
                    if (endedCall) {
                        MEGALogWarning(@"[CallKit] A VoIP push has been received for an ended call and the application is in background. End the call after reporting the incoming call");
                        [self reportEndCall:endedCall];
                    } else {
                        [weakSelf.megaCallManager addCallWithCallId:callId uuid:uuid];
                    }
                }
            }
            completion();
        }];
    }
}

- (CXCallUpdate *)callUpdateWithValue:(NSString *)value localizedCallerName:(NSString *)name hasVideo:(BOOL)hasVideo {
    CXCallUpdate *update = CXCallUpdate.new;
    update.remoteHandle = [CXHandle.alloc initWithType:CXHandleTypeGeneric value:value];
    update.localizedCallerName = name;
    update.supportsHolding = NO;
    update.supportsGrouping = NO;
    update.supportsUngrouping = NO;
    update.supportsDTMF = NO;
    update.hasVideo = hasVideo;
    
    return update;
}

- (void)callUpdateVideoForCall:(MEGAChatCall *)call {
    if (call.uuid == nil) {
        return;
    }
    
    CXCallUpdate *callUpdate = CXCallUpdate.alloc.init;
    callUpdate.hasVideo = NO;

    if (call.hasLocalVideo) {
        callUpdate.hasVideo = YES;
    } else {
        for (int i = 0; i < call.sessionsClientId.size; i++) {
            MEGAChatSession *session = [call sessionForClientId:[call.sessionsClientId megaHandleAtIndex:i]];
            if (session.hasVideo) {
                callUpdate.hasVideo = YES;
                break;
            }
        }
    }
    
    [self.provider reportCallWithUUID:call.uuid updated:callUpdate];
}

- (void)sendAudioPlayerInterruptDidStartNotificationIfNeeded {
    if ([AudioPlayerManager.shared isPlayerAlive]) {
        [AudioPlayerManager.shared audioInterruptionDidStart];
    }
}

- (void)sendAudioPlayerInterruptDidEndNotificationIfNeeded {
    if ([AudioPlayerManager.shared isPlayerAlive]) {
        [AudioPlayerManager.shared audioInterruptionDidEndNeedToResume:YES];
    }
}

- (void)reportEndCallWithCallId:(uint64_t)callId chatId:(uint64_t)chatId {
    MEGALogDebug(@"[CallKit] Report end call with callid %@ and chatid %@", [MEGASdk base64HandleForUserHandle:callId], [MEGASdk base64HandleForUserHandle:chatId]);
    
    NSUUID *uuid = [self.megaCallManager uuidForChatId:chatId callId:callId];
    [self.provider reportCallWithUUID:uuid endedAtDate:nil reason:CXCallEndedReasonRemoteEnded];
    [self.megaCallManager removeCallByUUID:uuid];
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
    uint64_t callId = [self.megaCallManager callIdForUUID:action.callUUID];
    MEGAChatCall *call = [MEGASdkManager.sharedMEGAChatSdk chatCallForCallId:callId];
    
    MEGALogDebug(@"[CallKit] Provider perform start call: %@, uuid: %@", call, action.callUUID);

    if (call) {
        MEGAChatRoom *chatRoom = [MEGASdkManager.sharedMEGAChatSdk chatRoomForChatId:call.chatId];
        CXCallUpdate *update = [self callUpdateWithValue:[MEGASdk base64HandleForUserHandle:chatRoom.chatId] localizedCallerName:chatRoom.title hasVideo:call.hasLocalVideo];
        [provider reportCallWithUUID:call.uuid updated:update];
        [action fulfill];
        [self disablePasscodeIfNeeded];
    } else {
        [action fail];
    }
}

- (void)provider:(CXProvider *)provider performAnswerCallAction:(CXAnswerCallAction *)action {
    uint64_t chatid = [self.megaCallManager chatIdForUUID:action.callUUID];
    MEGAChatRoom *chatRoom = [[MEGASdkManager sharedMEGAChatSdk] chatRoomForChatId:chatid];
    MEGAChatCall *call = [MEGASdkManager.sharedMEGAChatSdk chatCallForChatId:chatid];
    MEGALogDebug(@"[CallKit] Provider perform answer call: %@, uuid: %@", call, action.callUUID);
    
    if (action.callUUID) {
        if (call == nil) {
            self.answerCallWhenConnect = YES;
            MEGALogDebug(@"[CallKit] Provider perform Wait for state online to answer call for chat id: %@, uuid: %@", [MEGASdk base64HandleForUserHandle:chatRoom.chatId], action.callUUID);
            [action fulfill];
        } else {
            [self answerCallForChatRoom:chatRoom call:call action:action];
        }
        
        [self disablePasscodeIfNeeded];
    } else {
        [action fail];
    }
}

- (void)provider:(CXProvider *)provider performEndCallAction:(CXEndCallAction *)action {
    uint64_t callId = [self.megaCallManager callIdForUUID:action.callUUID];
    MEGAChatCall *call = [MEGASdkManager.sharedMEGAChatSdk chatCallForCallId:callId];
    
    MEGALogDebug(@"[CallKit] Provider perform end call: %@, uuid: %@", call, action.callUUID);
    
    if (action.callUUID) {
        if (call) {
            MEGAChatRoom *chatRoom = [MEGASdkManager.sharedMEGAChatSdk chatRoomForChatId:call.chatId];
            if ((call.status != MEGAChatCallStatusInitial && call.status != MEGAChatCallStatusUserNoPresent)
                || chatRoom.isOneToOne) {
                MEGALogDebug(@"[CallKit] hanging call for: %@, uuid: %@", call, action.callUUID);
                [MEGASdkManager.sharedMEGAChatSdk hangChatCall:call.callId];
            }
        } else {
            self.endCallWhenConnect = YES;
            self.muteAudioWhenConnect = self.answerCallWhenConnect = NO;
        }
        [self.megaCallManager removeCallByUUID:action.callUUID];
        [action fulfill];
    } else {
        [action fail];
    }
}

- (void)provider:(CXProvider *)provider performSetMutedCallAction:(CXSetMutedCallAction *)action {
    uint64_t callId = [self.megaCallManager callIdForUUID:action.callUUID];
    MEGAChatCall *call = [MEGASdkManager.sharedMEGAChatSdk chatCallForCallId:callId];
    
    MEGALogDebug(@"[CallKit] Provider perform mute/unmute call: %@, uuid: %@, action: %d", call, action.callUUID, action.muted);
    
    if (action.callUUID) {
        if (call) {
            if (call.hasLocalAudio && action.muted) {
                MEGALogDebug(@"[CallKit][ChatSDK] Provider perform mute call: %@", call);
                [MEGASdkManager.sharedMEGAChatSdk disableAudioForChat:call.chatId];
            } else if (!call.hasLocalAudio && !action.muted) {
                MEGALogDebug(@"[CallKit][ChatSDK] Provider perform unmute call: %@", call);
                [MEGASdkManager.sharedMEGAChatSdk enableAudioForChat:call.chatId];
            }
        } else {
            MEGALogDebug(@"[CallKit][ChatSDK] Provider perfom store action for call");
            self.muteAudioWhenConnect = action.muted;
        }
        [action fulfill];
        MEGALogDebug(@"[CallKit] Provider perform mute/umute fulfill");
    } else {
        [action fail];
        MEGALogDebug(@"[CallKit] Provider perform mute/umute fail");
    }
}

- (void)provider:(CXProvider *)provider timedOutPerformingAction:(CXAction *)action {
    MEGALogDebug(@"[CallKit] Provider time out performing action");
    if ([action isKindOfClass:[CXSetMutedCallAction class]]) {
        BOOL muted = ((CXSetMutedCallAction *) action).muted;
        [NSNotificationCenter.defaultCenter postNotificationName:MEGACallMuteUnmuteOperationFailedNotification
                                                          object:nil
                                                        userInfo:@{@"muted" : @(muted)}];
    }
}

- (void)provider:(CXProvider *)provider didActivateAudioSession:(AVAudioSession *)audioSession {
    MEGALogDebug(@"[CallKit] Provider did activate audio session");
    
    if (self.isOutgoingCall) {
        NSString *soundFilePath = [[NSBundle mainBundle] pathForResource:@"incoming_voice_video_call" ofType:@"mp3"];
        NSURL *soundFileURL = [NSURL fileURLWithPath:soundFilePath];
        
        self.player = [[AVAudioPlayer alloc] initWithContentsOfURL:soundFileURL error:nil];
        self.player.volume = 1.0f;
        self.player.numberOfLoops = -1;
        
        [self.player play];
    } else {
        [[CallActionManager shared] enableRTCAudioIfRequired];
    }
    
    self.isAudioSessionActive = YES;

    if (self.isCallKitAnsweredCall) {
        self.callKitAnsweredCall = NO;
        MEGAChatRoom *chatRoom = [[MEGASdkManager sharedMEGAChatSdk] chatRoomForChatId:self.answeredChatId.unsignedLongLongValue];
        MEGAChatCall *chatCall = [MEGASdkManager.sharedMEGAChatSdk chatCallForChatId:chatRoom.chatId];
        if (chatCall != nil) {
            MEGALogDebug(@"[CallKit] Loud speaker is %d", chatRoom.isMeeting);
            [AudioSessionUseCaseOCWrapper.alloc.init setSpeakerEnabled:chatRoom.isMeeting];
        }
    }
}

- (void)provider:(CXProvider *)provider didDeactivateAudioSession:(AVAudioSession *)audioSession {
    MEGALogDebug(@"[CallKit] Provider did deactivate audio session");
    
    self.isAudioSessionActive = NO;
    [self sendAudioPlayerInterruptDidEndNotificationIfNeeded];
    
    if (self.shouldPlayCallEndedSound) {
        self.playCallEndedSound = NO;
        [self playCallEndedTone];
    }
}

#pragma mark - MEGAChatCallDelegate

- (void)onChatSessionUpdate:(MEGAChatSdk *)api chatId:(uint64_t)chatId callId:(uint64_t)callId session:(MEGAChatSession *)session{
    MEGALogDebug(@"onChatSessionUpdate %@", session);
    
    if ([session hasChanged:MEGAChatSessionChangeRemoteAvFlags]) {
        MEGAChatCall *chatCall = [MEGASdkManager.sharedMEGAChatSdk chatCallForCallId:callId];
        [self callUpdateVideoForCall:chatCall];
    } else if ([session hasChanged:MEGAChatSessionChangeStatus]
               && session.status == MEGAChatSessionStatusInProgress
               && self.isOutgoingCall
               && [self isOneToOneChatRoom:[MEGASdkManager.sharedMEGAChatSdk chatRoomForChatId:chatId]]) {
        [self stopDialerTone];
        self.outgoingCall = NO;
    } else if (session.status == MEGAChatSessionStatusDestroyed && session.termCode == MEGAChatSessionTermCodeNonRecoverable) {
        MEGAChatRoom *chatRoom = [api chatRoomForChatId:chatId];
        if (!chatRoom.isMeeting && !chatRoom.isGroup) {
            self.playCallEndedSound = YES;
        }
    }
}

- (void)onChatCallUpdate:(MEGAChatSdk *)api call:(MEGAChatCall *)call {
    MEGALogDebug(@"onChatCallUpdate %@", call);
    
    switch (call.status) {
        case MEGAChatCallStatusUserNoPresent: {
            if (call.isRinging) {
                NSUUID *uuid = [self.megaCallManager uuidForChatId:call.chatId callId:call.callId];
                if (uuid) {
                    [self updateCall:call];
                }
                [self sendAudioPlayerInterruptDidStartNotificationIfNeeded];
            } else if (call.changes == MEGAChatCallChangeTypeRingingStatus) {
                [self reportEndCall:call];
            }
            break;
        }
            
        case MEGAChatCallStatusJoining:
            if ([self.megaCallManager callIdForUUID:[self.megaCallManager uuidForChatId:call.chatId callId:call.callId]]) {
                [self.megaCallManager answerCall:call];
            }
            break;
            
        case MEGAChatCallStatusInProgress: {
            if ([call hasChangedForType:MEGAChatCallChangeTypeLocalAVFlags]) {
                [self callUpdateVideoForCall:call];
            }
            
            if ([call hasChangedForType:MEGAChatCallChangeTypeCallComposition]) {
                switch (call.callCompositionChange) {
                    case MEGAChatCallCompositionChangePeerRemoved:
                        if (call.participants.size < MEGAGroupCallsPeersChangeLayout && [api isAudioLevelMonitorEnabledForChatId:call.chatId]) {
                            [api enableAudioMonitor:NO chatId:call.chatId];
                        }
                        break;
                        
                    case MEGAChatCallCompositionChangePeerAdded:
                        if (call.participants.size >= MEGAGroupCallsPeersChangeLayout && ![api isAudioLevelMonitorEnabledForChatId:call.chatId]) {
                            [api enableAudioMonitor:YES chatId:call.chatId];
                        }
                        break;
                        
                    default:
                        break;
                }
            }
            break;
        }
            
        case MEGAChatCallStatusTerminatingUserParticipation:
            if ([call hasChangedForType:MEGAChatCallChangeTypeStatus]) {
                if((call.termCode == MEGAChatCallTermCodeCallReject && !self.isOutgoingCall) || call.termCode == MEGAChatCallTermCodeError) {
                    [self sendAudioPlayerInterruptDidEndNotificationIfNeeded];
                }
            }
            
            if (self.isOutgoingCall) {
                [self stopDialerTone];
                self.outgoingCall = NO;
            }
            break;
            
        case MEGAChatCallStatusDestroyed:
            [self reportEndCall:call];
            break;
            
        default:
            break;
    }
}

#pragma mark - MEGAChatDelegate

- (void)onChatConnectionStateUpdate:(MEGAChatSdk *)api chatId:(uint64_t)chatId newState:(int)newState {
    if (self.chatId.unsignedLongLongValue == chatId && newState == MEGAChatConnectionOnline && self.callId) {
        MEGAChatCall *call = [api chatCallForChatId:self.chatId.unsignedLongLongValue];
        if (call) {
            if (call.status == MEGAChatCallStatusUserNoPresent) {
                if (self.shouldAnswerCallWhenConnect) {
                    MEGALogDebug(@"[CallKit] Online now for call %@, ready to answer", call);
                    MEGAChatRoom *chatRoom = [[MEGASdkManager sharedMEGAChatSdk] chatRoomForChatId:chatId];
                    [self answerCallForChatRoom:chatRoom call:call action:nil];
                    self.answerCallWhenConnect = NO;
                }
                
                if (self.shouldMuteAudioWhenConnect) {
                    MEGALogDebug(@"[CallKit] Mute audio when connect %@", call);
                    [api disableAudioForChat:call.chatId];
                    self.muteAudioWhenConnect = NO;
                }
            } else {
                [self reportEndCall:call];
            }
        } else {
            MEGALogWarning(@"[CallKit] The call %@ doesn't exist, end it", [MEGASdk base64HandleForUserHandle:self.callId.unsignedLongLongValue]);
            [self reportEndCallWithCallId:self.callId.unsignedLongLongValue chatId:chatId];
        }
        
        self.chatId = nil;
        self.callId = nil;
    }
}

- (void)answerCallForChatRoom:(MEGAChatRoom *)chatRoom call:(MEGAChatCall *)call action:(CXAnswerCallAction *)action {
    if (call.status != MEGAChatCallStatusUserNoPresent) {
        [action fulfill];
        return;
    }

    MEGAChatAnswerCallRequestDelegate *answerCallRequestDelegate = [MEGAChatAnswerCallRequestDelegate.alloc initWithCompletion:^(MEGAChatError *error) {
        if (error.type == MEGAChatErrorTypeOk) {
            [self answerWithCall:call chatRoom:chatRoom presenter:UIApplication.mnz_presentingViewController];
        }
        
        MEGALogDebug(@"[CallKit] answered %@ call %@",error, call);
        [action fulfill];
    }];
    
    MEGALogWarning(@"[CallKit] Answering call for chat id %@", [MEGASdk base64HandleForUserHandle:chatRoom.chatId]);
    self.callKitAnsweredCall = YES;
    self.answeredChatId = @(chatRoom.chatId);
    [AudioSessionUseCaseOCWrapper.alloc.init setSpeakerEnabled:chatRoom.isMeeting];
    [[CallActionManager shared] answerCallWithChatId:chatRoom.chatId
                                         enableVideo:call.hasLocalVideo
                                         enableAudio:!chatRoom.isMeeting
                                            delegate:answerCallRequestDelegate];
}

@end
