#import "MEGAMessage.h"
#import "MEGASdkManager.h"
#import "MEGAStore.h"

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
            _text = AMLocalizedString(@"thisMessageHasBeenDeleted", @"A log message in a chat to indicate that the message has been deleted by the user.");
        } else if (message.isManagementMessage) {
            _managementMessage = message.managementMessage;
            
            uint64_t myHandle = [[MEGASdkManager sharedMEGAChatSdk] myUserHandle];
            NSString *fullNameDidAction = @"";
            
            if (myHandle == message.userHandle) {
                fullNameDidAction = [[MEGASdkManager sharedMEGAChatSdk] myFullname];
            } else {
                fullNameDidAction = [chatRoom peerFullnameByHandle:message.userHandle];
                if (fullNameDidAction.length == 0) {                    
                    MOUser *moUser = [[MEGAStore shareInstance] fetchUserWithUserHandle:message.userHandle];
                    if (moUser) {
                        fullNameDidAction = moUser.fullName;
                    } else {
                        // TODO: request firstname and lastname
                        fullNameDidAction = @"Unknown user";
                    }
                }
            }
            
            NSString *fullNameReceiveAction = @"";
            
            uint64_t tempHandle;
            if (message.type == MEGAChatMessageTypeAlterParticipants || message.type == MEGAChatMessageTypePrivilegeChange) {
                tempHandle = message.userHandleOfAction;
            } else {
                tempHandle = message.userHandle;
            }
            
            if (tempHandle == myHandle) {
                fullNameReceiveAction = [[MEGASdkManager sharedMEGAChatSdk] myFullname];
            } else {
                fullNameReceiveAction = [chatRoom peerFullnameByHandle:tempHandle];
                if (fullNameReceiveAction.length == 0) {
                    MOUser *moUser = [[MEGAStore shareInstance] fetchUserWithUserHandle:tempHandle];
                    if (moUser) {
                        fullNameReceiveAction = moUser.fullName;
                    } else {                        
                        // TODO: request firstname and lastname
                        fullNameReceiveAction = @"Unknown user";
                    }
                }
            }
            
            switch (message.type) {
                case MEGAChatMessageTypeAlterParticipants:
                    switch (message.privilege) {
                        case -1: {
                            if (fullNameDidAction && ![fullNameReceiveAction isEqualToString:fullNameDidAction]) {
                                NSString *wasRemovedFromTheGroupChatBy = AMLocalizedString(@"wasRemovedFromTheGroupChatBy", @"A log message in a chat conversation to tell the reader that a participant [A] was removed from the group chat by the moderator [B]. Please keep [A] and [B], they will be replaced by the participant and the moderator names at runtime. For example: Alice was removed from the group chat by Frank.");
                                wasRemovedFromTheGroupChatBy = [wasRemovedFromTheGroupChatBy stringByReplacingOccurrencesOfString:@"[A]" withString:fullNameReceiveAction];
                                wasRemovedFromTheGroupChatBy = [wasRemovedFromTheGroupChatBy stringByReplacingOccurrencesOfString:@"[B]" withString:fullNameDidAction];
                                _text = wasRemovedFromTheGroupChatBy;
                            } else {
                                NSString *leftTheGroupChat = AMLocalizedString(@"leftTheGroupChat", @"A log message in the chat conversation to tell the reader that a participant [A] left the group chat. For example: Alice left the group chat.");
                                leftTheGroupChat = [leftTheGroupChat stringByReplacingOccurrencesOfString:@"[A]" withString:fullNameReceiveAction];
                                _text = leftTheGroupChat;
                            }
                            break;
                        }
                            
                        case -2: {
                            NSString *joinedTheGroupChatByInvitationFrom = AMLocalizedString(@"joinedTheGroupChatByInvitationFrom", @"A log message in a chat conversation to tell the reader that a participant [A] was added to the chat by a moderator [B]. Please keep the [A] and [B] placeholders, they will be replaced by the participant and the moderator names at runtime. For example: Alice joined the group chat by invitation from Frank.");
                            joinedTheGroupChatByInvitationFrom = [joinedTheGroupChatByInvitationFrom stringByReplacingOccurrencesOfString:@"[A]" withString:fullNameReceiveAction];
                            joinedTheGroupChatByInvitationFrom = [joinedTheGroupChatByInvitationFrom stringByReplacingOccurrencesOfString:@"[B]" withString:fullNameDidAction];
                            _text = joinedTheGroupChatByInvitationFrom;
                            break;
                        }
                            
                        default:
                            break;
                    }
                    break;
                    
                case MEGAChatMessageTypeTruncate: {
                    NSString *clearedTheChatHistory = AMLocalizedString(@"clearedTheChatHistory", @"A log message in the chat conversation to tell the reader that a participant [A] cleared the history of the chat. For example, Alice cleared the chat history.");
                    clearedTheChatHistory = [clearedTheChatHistory stringByReplacingOccurrencesOfString:@"[A]" withString:fullNameDidAction];
                    _text = clearedTheChatHistory;
                    break;
                }
                    
                case MEGAChatMessageTypePrivilegeChange: {
                    NSString *wasChangedToBy = AMLocalizedString(@"wasChangedToBy", @"A log message in a chat to display that a participant's permission was changed and by whom. This message begins with the user's name who receive the permission change [A]. [B] will be replaced with the permission name (such as Moderator or Read-only) and [C] will be replaced with the person who did it. Please keep the [A], [B] and [C] placeholders, they will be replaced at runtime. For example: Alice Jones was changed to Moderator by John Smith.");
                    wasChangedToBy = [wasChangedToBy stringByReplacingOccurrencesOfString:@"[A]" withString:fullNameReceiveAction];
                    NSString *privilige;
                    switch (message.privilege) {
                        case 0:
                            privilige = AMLocalizedString(@"readOnly", @"Permissions given to the user you share your folder with");
                            break;
                            
                        case 2:
                            privilige = AMLocalizedString(@"standard", @"The Standard permission level in chat. With the standard permissions a participant can read and type messages in a chat.");
                            break;
                            
                        case 3:
                            privilige = AMLocalizedString(@"moderator", @"The Moderator permission level in chat. With moderator permissions a participant can manage the chat");
                            break;
                            
                        default:
                            break;
                    }
                    wasChangedToBy = [wasChangedToBy stringByReplacingOccurrencesOfString:@"[B]" withString:privilige];
                    wasChangedToBy = [wasChangedToBy stringByReplacingOccurrencesOfString:@"[C]" withString:fullNameDidAction];
                    _text = wasChangedToBy;
                    break;
                }
                    
                case MEGAChatMessageTypeChatTitle: {
                    NSString *changedGroupChatNameTo = AMLocalizedString(@"changedGroupChatNameTo", @"A hint message in a group chat to indicate the group chat name is changed to a new one. Please keep %s when translating this string which will be replaced with the name at runtime.");
                    changedGroupChatNameTo = [changedGroupChatNameTo stringByReplacingOccurrencesOfString:@"[A]" withString:fullNameDidAction];
                    if (message.content) {
                        changedGroupChatNameTo = [changedGroupChatNameTo stringByReplacingOccurrencesOfString:@"[B]" withString:message.content];
                    }
                    _text = changedGroupChatNameTo;
                    break;
                }
                    
                case MEGAChatMessageTypeAttachment:
                    _text = @"MEGAChatMessageTypeAttachment";
                    break;
                    
                case MEGAChatMessageTypeRevoke:
                    _text = @"MEGAChatMessageTypeRevoke";
                    break;
                    
                case MEGAChatMessageTypeContact:
                    _text = @"MEGAChatMessageTypeContact";
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
