
#import "MEGAProviderDelegate.h"

#import <AVFoundation/AVFoundation.h>
#import <UserNotifications/UserNotifications.h>

#import <WebRTC/RTCDispatcher.h>
#import <WebRTC/RTCAudioSession.h>
#import <WebRTC/RTCAudioSessionConfiguration.h>

#import "LTHPasscodeViewController.h"

#import "CallViewController.h"
#import "DevicePermissionsHelper.h"
#import "GroupCallViewController.h"
#import "NSString+MNZCategory.h"
#import "UIApplication+MNZCategory.h"

#import "MEGANavigationController.h"

@interface MEGAProviderDelegate () <MEGAChatCallDelegate>

@property (nonatomic, strong) MEGACallManager *megaCallManager;
@property (nonatomic, strong) CXProvider *provider;

@property (strong, nonatomic) AVAudioPlayer *player;

@property (getter=isOutgoingCall) BOOL outgoingCall;
@property (nonatomic, strong) NSMutableDictionary *missedCallsDictionary;
@property (nonatomic, strong) NSMutableArray *currentNotifications;

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
    
    [MEGASdkManager.sharedMEGAChatSdk addChatCallDelegate:self];
    
    self.missedCallsDictionary = NSMutableDictionary.new;
    self.currentNotifications = NSMutableArray.new;
    
    return self;
}

- (void)invalidateProvider {
    [self.provider invalidate];
}

- (void)reportIncomingCallWithCallId:(uint64_t)callId chatId:(uint64_t)chatId {
    MEGALogDebug(@"[CallKit] Report incoming call with callid %@ and chatid %@", [MEGASdk base64HandleForUserHandle:callId], [MEGASdk base64HandleForUserHandle:chatId]);
    
    MEGAChatCall *call = [MEGASdkManager.sharedMEGAChatSdk chatCallForCallId:callId];
    if (call) {
        [self reportIncomingCallOrUpdate:call];
    } else {
        MEGAChatRoom *chatRoom = [MEGASdkManager.sharedMEGAChatSdk chatRoomForChatId:chatId];
        NSUUID *uuid = [self uuidForChatId:chatId callId:callId];
        if (chatRoom) {
            [self reportNewIncomingCallWithValue:[MEGASdk base64HandleForUserHandle:chatRoom.chatId]
                                      callerName:chatRoom.title
                                        hasVideo:NO
                                            uuid:uuid
                                          callId:callId];
        } else {
            [self reportNewIncomingCallWithValue:[MEGASdk base64HandleForUserHandle:chatId]
                                      callerName:AMLocalizedString(@"connecting", nil)
                                        hasVideo:NO
                                            uuid:uuid
                                          callId:callId];
        }
    }
}

- (void)reportOutgoingCall:(MEGAChatCall *)call {
    MEGALogDebug(@"[CallKit] Report outgoing call %@", call);
    
    [self stopDialerTone];
    [self.provider reportOutgoingCallWithUUID:call.uuid connectedAtDate:nil];
}

- (void)reportEndCallWithCallId:(uint64_t)callId chatId:(uint64_t)chatId {
    MEGALogDebug(@"[CallKit] Report end call with callid %@ and chatid %@", [MEGASdk base64HandleForUserHandle:callId], [MEGASdk base64HandleForUserHandle:chatId]);
    
    NSUUID *uuid = [self uuidForChatId:chatId callId:callId];
    [self.provider reportCallWithUUID:uuid endedAtDate:nil reason:CXCallEndedReasonRemoteEnded];
    [self.megaCallManager removeCallByUUID:uuid];
    [self missedCallNotificationWithCallId:callId chatId:chatId];
}

- (void)reportEndCall:(MEGAChatCall *)call {
    MEGALogDebug(@"[CallKit] Report end call %@", call);
    if (!call.uuid) return;
    
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
        [self.provider reportCallWithUUID:call.uuid endedAtDate:nil reason:callEndedReason];
    }
    [self.megaCallManager removeCallByUUID:call.uuid];
}

#pragma mark - Private

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

- (void)reportIncomingCallOrUpdate:(MEGAChatCall *)call {
    MEGALogDebug(@"[CallKit] Report incoming call %@, video %@", call, call.hasVideoInitialCall ? @"YES" : @"NO");
    
    MEGAChatRoom *chatRoom = [MEGASdkManager.sharedMEGAChatSdk chatRoomForChatId:call.chatId];

    CXCallUpdate *update = [self callUpdateWithValue:[MEGASdk base64HandleForUserHandle:chatRoom.chatId] localizedCallerName:chatRoom.title hasVideo:call.hasVideoInitialCall];
        
    uint64_t callId = [self.megaCallManager callForUUID:call.uuid];
    
    if (callId) {
        MEGALogDebug(@"[CallKit] Call already reported, update the information");
        [self.provider reportCallWithUUID:call.uuid updated:update];
    } else {
        __weak __typeof__(self) weakSelf = self;
        [self.provider reportNewIncomingCallWithUUID:call.uuid update:update completion:^(NSError * _Nullable error) {
            if (error) {
                MEGALogError(@"[CallKit] Report new incoming call failed with error: %@", error);
            } else {
                [weakSelf.megaCallManager addCall:call];
            }
        }];
    }
}

- (void)reportNewIncomingCallWithValue:(NSString *)value
                            callerName:(NSString *)callerName
                              hasVideo:(BOOL)hasVideo
                                  uuid:(NSUUID *)uuid
                                callId:(uint64_t)callId {
    
    CXCallUpdate *update = [self callUpdateWithValue:value localizedCallerName:callerName hasVideo:hasVideo];
    
    __weak __typeof__(self) weakSelf = self;
    [self.provider reportNewIncomingCallWithUUID:uuid update:update completion:^(NSError * _Nullable error) {
        if (error) {
            MEGALogError(@"[CallKit] Report new incoming call failed with error: %@", error);
        } else {
            MEGAChatCall *call = [MEGASdkManager.sharedMEGAChatSdk chatCallForCallId:callId];
            if (call) {
                [weakSelf.megaCallManager addCall:call];
            } else {
                [weakSelf.megaCallManager addCallWithCallId:callId uuid:uuid];
            }
        }
    }];
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

- (NSUUID *)uuidForChatId:(uint64_t)chatId callId:(uint64_t)callId {
    unsigned char tempUuid[128];
    memcpy(tempUuid, &chatId, sizeof(chatId));
    memcpy(tempUuid + sizeof(chatId), &callId, sizeof(callId));
    NSUUID *uuid = [NSUUID.alloc initWithUUIDBytes:tempUuid];
    return uuid;
}

- (void)missedCallNotificationWithCallId:(uint64_t)callId chatId:(uint64_t)chatId {
    MEGAChatCall *call = [MEGASdkManager.sharedMEGAChatSdk chatCallForCallId:callId];
    MEGAChatRoom *chatRoom = [MEGASdkManager.sharedMEGAChatSdk chatRoomForChatId:chatId];
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    [center getDeliveredNotificationsWithCompletionHandler:^(NSArray<UNNotification *> *notifications) {
        NSInteger missedVideoCalls, missedAudioCalls;
        if (call.hasVideoInitialCall) {
            missedVideoCalls = 1;
            missedAudioCalls = 0;
        } else {
            missedAudioCalls = 1;
            missedVideoCalls = 0;
        }
        
        for (UNNotification *notification in notifications) {
            if ([[MEGASdk base64HandleForUserHandle:chatId] isEqualToString:notification.request.identifier]) {
                missedAudioCalls = [notification.request.content.userInfo[@"missedAudioCalls"] integerValue];
                missedVideoCalls = [notification.request.content.userInfo[@"missedVideoCalls"] integerValue];
                if (call.hasVideoInitialCall) {
                    missedVideoCalls++;
                } else {
                    missedAudioCalls++;
                }
                break;
            }
        }
        
        NSString *notificationText = [NSString mnz_stringByMissedAudioCalls:missedAudioCalls andMissedVideoCalls:missedVideoCalls];
        
        UNMutableNotificationContent *content = [UNMutableNotificationContent new];
        content.title = chatRoom.title;
        content.body = notificationText;
        content.sound = UNNotificationSound.defaultSound;
        content.userInfo = @{@"missedAudioCalls" : @(missedAudioCalls),
                             @"missedVideoCalls" : @(missedVideoCalls),
                             @"chatId" : @(chatId)
                             };
        content.categoryIdentifier = @"nz.mega.chat.call";
        UNTimeIntervalNotificationTrigger *trigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:1 repeats:NO];
        NSString *identifier = [MEGASdk base64HandleForUserHandle:chatRoom.chatId];
        UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:identifier content:content trigger:trigger];
        [center addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
            if (error) {
                MEGALogError(@"Add NotificationRequest failed with error: %@", error);
            }
        }];
    }];
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
    uint64_t callId = [self.megaCallManager callForUUID:action.callUUID];
    MEGAChatCall *call = [MEGASdkManager.sharedMEGAChatSdk chatCallForCallId:callId];
    
    MEGALogDebug(@"[CallKit] Provider perform start call: %@, uuid: %@", call, action.callUUID);
    
    if (call) {
        MEGAChatRoom *chatRoom = [MEGASdkManager.sharedMEGAChatSdk chatRoomForChatId:call.chatId];
        CXCallUpdate *update = [self callUpdateWithValue:[MEGASdk base64HandleForUserHandle:chatRoom.chatId] localizedCallerName:chatRoom.title hasVideo:call.hasVideoInitialCall];
        [provider reportCallWithUUID:call.uuid updated:update];
        [action fulfill];
        [self disablePasscodeIfNeeded];
    } else {
        [action fail];
    }
}

- (void)provider:(CXProvider *)provider performAnswerCallAction:(CXAnswerCallAction *)action {
    uint64_t callId = [self.megaCallManager callForUUID:action.callUUID];
    MEGAChatCall *call = [MEGASdkManager.sharedMEGAChatSdk chatCallForCallId:callId];
    
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
    uint64_t callId = [self.megaCallManager callForUUID:action.callUUID];
    MEGAChatCall *call = [MEGASdkManager.sharedMEGAChatSdk chatCallForCallId:callId];
    
    MEGALogDebug(@"[CallKit] Provider perform end call: %@, uuid: %@", call, action.callUUID);
    
    if (call) {
        [MEGASdkManager.sharedMEGAChatSdk hangChatCall:call.chatId];
        [action fulfill];
        [self.megaCallManager removeCallByUUID:call.uuid];
    } else {
        [action fail];
    }
}

- (void)provider:(CXProvider *)provider performSetMutedCallAction:(CXSetMutedCallAction *)action {
    uint64_t callId = [self.megaCallManager callForUUID:action.callUUID];
    MEGAChatCall *call = [MEGASdkManager.sharedMEGAChatSdk chatCallForCallId:callId];
    
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

#pragma mark - MEGAChatCallDelegate

- (void)onChatCallUpdate:(MEGAChatSdk *)api call:(MEGAChatCall *)call {
    MEGALogDebug(@"onChatCallUpdate %@", call);
    
    switch (call.status) {
        case MEGAChatCallStatusInitial:
            break;
            
        case MEGAChatCallStatusHasLocalStream:
            break;
            
        case MEGAChatCallStatusRequestSent:
            self.outgoingCall = YES;
            [self.provider reportOutgoingCallWithUUID:call.uuid startedConnectingAtDate:nil];
            break;
            
        case MEGAChatCallStatusRingIn: {
            if (![self.missedCallsDictionary objectForKey:@(call.chatId)]) {
                self.missedCallsDictionary[@(call.chatId)] = call;
                [DevicePermissionsHelper audioPermissionModal:YES forIncomingCall:YES withCompletionHandler:^(BOOL granted) {
                    if (granted) {
                        if (call.hasVideoInitialCall) {
                            [DevicePermissionsHelper videoPermissionWithCompletionHandler:^(BOOL granted) {
                                [self reportIncomingCallOrUpdate:call];
                            }];
                        } else {
                            [self reportIncomingCallOrUpdate:call];
                        }
                    } else {
                        [DevicePermissionsHelper alertAudioPermissionForIncomingCall:YES];
                    }
                }];
            }
            break;
        }
            
        case MEGAChatCallStatusJoining:
            self.outgoingCall = NO;
            break;
            
        case MEGAChatCallStatusInProgress: {
            if (self.isOutgoingCall) {
                [self reportOutgoingCall:call];
                self.outgoingCall = NO;
            }
            
            if ([call hasChangedForType:MEGAChatCallChangeTypeLocalAVFlags] || [call hasChangedForType:MEGAChatCallChangeTypeRemoteAVFlags]) {
                CXCallUpdate *callUpdate = CXCallUpdate.alloc.init;
                MEGAChatSession *remoteSession = [call sessionForPeer:call.peerSessionStatusChange clientId:call.clientSessionStatusChange];
                callUpdate.hasVideo = call.hasLocalVideo || remoteSession.hasVideo;
                
                [self.provider reportCallWithUUID:call.uuid updated:callUpdate];
            }
            
            [self.missedCallsDictionary removeObjectForKey:@(call.chatId)];
            break;
        }
            
        case MEGAChatCallStatusUserNoPresent:
            break;
            
        case MEGAChatCallStatusTerminatingUserParticipation:
            if ([call hasChangedForType:MEGAChatCallChangeTypeStatus]) {
                [self reportEndCall:call];
            }
            break;
            
        case MEGAChatCallStatusDestroyed:
            if (call.isLocalTermCode) {
                [self.missedCallsDictionary removeObjectForKey:@(call.chatId)];
            }
            if ([self.missedCallsDictionary objectForKey:@(call.chatId)]) {
                [self missedCallNotificationWithCallId:call.callId chatId:call.chatId];
                [self.missedCallsDictionary removeObjectForKey:@(call.chatId)];
            }
            
            break;
            
        default:
            break;
    }
}

@end
