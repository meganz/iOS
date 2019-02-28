#import "MEGACallStartedMediaItem.h"
#import "MEGAMessageCallStartedView.h"

@interface MEGACallStartedMediaItem ()

@property (strong, nonatomic) UIView *cachedCallStartedView;
@property (copy, nonatomic) MEGAChatMessage *message;

@end

@implementation MEGACallStartedMediaItem

#pragma mark - Initialization

- (instancetype)initWithMEGAChatMessage:(MEGAChatMessage *)message {
    self = [super init];
    if (self) {
        _message = message;
        _cachedCallStartedView = nil;
    }
    return self;
}

- (void)clearCachedMediaViews {
    [super clearCachedMediaViews];
    _cachedCallStartedView = nil;
}

#pragma mark - Setters

- (void)setMessage:(MEGAChatMessage *)message {
    _message = [message copy];
    _cachedCallStartedView = nil;
}

- (void)setAppliesMediaViewMaskAsOutgoing:(BOOL)appliesMediaViewMaskAsOutgoing {
    [super setAppliesMediaViewMaskAsOutgoing:appliesMediaViewMaskAsOutgoing];
    _cachedCallStartedView = nil;
}

#pragma mark - JSQMessageMediaData protocol

- (UIView *)mediaView {
    if (self.message == nil) {
        return nil;
    }
    
    if (self.cachedCallStartedView == nil) {
        MEGAMessageCallStartedView *callStartedView = [[[NSBundle bundleForClass:[MEGAMessageCallStartedView class]] loadNibNamed:@"MEGAMessageCallStartedView" owner:self options:nil] objectAtIndex:0];
        // Sizes:
        CGSize callStartedViewSize = [self mediaViewDisplaySize];
        callStartedView.frame = CGRectMake(callStartedView.frame.origin.x,
                                         callStartedView.frame.origin.y,
                                         callStartedViewSize.width,
                                         callStartedViewSize.height);
        
        callStartedView.callStartedLabel.text = AMLocalizedString(@"Call Started", @"Text to inform the user there is an active call and is participating");
        self.cachedCallStartedView = callStartedView;
    }
    
    return self.cachedCallStartedView;
}

- (CGSize)mediaViewDisplaySize {
    return CGSizeMake([[UIDevice currentDevice] mnz_maxSideForChatBubbleWithMedia:NO], 48.0f);
}

- (NSUInteger)mediaHash {
    return self.hash;
}

- (NSString *)mediaDataType {
    return @"MEGACallStarted";
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
    MEGACallStartedMediaItem *copy = [[MEGACallStartedMediaItem allocWithZone:zone] initWithMEGAChatMessage:self.message];
    copy.appliesMediaViewMaskAsOutgoing = self.appliesMediaViewMaskAsOutgoing;
    return copy;
}

@end
