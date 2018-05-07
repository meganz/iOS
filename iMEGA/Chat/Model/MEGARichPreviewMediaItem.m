
#import "MEGARichPreviewMediaItem.h"

#import <MobileCoreServices/UTCoreTypes.h>

#import "JSQMessagesBubbleImageFactory.h"
#import "JSQMessagesMediaViewBubbleImageMasker.h"

#import "MEGAMessageRichPreviewView.h"
#import "MEGAChatMessage+MNZCategory.h"
#import "MEGASdkManager.h"
#import "UIFont+MNZCategory.h"

@interface MEGARichPreviewMediaItem()

@property (nonatomic) UIView *cachedDialogView;

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
    dialogView.contentTextView.text = self.message.containsMeta.richPreview.text;
    dialogView.titleLabel.text = self.message.containsMeta.richPreview.title;
    dialogView.descriptionLabel.text = self.message.containsMeta.richPreview.previewDescription;
    dialogView.linkLabel.text = self.message.containsMeta.richPreview.url;
    NSString *imageString = self.message.containsMeta.richPreview.image;
    if (imageString) {
        NSData *imageData = [[NSData alloc] initWithBase64EncodedString:imageString options:NSDataBase64DecodingIgnoreUnknownCharacters];
        dialogView.imageImageView.image = [UIImage imageWithData:imageData];
    }
    NSString *iconString = self.message.containsMeta.richPreview.icon;
    if (iconString) {
        NSData *iconData = [[NSData alloc] initWithBase64EncodedString:iconString options:NSDataBase64DecodingIgnoreUnknownCharacters];
        dialogView.iconImageView.image = [UIImage imageWithData:iconData];
    }

    // Bubble:
    JSQMessagesBubbleImageFactory *bubbleFactory = [[JSQMessagesBubbleImageFactory alloc] initWithBubbleImage:[UIImage imageNamed:@"bubble_tailless"] capInsets:UIEdgeInsetsZero layoutDirection:[UIApplication sharedApplication].userInterfaceLayoutDirection];
    JSQMessagesMediaViewBubbleImageMasker *messageMediaViewBubleImageMasker = [[JSQMessagesMediaViewBubbleImageMasker alloc] initWithBubbleImageFactory:bubbleFactory];
    [messageMediaViewBubleImageMasker applyOutgoingBubbleImageMaskToMediaView:dialogView];
    
    self.cachedDialogView = dialogView;
    
    return self.cachedDialogView;
}

- (CGSize)mediaViewDisplaySize {
    CGFloat bubbleWidth = [[UIDevice currentDevice] mnz_widthForChatBubble];
    CGFloat maxTextViewWidth = bubbleWidth - 20.0f;
    UIFont *messageFont = [UIFont mnz_SFUIRegularWithSize:15.0f];
    CGRect messageRect = [self.message.containsMeta.richPreview.text boundingRectWithSize:CGSizeMake(maxTextViewWidth, CGFLOAT_MAX)
                                                                                  options:(NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading)
                                                                               attributes:@{ NSFontAttributeName : messageFont }
                                                                                  context:nil];
    // The bubble height is the message plus the rich preview height plus the margins, @see MEGAMessageRichPreviewView.xib
    CGFloat bubbleHeight = 10.0f + messageRect.size.height + 10.0f + 104.0f + 3.0f;
    return CGSizeMake(bubbleWidth, bubbleHeight);
}

- (NSUInteger)mediaHash {
    return self.hash;
}

- (NSString *)mediaDataType {
    return (NSString *)kUTTypeText;
}

- (id)mediaData {
    return self.message.containsMeta.richPreview.text;
}

#pragma mark - NSObject

- (NSUInteger)hash {
    return super.hash ^ self.message.userHandle;
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
