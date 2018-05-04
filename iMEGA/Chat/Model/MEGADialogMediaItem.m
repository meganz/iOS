
#import "MEGADialogMediaItem.h"

#import "JSQMessagesBubbleImageFactory.h"
#import "JSQMessagesMediaViewBubbleImageMasker.h"

#import "MEGAChatMessage+MNZCategory.h"
#import "MEGAMessageDialogView.h"
#import "MEGASdkManager.h"

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

- (CGSize)mediaViewDisplaySize {
    CGFloat displaySize = [[UIDevice currentDevice] mnz_widthForChatBubble];
    return CGSizeMake(displaySize, 228.0f);
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
    
    if (!self.cachedDialogView) {
        MEGAMessageDialogView *dialogView = [[[NSBundle bundleForClass:MEGAMessageDialogView.class] loadNibNamed:@"MEGAMessageDialogView" owner:self options:nil] objectAtIndex:0];
        
        // Sizes:
        CGSize dialogViewSize = [self mediaViewDisplaySize];
        dialogView.frame = CGRectMake(dialogView.frame.origin.x,
                                      dialogView.frame.origin.y,
                                      dialogViewSize.width,
                                      dialogViewSize.height);
        
        // Colors:
        if (self.message.userHandle == [[MEGASdkManager sharedMEGAChatSdk] myUserHandle]) {
            dialogView.backgroundColor = [UIColor mnz_green00BFA5];
            dialogView.headingLabel.textColor = [UIColor whiteColor];
        } else {
            dialogView.backgroundColor = [UIColor mnz_grayE2EAEA];
        }
        
        // Content:
        dialogView.headingLabel.text = self.message.content;
        dialogView.neverButton.hidden = self.message.warningDialog != MEGAChatMessageWarningDialogStandard;
        dialogView.delegate = self;
        
        // Bubble:
        JSQMessagesBubbleImageFactory *bubbleFactory = [[JSQMessagesBubbleImageFactory alloc] initWithBubbleImage:[UIImage imageNamed:@"bubble_tailless"] capInsets:UIEdgeInsetsZero layoutDirection:[UIApplication sharedApplication].userInterfaceLayoutDirection];
        JSQMessagesMediaViewBubbleImageMasker *messageMediaViewBubleImageMasker = [[JSQMessagesMediaViewBubbleImageMasker alloc] initWithBubbleImageFactory:bubbleFactory];
        [messageMediaViewBubleImageMasker applyOutgoingBubbleImageMaskToMediaView:dialogView];
        self.cachedDialogView = dialogView;

    }
    
    return self.cachedDialogView;
}

- (NSUInteger)mediaHash {
    return self.hash;
}

#pragma mark - MEGAMessageDialogViewDelegate

- (void)dialogView:(MEGAMessageDialogView *)dialogView chosedOption:(MEGAMessageDialogOption)option {
    switch (option) {
        case MEGAMessageDialogOptionNever:
            [[MEGASdkManager sharedMEGASdk] enableRichPreviews:NO];
            self.message.warningDialog = MEGAChatMessageWarningDialogNone;
            
            break;
            
        case MEGAMessageDialogOptionNotNow:
            self.message.warningDialog = MEGAChatMessageWarningDialogDismiss;

            break;
            
        case MEGAMessageDialogOptionAlwaysAccept:
            [[MEGASdkManager sharedMEGASdk] enableRichPreviews:YES];
            self.message.warningDialog = MEGAChatMessageWarningDialogNone;

            break;
    }
    
    self.cachedDialogView = nil;
}

#pragma mark - NSObject

- (NSUInteger)hash {
    return super.hash ^ self.message.userHandle ^ self.message.warningDialog;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: message=%@>", [self class], self.message];
}

- (NSString *)mediaDataType {
    return @"MEGADialog";
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
