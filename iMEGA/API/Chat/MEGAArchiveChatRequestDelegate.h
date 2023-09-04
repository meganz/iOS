#import "MEGAChatBaseRequestDelegate.h"

@interface MEGAArchiveChatRequestDelegate : MEGAChatBaseRequestDelegate

- (id)init NS_UNAVAILABLE;

- (instancetype)initWithCompletion:(void (^)(MEGAChatRoom *))completion;

@end
