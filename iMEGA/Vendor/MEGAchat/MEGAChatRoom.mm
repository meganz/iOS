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
    NSString *ownPrivilege = [MEGAChatRoom stringForPrivilege:self.ownPrivilege];
    NSString *onlineStatus = [MEGAChatRoom stringForStatus:self.onlineStatus];
    NSString *changes      = [MEGAChatRoom stringForChangeType:self.changes];
    NSString *active       = self.isActive ? @"YES" : @"NO";
    NSString *group        = self.isGroup ? @"YES" : @"NO";
    
    return [NSString stringWithFormat:@"<%@: chatId=%llu, title=%@, online status=%@, own privilege=%@, peer count=%lu, group=%@, changes=%@, unread=%ld, user typing=%llu, active=%@>",
            [self class], self.chatId, self.title, onlineStatus, ownPrivilege, (unsigned long)self.peerCount, group, changes, (long)self.unreadCount, self.userTypingHandle, active];
}

- (uint64_t)chatId {
    return self.megaChatRoom ? self.megaChatRoom->getChatId() : MEGACHAT_INVALID_HANDLE;
}

- (MEGAChatRoomPrivilege)ownPrivilege {
    return (MEGAChatRoomPrivilege) (self.megaChatRoom ?  self.megaChatRoom->getOwnPrivilege() : -2);
}

- (NSUInteger)peerCount {
    return self.megaChatRoom ? self.megaChatRoom->getPeerCount() : 0;
}

- (BOOL)isGroup {
    return self.megaChatRoom ? self.megaChatRoom->isGroup() : NO;
}

- (NSString *)title {
    if (!self.megaChatRoom) return nil;
    const char *ret = self.megaChatRoom->getTitle();
    return ret ? [[NSString alloc] initWithUTF8String:ret] : nil;
}

- (MEGAChatRoomChangeType)changes {
    return (MEGAChatRoomChangeType) ( self.megaChatRoom ? self.megaChatRoom->getChanges() : 0x00);
}

- (NSInteger)unreadCount {
    return self.megaChatRoom ? self.megaChatRoom->getUnreadCount() : 0;
}

- (MEGAChatStatus)onlineStatus {
    return (MEGAChatStatus) (self.megaChatRoom ? self.megaChatRoom->getOnlineStatus() : 0);
}

- (uint64_t)userTypingHandle {
    return self.megaChatRoom ? self.megaChatRoom->getUserTyping() : MEGACHAT_INVALID_HANDLE;
}

- (BOOL)isActive {
    return self.megaChatRoom ? self.megaChatRoom->isActive() : NO;
}

- (NSInteger)peerPrivilegeByHandle:(uint64_t)userHande {
    return self.megaChatRoom ? self.megaChatRoom->getPeerPrivilegeByHandle(userHande) : -2;
}

- (NSString *)peerFirstnameByHandle:(uint64_t)userHande {
    if (!self.megaChatRoom) return nil;
    const char *ret = self.megaChatRoom->getPeerFirstnameByHandle(userHande);
    return ret ? [[NSString alloc] initWithUTF8String:ret] : nil;
}

- (NSString *)peerLastnameByHandle:(uint64_t)userHande {
    if (!self.megaChatRoom) return nil;
    const char *ret = self.megaChatRoom->getPeerLastnameByHandle(userHande);
    return ret ? [[NSString alloc] initWithUTF8String:ret] : nil;
}

- (NSString *)peerFullnameByHandle:(uint64_t)userHande {
    const char *val = self.megaChatRoom->getPeerFullnameByHandle(userHande);
    if (!val) return nil;
    
    NSString *ret = [[NSString alloc] initWithUTF8String:val];
    
    delete [] val;
    return ret;
}

- (NSString *)peerEmailByHandle:(uint64_t)userHande {
    if (!self.megaChatRoom) return nil;
    const char *ret = self.megaChatRoom->getPeerEmailByHandle(userHande);
    return ret ? [[NSString alloc] initWithUTF8String:ret] : nil;
}

- (uint64_t)peerHandleAtIndex:(NSUInteger)index {
    return self.megaChatRoom ? self.megaChatRoom->getPeerHandle((int)index) : MEGACHAT_INVALID_HANDLE;
}

- (MEGAChatRoomPrivilege)peerPrivilegeAtIndex:(NSUInteger)index {
    return (MEGAChatRoomPrivilege) (self.megaChatRoom ? self.megaChatRoom->getPeerPrivilege((int)index) : -2);
}

- (NSString *)peerFirstnameAtIndex:(NSUInteger)index {
    if (!self.megaChatRoom) return nil;
    const char *ret = self.megaChatRoom->getPeerFirstname((unsigned int)index);
    return ret ? [[NSString alloc] initWithUTF8String:ret] : nil;
}

- (NSString *)peerLastnameAtIndex:(NSUInteger)index {
    if (!self.megaChatRoom) return nil;
    const char *ret = self.megaChatRoom->getPeerLastname((unsigned int)index);
    return ret ? [[NSString alloc] initWithUTF8String:ret] : nil;
}

- (NSString *)peerFullnameAtIndex:(NSUInteger)index {
    const char *val = self.megaChatRoom->getPeerFullname((unsigned int)index);
    if (!val) return nil;
    
    NSString *ret = [[NSString alloc] initWithUTF8String:val];
    
    delete [] val;
    return ret;
}

- (BOOL)hasChangedForType:(MEGAChatRoomChangeType)changeType {
    return self.megaChatRoom ? self.megaChatRoom->hasChanged((int)changeType) : NO;
}

+ (NSString *)stringForPrivilege:(MEGAChatRoomPrivilege)privilege {
    return [[NSString alloc] initWithUTF8String:MegaChatRoom::privToString((int)privilege)];
}

+ (NSString *)stringForChangeType:(MEGAChatRoomChangeType)changeType {
    NSString *result;
    switch (changeType) {
        case MEGAChatRoomChangeTypeStatus:
            result = @"Status";
            break;
        case MEGAChatRoomChangeTypeUnreadCount:
            result = @"Unread count";
            break;
        case MEGAChatRoomChangeTypeParticipans:
            result = @"Participants";
            break;
        case MEGAChatRoomChangeTypeTitle:
            result = @"Title";
            break;
        case MEGAChatRoomChangeTypeUserTyping:
            result = @"User typing";
            break;
        case MEGAChatRoomChangeTypeClosed:
            result = @"Closed";
            break;
            
        default:
            result = @"Default";
            break;
    }
    return result;
}

+ (NSString *)stringForStatus:(MEGAChatStatus)status {
    return [[NSString alloc] initWithUTF8String:MegaChatRoom::statusToString((int)status)];
}

@end
