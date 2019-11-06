
#import "MEGALocationMediaItem.h"

#import <MobileCoreServices/UTCoreTypes.h>

#import "JSQMessagesBubbleImageFactory.h"
#import "JSQMessagesMediaViewBubbleImageMasker.h"

#import "MEGAMessageGeoLocationView.h"
#import "MEGAChatMessage+MNZCategory.h"
#import "MEGASdkManager.h"
#import "NSString+MNZCategory.h"
#import "NSURL+MNZCategory.h"
#import "UIDevice+MNZCategory.h"
#import "UIFont+MNZCategory.h"
#import "UIImageView+MNZCategory.h"

@interface MEGALocationMediaItem ()

@property (copy, nonatomic) MEGAChatMessage *message;
@property (nonatomic) MEGAMessageGeoLocationView *cachedImageView;

@end

@implementation MEGALocationMediaItem

#pragma mark - Initialization

- (instancetype)initWithMEGAChatMessage:(MEGAChatMessage *)message {
    self = [super init];
    if (self) {
        _message = message;
        _cachedImageView = nil;
    }
    return self;
}

- (void)clearCachedMediaViews {
    [super clearCachedMediaViews];
    self.cachedImageView = nil;
}

#pragma mark - Setters

- (void)setMessage:(MEGAChatMessage *)message {
    self.message = [message copy];
    self.cachedImageView = nil;
}

- (void)setAppliesMediaViewMaskAsOutgoing:(BOOL)appliesMediaViewMaskAsOutgoing {
    [super setAppliesMediaViewMaskAsOutgoing:appliesMediaViewMaskAsOutgoing];
    self.cachedImageView = nil;
}

#pragma mark - JSQMessageMediaData protocol

- (UIView *)mediaView {
    if (self.cachedImageView) {
        return self.cachedImageView;
    }
    
    NSBundle *bundle = [NSBundle bundleForClass:MEGAMessageGeoLocationView.class];
    NSArray *array = [bundle loadNibNamed:@"MEGAMessageGeoLocationView" owner:self options:nil];
    MEGAMessageGeoLocationView *geolocationView = array.firstObject;
    
    CGSize size = [self mediaViewDisplaySize];
    geolocationView.frame = CGRectMake(geolocationView.frame.origin.x,
                                  geolocationView.frame.origin.y,
                                  size.width,
                                  size.height);
    
    // Colors:
    if (self.message.userHandle == [[MEGASdkManager sharedMEGAChatSdk] myUserHandle]) {
        geolocationView.backgroundColor = [UIColor mnz_chatBlueForTraitCollection:UIScreen.mainScreen.traitCollection];
    } else {
        geolocationView.backgroundColor = [UIColor mnz_chatGrayForTraitCollection:UIScreen.mainScreen.traitCollection];
    }
    
    NSData *imageData = [[NSData alloc] initWithBase64EncodedString:self.message.containsMeta.geolocation.image options:NSDataBase64DecodingIgnoreUnknownCharacters];
    UIImage *image = [UIImage imageWithData:imageData];
    geolocationView.imageView.image = image;
    geolocationView.titleLabel.text = AMLocalizedString(@"Pinned Location", @"Text shown in location-type messages");
    geolocationView.subtitleLabel.text = [NSString mnz_convertCoordinatesLatitude:self.message.containsMeta.geolocation.latitude longitude:self.message.containsMeta.geolocation.longitude];
    
    if (@available(iOS 11.0, *)) {
        self.cachedImageView.accessibilityIgnoresInvertColors = YES;
    }
    
    // Bubble:
    JSQMessagesBubbleImageFactory *bubbleFactory = [[JSQMessagesBubbleImageFactory alloc] initWithBubbleImage:[UIImage imageNamed:@"bubble_tailless"] capInsets:UIEdgeInsetsZero layoutDirection:[UIApplication sharedApplication].userInterfaceLayoutDirection];
    JSQMessagesMediaViewBubbleImageMasker *messageMediaViewBubleImageMasker = [[JSQMessagesMediaViewBubbleImageMasker alloc] initWithBubbleImageFactory:bubbleFactory];
    [messageMediaViewBubleImageMasker applyOutgoingBubbleImageMaskToMediaView:geolocationView];
    
    self.cachedImageView = geolocationView;
    
    return self.cachedImageView;
}

- (CGSize)mediaViewDisplaySize {
    CGFloat width = [UIDevice.currentDevice mnz_maxSideForChatBubbleWithMedia:YES];
    CGFloat height = 171.0;
    return CGSizeMake(width, height);
}

- (NSUInteger)mediaHash {
    return self.hash;
}

- (NSString *)mediaDataType {
    return (NSString *)kUTTypePlainText;
}

- (id)mediaData {
    return self.message.containsMeta.textMessage;
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
    MEGALocationMediaItem *copy = [[MEGALocationMediaItem allocWithZone:zone] initWithMEGAChatMessage:self.message];
    copy.appliesMediaViewMaskAsOutgoing = self.appliesMediaViewMaskAsOutgoing;
    return copy;
}

@end
