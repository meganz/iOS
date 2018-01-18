
#import "MEGAChatBaseRequestDelegate.h"

@interface MEGAChatCreateChatGroupRequestDelegate : MEGAChatBaseRequestDelegate

- (id)init NS_UNAVAILABLE;

- (instancetype)initWithCompletion:(void (^)(MEGAChatRoom *))completion;

@end
