
#import "MEGACallManager.h"
#import "MEGASdkManager.h"

#import <CallKit/CallKit.h>

@interface MEGACallManager ()

@property (nonatomic, strong) CXCallController *callController;
@property (nonatomic, strong) NSMutableDictionary *callsDictionary;

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
    CXHandle *handle = [[CXHandle alloc] initWithType:CXHandleTypeGeneric value:[MEGASdk base64HandleForUserHandle:call.chatId]];
    CXStartCallAction *startCallAction = [[CXStartCallAction alloc] initWithCallUUID:call.uuid handle:handle];
    startCallAction.video = call.hasLocalVideo;
    
    CXTransaction *transaction = [[CXTransaction alloc] init];
    [transaction addAction:startCallAction];
    [self requestTransaction:transaction];
}

- (void)endCall:(MEGAChatCall *)call {
    if (call.uuid) {
        MEGALogDebug(@"[CallKit] End call %@", call);
        CXEndCallAction *endCallAction = [[CXEndCallAction alloc] initWithCallUUID:call.uuid];
        CXTransaction *transaction = [[CXTransaction alloc] init];
        [transaction addAction:endCallAction];
        [self requestTransaction:transaction];
    } else {
        MEGALogDebug(@"[CallKit] Call %@ not found in the calls dictionary. Hang the call", call);
        [self printAllCalls];
        [[MEGASdkManager sharedMEGAChatSdk] hangChatCall:call.chatId];
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

- (void)addCall:(MEGAChatCall *)call {
    MEGALogDebug(@"[CallKit] Add call %@", call);
    [self.callsDictionary setObject:@(call.callId) forKey:call.uuid];
    [self printAllCalls];
}

- (void)removeCall:(MEGAChatCall *)call {
    MEGALogDebug(@"[CallKit] Remove call: %@", call);
    [self.callsDictionary removeObjectForKey:call.uuid];
    [self printAllCalls];
}

- (void)removeAllCalls {
    MEGALogDebug(@"Remove all calls:");
    [self.callsDictionary removeAllObjects];
    [self printAllCalls];
}


- (MEGAChatCall *)callForUUID:(NSUUID *)uuid {
    [self printAllCalls];
    uint64_t callId = [[self.callsDictionary objectForKey:uuid] unsignedLongLongValue];
    MEGAChatCall *call = [[MEGASdkManager sharedMEGAChatSdk] chatCallForCallId:callId];
    MEGALogDebug(@"[CallKit] Call %@ for uuid: %@", call, uuid);
    return call;
}

- (void)printAllCalls {
    MEGALogDebug(@"[CallKit] All calls: %tu", self.callsDictionary.count);
    for (MEGAChatCall *call in self.callsDictionary) {
        MEGALogDebug(@"[CallKit] call %@", call);
    }
}

@end
