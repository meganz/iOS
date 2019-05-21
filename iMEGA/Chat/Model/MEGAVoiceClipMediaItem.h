
#import "JSQAudioMediaItem.h"

#import "MEGAChatMessage.h"

NS_ASSUME_NONNULL_BEGIN

extern NSNotificationName kVoiceClipsShouldPauseNotification;

@interface MEGAVoiceClipMediaItem : JSQAudioMediaItem <JSQMessageMediaData, NSCoding, NSCopying, NSDiscardableContent>

- (instancetype)initWithMEGAChatMessage:(MEGAChatMessage *)message;

@end

NS_ASSUME_NONNULL_END
