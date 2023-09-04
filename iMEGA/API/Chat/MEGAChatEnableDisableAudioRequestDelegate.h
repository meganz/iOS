#import "MEGAChatBaseRequestDelegate.h"

@interface MEGAChatEnableDisableAudioRequestDelegate : MEGAChatBaseRequestDelegate

- (id)init NS_UNAVAILABLE;

- (instancetype)initWithCompletion:(void (^)(MEGAChatError *error))completion;

@end
