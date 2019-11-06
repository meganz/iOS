
#import "MEGAAttachmentMediaItem.h"
#import "MEGAMessageAttachmentView.h"

#import "JSQMessagesBubbleImageFactory.h"
#import "JSQMessagesMediaViewBubbleImageMasker.h"
#import "UIImage+GKContact.h"
#import "UIColor+JSQMessages.h"

#import "UIDevice+MNZCategory.h"
#import "Helper.h"
#import "MEGASdkManager.h"
#import "UIImageView+MNZCategory.h"

@interface MEGAAttachmentMediaItem ()

@property (strong, nonatomic) UIView *cachedContactView;
@property (copy, nonatomic) MEGAChatMessage *message;

@end

@implementation MEGAAttachmentMediaItem

#pragma mark - Initialization

- (instancetype)initWithMEGAChatMessage:(MEGAChatMessage *)message {
    self = [super init];
    if (self) {
        _message = message;
        _cachedContactView = nil;
    }
    return self;
}

- (void)clearCachedMediaViews {
    [super clearCachedMediaViews];
    _cachedContactView = nil;
}

#pragma mark - Setters

- (void)setMessage:(MEGAChatMessage *)message {
    _message = [message copy];
    _cachedContactView = nil;
}

- (void)setAppliesMediaViewMaskAsOutgoing:(BOOL)appliesMediaViewMaskAsOutgoing {
    [super setAppliesMediaViewMaskAsOutgoing:appliesMediaViewMaskAsOutgoing];
    _cachedContactView = nil;
}

#pragma mark - JSQMessageMediaData protocol

- (UIView *)mediaView {
    if (self.message == nil) {
        return nil;
    }
    
    if (self.cachedContactView == nil) {
        MEGAMessageAttachmentView *contactView = [[NSBundle bundleForClass:MEGAMessageAttachmentView.class] loadNibNamed:@"MEGAMessageAttachmentView" owner:self options:nil].firstObject;
        // Sizes:
        CGSize contactViewSize = [self mediaViewDisplaySize];
        contactView.frame = CGRectMake(contactView.frame.origin.x,
                                       contactView.frame.origin.y,
                                       contactViewSize.width,
                                       contactViewSize.height);
        
        // Colors:
        if (self.message.userHandle == [[MEGASdkManager sharedMEGAChatSdk] myUserHandle]) {
            contactView.backgroundColor = [UIColor mnz_chatBlueForTraitCollection:UIScreen.mainScreen.traitCollection];
            contactView.titleLabel.textColor = [UIColor whiteColor];
            contactView.detailLabel.textColor = [UIColor whiteColor];
        } else {
            contactView.backgroundColor = [UIColor mnz_chatGrayForTraitCollection:UIScreen.mainScreen.traitCollection];
            contactView.titleLabel.textColor = UIColor.mnz_label;
            contactView.detailLabel.textColor = [UIColor mnz_primaryGrayForTraitCollection:UIScreen.mainScreen.traitCollection];
        }
        
        if (self.message.type == MEGAChatMessageTypeAttachment) {
            NSUInteger totalNodes = [self.message.nodeList.size unsignedIntegerValue];
            NSString *filename;
            NSString *size;
            if (totalNodes == 1) {
                MEGANode *node = [self.message.nodeList nodeAtIndex:0];
                filename = node.name;
                size = [Helper memoryStyleStringFromByteCount:node.size.longLongValue];
                [contactView.avatarImage mnz_setThumbnailByNode:node];
            } else {
                filename = [NSString stringWithFormat:AMLocalizedString(@"files", nil), totalNodes];
                NSUInteger totalSize = 0;
                for (NSUInteger i = 0; i < totalNodes; i++) {
                    totalSize += [[[self.message.nodeList nodeAtIndex:i] size] unsignedIntegerValue];
                }
                size = [Helper memoryStyleStringFromByteCount:totalSize];
                UIImage *avatar = [UIImage imageForName:[NSString stringWithFormat:@"%tu", totalNodes] size:contactView.avatarImage.frame.size backgroundColor:[UIColor mnz_secondaryGrayForTraitCollection:UIScreen.mainScreen.traitCollection] textColor:UIColor.whiteColor font:[UIFont systemFontOfSize:(contactView.avatarImage.frame.size.width/2.0f)]];
                contactView.avatarImage.image = avatar;
            }
            contactView.titleLabel.text = filename;
            contactView.detailLabel.text = size;
        } else { // MEGAChatMessageTypeContact
            if (self.message.usersCount == 1) {
                [contactView.avatarImage mnz_setImageForUserHandle:[self.message userHandleAtIndex:0] name:[self.message userNameAtIndex:0]];
                contactView.titleLabel.text = [self.message userNameAtIndex:0];
                contactView.detailLabel.text = [self.message userEmailAtIndex:0];
            } else {
                NSNumber *users = [NSNumber numberWithUnsignedInteger:self.message.usersCount];
                NSString *usersString = AMLocalizedString(@"XContactsSelected", nil);
                usersString = [usersString stringByReplacingOccurrencesOfString:@"[X]" withString:users.stringValue];
                UIImage *avatar = [UIImage imageForName:[NSString stringWithFormat:@"%lu", (unsigned long)self.message.usersCount] size:contactView.avatarImage.frame.size backgroundColor:[UIColor mnz_secondaryGrayForTraitCollection:UIScreen.mainScreen.traitCollection] textColor:UIColor.whiteColor font:[UIFont systemFontOfSize:(contactView.avatarImage.frame.size.width/2.0f)]];                
                contactView.avatarImage.image = avatar;
                contactView.titleLabel.text = usersString;
                NSString *emails = [self.message userEmailAtIndex:0];
                for (NSUInteger i = 1; i < self.message.usersCount; i++) {
                    emails = [NSString stringWithFormat:@"%@ %@", emails, [self.message userEmailAtIndex:i]];
                }
                contactView.detailLabel.text = emails;
            }
        }
        
        JSQMessagesBubbleImageFactory *bubbleFactory = [[JSQMessagesBubbleImageFactory alloc] initWithBubbleImage:[UIImage imageNamed:@"bubble_tailless"] capInsets:UIEdgeInsetsZero layoutDirection:[UIApplication sharedApplication].userInterfaceLayoutDirection];
        JSQMessagesMediaViewBubbleImageMasker *messageMediaViewBubleImageMasker = [[JSQMessagesMediaViewBubbleImageMasker alloc] initWithBubbleImageFactory:bubbleFactory];
        [messageMediaViewBubleImageMasker applyOutgoingBubbleImageMaskToMediaView:contactView];
        self.cachedContactView = contactView;
    }
    
    return self.cachedContactView;
}

- (CGSize)mediaViewDisplaySize {
    CGFloat maxAttachmentBubbleWidth = [[UIDevice currentDevice] mnz_maxSideForChatBubbleWithMedia:NO] - (10.0f + 40.0f + 10.0f + 10.f);
    
    NSString *title;
    NSString *subtitle;
    if (self.message.type == MEGAChatMessageTypeAttachment) {
        NSUInteger totalNodes = [self.message.nodeList.size unsignedIntegerValue];
        if (totalNodes == 1) {
            MEGANode *node = [self.message.nodeList nodeAtIndex:0];
            title = node.name;
            subtitle = [Helper memoryStyleStringFromByteCount:node.size.longLongValue];
        } else {
            title = [NSString stringWithFormat:AMLocalizedString(@"files", nil), totalNodes];
            NSUInteger totalSize = 0;
            for (NSUInteger i = 0; i < totalNodes; i++) {
                totalSize += [[[self.message.nodeList nodeAtIndex:i] size] unsignedIntegerValue];
            }
            subtitle = [Helper memoryStyleStringFromByteCount:totalSize];
        }
    } else { // MEGAChatMessageTypeContact
        if (self.message.usersCount == 1) {
            title = [self.message userNameAtIndex:0];
            subtitle = [self.message userEmailAtIndex:0];
        } else {
            NSNumber *users = [NSNumber numberWithUnsignedInteger:self.message.usersCount];
            NSString *usersString = AMLocalizedString(@"XContactsSelected", nil);
            title = [usersString stringByReplacingOccurrencesOfString:@"[X]" withString:users.stringValue];
            NSString *emails = [self.message userEmailAtIndex:0];
            for (NSUInteger i = 1; i < self.message.usersCount; i++) {
                emails = [NSString stringWithFormat:@"%@ %@", emails, [self.message userEmailAtIndex:i]];
            }
            subtitle = emails;
        }
    }
    
    CGRect attachmentTitleRect = [title boundingRectWithSize:CGSizeMake(maxAttachmentBubbleWidth, CGFLOAT_MAX)
                                                 options:(NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading)
                                              attributes:@{NSFontAttributeName : [UIFont mnz_SFUIMediumWithSize:15.0f]}
                                                 context:nil];
    
    CGRect attachmentSubtitleRect = [subtitle boundingRectWithSize:CGSizeMake(maxAttachmentBubbleWidth, CGFLOAT_MAX)
                                                options:(NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading)
                                             attributes:@{NSFontAttributeName : [UIFont mnz_SFUIRegularWithSize:13.0f]}
                                                context:nil];
    
    CGFloat minimumLabelsWidth = (attachmentTitleRect.size.width > attachmentSubtitleRect.size.width) ? attachmentTitleRect.size.width : attachmentSubtitleRect.size.width;
    
    // @see MEGAMessageAttachmentView.xib
    CGFloat attachmentBubbleWidth = 10.0f + 40.0f + 10.0f + minimumLabelsWidth + 10.f;
    CGFloat attachmentBubbleHeight = (self.message.type == MEGAChatMessageTypeAttachment) ? 60.0f : 64.0f;
    
    return CGSizeMake(attachmentBubbleWidth, attachmentBubbleHeight);
}

- (NSUInteger)mediaHash {
    return self.hash;
}

- (NSString *)mediaDataType {
    return @"MEGAAttachment";
}

#pragma mark - NSObject

- (NSUInteger)hash {
    return super.hash ^ (NSUInteger)self.message.userHandle;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: image=%@, appliesMediaViewMaskAsOutgoing=%@>",
            [self class], self.message, @(self.appliesMediaViewMaskAsOutgoing)];
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        _message = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(message))];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:self.message forKey:NSStringFromSelector(@selector(message))];
}

#pragma mark - NSCopying

- (instancetype)copyWithZone:(NSZone *)zone {
    MEGAAttachmentMediaItem *copy = [[MEGAAttachmentMediaItem allocWithZone:zone] initWithMEGAChatMessage:self.message];
    copy.appliesMediaViewMaskAsOutgoing = self.appliesMediaViewMaskAsOutgoing;
    return copy;
}


@end
