
#import "MEGAAttachmentMediaItem.h"
#import "MEGAMessageAttachmentView.h"

#import "JSQMessagesBubbleImageFactory.h"
#import "JSQMessagesMediaViewBubbleImageMasker.h"
#import "UIImage+GKContact.h"
#import "UIColor+JSQMessages.h"

#import "UIImageView+MNZCategory.h"
#import "MEGASdkManager.h"

@interface MEGAAttachmentMediaItem ()

@property (strong, nonatomic) UIView *cachedContactView;

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

- (CGSize)mediaViewDisplaySize {
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        return CGSizeMake(315.0f, 225.0f);
    }
    
    // TODO: make width based on screen width?
    return CGSizeMake(250.0f, 77.0f);
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
        MEGAMessageAttachmentView *contactView = [[[NSBundle bundleForClass:[MEGAMessageAttachmentView class]] loadNibNamed:@"MEGAMessageAttachmentView" owner:self options:nil] objectAtIndex:0];
        if (self.message.userHandle == [[MEGASdkManager sharedMEGAChatSdk] myUserHandle]) {
            contactView.backgroundColor = [UIColor mnz_grayE3E3E3];
        } else {
            contactView.backgroundColor = [UIColor whiteColor];
        }
        if (self.message.type == MEGAChatMessageTypeAttachment) {
            NSUInteger totalNodes = [self.message.nodeList.size unsignedIntegerValue];
            NSString *filename;
            NSString *size;
            if (totalNodes == 1) {
                MEGANode *node = [self.message.nodeList nodeAtIndex:0];
                filename = node.name;
                size = [NSByteCountFormatter stringFromByteCount:node.size.longLongValue  countStyle:NSByteCountFormatterCountStyleMemory];
                [contactView.avatarImage mnz_setImageForExtension:filename.pathExtension];
            } else {
                filename = [NSString stringWithFormat:AMLocalizedString(@"files", nil), totalNodes];
                NSUInteger totalSize = 0;
                for (NSUInteger i = 0; i < totalNodes; i++) {
                    totalSize += [[[self.message.nodeList nodeAtIndex:i] size] unsignedIntegerValue];
                }
                size = [NSByteCountFormatter stringFromByteCount:totalSize  countStyle:NSByteCountFormatterCountStyleMemory];
                UIImage *avatar = [UIImage imageForName:[NSString stringWithFormat:@"%lu", totalNodes] size:contactView.avatarImage.frame.size backgroundColor:[UIColor mnz_gray999999] textColor:[UIColor whiteColor] font:[UIFont mnz_SFUIRegularWithSize:(contactView.avatarImage.frame.size.width/2.0f)]];
                contactView.avatarImage.image = avatar;
            }
            contactView.titleLabel.text = filename;
            contactView.detailLabel.text = size;
        } else { // MEGAChatMessageTypeContact
            if (self.message.usersCount == 1) {
                [contactView.avatarImage mnz_setImageForUserHandle:[self.message userHandleAtIndex:0]];
                contactView.titleLabel.text = [self.message userNameAtIndex:0];
                contactView.detailLabel.text = [self.message userEmailAtIndex:0];
            } else {
                NSNumber *users = [NSNumber numberWithUnsignedInteger:self.message.usersCount];
                NSString *usersString = AMLocalizedString(@"XContactsSelected", nil);
                usersString = [usersString stringByReplacingOccurrencesOfString:@"[X]" withString:users.stringValue];
                UIImage *avatar = [UIImage imageForName:[NSString stringWithFormat:@"%lu", (unsigned long)self.message.usersCount] size:contactView.avatarImage.frame.size backgroundColor:[UIColor mnz_gray999999] textColor:[UIColor whiteColor] font:[UIFont mnz_SFUIRegularWithSize:(contactView.avatarImage.frame.size.width/2.0f)]];                
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

- (NSUInteger)mediaHash {
    return self.hash;
}

#pragma mark - NSObject

- (NSUInteger)hash {
    return super.hash ^ self.message.userHandle;
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
