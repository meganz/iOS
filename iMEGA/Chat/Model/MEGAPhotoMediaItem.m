
#import "MEGAPhotoMediaItem.h"

#import <MobileCoreServices/UTCoreTypes.h>

#import "JSQMessagesMediaPlaceholderView.h"

#import "NSString+MNZCategory.h"
#import "UIDevice+MNZCategory.h"
#import "UIImageView+MNZCategory.h"
#import "MEGAChatMessage+MNZCategory.h"
#import "MEGAGetPreviewRequestDelegate.h"

@interface MEGAPhotoMediaItem ()

@property (nonatomic) MEGAChatMessage *message;
@property (nonatomic) MEGANode *node;
@property (nonatomic) NSString *previewFilePath;

@property (nonatomic) UIImageView *cachedImageView;
@property (nonatomic) UIView *activityIndicator;

@end

@implementation MEGAPhotoMediaItem

#pragma mark - Initialization

- (instancetype)initWithMEGAChatMessage:(MEGAChatMessage *)message {
    if (self = [super init]) {
        _message = message;
        _node = [message.nodeList nodeAtIndex:0];
        
        if (_node.hasPreview) {
            NSString *previewsDirectory = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject stringByAppendingPathComponent:@"previewsV3"];
            _previewFilePath = [previewsDirectory stringByAppendingPathComponent:_node.base64Handle];
            
            if ([NSFileManager.defaultManager fileExistsAtPath:_previewFilePath]) {
                self.image = [UIImage imageWithContentsOfFile:_previewFilePath];
            } else if (![NSFileManager.defaultManager fileExistsAtPath:previewsDirectory]) {
                NSError *error;
                if (![[NSFileManager defaultManager] createDirectoryAtPath:previewsDirectory withIntermediateDirectories:NO attributes:nil error:&error]) {
                    MEGALogError(@"Create directory at path failed with error: %@", error);
                }
            }
        }
    }
    return self;
}

- (void)clearCachedMediaViews {
    [super clearCachedMediaViews];
    self.cachedImageView = nil;
}

- (void)setAppliesMediaViewMaskAsOutgoing:(BOOL)appliesMediaViewMaskAsOutgoing {
    [super setAppliesMediaViewMaskAsOutgoing:appliesMediaViewMaskAsOutgoing];
    self.cachedImageView = nil;
}

#pragma mark - Private

- (void)configureCachedImageViewWithImagePath:(NSString *)imagePath {
    self.image = [UIImage imageWithContentsOfFile:imagePath];
    if (self.image) {
        self.cachedImageView.image = self.image;

        if (self.node.name.mnz_isVideoPathExtension) {
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
        
        self.message.richNumber = @(YES);
    }
}

#pragma mark - JSQMessageMediaData protocol

- (UIView *)mediaView {
    if (self.cachedImageView) {
        return self.cachedImageView;
    }
    
    CGSize size = [self mediaViewDisplaySize];
    self.cachedImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)];
    self.cachedImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.cachedImageView.clipsToBounds = YES;
    self.cachedImageView.layer.cornerRadius = 4.0f;
    self.cachedImageView.layer.borderColor = UIColor.mnz_black000000_01.CGColor;
    self.cachedImageView.layer.borderWidth = 1.0f;
    
    if (@available(iOS 11.0, *)) {
        self.cachedImageView.accessibilityIgnoresInvertColors = YES;
    }
    
    if (self.image) {
        [self configureCachedImageViewWithImagePath:self.previewFilePath];
    } else if (self.previewFilePath) {
        self.activityIndicator = [JSQMessagesMediaPlaceholderView viewWithActivityIndicator];
        self.activityIndicator.frame = self.cachedImageView.frame;
        [self.cachedImageView addSubview:self.activityIndicator];
        MEGAGetPreviewRequestDelegate *getPreviewRequestDelegate = [[MEGAGetPreviewRequestDelegate alloc] initWithCompletion:^(MEGARequest *request) {
            [self configureCachedImageViewWithImagePath:request.file];
            [self.activityIndicator removeFromSuperview];
        }];
        
        [[MEGASdkManager sharedMEGASdk] getPreviewNode:self.node destinationFilePath:self.previewFilePath delegate:getPreviewRequestDelegate];
    } else {
        [self.cachedImageView mnz_setImageForExtension:self.node.name.pathExtension];
    }
    
    return self.cachedImageView;
}

- (CGSize)mediaViewDisplaySize {
    CGFloat width, height;
    CGFloat maxSide = [[UIDevice currentDevice] mnz_maxSideForChatBubbleWithMedia:YES];
    if (self.image) {
        if (self.image.size.width > self.image.size.height) {
            width = maxSide;
            height = width * (self.image.size.height / self.image.size.width);
        } else {
            height = maxSide;
            width = height * (self.image.size.width / self.image.size.height);
        }
    } else if (self.node.hasPreview && self.node.width > 0 && self.node.height > 0) {
        if (self.node.width > self.node.height) {
            width = maxSide;
            height = width * ((CGFloat) self.node.height / self.node.width);
        } else {
            height = maxSide;
            width = height * ((CGFloat) self.node.width / self.node.height);
        }
    } else {
        width = height = maxSide;
    }
    
    return CGSizeMake(width, height);
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
    MEGAPhotoMediaItem *copy = [[MEGAPhotoMediaItem allocWithZone:zone] initWithMEGAChatMessage:self.message];
    copy.appliesMediaViewMaskAsOutgoing = self.appliesMediaViewMaskAsOutgoing;
    return copy;
}

@end
