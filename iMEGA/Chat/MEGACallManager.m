#import "MEGACallManager.h"
#import "MEGASdkManager.h"

#import <CallKit/CallKit.h>

@interface MEGACallManager ()

@property (nonatomic, strong) CXCallController *callController;
@property (nonatomic, strong) NSMutableDictionary <NSUUID *, NSNumber *> *callsDictionary;
@property (nonatomic, copy) void (^callRemoved)(NSUUID *);

@end

@implementation MEGACallManager

- (instancetype)init {
    self = [super init];
    
    if (self) {
        _callController = [[CXCallController alloc] init];
        _callsDictionary = [[NSMutableDictionary alloc] init];
    }
    
    return self;
}

- (void)startCall:(MEGAChatCall *)call {
    MEGALogDebug(@"[CallKit] Start call %@", call);
    NSString *uuidString = [call.uuid UUIDString];
    if (uuidString == nil || uuidString.length == 0) {
        MEGALogDebug(@"UUID string cannot be empty of nil");
        return;
    }
    
    CXHandle *handle = [[CXHandle alloc] initWithType:CXHandleTypeGeneric value:[MEGASdk base64HandleForUserHandle:call.chatId]];
    CXStartCallAction *startCallAction = [[CXStartCallAction alloc] initWithCallUUID:call.uuid handle:handle];
    startCallAction.video = call.hasLocalVideo;
    MEGAChatRoom *chatRoom = [MEGASdkManager.sharedMEGAChatSdk chatRoomForChatId:call.chatId];
    startCallAction.contactIdentifier = chatRoom.title;
    
    CXTransaction *transaction = [[CXTransaction alloc] init];
    [transaction addAction:startCallAction];
    [self requestTransaction:transaction];
}

- (void)answerCall:(MEGAChatCall *)call {
    MEGALogDebug(@"[CallKit] Answer call %@", call);
    NSUUID *uuid = [self uuidForChatId:call.chatId callId:call.callId];
    CXAnswerCallAction *answerCallAction = [CXAnswerCallAction.alloc initWithCallUUID:uuid];
    [answerCallAction fulfillWithDateConnected:NSDate.date];
    
    CXTransaction *transaction = CXTransaction.new;
    [transaction addAction:answerCallAction];
    [self requestTransaction:transaction];
}

- (void)endCallWithCallId:(uint64_t)callId chatId:(uint64_t)chatId {
    NSUUID *uuid = [self uuidForChatId:chatId callId:callId];
    MEGALogDebug(@"[CallKit] End call %@", uuid);
    if ([self.callsDictionary objectForKey:uuid]) {
        CXEndCallAction *endCallAction = [[CXEndCallAction alloc] initWithCallUUID:uuid];
        CXTransaction *transaction = [[CXTransaction alloc] init];
        [transaction addAction:endCallAction];
        [self requestTransaction:transaction];
    } else {
        MEGALogDebug(@"[CallKit] Call %@ not found in the calls dictionary. Hang the call", [MEGASdk base64HandleForUserHandle:callId]);
        [self printAllCalls];
    }
}

- (void)muteUnmuteCallWithCallId:(uint64_t)callId chatId:(uint64_t)chatId muted:(BOOL)muted {
    NSUUID *uuid = [self uuidForChatId:chatId callId:callId];
    MEGALogDebug(@"[CallKit] %@ call %@", muted ? @"Mute" : @"Unmute", uuid);
    if ([self.callsDictionary objectForKey:uuid]) {
        CXSetMutedCallAction *muteCallAction = [CXSetMutedCallAction.alloc initWithCallUUID:uuid muted:muted];
        CXTransaction *transaction = [[CXTransaction alloc] init];
        [transaction addAction:muteCallAction];
        [self requestTransaction:transaction];
    } else {
        MEGALogDebug(@"[CallKit] Call %@ not found in the calls dictionary. %@ the call", [MEGASdk base64HandleForUserHandle:callId], muted ? @"Mute" : @"Unmute");
        [self printAllCalls];
        MEGAChatCall *call = [MEGASdkManager.sharedMEGAChatSdk chatCallForChatId:chatId];
        if (muted && call.hasLocalAudio) {
            [MEGASdkManager.sharedMEGAChatSdk disableAudioForChat:chatId];
        } else if (!call.hasLocalAudio) {
            [MEGASdkManager.sharedMEGAChatSdk enableAudioForChat:chatId];
        }
    }
}

- (void)addCall:(MEGAChatCall *)call {
    [self addCallWithCallId:call.callId uuid:call.uuid];
}

- (void)addCallWithCallId:(uint64_t)callId uuid:(NSUUID *)uuid {
    MEGALogDebug(@"[CallKit] Add call with callid %@ and uuid %@", [MEGASdk base64HandleForUserHandle:callId], uuid);
    self.callsDictionary[uuid] = @(callId);
    [self printAllCalls];
}

- (void)removeCallByUUID:(NSUUID *)uuid {
    MEGALogDebug(@"[CallKit] Remove call: %@", uuid);
    [self.callsDictionary removeObjectForKey:uuid];
    [self printAllCalls];
    if (self.callRemoved) {
        self.callRemoved(uuid);
    }
}

- (void)removeAllCalls {
    MEGALogDebug(@"Remove all calls:");
    NSArray *allkeys = self.callsDictionary.allKeys;
    [self.callsDictionary removeAllObjects];
    [self printAllCalls];
    if (self.callRemoved) {
        [allkeys enumerateObjectsUsingBlock:^(NSUUID * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            self.callRemoved(obj);
        }];
    }
}

- (uint64_t)callIdForUUID:(NSUUID *)uuid {
    [self printAllCalls];
    uint64_t callId = [[self.callsDictionary objectForKey:uuid] unsignedLongLongValue];
    MEGALogDebug(@"[CallKit] Call %@ for uuid: %@", [MEGASdk base64HandleForUserHandle:callId], uuid);
    return callId;
}

- (uint64_t)chatIdForUUID:(NSUUID *)uuid {
    unsigned char bytes[128];
    [uuid getUUIDBytes:bytes];
    uint64_t chatid;
    memcpy(&chatid, bytes, sizeof(chatid));
    MEGALogDebug(@"[CallKit] Chat %@ for uuid: %@", [MEGASdk base64HandleForUserHandle:chatid], uuid);
    return chatid;
}

- (NSUUID *)uuidForChatId:(uint64_t)chatId callId:(uint64_t)callId {
    unsigned char tempUuid[128];
    memcpy(tempUuid, &chatId, sizeof(chatId));
    memcpy(tempUuid + sizeof(chatId), &callId, sizeof(callId));
    NSUUID *uuid = [NSUUID.alloc initWithUUIDBytes:tempUuid];
    return uuid;
}

- (void)startCallWithChatId:(MEGAHandle)chatId {
    MEGAChatCall *call = [MEGASdkManager.sharedMEGAChatSdk chatCallForChatId:chatId];
    [self startCall:call];
}

- (void)answerCallWithChatId:(MEGAHandle)chatId {
    MEGAChatCall *call = [MEGASdkManager.sharedMEGAChatSdk chatCallForChatId:chatId];
    [self answerCall:call];
}

- (void)addCallRemovedHandler:(void (^)(NSUUID *))handler {
    self.callRemoved = handler;
}

- (void)removeCallRemovedHandler {
    self.callRemoved = nil;
}

#pragma mark - Private

- (void)printAllCalls {
    MEGALogDebug(@"[CallKit] All calls: %tu call manager: %@", self.callsDictionary.count, self);
    for (MEGAChatCall *call in self.callsDictionary) {
        MEGALogDebug(@"[CallKit] call %@", call);
    }
}

- (void)requestTransaction:(CXTransaction *)transaction {
    MEGALogDebug(@"[CallKit] Request transaction  %@", transaction);
    [self.callController requestTransaction:transaction completion:^(NSError * _Nullable error) {
        if (error) {
            MEGALogError(@"[CallKit] Requested transaction %@ failed %@", transaction, error.localizedDescription);
        } else {
            MEGALogDebug(@"[CallKit] Requested transaction successfully %@", transaction);
        }
    }];
}



@end
