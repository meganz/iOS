#import "MEGAChatListItem.h"
#import "megachatapi.h"
#import "MEGAChatMessage+init.h"

using namespace megachat;

@interface MEGAChatListItem ()

@property MegaChatListItem *megaChatListItem;
@property BOOL cMemoryOwn;

@end

@implementation MEGAChatListItem

- (instancetype)initWithMegaChatListItem:(megachat::MegaChatListItem *)megaChatListItem cMemoryOwn:(BOOL)cMemoryOwn {
    self = [super init];
    
    if (self != nil) {
        _megaChatListItem = megaChatListItem;
        _cMemoryOwn = cMemoryOwn;
    }
    
    return self;
}

- (void)dealloc {
    if (self.cMemoryOwn){
        delete _megaChatListItem;
    }
}

- (instancetype)clone {
    return self.megaChatListItem ? [[MEGAChatListItem alloc] initWithMegaChatListItem:self.megaChatListItem cMemoryOwn:YES] : nil;
}

- (MegaChatListItem *)getCPtr {
    return self.megaChatListItem;
}

- (NSString *)description {
    NSString *changes      = [MEGAChatListItem stringForChangeType:self.changes];
    NSString *active       = self.isActive ? @"YES" : @"NO";
    NSString *group        = self.isGroup ? @"YES" : @"NO";
    NSString *visibility   = [MEGAChatListItem stringForVisibility:self.visibility];
    NSString *type         = [MEGAChatListItem stringForMessageType:self.lastMessageType];
    
    return [NSString stringWithFormat:@"<%@: chatId=%llu, title=%@, changes=%@, last message=%@, last date=%@, last type=%@, visibility=%@, unread=%ld, group=%@, active=%@>",
            [self class], self.chatId, self.title, changes, self.lastMessage, self.lastMessageDate, type, visibility, (long)self.unreadCount, group, active];
}

- (uint64_t)chatId {
    return self.megaChatListItem ? self.megaChatListItem->getChatId() : MEGACHAT_INVALID_HANDLE;
}

- (NSString *)title {
    if (!self.megaChatListItem) return nil;
    const char *ret = self.megaChatListItem->getTitle();
    return ret ? [[NSString alloc] initWithUTF8String:ret] : nil;
}

- (MEGAChatListItemChangeType)changes {
    return (MEGAChatListItemChangeType) (self.megaChatListItem ? self.megaChatListItem->getChanges() : 0x00);
}

- (NSInteger)visibility {
    return self.megaChatListItem ? self.megaChatListItem->getVisibility() : -1;
}

- (NSInteger)unreadCount {
    return self.megaChatListItem ? self.megaChatListItem->getUnreadCount() : 0;
}

- (BOOL)isGroup {
    return self.megaChatListItem ? self.megaChatListItem->isGroup() : NO;
}

- (uint64_t)peerHandle {
    return self.megaChatListItem ? self.megaChatListItem->getPeerHandle() : MEGACHAT_INVALID_HANDLE;
}

- (BOOL)isActive {
    return self.megaChatListItem ? self.megaChatListItem->isActive() : NO;
}

- (NSString *)lastMessage {
    if (!self.megaChatListItem) return nil;
    const char *ret = self.megaChatListItem->getLastMessage();
    return ret ? [[NSString alloc] initWithUTF8String:ret] : nil;
}

- (MEGAChatMessageType)lastMessageType {
    return (MEGAChatMessageType) (self.megaChatListItem ? self.megaChatListItem->getLastMessageType() : 0);
}

- (uint64_t)lastMessageSender {
    return self.megaChatListItem ? self.megaChatListItem->getLastMessageSender() : MEGACHAT_INVALID_HANDLE;
}

- (NSDate *)lastMessageDate {
    return self.megaChatListItem ? [[NSDate alloc] initWithTimeIntervalSince1970:self.megaChatListItem->getLastTimestamp()] : nil;
}

- (BOOL)hasChangedForType:(MEGAChatListItemChangeType)changeType {
    return self.megaChatListItem ? self.megaChatListItem->hasChanged((int) changeType) : NO;
}

+ (NSString *)stringForChangeType:(MEGAChatListItemChangeType)changeType {
    NSString *result;
    switch (changeType) {
        case MEGAChatListItemChangeTypeStatus:
            result = @"Status";
            break;
        case MEGAChatListItemChangeTypeVisibility:
            result = @"Visibility";
            break;
        case MEGAChatListItemChangeTypeUnreadCount:
            result = @"Unread count";
            break;
        case MEGAChatListItemChangeTypeParticipants:
            result = @"Participants";
            break;
        case MEGAChatListItemChangeTypeTitle:
            result = @"Title";
            break;
        case MEGAChatListItemChangeTypeClosed:
            result = @"Closed";
            break;
        case MEGAChatListItemChangeTypeLastMsg:
            result = @"Last message";
            break;
        case MEGAChatListItemChangeTypeLastTs:
            result = @"Last timestamp";
            break;
            
        default:
            result = @"Default";
            break;
    }
    return result;
}

+ (NSString *)stringForVisibility:(NSInteger)visibility {
    NSString *result;
    
    switch (visibility) {
        case -1:
            result = @"Unknown";
            break;
        case 0:
            result = @"Hidden";
            break;
        case 1:
            result = @"Visible";
            break;
        case 2:
            result = @"Inactive";
            break;
        case 3:
            result = @"Blocked";
            break;
            
        default:
            result = @"Default";
            break;
    }
    return result;
}

+ (NSString *)stringForMessageType:(MEGAChatMessageType)type {
    NSString *result;
    
    switch (type) {
        case MEGAChatMessageTypeInvalid:
            result = @"Invalid";
            break;
        case MEGAChatMessageTypeNormal:
            result = @"Normal";
            break;
        case MEGAChatMessageTypeAlterParticipants:
            result = @"Alter participants";
            break;
        case MEGAChatMessageTypeTruncate:
            result = @"Truncate";
            break;
        case MEGAChatMessageTypePrivilegeChange:
            result = @"Privilege change";
            break;
        case MEGAChatMessageTypeChatTitle:
            result = @"Chat title";
            break;
        case MEGAChatMessageTypeAttachment:
            result = @"Attachment";
            break;
        case MEGAChatMessageTypeRevoke:
            result = @"Revoke";
            break;
        case MEGAChatMessageTypeContact:
            result = @"Contact";
            break;
            
        default:
            result = @"Default";
            break;
    }
    return result;

}

@end
