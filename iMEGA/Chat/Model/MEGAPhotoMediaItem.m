
#import "MEGAPhotoMediaItem.h"

#import "JSQMessagesBubbleImageFactory.h"
#import "JSQMessagesMediaViewBubbleImageMasker.h"
#import "JSQMessagesMediaPlaceholderView.h"

#import "NSString+MNZCategory.h"
#import "UIImageView+MNZCategory.h"
#import "MEGAGetPreviewRequestDelegate.h"

#import <MobileCoreServices/UTCoreTypes.h>

@interface MEGAPhotoMediaItem ()

@property (strong, nonatomic) UIImageView *cachedImageView;
@property (strong, nonatomic) UIView *activityIndicator;

@end

@implementation MEGAPhotoMediaItem

- (instancetype)initWithMEGANode:(MEGANode *)node {
    self = [super init];
    if (self) {
        _node = node;
        
        CGSize size = [self mediaViewDisplaySize];
        _cachedImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)];
        _cachedImageView.contentMode = UIViewContentModeScaleAspectFill;
        _cachedImageView.clipsToBounds = YES;
        _cachedImageView.layer.cornerRadius = 4;
        _cachedImageView.backgroundColor = [UIColor grayColor];
        
        _activityIndicator = [JSQMessagesMediaPlaceholderView viewWithActivityIndicator];
        _activityIndicator.frame = _cachedImageView.frame;

        [_cachedImageView addSubview:_activityIndicator];
        
        NSString *previewFilePath = [[[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"previewsV3"] stringByAppendingPathComponent:self.node.base64Handle];
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:previewFilePath]) {
            [self configureCachedImageViewWithImagePath:previewFilePath];
        } else {
            if ([self.node hasPreview]) {
                MEGAGetPreviewRequestDelegate *getPreviewRequestDelegate = [[MEGAGetPreviewRequestDelegate alloc] initWithCompletion:^(MEGARequest *request) {
                    [self configureCachedImageViewWithImagePath:request.file];
                }];
                [self.cachedImageView mnz_setImageForExtension:self.node.name.pathExtension];
                [[MEGASdkManager sharedMEGASdk] getPreviewNode:self.node destinationFilePath:previewFilePath delegate:getPreviewRequestDelegate];
            } else {
                [self.cachedImageView mnz_setImageForExtension:self.node.name.pathExtension];
            }
        }
    }
    return self;
}

- (void)clearCachedMediaViews {
    [super clearCachedMediaViews];
    _cachedImageView = nil;
}

- (void)setNode:(MEGANode *)node {
    _node = [node copy];
    _cachedImageView = nil;
}

- (void)setAppliesMediaViewMaskAsOutgoing:(BOOL)appliesMediaViewMaskAsOutgoing {
    [super setAppliesMediaViewMaskAsOutgoing:appliesMediaViewMaskAsOutgoing];
    _cachedImageView = nil;
}

- (CGSize)mediaViewDisplaySize {
    CGSize size;
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        size = CGSizeMake(315.0f, 315.0f);
    } else {
        size = CGSizeMake(210.0f, 210.0f);
    }
    
    return size;
}

- (UIView *)mediaPlaceholderView {
    UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [indicator startAnimating];
    return indicator;
}

#pragma mark - Private

- (void)configureCachedImageViewWithImagePath:(NSString *)imagePath {
    self.cachedImageView.image = [UIImage imageWithContentsOfFile:imagePath];
    [self.activityIndicator removeFromSuperview];
    if (self.node.name.mnz_isMultimediaPathExtension) {
        UIImageView *playImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"video_list"]];
        playImageView.center = [self.cachedImageView convertPoint:self.cachedImageView.center fromView:self.cachedImageView.superview];
        [self.cachedImageView addSubview:playImageView];
    }
    [_activityIndicator removeFromSuperview];
}

#pragma mark - JSQMessageMediaData protocol

- (UIView *)mediaView {
    return self.cachedImageView;
}

- (NSUInteger)mediaHash {
    return self.hash;
}

- (NSString *)mediaDataType {
    return (NSString *)kUTTypeJPEG;
}

- (id)mediaData {
    return UIImageJPEGRepresentation(self.image, 1);
}

#pragma mark - NSObject

- (NSUInteger)hash {
    return super.hash ^ self.image.hash;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: image=%@, appliesMediaViewMaskAsOutgoing=%@>",
            [self class], self.image, @(self.appliesMediaViewMaskAsOutgoing)];
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        _node = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(node))];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:self.node forKey:NSStringFromSelector(@selector(node))];
}

#pragma mark - NSCopying

- (instancetype)copyWithZone:(NSZone *)zone {
    MEGAPhotoMediaItem *copy = [[MEGAPhotoMediaItem allocWithZone:zone] initWithMEGANode:self.node];
    copy.appliesMediaViewMaskAsOutgoing = self.appliesMediaViewMaskAsOutgoing;
    return copy;
}

@end
