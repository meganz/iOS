
#import "JSQAudioMediaItem.h"

#import "MEGAChatMessage.h"

NS_ASSUME_NONNULL_BEGIN

@interface MEGAVoiceClipMediaItem : JSQAudioMediaItem <JSQMessageMediaData, NSCoding, NSCopying>

- (instancetype)initWithMEGAChatMessage:(MEGAChatMessage *)message;

@end

NS_ASSUME_NONNULL_END
