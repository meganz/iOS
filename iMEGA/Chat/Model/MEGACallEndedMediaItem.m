
#import "MEGACallEndedMediaItem.h"
#import "MEGAMessageCallEndedView.h"

#import "MEGASdkManager.h"
#import "NSString+MNZCategory.h"
#import "UIImage+MNZCategory.h"

@interface MEGACallEndedMediaItem ()

@property (strong, nonatomic) UIView *cachedContactView;
@property (copy, nonatomic) MEGAChatMessage *message;

@end

@implementation MEGACallEndedMediaItem

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
    return CGSizeMake([[UIScreen mainScreen] bounds].size.width - 50, 48.0f);
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
        MEGAMessageCallEndedView *contactView = [[[NSBundle bundleForClass:[MEGAMessageCallEndedView class]] loadNibNamed:@"MEGAMessageCallEndedView" owner:self options:nil] objectAtIndex:0];
        // Sizes:
        CGSize contactViewSize = [self mediaViewDisplaySize];
        contactView.frame = CGRectMake(contactView.frame.origin.x,
                                       contactView.frame.origin.y,
                                       contactViewSize.width,
                                       contactViewSize.height);
        
        contactView.callEndedImageView.image = [UIImage mnz_imageByEndCallReason:self.message.termCode userHandle:self.message.userHandle];
        contactView.callEndedLabel.text = [NSString mnz_stringByEndCallReason:self.message.termCode userHandle:self.message.userHandle duration:self.message.duration];
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

- (NSString *)mediaDataType {
    return @"MEGACallEnded";
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
