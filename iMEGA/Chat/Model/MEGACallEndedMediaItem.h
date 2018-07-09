
#import "JSQMediaItem.h"
#import "MEGAChatMessage.h"

@interface MEGACallEndedMediaItem : JSQMediaItem <JSQMessageMediaData, NSCoding, NSCopying>

- (instancetype)initWithMEGAChatMessage:(MEGAChatMessage *)message;

@end
