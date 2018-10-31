
#import "MEGACallEndedMediaItem.h"
#import "MEGAMessageCallEndedView.h"

#import "MEGASdkManager.h"
#import "NSString+MNZCategory.h"
#import "UIImage+MNZCategory.h"

@interface MEGACallEndedMediaItem ()

@property (strong, nonatomic) UIView *cachedCallEndedView;
@property (copy, nonatomic) MEGAChatMessage *message;

@end

@implementation MEGACallEndedMediaItem

#pragma mark - Initialization

- (instancetype)initWithMEGAChatMessage:(MEGAChatMessage *)message {
    self = [super init];
    if (self) {
        _message = message;
        _cachedCallEndedView = nil;
    }
    return self;
}

- (void)clearCachedMediaViews {
    [super clearCachedMediaViews];
    _cachedCallEndedView = nil;
}

#pragma mark - Setters

- (void)setMessage:(MEGAChatMessage *)message {
    _message = [message copy];
    _cachedCallEndedView = nil;
}

- (void)setAppliesMediaViewMaskAsOutgoing:(BOOL)appliesMediaViewMaskAsOutgoing {
    [super setAppliesMediaViewMaskAsOutgoing:appliesMediaViewMaskAsOutgoing];
    _cachedCallEndedView = nil;
}

#pragma mark - JSQMessageMediaData protocol

- (UIView *)mediaView {
    if (self.message == nil) {
        return nil;
    }
    
    if (self.cachedCallEndedView == nil) {
        MEGAMessageCallEndedView *callEndedView = [[[NSBundle bundleForClass:[MEGAMessageCallEndedView class]] loadNibNamed:@"MEGAMessageCallEndedView" owner:self options:nil] objectAtIndex:0];
        // Sizes:
        CGSize callEndedViewSize = [self mediaViewDisplaySize];
        callEndedView.frame = CGRectMake(callEndedView.frame.origin.x,
                                       callEndedView.frame.origin.y,
                                       callEndedViewSize.width,
                                       callEndedViewSize.height);
        
        callEndedView.callEndedImageView.image = [UIImage mnz_imageByEndCallReason:self.message.termCode userHandle:self.message.userHandle];
        callEndedView.callEndedLabel.text = [NSString mnz_stringByEndCallReason:self.message.termCode userHandle:self.message.userHandle duration:self.message.duration];
        self.cachedCallEndedView = callEndedView;
    }
    
    return self.cachedCallEndedView;
}

- (CGSize)mediaViewDisplaySize {
    return CGSizeMake([[UIDevice currentDevice] mnz_maxSideForChatBubbleWithMedia:NO], 48.0f);
}

- (NSUInteger)mediaHash {
    return self.hash;
}

- (NSString *)mediaDataType {
    return @"MEGACallEnded";
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
    MEGACallEndedMediaItem *copy = [[MEGACallEndedMediaItem allocWithZone:zone] initWithMEGAChatMessage:self.message];
    copy.appliesMediaViewMaskAsOutgoing = self.appliesMediaViewMaskAsOutgoing;
    return copy;
}

@end
