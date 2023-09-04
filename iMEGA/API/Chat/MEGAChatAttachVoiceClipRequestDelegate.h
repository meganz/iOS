#import "MEGAChatBaseRequestDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@interface MEGAChatAttachVoiceClipRequestDelegate : MEGAChatBaseRequestDelegate

- (id)init NS_UNAVAILABLE;

- (instancetype)initWithCompletion:(void (^)(MEGAChatRequest *request, MEGAChatError *error))completion;

@end

NS_ASSUME_NONNULL_END
