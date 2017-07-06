
#import "MEGAChatMessage+MNZCategory.h"
#import "MEGASdkManager.h"
#import "MEGAStore.h"
#import "MEGAAttachmentMediaItem.h"

#import "MEGAPhotoMediaItem.h"
#import "NSString+MNZCategory.h"

#import <objc/runtime.h>

static const void *chatRoomTagKey = &chatRoomTagKey;
static const void *attributedTextTagKey = &attributedTextTagKey;

@implementation MEGAChatMessage (MNZCategory)

- (NSString *)senderId {
    return [NSString stringWithFormat:@"%llu", self.userHandle];
}

- (NSString *)senderDisplayName {
    return [NSString stringWithFormat:@"%llu", self.userHandle];
}

- (NSDate *)date {
    return self.timestamp;
}

- (BOOL)isMediaMessage {
    BOOL mediaMessage = NO;
    
    if (self.isDeleted) {
        mediaMessage = NO;
    } else {
        if (self.type == MEGAChatMessageTypeContact || self.type == MEGAChatMessageTypeAttachment) {
            mediaMessage = YES;
        }
    }
    
    return mediaMessage;
}

- (NSString *)text {
    NSString *text;
    if (self.isDeleted) {
        text = AMLocalizedString(@"thisMessageHasBeenDeleted", @"A log message in a chat to indicate that the message has been deleted by the user.");
    } else if (self.isManagementMessage) {
        
        uint64_t myHandle = [[MEGASdkManager sharedMEGAChatSdk] myUserHandle];
        NSString *fullNameDidAction = @"";
        
        if (myHandle == self.userHandle) {
            fullNameDidAction = [[MEGASdkManager sharedMEGAChatSdk] myFullname];
        } else {
            fullNameDidAction = [self.chatRoom peerFullnameByHandle:self.userHandle];
            if (fullNameDidAction.length == 0) {
                MOUser *moUser = [[MEGAStore shareInstance] fetchUserWithUserHandle:self.userHandle];
                if (moUser) {
                    fullNameDidAction = moUser.fullName ? moUser.fullName : moUser.email;
                } else {
                    // TODO: request firstname and lastname
                    fullNameDidAction = @"Unknown user";
                }
            }
        }
        
        NSString *fullNameReceiveAction = @"";
        
        uint64_t tempHandle;
        if (self.type == MEGAChatMessageTypeAlterParticipants || self.type == MEGAChatMessageTypePrivilegeChange) {
            tempHandle = self.userHandleOfAction;
        } else {
            tempHandle = self.userHandle;
        }
        
        if (tempHandle == myHandle) {
            fullNameReceiveAction = [[MEGASdkManager sharedMEGAChatSdk] myFullname];
        } else {
            fullNameReceiveAction = [self.chatRoom peerFullnameByHandle:tempHandle];
            if (fullNameReceiveAction.length == 0) {
                MOUser *moUser = [[MEGAStore shareInstance] fetchUserWithUserHandle:tempHandle];
                if (moUser) {
                    fullNameReceiveAction = moUser.fullName ? moUser.fullName : moUser.email;
                } else {
                    // TODO: request firstname and lastname
                    fullNameReceiveAction = @"Unknown user";
                }
            }
        }
        
        switch (self.type) {
            case MEGAChatMessageTypeAlterParticipants:
                switch (self.privilege) {
                    case -1: {
                        if (fullNameDidAction && ![fullNameReceiveAction isEqualToString:fullNameDidAction]) {
                            NSString *wasRemovedFromTheGroupChatBy = AMLocalizedString(@"wasRemovedFromTheGroupChatBy", @"A log message in a chat conversation to tell the reader that a participant [A] was removed from the group chat by the moderator [B]. Please keep [A] and [B], they will be replaced by the participant and the moderator names at runtime. For example: Alice was removed from the group chat by Frank.");
                            wasRemovedFromTheGroupChatBy = [wasRemovedFromTheGroupChatBy stringByReplacingOccurrencesOfString:@"[A]" withString:fullNameReceiveAction];
                            wasRemovedFromTheGroupChatBy = [wasRemovedFromTheGroupChatBy stringByReplacingOccurrencesOfString:@"[B]" withString:fullNameDidAction];
                            text = wasRemovedFromTheGroupChatBy;
                            
                            NSMutableAttributedString *mutableAttributedString = [[NSMutableAttributedString alloc] initWithString:wasRemovedFromTheGroupChatBy attributes:@{NSFontAttributeName:[UIFont mnz_SFUIRegularWithSize:11.0f], NSForegroundColorAttributeName:[UIColor mnz_black333333]}];
                            [mutableAttributedString addAttribute:NSFontAttributeName value:[UIFont mnz_SFUIMediumWithSize:11.0f] range:[wasRemovedFromTheGroupChatBy rangeOfString:fullNameReceiveAction]];
                            [mutableAttributedString addAttribute:NSFontAttributeName value:[UIFont mnz_SFUIMediumWithSize:11.0f] range:[wasRemovedFromTheGroupChatBy rangeOfString:fullNameDidAction]];
                            self.attributedText = mutableAttributedString;
                        } else {
                            NSString *leftTheGroupChat = AMLocalizedString(@"leftTheGroupChat", @"A log message in the chat conversation to tell the reader that a participant [A] left the group chat. For example: Alice left the group chat.");
                            leftTheGroupChat = [leftTheGroupChat stringByReplacingOccurrencesOfString:@"[A]" withString:fullNameReceiveAction];
                            text = leftTheGroupChat;
                            
                            NSMutableAttributedString *mutableAttributedString = [[NSMutableAttributedString alloc] initWithString:leftTheGroupChat attributes:@{NSFontAttributeName:[UIFont mnz_SFUIRegularWithSize:11.0f], NSForegroundColorAttributeName:[UIColor mnz_black333333]}];
                            [mutableAttributedString addAttribute:NSFontAttributeName value:[UIFont mnz_SFUIMediumWithSize:11.0f] range:[leftTheGroupChat rangeOfString:fullNameReceiveAction]];
                            self.attributedText = mutableAttributedString;
                        }
                        break;
                    }
                        
                    case -2: {
                        NSString *joinedTheGroupChatByInvitationFrom = AMLocalizedString(@"joinedTheGroupChatByInvitationFrom", @"A log message in a chat conversation to tell the reader that a participant [A] was added to the chat by a moderator [B]. Please keep the [A] and [B] placeholders, they will be replaced by the participant and the moderator names at runtime. For example: Alice joined the group chat by invitation from Frank.");
                        joinedTheGroupChatByInvitationFrom = [joinedTheGroupChatByInvitationFrom stringByReplacingOccurrencesOfString:@"[A]" withString:fullNameReceiveAction];
                        joinedTheGroupChatByInvitationFrom = [joinedTheGroupChatByInvitationFrom stringByReplacingOccurrencesOfString:@"[B]" withString:fullNameDidAction];
                        text = joinedTheGroupChatByInvitationFrom;
                        
                        NSMutableAttributedString *mutableAttributedString = [[NSMutableAttributedString alloc] initWithString:joinedTheGroupChatByInvitationFrom attributes:@{NSFontAttributeName:[UIFont mnz_SFUIRegularWithSize:11.0f], NSForegroundColorAttributeName:[UIColor mnz_black333333]}];
                        [mutableAttributedString addAttribute:NSFontAttributeName value:[UIFont mnz_SFUIMediumWithSize:11.0f] range:[joinedTheGroupChatByInvitationFrom rangeOfString:fullNameReceiveAction]];
                        [mutableAttributedString addAttribute:NSFontAttributeName value:[UIFont mnz_SFUIMediumWithSize:11.0f] range:[joinedTheGroupChatByInvitationFrom rangeOfString:fullNameDidAction]];
                        self.attributedText = mutableAttributedString;
                        break;
                    }
                        
                    default:
                        break;
                }
                break;
                
            case MEGAChatMessageTypeTruncate: {
                NSString *clearedTheChatHistory = AMLocalizedString(@"clearedTheChatHistory", @"A log message in the chat conversation to tell the reader that a participant [A] cleared the history of the chat. For example, Alice cleared the chat history.");
                clearedTheChatHistory = [clearedTheChatHistory stringByReplacingOccurrencesOfString:@"[A]" withString:fullNameDidAction];
                text = clearedTheChatHistory;
                
                NSMutableAttributedString *mutableAttributedString = [[NSMutableAttributedString alloc] initWithString:clearedTheChatHistory attributes:@{NSFontAttributeName:[UIFont mnz_SFUIRegularWithSize:11.0f], NSForegroundColorAttributeName:[UIColor mnz_black333333]}];
                [mutableAttributedString addAttribute:NSFontAttributeName value:[UIFont mnz_SFUIMediumWithSize:11.0f] range:[clearedTheChatHistory rangeOfString:fullNameDidAction]];
                self.attributedText = mutableAttributedString;
                break;
            }
                
            case MEGAChatMessageTypePrivilegeChange: {
                NSString *wasChangedToBy = AMLocalizedString(@"wasChangedToBy", @"A log message in a chat to display that a participant's permission was changed and by whom. This message begins with the user's name who receive the permission change [A]. [B] will be replaced with the permission name (such as Moderator or Read-only) and [C] will be replaced with the person who did it. Please keep the [A], [B] and [C] placeholders, they will be replaced at runtime. For example: Alice Jones was changed to Moderator by John Smith.");
                wasChangedToBy = [wasChangedToBy stringByReplacingOccurrencesOfString:@"[A]" withString:fullNameReceiveAction];
                NSString *privilige;
                switch (self.privilege) {
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
                text = wasChangedToBy;
                
                NSMutableAttributedString *mutableAttributedString = [[NSMutableAttributedString alloc] initWithString:wasChangedToBy attributes:@{NSFontAttributeName:[UIFont mnz_SFUIRegularWithSize:11.0f], NSForegroundColorAttributeName:[UIColor mnz_black333333]}];
                [mutableAttributedString addAttribute:NSFontAttributeName value:[UIFont mnz_SFUIMediumWithSize:11.0f] range:[wasChangedToBy rangeOfString:fullNameReceiveAction]];
                [mutableAttributedString addAttribute:NSFontAttributeName value:[UIFont mnz_SFUIMediumWithSize:11.0f] range:[wasChangedToBy rangeOfString:privilige]];
                [mutableAttributedString addAttribute:NSFontAttributeName value:[UIFont mnz_SFUIMediumWithSize:11.0f] range:[wasChangedToBy rangeOfString:fullNameDidAction]];
                self.attributedText = mutableAttributedString;
                break;
            }
                
            case MEGAChatMessageTypeChatTitle: {
                NSString *changedGroupChatNameTo = AMLocalizedString(@"changedGroupChatNameTo", @"A hint message in a group chat to indicate the group chat name is changed to a new one. Please keep %s when translating this string which will be replaced with the name at runtime.");
                changedGroupChatNameTo = [changedGroupChatNameTo stringByReplacingOccurrencesOfString:@"[A]" withString:fullNameDidAction];
                changedGroupChatNameTo = [changedGroupChatNameTo stringByReplacingOccurrencesOfString:@"[B]" withString:(self.content ? self.content : @" ")];
                text = changedGroupChatNameTo;
                
                NSMutableAttributedString *mutableAttributedString = [[NSMutableAttributedString alloc] initWithString:changedGroupChatNameTo attributes:@{NSFontAttributeName:[UIFont mnz_SFUIRegularWithSize:11.0f], NSForegroundColorAttributeName:[UIColor mnz_black333333]}];
                [mutableAttributedString addAttribute:NSFontAttributeName value:[UIFont mnz_SFUIMediumWithSize:11.0f] range:[changedGroupChatNameTo rangeOfString:fullNameDidAction]];
                if (self.content) [mutableAttributedString addAttribute:NSFontAttributeName value:[UIFont mnz_SFUIMediumWithSize:11.0f] range:[changedGroupChatNameTo rangeOfString:self.content]];
                self.attributedText = mutableAttributedString;
                break;
            }
                
            default:
                text = @"default";
                break;
        }
    } else if (self.type == MEGAChatMessageTypeContact) {
        text = @"MEGAChatMessageTypeContact";
    } else if (self.type == MEGAChatMessageTypeAttachment) {
        text = @"MEGAChatMessageTypeAttachment";
    } else if (self.type == MEGAChatMessageTypeRevokeAttachment) {
        text = @"MEGAChatMessageTypeRevokeAttachment";
    } else {
        text = self.content;
    }
    return text;
}

- (id<JSQMessageMediaData>)media {
    if (self.type == MEGAChatMessageTypeContact) {
        MEGAAttachmentMediaItem *attachmentMediaItem = [[MEGAAttachmentMediaItem alloc] initWithMEGAChatMessage:self];
        return attachmentMediaItem;
    } else if (self.type == MEGAChatMessageTypeAttachment) {
        MEGANode *node = [self.nodeList nodeAtIndex:0];
        if (self.nodeList.size.integerValue > 1 || (!node.name.mnz_isImagePathExtension && !node.name.mnz_isVideoPathExtension)) {
            MEGAAttachmentMediaItem *attachmentMediaItem = [[MEGAAttachmentMediaItem alloc] initWithMEGAChatMessage:self];
            return attachmentMediaItem;
        } else {
            MEGAPhotoMediaItem *photoItem = [[MEGAPhotoMediaItem alloc] initWithMEGANode:node];
            return photoItem;
        }
    }
    return nil;
}

- (NSUInteger)messageHash {
    return [self hash];
}

#pragma mark - NSObject

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    }
    
    if (![object isKindOfClass:[self class]]) {
        return NO;
    }
    
    MEGAChatMessage *aMessage = (MEGAChatMessage *)object;
    
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

- (id)debugQuickLookObject {
    return [self.media mediaView] ?: [self.media mediaPlaceholderView];
}

#pragma mark - Properties

- (MEGAChatRoom *)chatRoom {
    return objc_getAssociatedObject(self, chatRoomTagKey);
}

- (void)setChatRoom:(MEGAChatRoom *)chatRoom {
    objc_setAssociatedObject(self, &chatRoomTagKey, chatRoom, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSAttributedString *)attributedText {
    return objc_getAssociatedObject(self, attributedTextTagKey);
}

- (void)setAttributedText:(NSAttributedString *)attributedText {
    objc_setAssociatedObject(self, &attributedTextTagKey, attributedText, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
