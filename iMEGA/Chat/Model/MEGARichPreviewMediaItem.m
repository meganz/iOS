
#import "MEGARichPreviewMediaItem.h"

#import <MobileCoreServices/UTCoreTypes.h>

#import "JSQMessagesBubbleImageFactory.h"
#import "JSQMessagesMediaViewBubbleImageMasker.h"

#import "Helper.h"
#import "MEGAMessageRichPreviewView.h"
#import "MEGAChatMessage+MNZCategory.h"
#import "MEGASdkManager.h"
#import "NSString+MNZCategory.h"
#import "NSURL+MNZCategory.h"
#import "UIFont+MNZCategory.h"
#import "UIImageView+MNZCategory.h"

@interface MEGARichPreviewMediaItem()

@property (nonatomic) MEGAMessageRichPreviewView *cachedDialogView;

@end

@implementation MEGARichPreviewMediaItem

#pragma mark - Initialization

- (instancetype)initWithMEGAChatMessage:(MEGAChatMessage *)message {
    self = [super init];
    if (self) {
        _message = message;
        _cachedDialogView = nil;
    }
    return self;
}

- (void)clearCachedMediaViews {
    [super clearCachedMediaViews];
    _cachedDialogView = nil;
}

#pragma mark - Private

- (CGFloat)richPreviewInfoHeight {
    CGFloat richPreviewInfoHeight = 84.0f;
    if (self.message.type == MEGAChatMessageTypeContainsMeta) {
        if (!self.message.containsMeta.richPreview.image) {
            if (self.message.containsMeta.richPreview.title.mnz_isEmpty && self.message.containsMeta.richPreview.previewDescription.mnz_isEmpty) {
                richPreviewInfoHeight = 10.0f + 14.0f;
            } else if (self.message.containsMeta.richPreview.title.mnz_isEmpty) {
                richPreviewInfoHeight = (15.0f * self.cachedDialogView.descriptionLabel.numberOfLines) + 10.0f + 14.0f;
            } else if (self.message.containsMeta.richPreview.previewDescription.mnz_isEmpty) {
                richPreviewInfoHeight = 18.0f + 10.0f + 14.0f;
            }
        }
    }
    return richPreviewInfoHeight;
}

#pragma mark - Setters

- (void)setMessage:(MEGAChatMessage *)message {
    _message = [message copy];
    _cachedDialogView = nil;
}

- (void)setAppliesMediaViewMaskAsOutgoing:(BOOL)appliesMediaViewMaskAsOutgoing {
    [super setAppliesMediaViewMaskAsOutgoing:appliesMediaViewMaskAsOutgoing];
    _cachedDialogView = nil;
}

#pragma mark - JSQMessageMediaData protocol

- (UIView *)mediaView {
    if (self.message == nil) {
        return nil;
    }
    
    if (self.cachedDialogView) {
        return self.cachedDialogView;
    }
    
    MEGAMessageRichPreviewView *dialogView = [[NSBundle bundleForClass:MEGAMessageRichPreviewView.class] loadNibNamed:@"MEGAMessageRichPreviewView" owner:self options:nil].firstObject;
    
    // Sizes:
    CGSize dialogViewSize = [self mediaViewDisplaySize];
    dialogView.frame = CGRectMake(dialogView.frame.origin.x,
                                  dialogView.frame.origin.y,
                                  dialogViewSize.width,
                                  dialogViewSize.height);
    
    // Colors:
    if (self.message.userHandle == [[MEGASdkManager sharedMEGAChatSdk] myUserHandle]) {
        dialogView.backgroundColor = [UIColor mnz_green00BFA5];
        dialogView.contentTextView.textColor = [UIColor whiteColor];
    } else {
        dialogView.backgroundColor = [UIColor mnz_grayE2EAEA];
        dialogView.contentTextView.textColor = [UIColor blackColor];
    }
    dialogView.contentTextView.linkTextAttributes = @{ NSForegroundColorAttributeName : dialogView.contentTextView.textColor,
                                                       NSUnderlineStyleAttributeName : @(NSUnderlineStyleSingle | NSUnderlinePatternSolid) };
    
    // Content:
    dialogView.contentTextView.dataDetectorTypes = UIDataDetectorTypeAll;
    if (self.message.type == MEGAChatMessageTypeContainsMeta) {
        dialogView.contentTextView.text = self.message.containsMeta.richPreview.text;
        if (self.message.containsMeta.richPreview.title.mnz_isEmpty) {
            dialogView.titleLabel.hidden = YES;
        } else {
            dialogView.titleLabel.text = self.message.containsMeta.richPreview.title;
        }
        
        if (self.message.containsMeta.richPreview.previewDescription.mnz_isEmpty) {
            dialogView.descriptionLabel.hidden = YES;
        } else {
            dialogView.descriptionLabel.text = self.message.containsMeta.richPreview.previewDescription;
        }
        NSURL *url = [NSURL URLWithString:self.message.containsMeta.richPreview.url];
        dialogView.linkLabel.text = url.host;
        NSString *imageString = self.message.containsMeta.richPreview.image;
        if (imageString) {
            NSData *imageData = [[NSData alloc] initWithBase64EncodedString:imageString options:NSDataBase64DecodingIgnoreUnknownCharacters];
            dialogView.imageImageView.image = [UIImage imageWithData:imageData];
        } else {
            dialogView.imageView.hidden = YES;
        }
        NSString *iconString = self.message.containsMeta.richPreview.icon;
        if (iconString) {
            NSData *iconData = [[NSData alloc] initWithBase64EncodedString:iconString options:NSDataBase64DecodingIgnoreUnknownCharacters];
            dialogView.iconImageView.image = [UIImage imageWithData:iconData];
        } else {
            dialogView.iconImageView.hidden = YES;
        }
        dialogView.richViewHeightConstraint.constant = 10.0f + [self richPreviewInfoHeight] + 10.0f;
    } else {
        URLType type = self.message.MEGALink.mnz_type;
        if (type == URLTypeFileLink) {
            dialogView.contentTextView.text = self.message.content;
            dialogView.titleLabel.text = self.message.node.name;
            dialogView.descriptionLabel.text = [Helper memoryStyleStringFromByteCount:self.message.richNumber.longLongValue > 0 ? self.message.richNumber.longLongValue : 0];
            dialogView.linkLabel.text = @"mega.nz";
            [dialogView.imageImageView mnz_setThumbnailByNode:self.message.node];
            dialogView.iconImageView.image = [UIImage imageNamed:@"favicon"];
        } else if (type == URLTypeFolderLink) {
            dialogView.contentTextView.text = self.message.content;
            dialogView.titleLabel.text = self.message.richTitle;
            dialogView.descriptionLabel.text = [Helper memoryStyleStringFromByteCount:self.message.richNumber.longLongValue > 0 ? self.message.richNumber.longLongValue : 0];
            dialogView.linkLabel.text = @"mega.nz";
            dialogView.imageImageView.image = [Helper folderImage];
            dialogView.descriptionLabel.text = [NSString stringWithFormat:@"%@\n%@", self.message.richString, dialogView.descriptionLabel.text];
            dialogView.iconImageView.image = [UIImage imageNamed:@"favicon"];
        } else if (type == URLTypePublicChatLink) {
            dialogView.contentTextView.text = self.message.content;
            dialogView.imageImageView.image = [UIImage imageNamed:@"groupChat"];
            dialogView.titleLabel.text = self.message.richString;
            dialogView.descriptionLabel.text = [NSString stringWithFormat:@"%lld %@", self.message.richNumber.longLongValue, AMLocalizedString(@"participants", @"Label to describe the section where you can see the participants of a group chat")];
            dialogView.iconImageView.image = [UIImage imageNamed:@"favicon"];
            dialogView.linkLabel.text = @"mega.nz";
        }
    }

    // Bubble:
    JSQMessagesBubbleImageFactory *bubbleFactory = [[JSQMessagesBubbleImageFactory alloc] initWithBubbleImage:[UIImage imageNamed:@"bubble_tailless"] capInsets:UIEdgeInsetsZero layoutDirection:[UIApplication sharedApplication].userInterfaceLayoutDirection];
    JSQMessagesMediaViewBubbleImageMasker *messageMediaViewBubleImageMasker = [[JSQMessagesMediaViewBubbleImageMasker alloc] initWithBubbleImageFactory:bubbleFactory];
    [messageMediaViewBubleImageMasker applyOutgoingBubbleImageMaskToMediaView:dialogView];
    
    self.cachedDialogView = dialogView;
    
    return self.cachedDialogView;
}

- (CGSize)mediaViewDisplaySize {
    CGFloat bubbleWidth = [[UIDevice currentDevice] mnz_maxSideForChatBubbleWithMedia:NO];
    CGFloat maxTextViewWidth = bubbleWidth - 20.0f;
    UIFont *messageFont = [UIFont mnz_SFUIRegularWithSize:15.0f];
    NSString *text = self.message.type == MEGAChatMessageTypeContainsMeta ? self.message.containsMeta.richPreview.text : self.message.content;
    CGRect messageRect = [text boundingRectWithSize:CGSizeMake(maxTextViewWidth, CGFLOAT_MAX)
                                            options:(NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading)
                                         attributes:@{ NSFontAttributeName : messageFont }
                                            context:nil];
    
    CGFloat richPreviewInfoHeight = [self richPreviewInfoHeight];
    // The bubble height is the message plus the rich preview height plus the margins, @see MEGAMessageRichPreviewView.xib
    CGFloat bubbleHeight = 10.0f + messageRect.size.height + 10.0f + (10.0f + richPreviewInfoHeight + 10.0f) + 3.0f;
    
    return CGSizeMake(bubbleWidth, bubbleHeight);
}

- (NSUInteger)mediaHash {
    return self.hash;
}

- (NSString *)mediaDataType {
    return (NSString *)kUTTypePlainText;
}

- (id)mediaData {
    return self.message.type == MEGAChatMessageTypeContainsMeta ? self.message.containsMeta.richPreview.text : self.message.content;
}

#pragma mark - NSObject

- (NSUInteger)hash {
    return super.hash ^ (NSUInteger)self.message.userHandle;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: message=%@>", [self class], self.message];
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
    MEGARichPreviewMediaItem *copy = [[MEGARichPreviewMediaItem allocWithZone:zone] initWithMEGAChatMessage:self.message];
    copy.appliesMediaViewMaskAsOutgoing = self.appliesMediaViewMaskAsOutgoing;
    return copy;
}

@end
