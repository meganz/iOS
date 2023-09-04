#import "MEGAChatBaseRequestDelegate.h"

@interface MEGAChatChangeGroupNameRequestDelegate : MEGAChatBaseRequestDelegate

- (id)init NS_UNAVAILABLE;

- (instancetype)initWithCompletion:(void (^)(MEGAChatError *error))completion;

@end
