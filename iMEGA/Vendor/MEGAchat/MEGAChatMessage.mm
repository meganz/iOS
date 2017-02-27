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
    NSString *status = [MEGAChatMessage stringForStatus:self.status];
    NSString *type = [MEGAChatMessage stringForType:self.type];
    NSString *changes = [MEGAChatMessage stringForChangeType:self.changes];
    NSString *code = [MEGAChatMessage stringForCode:self.code];
    
    return [NSString stringWithFormat:@"<%@: messageId=%llu, temporalId=%llu, status=%@, index=%ld, user handle=%llu, type=%@, timestamp=%@, content=%@, edited=%@, deleted=%@, editable=%@, management message=%@, userHandleOfAction=%lld, privilege=%ld, changes=%@, code=%@>",
            [self class], self.messageId, self.temporalId, status,  self.messageIndex, self.userHandle, type, self.timestamp, self.content, @(self.edited), @(self.deleted), @(self.editable), @(self.managementMessage), self.userHandleOfAction, (long)self.privilege, changes, code];
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
    return (MEGAChatMessageType) (self.megaChatMessage ? self.megaChatMessage->getType() : 0);
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

- (MEGAChatMessageChangeType)changes {
    return (MEGAChatMessageChangeType) (self.megaChatMessage ? self.megaChatMessage->getChanges() : 0x00);
}

- (MEGAChatMessageReason)code {
    return (MEGAChatMessageReason) (self.megaChatMessage ? self.megaChatMessage->getCode() : 0);
}

- (BOOL)hasChangedForType:(MEGAChatMessageChangeType)changeType {
    return self.megaChatMessage ? self.megaChatMessage->hasChanged((int)changeType) : NO;
}

+ (NSString *)stringForChangeType:(MEGAChatMessageChangeType)changeType {
    NSString *result;
    switch (changeType) {
        case MEGAChatMessageChangeTypeStatus:
            result = @"Status";
            break;
        case MEGAChatMessageChangeTypeContent:
            result = @"Content";
            break;
            
        default:
            result = @"Default";
            break;
    }
    return result;
}
+ (NSString *)stringForStatus:(MEGAChatMessageStatus)status {
    NSString *result;
    switch (status) {
        case MEGAChatMessageStatusUnknown:
            result = @"Unknown";
            break;
        case MEGAChatMessageStatusSending:
            result = @"Sending";
            break;
        case MEGAChatMessageStatusSendingManual:
            result = @"Sending manual";
            break;
        case MEGAChatMessageStatusServerReceived:
            result = @"Server received";
            break;
        case MEGAChatMessageStatusServerRejected:
            result = @"Server rejected";
            break;
        case MEGAChatMessageStatusDelivered:
            result = @"Delivered";
            break;
        case MEGAChatMessageStatusNotSeen:
            result = @"Not seen";
            break;
        case MEGAChatMessageStatusSeen:
            result = @"Seen";
            break;
            
        default:
            result = @"Default";
            break;
    }
    return result;
    
}

+ (NSString *)stringForType:(MEGAChatMessageType)type {
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

+ (NSString *)stringForCode:(MEGAChatMessageReason)code {
    NSString *result;
    switch (code) {
        case MEGAChatMessageReasonPeersChanged:
            result = @"Peers changed";
            break;
        case MEGAChatMessageReasonTooOld:
            result = @"Too old";
            break;
        case MEGAChatMessageReasonGeneralReject:
            result = @"General reject";
            break;
        case MEGAChatMessageReasonNoWriteAccess:
            result = @"No write access";
        default:
            result = @"Default";
            break;
    }
    return result;
}

@end
