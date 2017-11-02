
#import "MEGAChatBaseRequestDelegate.h"

@interface MEGAChatEnableDisableVideoRequestDelegate : MEGAChatBaseRequestDelegate

- (id)init NS_UNAVAILABLE;

- (instancetype)initWithCompletion:(void (^)(MEGAChatError *error))completion;

@end
