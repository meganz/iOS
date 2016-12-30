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
    return [NSString stringWithFormat:@"<%@: chatId=%llu, title=%@, online status=%ld changes=%@, visibility=%ld, unread=%ld>",
            [self class], self.chatId, self.title, self.onlineStatus, @(self.changes), self.visibility, (long)self.unreadCount];
}

- (uint64_t)chatId {
    return self.megaChatListItem->getChatId();
}

- (NSString *)title {
    return self.megaChatListItem->getTitle() ? [[NSString alloc] initWithUTF8String:self.megaChatListItem->getTitle()] : nil;
}

- (MEGAChatListItemChangeType)changes {
    return (MEGAChatListItemChangeType) self.megaChatListItem->getChanges();
}

- (MEGAChatStatus)onlineStatus {
    return (MEGAChatStatus) self.megaChatListItem->getOnlineStatus();
}

- (NSInteger)visibility {
    return self.megaChatListItem->getVisibility();
}

- (NSInteger)unreadCount {
    return self.megaChatListItem->getUnreadCount();
}

- (MEGAChatMessage *)lastMessage {
    return self.megaChatListItem->getLastMessage() ? [[MEGAChatMessage alloc] initWithMegaChatMessage:self.megaChatListItem->getLastMessage()->copy() cMemoryOwn:YES] : nil;
}

- (BOOL)isGroup {
    return self.megaChatListItem->isGroup();
}

- (uint64_t)peerHandle {
    return self.megaChatListItem->getPeerHandle();
}

- (BOOL)hasChangedForType:(MEGAChatListItemChangeType)changeType {
    return self.megaChatListItem->hasChanged((int) changeType);
}

@end
