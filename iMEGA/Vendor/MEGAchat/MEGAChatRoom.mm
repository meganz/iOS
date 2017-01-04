#import "MEGAChatRoom.h"
#import "megachatapi.h"

using namespace megachat;

@interface MEGAChatRoom ()

@property MegaChatRoom *megaChatRoom;
@property BOOL cMemoryOwn;

@end

@implementation MEGAChatRoom

- (instancetype)initWithMegaChatRoom:(MegaChatRoom *)megaChatRoom cMemoryOwn:(BOOL)cMemoryOwn {
    NSParameterAssert(megaChatRoom);
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
    return [NSString stringWithFormat:@"<%@: chatId=%llu, own privilege=%ld, peer count=%lu, group=%@, title=%@, online state=%@, online status=%ld changes=%@, unread=%ld>",
            [self class], self.chatId, (long)self.ownPrivilege, (unsigned long)self.peerCount, @(self.isGroup), self.title, @(self.onlineState), self.onlineStatus, @(self.changes), (long)self.unreadCount];
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
    return self.megaChatRoom->getTitle() ? [[NSString alloc] initWithUTF8String:self.megaChatRoom->getTitle()] : nil;
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

- (MEGAChatStatus)onlineStatus {
    return (MEGAChatStatus) self.megaChatRoom->getOnlineStatus();
}

- (uint64_t)userTypingHandle {
    return self.megaChatRoom->getUserTyping();
}

- (NSInteger)peerPrivilegeByHandle:(uint64_t)userHande {
    return self.megaChatRoom->getPeerPrivilegeByHandle(userHande);
}

- (NSString *)peerFirstnameByHandle:(uint64_t)userHande {
    return self.megaChatRoom->getPeerFirstnameByHandle(userHande) ? [[NSString alloc] initWithUTF8String:self.megaChatRoom->getPeerFirstnameByHandle(userHande)] : nil;
}

- (NSString *)peerLastnameByHandle:(uint64_t)userHande {
    return self.megaChatRoom->getPeerLastnameByHandle(userHande) ? [[NSString alloc] initWithUTF8String:self.megaChatRoom->getPeerLastnameByHandle(userHande)] : nil;
}

- (NSString *)peerFullnameByHandle:(uint64_t)userHande {
    const char *val = self.megaChatRoom->getPeerFullnameByHandle(userHande);
    if (!val) return nil;
    
    NSString *ret = [[NSString alloc] initWithUTF8String:val];
    
    delete [] val;
    return ret;
}

- (uint64_t)peerHandleAtIndex:(NSUInteger)index {
    return self.megaChatRoom->getPeerHandle((int)index);
}

- (MEGAChatRoomPrivilege)peerPrivilegeAtIndex:(NSUInteger)index {
    return (MEGAChatRoomPrivilege) self.megaChatRoom->getPeerPrivilege((int)index);
}

- (NSString *)peerFirstnameAtIndex:(NSUInteger)index {
    return self.megaChatRoom->getPeerFirstname((unsigned int)index) ? [[NSString alloc] initWithUTF8String:self.megaChatRoom->getPeerFirstname((unsigned int)index)] : nil;
}

- (NSString *)peerLastnameAtIndex:(NSUInteger)index {
    return self.megaChatRoom->getPeerLastname((unsigned int)index) ? [[NSString alloc] initWithUTF8String:self.megaChatRoom->getPeerLastname((unsigned int)index)] : nil;
}

- (NSString *)peerFullnameAtIndex:(NSUInteger)index {
    const char *val = self.megaChatRoom->getPeerFullname((unsigned int)index);
    if (!val) return nil;
    
    NSString *ret = [[NSString alloc] initWithUTF8String:val];
    
    delete [] val;
    return ret;
}

- (BOOL)hasChangedForType:(MEGAChatRoomChangeType)changeType {
    return self.megaChatRoom->hasChanged((int)changeType);
}

@end
