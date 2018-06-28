
#import "JSQMediaItem.h"
#import "MEGAChatMessage.h"

@interface MEGAAttachmentMediaItem : JSQMediaItem <JSQMessageMediaData, NSCoding, NSCopying>

- (instancetype)initWithMEGAChatMessage:(MEGAChatMessage *)message;

@end
