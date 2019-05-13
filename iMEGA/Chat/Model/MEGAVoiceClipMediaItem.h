
#import "JSQAudioMediaItem.h"

#import "MEGAChatMessage.h"

NS_ASSUME_NONNULL_BEGIN

extern NSNotificationName kVoiceClipWillPlayOrRecordNotification;

@interface MEGAVoiceClipMediaItem : JSQAudioMediaItem <JSQMessageMediaData, NSCoding, NSCopying>

- (instancetype)initWithMEGAChatMessage:(MEGAChatMessage *)message;

@end

NS_ASSUME_NONNULL_END
