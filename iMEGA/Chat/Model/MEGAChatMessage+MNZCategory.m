#import "MEGAChatMessage+MNZCategory.h"

#import <objc/runtime.h>

#import "Helper.h"

#import "MEGAStore.h"
#import "NSAttributedString+MNZCategory.h"
#import "NSString+MNZCategory.h"
#import "NSURL+MNZCategory.h"
#import "MEGA-Swift.h"

@import MEGAL10nObjc;

static const void *chatIdTagKey = &chatIdTagKey;
static const void *attributedTextTagKey = &attributedTextTagKey;
static const void *warningDialogTagKey = &warningDialogTagKey;
static const void *MEGALinkTagKey = &MEGALinkTagKey;
static const void *nodeTagKey = &nodeTagKey;
static const void *richStringTagKey = &richStringTagKey;
static const void *richNumberTagKey = &richNumberTagKey;
static const void *richTitleTagKey = &richTitleTagKey;
static const void *contactLinkUserHandleTagKey = &contactLinkUserHandleTagKey;

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
    
    if (!self.isDeleted && (self.type == MEGAChatMessageTypeContact || self.type == MEGAChatMessageTypeAttachment || self.type == MEGAChatMessageTypeVoiceClip || (self.warningDialog > MEGAChatMessageWarningDialogNone) || (self.type == MEGAChatMessageTypeContainsMeta && [self containsMetaAnyValue]) || self.richNumber || self.type == MEGAChatMessageTypeCallEnded || self.type == MEGAChatMessageTypeCallStarted)) {
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
    if (self.containsMeta.geolocation.image) {
        return YES;
    }
    if (self.containsMeta.giphy.webpSrc) {
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
        if (type == URLTypeFileLink || type == URLTypeFolderLink || type == URLTypePublicChatLink || type == URLTypeContactLink || type == URLTypeCollection) {
            self.MEGALink = match.URL;

            return YES;
        }
    }
    
    return NO;
}

- (BOOL)shouldShowForwardAccessory {
    BOOL shouldShowForwardAccessory = NO;
    
    if (!self.isDeleted && (self.type == MEGAChatMessageTypeContact || self.type == MEGAChatMessageTypeAttachment || (self.type == MEGAChatMessageTypeVoiceClip && !self.richNumber) || (self.type == MEGAChatMessageTypeContainsMeta && [self containsMetaAnyValue]) || self.node || (self.type == MEGAChatMessageTypeNormal && self.containsMEGALink))) {
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

- (NSString *)generateAttributedString:(BOOL)isMeeting {
    NSString *text;
    uint64_t myHandle = [MEGAChatSdk.shared myUserHandle];
    
    UIFont *textFontRegular = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    UIFont *textFontMedium = [[UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline] fontWithWeight:UIFontWeightMedium];
    UIFont *textFontMediumFootnote = [[UIFont preferredFontForTextStyle:UIFontTextStyleFootnote] fontWithWeight:UIFontWeightMedium];

    if (self.isDeleted) {
        text = LocalizedString(@"thisMessageHasBeenDeleted", @"A log message in a chat to indicate that the message has been deleted by the user.");
    } else if (self.isManagementMessage) {
        NSString *fullNameDidAction = [self fullNameDidAction];
        NSString *fullNameReceiveAction = [self fullNameReceiveAction];
        
        switch (self.type) {
            case MEGAChatMessageTypeAlterParticipants: {
                [self alterParticipantsMessageWithFullNameDidAction:fullNameDidAction
                                               fullNameReceiveAction:fullNameReceiveAction
                                                           isMeeting:isMeeting];
                text = self.attributedText.string;
                break;
            }
                
            case MEGAChatMessageTypeTruncate: {
                NSString *clearedTheChatHistory = LocalizedString(@"clearedTheChatHistory", @"A log message in the chat conversation to tell the reader that a participant [A] cleared the history of the chat. For example, Alice cleared the chat history.");
                clearedTheChatHistory = [clearedTheChatHistory stringByReplacingOccurrencesOfString:@"[A]" withString:fullNameDidAction];
                text = clearedTheChatHistory;
                
                NSMutableAttributedString *mutableAttributedString = [NSMutableAttributedString.alloc initWithString:clearedTheChatHistory attributes:@{NSFontAttributeName:textFontRegular, NSForegroundColorAttributeName:UIColor.labelColor}];
                [mutableAttributedString addAttributes:@{ NSFontAttributeName: textFontMedium, NSFontAttributeName: [self chatPeerOptionsUrlStringForUserHandle:[self userHandleReceiveAction]] } range:[clearedTheChatHistory rangeOfString:fullNameDidAction]];
                self.attributedText = mutableAttributedString;
                break;
            }
                
            case MEGAChatMessageTypePrivilegeChange: {
                NSString *wasChangedToBy;
                switch (self.privilege) {
                    case 0:
                        wasChangedToBy = LocalizedString(@"chat.message.changedRole.readOnly", @"A log message in a chat to display that a participant's permission was changed to read-only and by whom");
                        break;
                        
                    case 2:
                        wasChangedToBy = LocalizedString(@"chat.message.changedRole.standard", @"A log message in a chat to display that a participant's permission was changed to standard role and by whom");
                        break;
                        
                    case 3:
                        wasChangedToBy = LocalizedString(@"chat.message.changedRole.host", @"A log message in a chat to display that a participant's permission was changed to host role and by whom");
                        break;
                        
                    default:
                        wasChangedToBy = @"";
                        break;
                }
                NSString *privilegeString = [wasChangedToBy mnz_stringBetweenString:@"[S]" andString:@"[/S]"];
                wasChangedToBy = [wasChangedToBy stringByReplacingOccurrencesOfString:@"[A]" withString:fullNameReceiveAction];
                wasChangedToBy = [wasChangedToBy stringByReplacingOccurrencesOfString:@"[B]" withString:fullNameDidAction];
                wasChangedToBy = wasChangedToBy.mnz_removeWebclientFormatters;
                text = wasChangedToBy;
                
                NSMutableAttributedString *mutableAttributedString = [NSMutableAttributedString.alloc initWithString:wasChangedToBy attributes:@{NSFontAttributeName:textFontRegular, NSForegroundColorAttributeName:UIColor.labelColor}];
                [mutableAttributedString addAttributes:@{ NSFontAttributeName: textFontMedium, NSFontAttributeName: [self chatPeerOptionsUrlStringForUserHandle:[self userHandleReceiveAction]] } range:[wasChangedToBy rangeOfString:fullNameReceiveAction]];
                [mutableAttributedString addAttribute:NSFontAttributeName value:textFontMedium range:[wasChangedToBy rangeOfString:privilegeString]];
                [mutableAttributedString addAttributes:@{ NSFontAttributeName: textFontMedium, NSFontAttributeName: [self chatPeerOptionsUrlStringForUserHandle:self.userHandle] } range:[wasChangedToBy rangeOfString:fullNameDidAction]];
                self.attributedText = mutableAttributedString;
                break;
            }
                
            case MEGAChatMessageTypeSetRetentionTime: {
                if (self.retentionTime <= 0) {
                    text = LocalizedString(@"[A]%1$s[/A][B] disabled message clearing.[/B]", @"System message that is shown to all chat participants upon disabling the Retention history.");
                    
                    text = [text stringByReplacingOccurrencesOfString:@"%1$s" withString:fullNameDidAction];
                    text = text.mnz_removeWebclientFormatters;
                    
                    NSMutableAttributedString *mutableAttributedString = [NSMutableAttributedString.alloc initWithString:text attributes:@{NSFontAttributeName:textFontRegular, NSForegroundColorAttributeName:UIColor.labelColor}];
                    [mutableAttributedString addAttributes:@{ NSFontAttributeName: textFontMedium} range:[text rangeOfString:fullNameDidAction]];
                    
                    self.attributedText = mutableAttributedString;
                } else {
                    text = LocalizedString(@"[A]%1$s[/A][B] changed the message clearing time to[/B][A] %2$s[/A][B].[/B]", @"System message displayed to all chat participants when one of them enables retention history");
                    
                    text = [text stringByReplacingOccurrencesOfString:@"%1$s" withString:fullNameDidAction];
                    
                    NSString *retentionTimeString = [NSString mnz_hoursDaysWeeksMonthsOrYearFrom:self.retentionTime];
                    text = [text stringByReplacingOccurrencesOfString:@"%2$s" withString:retentionTimeString];
                    
                    text = text.mnz_removeWebclientFormatters;
                    
                    NSMutableAttributedString *mutableAttributedString = [NSMutableAttributedString.alloc initWithString:text attributes:@{NSFontAttributeName:textFontRegular, NSForegroundColorAttributeName:UIColor.labelColor}];
                    [mutableAttributedString addAttributes:@{NSFontAttributeName: textFontMedium} range:[text rangeOfString:fullNameDidAction]];
                    [mutableAttributedString addAttributes:@{NSFontAttributeName: textFontMedium} range:[text rangeOfString:retentionTimeString]];
                    self.attributedText = mutableAttributedString;
                }
                break;
            }
                
            case MEGAChatMessageTypeChatTitle: {
                NSString *changedGroupChatNameTo = LocalizedString(@"changedGroupChatNameTo", @"A hint message in a group chat to indicate the group chat name is changed to a new one. Please keep %s when translating this string which will be replaced with the name at runtime.");
                changedGroupChatNameTo = [changedGroupChatNameTo stringByReplacingOccurrencesOfString:@"[A]" withString:fullNameDidAction];
                changedGroupChatNameTo = [changedGroupChatNameTo stringByReplacingOccurrencesOfString:@"[B]" withString:(self.content ? self.content : @" ")];
                text = changedGroupChatNameTo;
                
                NSMutableAttributedString *mutableAttributedString = [NSMutableAttributedString.alloc initWithString:changedGroupChatNameTo attributes:@{NSFontAttributeName:textFontRegular, NSForegroundColorAttributeName:UIColor.labelColor}];
                [mutableAttributedString addAttributes:@{ NSFontAttributeName: textFontMedium, NSFontAttributeName: [self chatPeerOptionsUrlStringForUserHandle:[self userHandleReceiveAction]] } range:[changedGroupChatNameTo rangeOfString:fullNameDidAction]];
                if (self.content) [mutableAttributedString addAttribute:NSFontAttributeName value:textFontMedium range:[changedGroupChatNameTo rangeOfString:self.content]];
                self.attributedText = mutableAttributedString;
                break;
            }
                
            case MEGAChatMessageTypePublicHandleCreate: {
                NSString *publicHandleCreated = [NSString stringWithFormat:LocalizedString(@"%@ created a public link for the chat.", @"Management message shown in a chat when the user %@ creates a public link for the chat"), fullNameReceiveAction];
                text = publicHandleCreated;
                
                NSMutableAttributedString *mutableAttributedString = [NSMutableAttributedString.alloc initWithString:publicHandleCreated attributes:@{NSFontAttributeName:textFontRegular, NSForegroundColorAttributeName:UIColor.labelColor}];
                [mutableAttributedString addAttributes:@{ NSFontAttributeName: textFontMedium, NSFontAttributeName: [self chatPeerOptionsUrlStringForUserHandle:[self userHandleReceiveAction]] } range:[publicHandleCreated rangeOfString:fullNameReceiveAction]];
                
                self.attributedText = mutableAttributedString;
                break;
            }
                
            case MEGAChatMessageTypePublicHandleDelete: {
                NSString *publicHandleRemoved = [NSString stringWithFormat:LocalizedString(@"%@ removed a public link for the chat.", @"Management message shown in a chat when the user %@ removes a public link for the chat"), fullNameReceiveAction];
                text = publicHandleRemoved;
                
                NSMutableAttributedString *mutableAttributedString = [NSMutableAttributedString.alloc initWithString:publicHandleRemoved attributes:@{NSFontAttributeName:textFontRegular, NSForegroundColorAttributeName:UIColor.labelColor}];
                [mutableAttributedString addAttributes:@{ NSFontAttributeName: textFontMedium, NSFontAttributeName: [self chatPeerOptionsUrlStringForUserHandle:[self userHandleReceiveAction]] } range:[publicHandleRemoved rangeOfString:fullNameReceiveAction]];
                
                self.attributedText = mutableAttributedString;
                break;
            }
                
            case MEGAChatMessageTypeSetPrivateMode: {
                NSString *setPrivateMode = [NSString stringWithFormat:LocalizedString(@"%@ enabled Encrypted Key Rotation", @"Management message shown in a chat when the user %@ enables the 'Encrypted Key Rotation'"), fullNameReceiveAction];
                NSString *keyRotationExplanation = LocalizedString(@"Key rotation is slightly more secure, but does not allow you to create a chat link and new participants will not see past messages.", @"Footer text to explain what means 'Encrypted Key Rotation'");
                text = [NSString stringWithFormat:@"%@\n\n%@", setPrivateMode, keyRotationExplanation];
                
                NSMutableAttributedString *mutableAttributedString = [NSMutableAttributedString.alloc initWithString:text attributes:@{NSFontAttributeName:textFontRegular, NSForegroundColorAttributeName:UIColor.labelColor}];
                [mutableAttributedString addAttributes:@{ NSFontAttributeName: textFontMedium, NSFontAttributeName: [self chatPeerOptionsUrlStringForUserHandle:[self userHandleReceiveAction]] } range:[text rangeOfString:fullNameReceiveAction]];
                [mutableAttributedString addAttribute:NSFontAttributeName value:textFontMedium range:[text rangeOfString:LocalizedString(@"Encrypted Key Rotation", @"")]];
                [mutableAttributedString addAttribute:NSFontAttributeName value:textFontMediumFootnote range:[text rangeOfString:keyRotationExplanation]];
                [mutableAttributedString addAttribute:NSForegroundColorAttributeName value:[UIColor iconSecondaryColor] range:[text rangeOfString:keyRotationExplanation]];
                
                self.attributedText = mutableAttributedString;
                break;
            }
                
            case MEGAChatMessageTypeScheduledMeeting: {
                [self attributedTextStringForScheduledMeetingChangeWithUserNameDidAction:fullNameDidAction];
                text = self.attributedText.string;
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
    } else if (self.type == MEGAChatMessageTypeVoiceClip) {
        text = @"MEGAChatMessageTypeVoiceClip";
    } else {
        BOOL IsFromCurrentSender = self.userHandle == myHandle;
        UIColor *textColor = [self normalTextColorWithIsFromCurrentSender: IsFromCurrentSender];
        UIFont *textFont = textFontRegular;
        if (self.content.mnz_isPureEmojiString) {
            textFont = [UIFont mnz_defaultFontForPureEmojiStringWithEmojis:[self.content mnz_emojiCount]];
            textColor = UIColor.labelColor;
        }
        self.attributedText = [NSAttributedString mnz_attributedStringFromMessage:self.content
                                                                             font:textFont
                                                                            color:textColor];
        
        if (self.isEdited && self.type != MEGAChatMessageTypeContainsMeta) {
            NSAttributedString *edited = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@" %@", LocalizedString(@"edited", @"A log message in a chat to indicate that the message has been edited by the user.")] attributes:@{NSFontAttributeName:[UIFont preferredFontForTextStyle:UIFontTextStyleCaption1].italic, NSForegroundColorAttributeName:textColor}];
            NSMutableAttributedString *attributedText = [self.attributedText mutableCopy];
            [attributedText appendAttributedString:edited];
            self.attributedText = attributedText;
        }
        
        text = self.attributedText.string;
    }
    return text;
}

- (NSUInteger)messageHash {
    return self.hash;
}

- (NSString *)fullNameDidAction {
    NSString *fullNameDidAction;
    
    if (MEGAChatSdk.shared.myUserHandle == self.userHandle) {
        fullNameDidAction = MEGAChatSdk.shared.myFullname;
    } else {
        fullNameDidAction = [self fullNameByHandle:self.userHandle];
    }
    
    return fullNameDidAction;
}

- (NSString *)fullNameReceiveAction {
    NSString *fullNameReceiveAction;
    uint64_t tempHandle = [self userHandleReceiveAction];
    
    if (MEGAChatSdk.shared.myUserHandle == tempHandle) {
        fullNameReceiveAction = MEGAChatSdk.shared.myFullname;
    } else {
        fullNameReceiveAction = [self fullNameByHandle:tempHandle];
    }
    
    return fullNameReceiveAction;
}

- (NSString *)fullNameByHandle:(uint64_t)handle {
    NSString *fullName = @"";
    
    MOUser *moUser = [[MEGAStore shareInstance] fetchUserWithUserHandle:handle];
    if (moUser) {
        fullName = moUser.displayName;
    }
    
    return fullName;
}

- (uint64_t)userHandleReceiveAction {
    return self.type == MEGAChatMessageTypeAlterParticipants || self.type == MEGAChatMessageTypePrivilegeChange ? self.userHandleOfAction : self.userHandle;
}

- (NSString *)chatPeerOptionsUrlStringForUserHandle:(uint64_t)userHandle {
    return [NSString stringWithFormat:@"mega://chatPeerOptions#%@", [MEGASdk base64HandleForUserHandle:userHandle]];
}

#pragma mark - NSObject

- (NSUInteger)hash {
    NSUInteger contentHash = self.type == MEGAChatMessageTypeAttachment || self.type == MEGAChatMessageTypeVoiceClip ? (NSUInteger)[self.nodeList nodeAtIndex:0].handle : self.content.hash ^ self.richNumber.hash;
    NSUInteger metaHash = self.type == MEGAChatMessageTypeContainsMeta ? self.containsMeta.type : MEGAChatContainsMetaTypeInvalid;
    NSUInteger messageHash = self.chatId ^ self.messageId ^ contentHash ^ self.warningDialog ^ metaHash ^ self.localPreview;
    return messageHash ^ UITraitCollection.currentTraitCollection.userInterfaceStyle;
}

#pragma mark - Properties

- (uint64_t)chatId {
    return ((NSNumber *)objc_getAssociatedObject(self, chatIdTagKey)).unsignedLongLongValue;
}

- (void)setChatId:(uint64_t)chatId {
    objc_setAssociatedObject(self, &chatIdTagKey, @(chatId), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
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
    objc_setAssociatedObject(self, &warningDialogTagKey, @(warningDialog), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
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

- (NSString *)richString {
    return objc_getAssociatedObject(self, richStringTagKey);
}

- (void)setRichString:(NSString *)richString {
    objc_setAssociatedObject(self, &richStringTagKey, richString, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSNumber *)richNumber {
    return objc_getAssociatedObject(self, richNumberTagKey);
}

- (void)setRichNumber:(NSNumber *)richNumber {
    objc_setAssociatedObject(self, &richNumberTagKey, richNumber, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSString *)richTitle {
    return objc_getAssociatedObject(self, richTitleTagKey);
}

- (void)setRichTitle:(NSString *)richTitle {
    objc_setAssociatedObject(self, &richTitleTagKey, richTitle, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (uint64_t)contactLinkUserHandle {
    return ((NSNumber *)objc_getAssociatedObject(self, contactLinkUserHandleTagKey)).unsignedLongLongValue;
}

- (void)setContactLinkUserHandle:(uint64_t)contactLinkUserHandle {
    objc_setAssociatedObject(self, &contactLinkUserHandleTagKey, @(contactLinkUserHandle), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
