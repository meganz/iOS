#import "MEGAChatRoom.h"
#import "megachatapi.h"

using namespace megachat;

@interface MEGAChatRoom ()

@property MegaChatRoom *megaChatRoom;
@property BOOL cMemoryOwn;

@end

@implementation MEGAChatRoom

- (instancetype)initWithMegaChatRoom:(MegaChatRoom *)megaChatRoom cMemoryOwn:(BOOL)cMemoryOwn {
    self = [super init];
    
    if (self != nil) {
        _megaChatRoom = megaChatRoom;
        _cMemoryOwn = cMemoryOwn;
    }
    
    return self;
}

- (void)dealloc {
    if (self.cMemoryOwn){
        delete _megaChatRoom;
    }
}

- (instancetype)clone {
    return self.megaChatRoom ? [[MEGAChatRoom alloc] initWithMegaChatRoom:self.megaChatRoom cMemoryOwn:YES] : nil;
}

- (MegaChatRoom *)getCPtr {
    return self.megaChatRoom;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: chatId=%llu, own privilege=%ld, peer count=%lu, group=%@, title=%@, online state=%@, changes=%@, unread=%ld ",
            [self class], self.chatId, (long)self.ownPrivilege, (unsigned long)self.peerCount, @(self.isGroup), self.title, @(self.onlineState), @(self.changes), (long)self.unreadCount];
}

- (uint64_t)chatId {
    return self.megaChatRoom->getChatId();
}

- (NSInteger)ownPrivilege {
    return self.megaChatRoom->getOwnPrivilege();
}

- (NSUInteger)peerCount {
    return self.megaChatRoom->getPeerCount();
}

- (BOOL)isGroup {
    return self.megaChatRoom->isGroup();
}

- (NSString *)title {
    return [[NSString alloc] initWithUTF8String:self.megaChatRoom->getTitle()];
}

- (MEGAChatRoomState)onlineState {
    return (MEGAChatRoomState) self.megaChatRoom->getOnlineState();
}

- (MEGAChatRoomChangeType)changes {
    return (MEGAChatRoomChangeType) self.megaChatRoom->getChanges();
}

- (NSInteger)unreadCount {
    return self.megaChatRoom->getUnreadCount();
}

//- (MEGAChatStatus)onlineStatus {
//    return (MEGAChatStatus) self.megaChatRoom->getOnlineStatus();
//}

- (NSInteger)peerPrivilegeByHandle:(uint64_t)userHande {
    return self.megaChatRoom->getPeerPrivilegeByHandle(userHande);
}

- (NSInteger)peerHandeAtIndex:(NSUInteger)index {
    return self.megaChatRoom->getPeerHandle((int)index);
}

- (MEGAChatRoomPrivilege)peerPrivilegeAtIndex:(NSUInteger)index {
    return (MEGAChatRoomPrivilege) self.megaChatRoom->getPeerPrivilege((int)index);
}

- (BOOL)hasChangedForType:(MEGAChatRoomChangeType)changeType {
    return self.megaChatRoom->hasChanged((int)changeType);
}

@end
