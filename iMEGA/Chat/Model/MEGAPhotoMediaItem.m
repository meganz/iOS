
#import "MEGAPhotoMediaItem.h"

#import <MobileCoreServices/UTCoreTypes.h>

#import "JSQMessagesMediaPlaceholderView.h"

#import "NSString+MNZCategory.h"
#import "UIDevice+MNZCategory.h"
#import "UIImageView+MNZCategory.h"
#import "MEGAGetPreviewRequestDelegate.h"

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
        _cachedImageView.layer.cornerRadius = 5;
        
        if (@available(iOS 11.0, *)) {
            self.cachedImageView.accessibilityIgnoresInvertColors = YES;
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

#pragma mark - Private

- (void)configureCachedImageViewWithImagePath:(NSString *)imagePath {
    UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
    if (image) {
        self.cachedImageView.image = image;
        
        if (self.node.name.mnz_isMultimediaPathExtension) {
            UIImageView *playImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"playButton"]];
            playImageView.center = _cachedImageView.center;
            [self.cachedImageView addSubview:playImageView];
        }
        
        if (self.node.duration > 0) {
            UILabel *durationLabel = [[UILabel alloc] init];
            durationLabel.lineBreakMode = NSLineBreakByWordWrapping;
            durationLabel.numberOfLines = 0;
            durationLabel.textColor = [UIColor whiteColor];
            durationLabel.textAlignment = NSTextAlignmentRight;
            NSString *textContent = [NSString mnz_stringFromTimeInterval:self.node.duration];
            NSRange textRange = NSMakeRange(0, textContent.length);
            NSMutableAttributedString *textString = [[NSMutableAttributedString alloc] initWithString:textContent];
            UIFont *font = [UIFont mnz_SFUIRegularWithSize:12];
            [textString addAttribute:NSFontAttributeName value:font range:textRange];
            NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
            paragraphStyle.lineSpacing = 1.21;
            [textString addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:textRange];
            durationLabel.attributedText = textString;
            durationLabel.layer.shadowOffset = CGSizeMake(0, 1);
            durationLabel.layer.shadowColor = [[UIColor colorWithRed:0 green:0 blue:0 alpha:0.2] CGColor];
            durationLabel.layer.shadowOpacity = 1;
            durationLabel.layer.shadowRadius = 2;
            [durationLabel sizeToFit];
            [self.cachedImageView addSubview:durationLabel];
            durationLabel.frame = CGRectMake(4, self.cachedImageView.frame.size.height - durationLabel.frame.size.height - 4, durationLabel.frame.size.width, durationLabel.frame.size.height);
        }
    }
}

#pragma mark - JSQMessageMediaData protocol

- (UIView *)mediaView {
    if (self.node.hasPreview) {
        NSString *previewFilePath = [[[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"previewsV3"] stringByAppendingPathComponent:self.node.base64Handle];
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:previewFilePath]) {
            [self configureCachedImageViewWithImagePath:previewFilePath];
        } else {
            self.activityIndicator = [JSQMessagesMediaPlaceholderView viewWithActivityIndicator];
            self.activityIndicator.frame = self.cachedImageView.frame;
            [self.cachedImageView addSubview:self.activityIndicator];
            MEGAGetPreviewRequestDelegate *getPreviewRequestDelegate = [[MEGAGetPreviewRequestDelegate alloc] initWithCompletion:^(MEGARequest *request) {
                [self configureCachedImageViewWithImagePath:request.file];
                [self.activityIndicator removeFromSuperview];
            }];
            
            [[MEGASdkManager sharedMEGASdk] getPreviewNode:self.node destinationFilePath:previewFilePath delegate:getPreviewRequestDelegate];
        }
    } else {
        [self.cachedImageView mnz_setImageForExtension:self.node.name.pathExtension];
    }
    
    return self.cachedImageView;
}

- (CGSize)mediaViewDisplaySize {
    CGFloat displaySize = [[UIDevice currentDevice] mnz_widthForChatBubble];
    return CGSizeMake(displaySize, displaySize);
}

- (UIView *)mediaPlaceholderView {
    UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [indicator startAnimating];
    return indicator;
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
