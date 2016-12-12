#import "MEGAMessage.h"
#import "MEGASdkManager.h"

@implementation MEGAMessage

#pragma mark - Initialization

- (instancetype)initWithMEGAChatMessage:(MEGAChatMessage *)message megaChatRoom:(MEGAChatRoom *)chatRoom {
    NSParameterAssert(message != nil);
    self = [super init];
    if (self) {
        _userHandle = message.userHandle;
        _messageId  = message.messageId;
        _senderId   = [NSString stringWithFormat:@"%llu", message.userHandle];
        _date       = message.timestamp;
        _index      = message.messageIndex;
        _editable   = message.isEditable;
        _edited     = message.isEdited;
        _deleted    = message.isDeleted;
        _type       = message.type;
        
        if (message.isDeleted) {
            _text = @"This message has been deleted";
        } else if (message.isManagementMessage) {
            _managementMessage = message.managementMessage;
            
            uint64_t myHandle = [[[MEGASdkManager sharedMEGASdk] myUser] handle];
            NSString *fullNameDidAction = nil;
            
            if (myHandle == message.userHandle) {
                fullNameDidAction = @"I";
            } else {
                NSString *firstNameDidAction = [chatRoom peerFirstnameByHandle:message.userHandle];
                NSString *lastNameDidAction  = [chatRoom peerLastnameByHandle:message.userHandle];
                if (firstNameDidAction) {
                    if (lastNameDidAction) {
                        fullNameDidAction = [firstNameDidAction stringByAppendingString:lastNameDidAction];
                    } else {
                        fullNameDidAction = firstNameDidAction;
                    }
                } else {
                    if (lastNameDidAction) {
                        fullNameDidAction = lastNameDidAction;
                    }
                }
            }
            
            NSString *firstNameReceiveAction = nil;
            NSString *lastNameReceiveAction  = nil;
            
            uint64_t tempHandle;
            if (message.type == MEGAChatMessageTypeAlterParticipants || message.type == MEGAChatMessageTypePrivilegeChange) {
                tempHandle = message.userHandleOfAction;
            } else {
                tempHandle = message.userHandle;
            }
            
            if (tempHandle == myHandle) {
                firstNameReceiveAction = @"I";
                lastNameReceiveAction  = @"";
            } else {
                firstNameReceiveAction = [chatRoom peerFirstnameByHandle:tempHandle];
                lastNameReceiveAction  = [chatRoom peerLastnameByHandle:tempHandle];
                if (!firstNameReceiveAction) {
                    //TODO: Use the app Core Data users cache
                    firstNameReceiveAction = @"Unknown user";
                    lastNameReceiveAction  = @"";
                }
            }
            
            NSString *fullNameReceiveAction = [firstNameReceiveAction stringByAppendingString:lastNameReceiveAction];
            
            switch (message.type) {
                case MEGAChatMessageTypeAlterParticipants:
                    switch (message.privilege) {
                        case -1:
                            if (fullNameDidAction && ![fullNameReceiveAction isEqualToString:fullNameDidAction]) {
                                _text = [NSString stringWithFormat:@"%@ was removed from the group chat by %@", fullNameReceiveAction, fullNameDidAction];
                            } else {
                                _text = [NSString stringWithFormat:@"%@ left the group chat.", fullNameReceiveAction];
                            }
                            break;
                            
                        case -2:
                            _text = [NSString stringWithFormat:@"%@ joined the group chat by invitation from %@", fullNameReceiveAction, fullNameDidAction];
                            break;
                            
                        default:
                            break;
                    }
                    break;
                    
                case MEGAChatMessageTypeTruncate:
                    _text = [NSString stringWithFormat:@"%@ cleared the chat history.", fullNameDidAction];
                    break;
                    
                case MEGAChatMessageTypePrivilegeChange: {
                    switch (message.privilege) {
                        case 0:
                            _text = [NSString stringWithFormat:@"%@ was change to Read-only by %@", fullNameReceiveAction, fullNameDidAction];
                            break;
                            
                        case 2:
                            _text = [NSString stringWithFormat:@"%@ was change to Standard by %@", fullNameReceiveAction, fullNameDidAction];
                            break;
                            
                        case 3:
                            _text = [NSString stringWithFormat:@"%@ was change to Moderator by %@", fullNameReceiveAction, fullNameDidAction];
                            break;
                            
                        default:
                            break;
                    }
                    break;
                }
                    
                case MEGAChatMessageTypeChatTitle:
                    _text = [NSString stringWithFormat:@"%@ changed group name to %@", fullNameDidAction, message.content];
                    break;
                    
                case MEGAChatMessageTypeUserMessage:
                    _text = [NSString stringWithFormat:@"%llu, %ld", message.userHandleOfAction, message.privilege];
                    break;
                    
                default:
                    _text = @"default";
                    break;
            }
        } else {
            _text = message.content;
        }
    }
    
    return self;
}

- (NSUInteger)messageHash {
    return self.hash;
}

#pragma mark - NSObject

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    }
    
    if (![object isKindOfClass:[self class]]) {
        return NO;
    }
    
    MEGAMessage *aMessage = (MEGAMessage *)object;
    
    if (self.isMediaMessage != aMessage.isMediaMessage) {
        return NO;
    }
    
    BOOL hasEqualContent = self.isMediaMessage ? [self.media isEqual:aMessage.media] : [self.text isEqualToString:aMessage.text];
    
    return [self.senderId isEqualToString:aMessage.senderId]
    && [self.senderDisplayName isEqualToString:aMessage.senderDisplayName]
    && ([self.date compare:aMessage.date] == NSOrderedSame)
    && hasEqualContent;
}

- (NSUInteger)hash {
    NSUInteger contentHash = self.isMediaMessage ? [self.media mediaHash] : self.text.hash;
    return self.senderId.hash ^ self.date.hash ^ contentHash;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: senderId=%@, date=%@, isMediaMessage=%@, text=%@, media=%@, index=%ld>",
            [self class], self.senderId, self.date, @(self.isMediaMessage), self.text, self.media, (long)self.index];
}

- (id)debugQuickLookObject {
    return [self.media mediaView] ?: [self.media mediaPlaceholderView];
}

@end
