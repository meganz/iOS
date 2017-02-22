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
    return self.megaChatRoom->getChatId();
}

- (MEGAChatRoomPrivilege)ownPrivilege {
    return (MEGAChatRoomPrivilege) self.megaChatRoom->getOwnPrivilege();
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

- (BOOL)isActive {
    return self.megaChatRoom->isActive();
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

- (NSString *)peerEmailByHandle:(uint64_t)userHande {
    return self.megaChatRoom->getPeerEmailByHandle(userHande) ? [[NSString alloc] initWithUTF8String:self.megaChatRoom->getPeerEmailByHandle(userHande)] : nil;
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
