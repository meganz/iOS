
#import "MEGAChatBaseRequestDelegate.h"

@interface MEGAChatAnswerCallRequestDelegate : MEGAChatBaseRequestDelegate

- (id)init NS_UNAVAILABLE;

- (instancetype)initWithCompletion:(void (^)(MEGAChatError *error))completion;

@end
