
#import "MEGAChatBaseRequestDelegate.h"

@interface MEGAChatAttachNodeRequestDelegate : MEGAChatBaseRequestDelegate

- (id)init NS_UNAVAILABLE;

- (instancetype)initWithCompletion:(void (^)(MEGAChatError *error))completion;

@end
