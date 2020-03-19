
#import "MEGACallManagementMediaItem.h"
#import "MEGAMessageCallManagementView.h"

#import "MEGAChatMessage+MNZCategory.h"
#import "MEGASDKManager.h"
#import "NSString+MNZCategory.h"
#import "UIImage+MNZCategory.h"

@interface MEGACallManagementMediaItem ()

@property (strong, nonatomic) UIView *cachedView;
@property (copy, nonatomic) MEGAChatMessage *message;

@end

@implementation MEGACallManagementMediaItem

#pragma mark - Initialization

- (instancetype)initWithMEGAChatMessage:(MEGAChatMessage *)message {
    self = [super init];
    if (self) {
        _message = message;
        _cachedView = nil;
    }
    return self;
}

- (void)clearCachedMediaViews {
    [super clearCachedMediaViews];
    _cachedView = nil;
}

#pragma mark - Setters

- (void)setMessage:(MEGAChatMessage *)message {
    _message = [message copy];
    _cachedView = nil;
}

- (void)setAppliesMediaViewMaskAsOutgoing:(BOOL)appliesMediaViewMaskAsOutgoing {
    [super setAppliesMediaViewMaskAsOutgoing:appliesMediaViewMaskAsOutgoing];
    _cachedView = nil;
}

#pragma mark - JSQMessageMediaData protocol

- (UIView *)mediaView {
    if (self.message == nil) {
        return nil;
    }
    
    if (self.cachedView == nil) {
        MEGAMessageCallManagementView *callView = [[NSBundle bundleForClass:MEGAMessageCallManagementView.class] loadNibNamed:@"MEGAMessageCallManagementView" owner:self options:nil].firstObject;
        // Sizes:
        CGSize callViewSize = [self mediaViewDisplaySize];
        callView.frame = CGRectMake(callView.frame.origin.x,
                                       callView.frame.origin.y,
                                       callViewSize.width,
                                       callViewSize.height);
        
        if (self.message.type == MEGAChatMessageTypeCallEnded) {
            callView.callImageView.image = [UIImage mnz_imageByEndCallReason:self.message.termCode userHandle:self.message.userHandle];
            MEGAChatRoom *chatRoom = [MEGASdkManager.sharedMEGAChatSdk chatRoomForChatId:self.message.chatId];
            callView.callLabel.text = [NSString mnz_stringByEndCallReason:self.message.termCode userHandle:self.message.userHandle duration:@(self.message.duration) isGroup:chatRoom.isGroup];
        } else { // MEGAChatMessageTypeCallStarted
            callView.callImageView.image = [UIImage imageNamed:@"callWithXIncoming"];
            callView.callLabel.text = AMLocalizedString(@"Call Started", @"Text to inform the user there is an active call and is participating");
        }
        self.cachedView = callView;
    }
    
    return self.cachedView;
}

- (CGSize)mediaViewDisplaySize {
    return CGSizeMake([[UIDevice currentDevice] mnz_maxSideForChatBubbleWithMedia:NO], 48.0f);
}

- (NSUInteger)mediaHash {
    return self.hash;
}

- (NSString *)mediaDataType {
    return @"MEGACallManagement";
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
    MEGACallManagementMediaItem *copy = [[MEGACallManagementMediaItem allocWithZone:zone] initWithMEGAChatMessage:self.message];
    copy.appliesMediaViewMaskAsOutgoing = self.appliesMediaViewMaskAsOutgoing;
    return copy;
}

@end
