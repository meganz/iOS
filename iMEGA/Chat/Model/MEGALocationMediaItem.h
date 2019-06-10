
#import "JSQLocationMediaItem.h"

@class MEGAChatMessage;

NS_ASSUME_NONNULL_BEGIN

@interface MEGALocationMediaItem : JSQMediaItem  <JSQMessageMediaData, NSCoding, NSCopying>

- (instancetype)initWithMEGAChatMessage:(MEGAChatMessage *)message;

@end

NS_ASSUME_NONNULL_END
