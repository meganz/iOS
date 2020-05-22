
#import "MEGADialogMediaItem.h"

#import <MobileCoreServices/UTCoreTypes.h>

#import "JSQMessagesBubbleImageFactory.h"
#import "JSQMessagesMediaViewBubbleImageMasker.h"

#import "MEGAChatMessage+MNZCategory.h"
#import "MEGAMessageDialogView.h"
#import "MEGASdkManager.h"
#import "MEGA-Swift.h"

@interface MEGADialogMediaItem () <MEGAMessageDialogViewDelegate>

@property (nonatomic) UIView *cachedDialogView;

@end

@implementation MEGADialogMediaItem

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

- (CGFloat)headingHeight {
    CGFloat bubbleWidth = [[UIDevice currentDevice] mnz_maxSideForChatBubbleWithMedia:NO];
    CGFloat maxMessageTextViewWidth = bubbleWidth - 20.0f;
    UIFont *messageFont = [UIFont systemFontOfSize:15.0f];
    CGRect messageRect = [self.message.content boundingRectWithSize:CGSizeMake(maxMessageTextViewWidth, CGFLOAT_MAX)
                                                            options:(NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading)
                                                         attributes:@{ NSFontAttributeName : messageFont }
                                                            context:nil];
    
    return roundf(messageRect.size.height + 0.5f);
}

- (CGFloat)titleHeight {
    CGFloat bubbleWidth = [[UIDevice currentDevice] mnz_maxSideForChatBubbleWithMedia:NO];
    CGFloat maxTitleTextViewWidth = bubbleWidth - 120.0f;
    UIFont *titleFont = [UIFont systemFontOfSize:15.0f weight:UIFontWeightMedium];
    NSString *titleText;
    switch (self.message.warningDialog) {
        case MEGAChatMessageWarningDialogInitial:
            titleText = AMLocalizedString(@"enableRichUrlPreviews", @"Used in the \"rich previews\", when the user first tries to send an url - we ask them before we generate previews for that URL, since we need to send them unencrypted to our servers.");
            break;
            
        case MEGAChatMessageWarningDialogStandard:
            titleText = AMLocalizedString(@"enableRichUrlPreviews", @"Used in the \"rich previews\", when the user first tries to send an url - we ask them before we generate previews for that URL, since we need to send them unencrypted to our servers.");
            break;
            
        case MEGAChatMessageWarningDialogConfirmation:
            titleText = AMLocalizedString(@"richUrlPreviews", @"Title used in settings that enables the generation of link previews in the chat");
            break;
            
        default:
            break;
    }
    
    CGRect titleRect = [titleText boundingRectWithSize:CGSizeMake(maxTitleTextViewWidth, CGFLOAT_MAX)
                                               options:(NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading)
                                            attributes:@{NSFontAttributeName : titleFont}
                                               context:nil];
    return titleRect.size.height;
}

- (CGFloat)descriptionHeight {
    CGFloat bubbleWidth = [[UIDevice currentDevice] mnz_maxSideForChatBubbleWithMedia:NO];
    CGFloat maxDialogTextViewWidth = bubbleWidth - 120.0f;
    UIFont *dialogFont = [UIFont systemFontOfSize:12.0f];
    NSString *dialogText = self.message.warningDialog == MEGAChatMessageWarningDialogConfirmation ? AMLocalizedString(@"richPreviewsConfirmation", @"After several times (right now set to 3) that the user may had decided to click \"Not now\" (for when being asked if he/she wants a URL preview to be generated for a link, posted in a chat room), we change the \"Not now\" button to \"Never\". If the user clicks it, we ask for one final time - to ensure he wants to not be asked for this anymore and tell him that he can do that in Settings.") : AMLocalizedString(@"richPreviewsFooter", @"Explanation of rich URL previews, given when users can enable/disable them, either in settings or in dialogs");
    CGRect dialogRect = [dialogText boundingRectWithSize:CGSizeMake(maxDialogTextViewWidth, CGFLOAT_MAX)
                                                 options:(NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading)
                                              attributes:@{ NSFontAttributeName : dialogFont }
                                                 context:nil];
    return dialogRect.size.height;
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

    MEGAMessageDialogView *dialogView = [[NSBundle bundleForClass:MEGAMessageDialogView.class] loadNibNamed:@"MEGAMessageDialogView" owner:self options:nil].firstObject;
    
    // Sizes:
    CGSize dialogViewSize = [self mediaViewDisplaySize];
    dialogView.frame = CGRectMake(dialogView.frame.origin.x,
                                  dialogView.frame.origin.y,
                                  dialogViewSize.width,
                                  dialogViewSize.height);
    
    // Colors:
    if (self.message.userHandle == [[MEGASdkManager sharedMEGAChatSdk] myUserHandle]) {
        dialogView.backgroundColor = [UIColor mnz_chatOutgoingBubble:UIScreen.mainScreen.traitCollection];
        dialogView.headingLabel.textColor = [UIColor whiteColor];
    } else {
        dialogView.backgroundColor = [UIColor mnz_chatIncomingBubble:UIScreen.mainScreen.traitCollection];
    }
    
    // Content:
    dialogView.headingLabel.text = self.message.content;
    dialogView.delegate = self;
    
    switch (self.message.warningDialog) {
        case MEGAChatMessageWarningDialogInitial:
            dialogView.titleLabel.text = AMLocalizedString(@"enableRichUrlPreviews", @"Used in the \"rich previews\", when the user first tries to send an url - we ask them before we generate previews for that URL, since we need to send them unencrypted to our servers.");
            dialogView.descriptionLabel.text = AMLocalizedString(@"richPreviewsFooter", @"Explanation of rich URL previews, given when users can enable/disable them, either in settings or in dialogs");
            [dialogView.alwaysAllowButton setTitle:AMLocalizedString(@"alwaysAllow", @"Used in the \"rich previews\", when the user first tries to send an url - we ask them before we generate previews for that URL, since we need to send them unencrypted to our servers.") forState:UIControlStateNormal];
            [dialogView.notNowButton setTitle:AMLocalizedString(@"notNow", @"Used in the \"rich previews\", when the user first tries to send an url - we ask them before we generate previews for that URL, since we need to send them unencrypted to our servers.") forState:UIControlStateNormal];
            
            [dialogView.neverButton removeFromSuperview];
            [dialogView.secondLineView removeFromSuperview];
            
            break;
            
        case MEGAChatMessageWarningDialogStandard:
            dialogView.titleLabel.text = AMLocalizedString(@"enableRichUrlPreviews", @"Used in the \"rich previews\", when the user first tries to send an url - we ask them before we generate previews for that URL, since we need to send them unencrypted to our servers.");
            dialogView.descriptionLabel.text = AMLocalizedString(@"richPreviewsFooter", @"Explanation of rich URL previews, given when users can enable/disable them, either in settings or in dialogs");
            [dialogView.alwaysAllowButton setTitle:AMLocalizedString(@"alwaysAllow", @"Used in the \"rich previews\", when the user first tries to send an url - we ask them before we generate previews for that URL, since we need to send them unencrypted to our servers.") forState:UIControlStateNormal];
            [dialogView.notNowButton setTitle:AMLocalizedString(@"notNow", @"Used in the \"rich previews\", when the user first tries to send an url - we ask them before we generate previews for that URL, since we need to send them unencrypted to our servers.") forState:UIControlStateNormal];
            [dialogView.neverButton setTitle:AMLocalizedString(@"never", @"") forState:UIControlStateNormal];
            
            break;
            
        case MEGAChatMessageWarningDialogConfirmation:
            dialogView.titleLabel.text = AMLocalizedString(@"richUrlPreviews", @"Title used in settings that enables the generation of link previews in the chat");
            dialogView.descriptionLabel.text = AMLocalizedString(@"richPreviewsConfirmation", @"After several times (right now set to 3) that the user may had decided to click \"Not now\" (for when being asked if he/she wants a URL preview to be generated for a link, posted in a chat room), we change the \"Not now\" button to \"Never\". If the user clicks it, we ask for one final time - to ensure he wants to not be asked for this anymore and tell him that he can do that in Settings.");
            [dialogView.alwaysAllowButton setTitle:AMLocalizedString(@"yes", nil) forState:UIControlStateNormal];
            dialogView.alwaysAllowButton.tag = MEGAMessageDialogOptionYes;
            [dialogView.notNowButton setTitle:AMLocalizedString(@"no", nil) forState:UIControlStateNormal];
            
            [dialogView.neverButton removeFromSuperview];
            [dialogView.secondLineView removeFromSuperview];

            break;
            
        default:
            break;
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
    CGFloat headingHeight = [self headingHeight];
    CGFloat titleHeight = [self titleHeight];
    CGFloat descriptionHeight = [self descriptionHeight];
    
    CGFloat imageHeight = 110.0f;
    CGFloat titleAndDescriptionHeight = (titleHeight + 3.0f + descriptionHeight + 3.0f);
    if (imageHeight > titleAndDescriptionHeight) {
        titleAndDescriptionHeight = 110.0f + 14.0f;
    }

    CGFloat optionsHeight = self.message.warningDialog == MEGAChatMessageWarningDialogStandard ? 132.0f : 88.0f;
    
    // @see MEGAMessageDialogView.xib
    CGFloat bubbleHeight = 10.0f + headingHeight + 10.0f + 10.0f + titleAndDescriptionHeight + optionsHeight + 3.0f;
    return CGSizeMake(bubbleWidth, roundf(bubbleHeight + 0.5f));
}

- (NSUInteger)mediaHash {
    return self.hash;
}

- (NSString *)mediaDataType {
    return (NSString *)kUTTypePlainText;
}

- (id)mediaData {
    return self.message.content;
}

#pragma mark - MEGAMessageDialogViewDelegate

- (void)dialogView:(MEGAMessageDialogView *)dialogView didChooseOption:(MEGAMessageDialogOption)option {
    switch (option) {
        case MEGAMessageDialogOptionAlwaysAllow:
            [[MEGASdkManager sharedMEGASdk] enableRichPreviews:YES];
            self.message.warningDialog = MEGAChatMessageWarningDialogNone;
            
            break;
            
        case MEGAMessageDialogOptionNotNowOrNo:
            self.message.warningDialog = MEGAChatMessageWarningDialogDismiss;

            break;
            
        case MEGAMessageDialogOptionNever:
            self.message.warningDialog = MEGAChatMessageWarningDialogConfirmation;
            
            break;
            
        case MEGAMessageDialogOptionYes:
            [[MEGASdkManager sharedMEGASdk] enableRichPreviews:NO];
            self.message.warningDialog = MEGAChatMessageWarningDialogNone;

            break;
    }
    
    self.cachedDialogView = nil;
}

#pragma mark - NSObject

- (NSUInteger)hash {
    return super.hash ^ (NSUInteger)self.message.userHandle ^ self.message.warningDialog;
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
    MEGADialogMediaItem *copy = [[MEGADialogMediaItem allocWithZone:zone] initWithMEGAChatMessage:self.message];
    copy.appliesMediaViewMaskAsOutgoing = self.appliesMediaViewMaskAsOutgoing;
    return copy;
}

@end
