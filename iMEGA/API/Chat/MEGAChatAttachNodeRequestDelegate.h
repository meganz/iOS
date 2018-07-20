
#import "MEGAChatBaseRequestDelegate.h"

@interface MEGAChatAttachNodeRequestDelegate : MEGAChatBaseRequestDelegate

- (id)init NS_UNAVAILABLE;

- (instancetype)initWithCompletion:(void (^)(MEGAChatRequest *request, MEGAChatError *error))completion;

@end
