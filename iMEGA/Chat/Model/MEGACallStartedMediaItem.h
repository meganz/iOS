
#import "JSQMediaItem.h"
#import "MEGAChatMessage.h"

NS_ASSUME_NONNULL_BEGIN

@interface MEGACallStartedMediaItem : JSQMediaItem <JSQMessageMediaData, NSCoding, NSCopying>

- (instancetype)initWithMEGAChatMessage:(MEGAChatMessage *)message;

@end

NS_ASSUME_NONNULL_END
