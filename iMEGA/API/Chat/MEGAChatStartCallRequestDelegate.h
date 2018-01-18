
#import "MEGAChatBaseRequestDelegate.h"

@interface MEGAChatStartCallRequestDelegate : MEGAChatBaseRequestDelegate

- (id)init NS_UNAVAILABLE;

- (instancetype)initWithCompletion:(void (^)(MEGAChatError *error))completion;

@end
