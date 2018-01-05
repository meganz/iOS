
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

- (void)startCall:(MEGAChatCall *)call email:(NSString *)email {
    MEGALogDebug(@"[CallKit] Start call %@, uuid: %@, email: %@", call, call.uuid, email);
    CXHandle *handle = [[CXHandle alloc] initWithType:CXHandleTypeEmailAddress value:email];
    CXStartCallAction *startCallAction = [[CXStartCallAction alloc] initWithCallUUID:call.uuid handle:handle];
    startCallAction.video = call.hasLocalVideo;
    
    CXTransaction *transaction = [[CXTransaction alloc] init];
    [transaction addAction:startCallAction];
    [self requestTransaction:transaction];
}

- (void)endCall:(MEGAChatCall *)call {
    NSUUID *uuid;
    if (call.uuid) {
        uuid = call.uuid;
    } else {
        NSArray *keysArray = [self.callsDictionary allKeysForObject:@(call.callId)];
        if (keysArray.count > 0) {
            uuid = [keysArray objectAtIndex:0];
        }
    }
    if (uuid) {
        MEGALogDebug(@"[CallKit] End call %@, uuid: %@", call, uuid);
        CXEndCallAction *endCallAction = [[CXEndCallAction alloc] initWithCallUUID:uuid];
        CXTransaction *transaction = [[CXTransaction alloc] init];
        [transaction addAction:endCallAction];
        [self requestTransaction:transaction];
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
    MEGALogDebug(@"[CallKit] Add call %@, uuid: %@", call, call.uuid);
    [self.callsDictionary setObject:@(call.callId) forKey:call.uuid];
    [self printAllCalls];
}

- (void)removeCallByUUID:(NSUUID *)uuid {
    MEGALogDebug(@"[CallKit] Remove call, uuid: %@", uuid);
    [self.callsDictionary removeObjectForKey:uuid];
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

- (NSUUID *)UUIDForCall:(MEGAChatCall *)call {
    [self printAllCalls];
    NSUUID *uuid = [[self.callsDictionary allKeysForObject:@(call.callId)] objectAtIndex:0];
    MEGALogDebug(@"[CallKit] UUID %@ for call: %@", uuid, call);
    return uuid;
}

- (void)printAllCalls {
    MEGALogDebug(@"[CallKit] All calls: ");
    for (NSUUID *key in self.callsDictionary) {
        NSNumber *callId = [self.callsDictionary objectForKey:key];
        NSString *base64CallId = [MEGASdk base64HandleForUserHandle:callId.unsignedLongLongValue];
        MEGALogDebug(@"[CallKit] %@ = %@", key, base64CallId);
    }
}

@end
