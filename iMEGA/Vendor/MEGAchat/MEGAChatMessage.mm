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
    return (MEGAChatMessageStatus) self.megaChatMessage->getStatus();
}

- (uint64_t)messageId {
    return self.megaChatMessage->getMsgId();
}

- (uint64_t)temporalId {
    return self.megaChatMessage->getTempId();
}

- (NSInteger)messageIndex {
    return self.megaChatMessage->getMsgIndex();
}

- (uint64_t)userHandle {
    return self.megaChatMessage->getUserHandle();
}

- (MEGAChatMessageType)type {
    return (MEGAChatMessageType) self.megaChatMessage->getType();
}

- (NSDate *)timestamp {
    return [[NSDate alloc] initWithTimeIntervalSince1970:self.megaChatMessage->getTimestamp()];
}

- (NSString *)content {
    return self.megaChatMessage->getContent() ? [[NSString alloc] initWithUTF8String:self.megaChatMessage->getContent()] : nil;
}

- (BOOL)isEdited {
    return self.megaChatMessage->isEdited();
}

- (BOOL)isDeleted {
    return self.megaChatMessage->isDeleted();
}

- (BOOL)isEditable {
    return self.megaChatMessage->isEditable();
}

- (BOOL)isManagementMessage {
    return self.megaChatMessage->isManagementMessage();
}

- (uint64_t)userHandleOfAction {
    return self.megaChatMessage->getUserHandleOfAction();
}

- (NSInteger)privilege {
    return self.megaChatMessage->getPrivilege();
}

- (NSInteger)changes {
    return self.megaChatMessage->getChanges();
}

- (BOOL)hasChangedForType:(MEGAChatMessageChangeType)changeType {
    return self.megaChatMessage->hasChanged((int)changeType);
}

@end
