
#import "MEGAChatMessage+MNZCategory.h"

#import <objc/runtime.h>

#import "Helper.h"
#import "MEGAAttachmentMediaItem.h"
#import "MEGACallEndedMediaItem.h"
#import "MEGADialogMediaItem.h"
#import "MEGAFetchNodesRequestDelegate.h"
#import "MEGAGetPublicNodeRequestDelegate.h"
#import "MEGALoginToFolderLinkRequestDelegate.h"
#import "MEGAPhotoMediaItem.h"
#import "MEGARichPreviewMediaItem.h"
#import "MEGASdkManager.h"
#import "MEGAStore.h"
#import "NSAttributedString+MNZCategory.h"
#import "NSString+MNZCategory.h"
#import "NSURL+MNZCategory.h"

static const void *chatRoomTagKey = &chatRoomTagKey;
static const void *attributedTextTagKey = &attributedTextTagKey;
static const void *warningDialogTagKey = &warningDialogTagKey;
static const void *MEGALinkTagKey = &MEGALinkTagKey;
static const void *nodeTagKey = &nodeTagKey;
static const void *nodeDetailsTagKey = &nodeDetailsTagKey;
static const void *nodeSizeTagKey = &nodeSizeTagKey;

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
    
    if (!self.isDeleted && (self.type == MEGAChatMessageTypeContact || self.type == MEGAChatMessageTypeAttachment || (self.warningDialog > MEGAChatMessageWarningDialogNone) || (self.type == MEGAChatMessageTypeContainsMeta && [self containsMetaAnyValue]) || self.node || self.type == MEGAChatMessageTypeCallEnded)) {
        mediaMessage = YES;
    }
    
    return mediaMessage;
}

- (BOOL)containsMetaAnyValue {
    if (self.containsMeta.richPreview.title && ![self.containsMeta.richPreview.title isEqualToString:@""]) {
        return YES;
    }
    if (self.containsMeta.richPreview.previewDescription && ![self.containsMeta.richPreview.previewDescription isEqualToString:@""]) {
        return YES;
    }
    if (self.containsMeta.richPreview.image && ![self.containsMeta.richPreview.image isEqualToString:@""]) {
        return YES;
    }
    if (self.containsMeta.richPreview.icon && ![self.containsMeta.richPreview.icon isEqualToString:@""]) {
        return YES;
    }
    if (self.containsMeta.richPreview.url && ![self.containsMeta.richPreview.url isEqualToString:@""]) {
        return YES;
    }
    return NO;
}

- (BOOL)containsMEGALink {
    if (self.MEGALink) {
        return YES;
    }
    if (!self.content) {
        return NO;
    }
    
    NSDataDetector* linkDetector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeLink error:nil];
    for (NSTextCheckingResult *match in [linkDetector matchesInString:self.content options:0 range:NSMakeRange(0, self.content.length)]) {
        URLType type = [match.URL mnz_type];
        if (type == URLTypeFileLink || type == URLTypeFolderLink) {
            self.MEGALink = match.URL;
            if (type == URLTypeFileLink) {
                MEGAGetPublicNodeRequestDelegate *delegate = [[MEGAGetPublicNodeRequestDelegate alloc] initWithCompletion:^(MEGARequest *request, MEGAError *error) {
                    self.nodeSize = request.publicNode.size;
                    self.node = request.publicNode;
                }];
                [[MEGASdkManager sharedMEGASdk] publicNodeForMegaFileLink:[self.MEGALink mnz_MEGAURL] delegate:delegate];
            } else if (type == URLTypeFolderLink) {
                MEGALoginToFolderLinkRequestDelegate *loginDelegate = [[MEGALoginToFolderLinkRequestDelegate alloc] initWithCompletion:^(MEGARequest *request) {
                    MEGAFetchNodesRequestDelegate *fetchNodesDelegate = [[MEGAFetchNodesRequestDelegate alloc] initWithCompletion:^(MEGARequest *request) {
                        if (!request.flag) {
                            MEGANode *node = [MEGASdkManager sharedMEGASdkFolder].rootNode;
                            self.nodeDetails = [Helper filesAndFoldersInFolderNode:node api:[MEGASdkManager sharedMEGASdkFolder]];
                            self.nodeSize = [[MEGASdkManager sharedMEGASdkFolder] sizeForNode:node];
                            self.node = node;
                            [[MEGASdkManager sharedMEGASdkFolder] logout];
                        }
                    }];
                    [[MEGASdkManager sharedMEGASdkFolder] fetchNodesWithDelegate:fetchNodesDelegate];
                }];
                [[MEGASdkManager sharedMEGASdkFolder] loginToFolderLink:[self.MEGALink mnz_MEGAURL] delegate:loginDelegate];
            }

            return YES;
        }
    }
    
    return NO;
}

- (BOOL)shouldShowForwardAccessory {
    BOOL shouldShowForwardAccessory = NO;
    
    if (!self.isDeleted && (self.type == MEGAChatMessageTypeContact || self.type == MEGAChatMessageTypeAttachment || (self.type == MEGAChatMessageTypeContainsMeta && [self containsMetaAnyValue]) || self.node)) {
        shouldShowForwardAccessory = YES;
    }
    
    return shouldShowForwardAccessory;
}

- (BOOL)localPreview {
    if (self.type == MEGAChatMessageTypeAttachment) {
        MEGANode *node = [self.nodeList nodeAtIndex:0];
        NSString *previewFilePath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject stringByAppendingPathComponent:@"previewsV3"] stringByAppendingPathComponent:node.base64Handle];
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:previewFilePath]) {
            return YES;
        }
    }
    return NO;
}

- (NSString *)text {
    NSString *text;
    uint64_t myHandle = [[MEGASdkManager sharedMEGAChatSdk] myUserHandle];
    
    UIFont *textFontRegular = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    UIFont *textFontMedium = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline weight:UIFontWeightMedium];

    if (self.isDeleted) {
        text = AMLocalizedString(@"thisMessageHasBeenDeleted", @"A log message in a chat to indicate that the message has been deleted by the user.");
    } else if (self.isManagementMessage) {
        
        NSString *fullNameDidAction = @"";
        
        if (myHandle == self.userHandle) {
            fullNameDidAction = [[MEGASdkManager sharedMEGAChatSdk] myFullname];
        } else {
            fullNameDidAction = [self.chatRoom peerFullnameByHandle:self.userHandle];
            if (fullNameDidAction.length == 0) {
                MOUser *moUser = [[MEGAStore shareInstance] fetchUserWithUserHandle:self.userHandle];
                if (moUser) {
                    fullNameDidAction = moUser.fullName;
                } else {
                    fullNameDidAction = @"";
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
                    fullNameReceiveAction = moUser.fullName;
                } else {
                    fullNameReceiveAction = @"";
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
                            
                            NSMutableAttributedString *mutableAttributedString = [[NSMutableAttributedString alloc] initWithString:wasRemovedFromTheGroupChatBy attributes:@{NSFontAttributeName:textFontRegular, NSForegroundColorAttributeName:[UIColor mnz_black333333]}];
                            [mutableAttributedString addAttribute:NSFontAttributeName value:textFontMedium range:[wasRemovedFromTheGroupChatBy rangeOfString:fullNameReceiveAction]];
                            [mutableAttributedString addAttribute:NSFontAttributeName value:textFontMedium range:[wasRemovedFromTheGroupChatBy rangeOfString:fullNameDidAction]];
                            self.attributedText = mutableAttributedString;
                        } else {
                            NSString *leftTheGroupChat = AMLocalizedString(@"leftTheGroupChat", @"A log message in the chat conversation to tell the reader that a participant [A] left the group chat. For example: Alice left the group chat.");
                            leftTheGroupChat = [leftTheGroupChat stringByReplacingOccurrencesOfString:@"[A]" withString:fullNameReceiveAction];
                            text = leftTheGroupChat;
                            
                            NSMutableAttributedString *mutableAttributedString = [[NSMutableAttributedString alloc] initWithString:leftTheGroupChat attributes:@{NSFontAttributeName:textFontRegular, NSForegroundColorAttributeName:[UIColor mnz_black333333]}];
                            [mutableAttributedString addAttribute:NSFontAttributeName value:textFontMedium range:[leftTheGroupChat rangeOfString:fullNameReceiveAction]];
                            self.attributedText = mutableAttributedString;
                        }
                        break;
                    }
                        
                    case -2: {
                        NSString *joinedTheGroupChatByInvitationFrom = AMLocalizedString(@"joinedTheGroupChatByInvitationFrom", @"A log message in a chat conversation to tell the reader that a participant [A] was added to the chat by a moderator [B]. Please keep the [A] and [B] placeholders, they will be replaced by the participant and the moderator names at runtime. For example: Alice joined the group chat by invitation from Frank.");
                        joinedTheGroupChatByInvitationFrom = [joinedTheGroupChatByInvitationFrom stringByReplacingOccurrencesOfString:@"[A]" withString:fullNameReceiveAction];
                        joinedTheGroupChatByInvitationFrom = [joinedTheGroupChatByInvitationFrom stringByReplacingOccurrencesOfString:@"[B]" withString:fullNameDidAction];
                        text = joinedTheGroupChatByInvitationFrom;
                        
                        NSMutableAttributedString *mutableAttributedString = [[NSMutableAttributedString alloc] initWithString:joinedTheGroupChatByInvitationFrom attributes:@{NSFontAttributeName:textFontRegular, NSForegroundColorAttributeName:[UIColor mnz_black333333]}];
                        [mutableAttributedString addAttribute:NSFontAttributeName value:textFontMedium range:[joinedTheGroupChatByInvitationFrom rangeOfString:fullNameReceiveAction]];
                        [mutableAttributedString addAttribute:NSFontAttributeName value:textFontMedium range:[joinedTheGroupChatByInvitationFrom rangeOfString:fullNameDidAction]];
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
                
                NSMutableAttributedString *mutableAttributedString = [[NSMutableAttributedString alloc] initWithString:clearedTheChatHistory attributes:@{NSFontAttributeName:textFontRegular, NSForegroundColorAttributeName:[UIColor mnz_black333333]}];
                [mutableAttributedString addAttribute:NSFontAttributeName value:textFontMedium range:[clearedTheChatHistory rangeOfString:fullNameDidAction]];
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
                
                NSMutableAttributedString *mutableAttributedString = [[NSMutableAttributedString alloc] initWithString:wasChangedToBy attributes:@{NSFontAttributeName:textFontRegular, NSForegroundColorAttributeName:[UIColor mnz_black333333]}];
                [mutableAttributedString addAttribute:NSFontAttributeName value:textFontMedium range:[wasChangedToBy rangeOfString:fullNameReceiveAction]];
                [mutableAttributedString addAttribute:NSFontAttributeName value:textFontMedium range:[wasChangedToBy rangeOfString:privilige]];
                [mutableAttributedString addAttribute:NSFontAttributeName value:textFontMedium range:[wasChangedToBy rangeOfString:fullNameDidAction]];
                self.attributedText = mutableAttributedString;
                break;
            }
                
            case MEGAChatMessageTypeChatTitle: {
                NSString *changedGroupChatNameTo = AMLocalizedString(@"changedGroupChatNameTo", @"A hint message in a group chat to indicate the group chat name is changed to a new one. Please keep %s when translating this string which will be replaced with the name at runtime.");
                changedGroupChatNameTo = [changedGroupChatNameTo stringByReplacingOccurrencesOfString:@"[A]" withString:fullNameDidAction];
                changedGroupChatNameTo = [changedGroupChatNameTo stringByReplacingOccurrencesOfString:@"[B]" withString:(self.content ? self.content : @" ")];
                text = changedGroupChatNameTo;
                
                NSMutableAttributedString *mutableAttributedString = [[NSMutableAttributedString alloc] initWithString:changedGroupChatNameTo attributes:@{NSFontAttributeName:textFontRegular, NSForegroundColorAttributeName:[UIColor mnz_black333333]}];
                [mutableAttributedString addAttribute:NSFontAttributeName value:textFontMedium range:[changedGroupChatNameTo rangeOfString:fullNameDidAction]];
                if (self.content) [mutableAttributedString addAttribute:NSFontAttributeName value:textFontMedium range:[changedGroupChatNameTo rangeOfString:self.content]];
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
    } else if (self.type == MEGAChatMessageTypeContainsMeta && self.containsMeta.type == MEGAChatContainsMetaTypeInvalid) {
        text = @"Message contains invalid meta";
    } else {
        UIColor *textColor = self.userHandle == myHandle ? [UIColor whiteColor] : [UIColor mnz_black333333];
        
        self.attributedText = [NSAttributedString mnz_attributedStringFromMessage:self.content
                                                                             font:textFontRegular
                                                                            color:textColor];
        
        if (self.isEdited && self.type != MEGAChatMessageTypeContainsMeta) {
            NSAttributedString *edited = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@" %@", AMLocalizedString(@"edited", @"A log message in a chat to indicate that the message has been edited by the user.")] attributes:@{NSFontAttributeName:[UIFont preferredFontForTextStyle:UIFontTextStyleCaption1].italic, NSForegroundColorAttributeName:textColor}];
            NSMutableAttributedString *attributedText = [self.attributedText mutableCopy];
            [attributedText appendAttributedString:edited];
            self.attributedText = attributedText;
        }
        
        text = self.attributedText.string;
    }
    return text;
}

- (id<JSQMessageMediaData>)media {
    id<JSQMessageMediaData> media = nil;
    
    switch (self.type) {
        case MEGAChatMessageTypeContact:
            media = [[MEGAAttachmentMediaItem alloc] initWithMEGAChatMessage:self];
            break;
            
        case MEGAChatMessageTypeAttachment: {
            MEGANode *node = [self.nodeList nodeAtIndex:0];
            if (self.nodeList.size.integerValue > 1 || (!node.name.mnz_isImagePathExtension && !node.name.mnz_isVideoPathExtension)) {
                media = [[MEGAAttachmentMediaItem alloc] initWithMEGAChatMessage:self];
            } else {
                media = [[MEGAPhotoMediaItem alloc] initWithMEGANode:node];
            }
            
            break;
        }
            
        case MEGAChatMessageTypeContainsMeta: {
            media = [[MEGARichPreviewMediaItem alloc] initWithMEGAChatMessage:self];
            
            break;
        }
            
        case MEGAChatMessageTypeNormal: {
            if (self.warningDialog > MEGAChatMessageWarningDialogNone) {
                media = [[MEGADialogMediaItem alloc] initWithMEGAChatMessage:self];
            } else if (self.node) {
                media = [[MEGARichPreviewMediaItem alloc] initWithMEGAChatMessage:self];
            }
            
            break;
        }
            
        case MEGAChatMessageTypeCallEnded:
            media = [[MEGACallEndedMediaItem alloc] initWithMEGAChatMessage:self];
            break;
            
        default:
            break;
    }
    
    return media;
}

- (NSUInteger)messageHash {
    return self.hash;
}

#pragma mark - NSObject

- (NSUInteger)hash {
    NSUInteger contentHash = self.type == MEGAChatMessageTypeAttachment ? (NSUInteger)[self.nodeList nodeAtIndex:0].handle : self.content.hash ^ self.node.hash;
    NSUInteger metaHash = self.type == MEGAChatMessageTypeContainsMeta ? self.containsMeta.type : MEGAChatContainsMetaTypeInvalid;
    return self.senderId.hash ^ self.date.hash ^ contentHash ^ self.warningDialog ^ metaHash ^ self.localPreview;
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

- (MEGAChatMessageWarningDialog)warningDialog {
    return ((NSNumber *)objc_getAssociatedObject(self, warningDialogTagKey)).integerValue;
}

- (void)setWarningDialog:(MEGAChatMessageWarningDialog)warningDialog {
    objc_setAssociatedObject(self, &warningDialogTagKey, [NSNumber numberWithInteger:warningDialog], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSURL *)MEGALink {
    return objc_getAssociatedObject(self, MEGALinkTagKey);
}

- (void)setMEGALink:(NSURL *)MEGALink {
    objc_setAssociatedObject(self, &MEGALinkTagKey, MEGALink, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (MEGANode *)node {
    return objc_getAssociatedObject(self, nodeTagKey);
}

- (void)setNode:(MEGANode *)node {
    objc_setAssociatedObject(self, &nodeTagKey, node, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSString *)nodeDetails {
    return objc_getAssociatedObject(self, nodeDetailsTagKey);
}

- (void)setNodeDetails:(NSString *)nodeDetails {
    objc_setAssociatedObject(self, &nodeDetailsTagKey, nodeDetails, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSNumber *)nodeSize {
    return objc_getAssociatedObject(self, nodeSizeTagKey);
}

- (void)setNodeSize:(NSNumber *)nodeSize {
    objc_setAssociatedObject(self, &nodeSizeTagKey, nodeSize, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
