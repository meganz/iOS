#import "MEGAChatMessage.h"
#import "megachatapi.h"

using namespace megachat;

@interface MEGAChatMessage ()

@property MegaChatMessage *megaChatMessage;
@property BOOL cMemoryOwn;

@end

@implementation MEGAChatMessage

- (instancetype)initWithMegaChatMessage:(megachat::MegaChatMessage *)megaChatMessage cMemoryOwn:(BOOL)cMemoryOwn {
    NSParameterAssert(megaChatMessage);
    self = [super init];
    
    if (self != nil) {
        _megaChatMessage = megaChatMessage;
        _cMemoryOwn = cMemoryOwn;
    }
    
    return self;
}

- (void)dealloc {
    if (self.cMemoryOwn){
        delete _megaChatMessage;
    }
}

- (instancetype)clone {
    return self.megaChatMessage ? [[MEGAChatMessage alloc] initWithMegaChatMessage:self.megaChatMessage cMemoryOwn:YES] : nil;
}

- (MegaChatMessage *)getCPtr {
    return self.megaChatMessage;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: messageId=%llu, temporalId=%llu, status=%ld, index=%ld, user handle=%llu, type=%@, timestamp=%@, content=%@, edited=%@, deleted=%@, editable=%@, management message=%@, userHandleOfAction=%lld, privilege=%ld, changes=%ld>",
            [self class], self.messageId, self.temporalId, self.status,  self.messageIndex, self.userHandle, @(self.type), self.timestamp, self.content, @(self.edited), @(self.deleted), @(self.editable), @(self.managementMessage), self.userHandleOfAction, (long)self.privilege, self.changes];
}

- (MEGAChatMessageStatus)status {
    return (MEGAChatMessageStatus) (self.megaChatMessage ? self.megaChatMessage->getStatus() : 0);
}

- (uint64_t)messageId {
    return self.megaChatMessage ? self.megaChatMessage->getMsgId() : MEGACHAT_INVALID_HANDLE;
}

- (uint64_t)temporalId {
    return self.megaChatMessage ? self.megaChatMessage->getTempId() : MEGACHAT_INVALID_HANDLE;
}

- (NSInteger)messageIndex {
    return self.megaChatMessage ? self.megaChatMessage->getMsgIndex() : 0;
}

- (uint64_t)userHandle {
    return self.megaChatMessage ? self.megaChatMessage->getUserHandle() : MEGACHAT_INVALID_HANDLE;
}

- (MEGAChatMessageType)type {
    return (MEGAChatMessageType) (self.megaChatMessage ? self.megaChatMessage->getType() : -2);
}

- (NSDate *)timestamp {
    return self.megaChatMessage ? [[NSDate alloc] initWithTimeIntervalSince1970:self.megaChatMessage->getTimestamp()] : nil;
}

- (NSString *)content {
    if (!self.megaChatMessage) return nil;
    const char *ret = self.megaChatMessage->getContent();
    return ret ? [[NSString alloc] initWithUTF8String:ret] : nil;
}

- (BOOL)isEdited {
    return self.megaChatMessage ? self.megaChatMessage->isEdited() : NO;
}

- (BOOL)isDeleted {
    return self.megaChatMessage ? self.megaChatMessage->isDeleted() : NO;
}

- (BOOL)isEditable {
    return self.megaChatMessage ? self.megaChatMessage->isEditable() : NO;
}

- (BOOL)isManagementMessage {
    return self.megaChatMessage ? self.megaChatMessage->isManagementMessage() : NO;
}

- (uint64_t)userHandleOfAction {
    return self.megaChatMessage ? self.megaChatMessage->getUserHandleOfAction() : MEGACHAT_INVALID_HANDLE;
}

- (NSInteger)privilege {
    return self.megaChatMessage ? self.megaChatMessage->getPrivilege() : -2;
}

- (NSInteger)changes {
    return self.megaChatMessage ? self.megaChatMessage->getChanges() : 0x00;
}

- (NSInteger)code {
    return self.megaChatMessage ? self.megaChatMessage->getCode() : 0;
}

- (BOOL)hasChangedForType:(MEGAChatMessageChangeType)changeType {
    return self.megaChatMessage ? self.megaChatMessage->hasChanged((int)changeType) : NO;
}

@end
