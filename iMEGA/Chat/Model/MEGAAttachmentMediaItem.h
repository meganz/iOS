
#import "JSQMediaItem.h"
#import "MEGAChatMessage.h"

@interface MEGAAttachmentMediaItem : JSQMediaItem <JSQMessageMediaData, NSCoding, NSCopying>

@property (copy, nonatomic) MEGAChatMessage *message;

- (instancetype)initWithMEGAChatMessage:(MEGAChatMessage *)message;

@end
